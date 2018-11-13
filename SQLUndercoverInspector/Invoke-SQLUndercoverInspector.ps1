# ensure this doesn't run without dbatools
# the '#' is necessary, not a comment :)
#requires -module dbatools

#$Filename is only used for opening in IE for testing purposes
$Filename = "C:\Temp\Inspector.html"

#Central logging server and database name , Mandatory for the collection
$CentralServer = "SQL02"
$LoggingDB = "SQLUndercoverDB"
[string]$ModuleConfig = $null 

$Builds = @() 
$InvalidServers = @()
[System.Collections.ArrayList]$ActiveServers = @()
$Pos = 0


#Set default value for $ModuleConfig, if this is null or blank thats fine as it will be set to a literal string value of "NULL" otherwise it will retain the value passed 
IF(!$ModuleConfig){$ModuleConfig="NULL"}ELSE{$ModuleConfig="`'$ModuleConfig`'"}

#Connect to the database
Write-Host "[$CentralServer] - Checking central server connectivity" -ForegroundColor Yellow
$CentralConnection = Get-DbaDatabase -SqlInstance $CentralServer -Database $LoggingDB -ErrorAction Stop -WarningAction Stop
Write-Host "[$CentralServer] - Central server connectivity ok" -ForegroundColor green

#Check that the logging database specified exists
IF(!$CentralConnection.Name){
write-host "[$CentralServer] - Logging database specified does not exist" -ForegroundColor Red 
Break
}

#Get list of active servers from the Inspector Currentservers table
$Query = "EXEC [$LoggingDB].[Inspector].[PSGetServers];"
$ActiveServers = $CentralConnection.Query($Query)


$ActiveServers | ForEach-Object {
Write-Host "[$($_.Servername)] - Getting Inspector build info" -ForegroundColor White
$Query = "EXEC [$LoggingDB].[Inspector].[PSGetInspectorBuild];"
$Connection = Get-DbaDatabase -SqlInstance $_.Servername -Database $LoggingDB -ErrorAction Stop -WarningAction Stop
#Check that the logging database specified exists
IF(!$Connection.Name){
write-host "[$($_.Servername)] - Logging database [$LoggingDB] does not exist" -ForegroundColor Red
#Remove Server from the Array if the logging database does not exist because we no longer want to process it.
$InvalidServers += $Pos
$Pos += 1
Return
}
$Builds += $Connection.Query($Query)
$Pos += 1
Clear-Variable Connection
}

#Remove Invalid servers from ActiveServers array
$InvalidServers | ForEach-Object {
Write-Host "[Validation] - Removing Invalid server [$($ActiveServers.Servername[$_])] from the Active servers list" -ForegroundColor Yellow
$ActiveServers.Remove($ActiveServers[$_])
}


#region Minimum Build check and build comparison
IF ($($Builds | Sort-Object  -Property Build | SELECT Build -First 1 -ExpandProperty Build) -lt 1.2){
write-host "[Validation] - One or more servers do not meet the Minimum build: 1.2" -ForegroundColor Red 
write-output $($Builds | SELECT Servername,Build | ?{$_.Build -lt 1.2} | format-table) 
Break
}
write-host "[Validation] - Minimum build check ok" -foregroundcolor Green


#Compare min build and max build , if they do not match then break
IF ($($Builds | Sort-Object  -Property Build | SELECT Build -First 1 -ExpandProperty Build) -ne $($Builds | Sort-Object  -Property Build -Descending | SELECT Build -First 1 -ExpandProperty Build)){
write-host "[Validation] - Inspector builds do not match" -ForegroundColor Red
write-output $($Builds | SELECT Servername,Build | format-table) 
Break
}
write-host "[Validation] - Active server Inspector builds match" -ForegroundColor Green
#endregion Minimum Build check and build comparison


#region Collect settings data for syncing between servers, Dynamically create variables for settings tables prefixed with 'Central' to store results of the queries
Write-Host "[$CentralServer] - Getting centralised settings" -ForegroundColor White
$SettingsTables = @("Settings","CurrentServers","EmailRecipients","EmailConfig","Modules")
$SettingsTables | ForEach-Object {
$Columnnames = @()
$Query = "EXEC [$LoggingDB].[Inspector].[PSGetColumns] @Tablename = '$_'"
$Columnnames = $CentralConnection.Query($Query)
$Query = "SELECT $($Columnnames.Columnnames) FROM [$LoggingDB].[Inspector].[$_]"
Set-Variable -Name $("Central"+$_) -Value ($CentralConnection.Query($Query))
}


#Validate $ModuleConfig
IF($ModuleConfig -eq "NULL"){
write-host "[Validation] - ModuleConfig = NULL (Auto determined)" -ForegroundColor White
}
ELSEIF ($ModuleConfig -notin $CentralModules.ModuleConfig_Desc){
write-host "[Validation] - ModuleConfig does not exist, valid options are: $($CentralModules.ModuleConfig_Desc) or leave blank for auto determined ModuleConfig" -ForegroundColor Red
Break
}
write-host "[Validation] - ModuleConfig ok" -ForegroundColor Green

#Populate variable with the LinkedServername Value from the Settings table
$LinkedServername = $($CentralSettings | Where-Object -Property Description -eq LinkedServername | Select-Object Value)

IF($LinkedServername.Value.Length -gt 1){
write-host "[Validation] - The Inspector has been configured for use with a Linked server please reinstall the Inspector with @LinkedServername = NULL" -ForegroundColor Red
Break
}
write-host "[Validation] - Inspector configured correctly for PS collection" -ForegroundColor Green
#endregion Collect settings data for syncing between servers


#Initialise WriteTableOptions
$WriteTableOptions = @{
                SqlInstance = ""
                Database = $LoggingDB
                Schema = 'Inspector'
                Table = ""
                NoTableLock = $true
            }

#region For each active server run collection
$ActiveServers.Servername |
    ForEach-Object -Begin {

        #Initalise the variable as an array
        $CollectedData = @()
        $Columnnames = @()
        $ExecutedModules = @()


    } -Process {

        #Store Currently processed server 
        $CurrentlyProcessedServer = $_

        Write-Host "[$CurrentlyProcessedServer] - Connecting..." -ForegroundColor Yellow
        $Connection = Get-DbaDatabase -SqlInstance $_ -Database $LoggingDB

        #Reset $Query Variable 
        Clear-Variable -Name Query,Columnnames

        if ($CurrentlyProcessedServer -ne $CentralServer) {
            Write-Host "[$CurrentlyProcessedServer] - Started settings sync" -ForegroundColor Cyan
            $WriteTableOptions.SqlInstance = $CurrentlyProcessedServer 
            #Truncate or Delete from settings tables
            $SettingsTables | sort-object | ForEach-Object { 
            $SettingsTablename = $_
            $WriteTableOptions.Table = $SettingsTablename
               
            IF ($SettingsTablename -eq "Modules"){
            Write-Host "[$CurrentlyProcessedServer] - Deleting from table [Inspector].[$SettingsTablename]" -ForegroundColor White
            $Query = "DELETE FROM [$LoggingDB].[Inspector].[$SettingsTablename];"
            } ELSE{
            Write-Host "[$CurrentlyProcessedServer] - Truncating table [Inspector].[$SettingsTablename]" -ForegroundColor White
            $Query = "TRUNCATE TABLE [$LoggingDB].[Inspector].[$SettingsTablename];"
            }
            $Connection.Query($Query)   
            } 

            #Sync data in settings tables (Reverse order to satisfy foreign key relationship between CurrentServers and Modules
            $SettingsTables | sort-object -Descending | ForEach-Object { 
            $SettingsTablename = $_
            $WriteTableOptions.Table = $SettingsTablename
               
            Write-Host "[$CurrentlyProcessedServer] - Syncing data for table [Inspector].[$SettingsTablename]" -ForegroundColor White 
            Write-DbaDataTable @WriteTableOptions -Inputobject $(Get-Variable $("Central"+$SettingsTablename) -ValueOnly)
            } 
        Write-Host "[$CurrentlyProcessedServer] - Finished settings sync" -ForegroundColor Cyan
        }
        
        
        #Run Collection Stored procedure
        Write-Host "[$CurrentlyProcessedServer] - Executing [Inspector].[InspectorDataCollection] @ModuleConfig = $($ModuleConfig),@PSCollection = 1" -ForegroundColor White
        $Query = "EXEC [$LoggingDB].[Inspector].[InspectorDataCollection] @ModuleConfig = $ModuleConfig,@PSCollection = 1;"
        $ExecutedModules = $Connection.Query($Query)

     #Get executed modules list for this server from the output of the InspectorDataCollection stored procedure where server is not the central server
     $ExecutedModules = $ExecutedModules | ?{$_.Servername -ne $CentralServer} | SELECT Servername,Module,Tablename,StageTablename,StageProcname,TableAction,InsertAction,RetentionInDays

     IF ($CurrentlyProcessedServer -NE $CentralServer){
     Write-Host "[$CurrentlyProcessedServer] - Starting data retrieval loop" -ForegroundColor Cyan
     }

     ForEach ($Module in $ExecutedModules)
     {
     $Modulename = $Module.Module
     $Tablename = $Module.Tablename.ToString().split(",")
     $TableAction = $Module.TableAction.ToString().split(",")
     $StageTablename = $Module.StageTablename.ToString().split(",")
     $StageProcname = $Module.StageProcname.ToString()
     $InsertAction = $Module.InsertAction.ToString().split(",")
     $RetentionInDays = $Module.RetentionInDays.ToString().split(",")
     $Pos = 0
     Write-Host "[$CurrentlyProcessedServer] - Getting data for: $Modulename" -ForegroundColor White
        $Tablename | ForEach-Object {
            $Query= @()
            $BaseTable = $_
            #Switch Write destination to central server
            $WriteTableOptions.SqlInstance = $CentralServer

            #If Table action less than 3 ,delete/delete with retention Delete data from the table accordingly
            IF ([int]$($TableAction[$Pos]) -lt 3) {
            $WriteTableOptions.Table = $($Tablename[$Pos])
            #Delete logged info for server from Central DB
            $Query = "EXEC sp_executesql N'DELETE FROM [$LoggingDB].[Inspector].[$($Tablename[$Pos])] WHERE [Servername] = @Servername"
            IF ([int]$($TableAction[$Pos]) -eq 2){
                #Append the retention period to the Where clause
                $Query = $Query + " AND [Log_Date] < DATEADD(DAY,-@Retention,GETDATE())',N'@Servername NVARCHAR(128),@Retention INT',@Servername = '$CurrentlyProcessedServer',@Retention = $($RetentionInDays[$Pos]);"
                }
            IF ([int]$($TableAction[$Pos]) -eq 1) {
                #Delete all data in table for server from 
                $Query = $Query + "',N'@Servername NVARCHAR(128)',@Servername = '$CurrentlyProcessedServer'"
                }
            }
            IF ([int]$($TableAction[$Pos]) -eq 3) {
            $WriteTableOptions.Table = $($StageTablename[$Pos])
            #Truncate stage table 
            $Query = "TRUNCATE TABLE [$LoggingDB].[Inspector].[$($StageTablename[$Pos])];"
            }
            $CentralConnection.Query($Query)

            #Retrieve data from local server table
            $Query = "EXEC [$LoggingDB].[Inspector].[PSGetColumns] @Tablename = '$($Tablename[$Pos])'"
            $Columnnames = $Connection.Query($Query) 
 
            IF ([int]$($InsertAction[$Pos]) -eq 1){
            #Get all data for the current server
            $Query = "EXEC sp_executesql N'SELECT $($Columnnames.Columnnames) FROM [$LoggingDB].[Inspector].[$($Tablename[$Pos])] WHERE Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$CurrentlyProcessedServer'"
            }
            IF ([int]$($InsertAction[$Pos]) -eq 2) {
            #Get data recorded for today only for the current server
            $Query = "EXEC sp_executesql N'DECLARE @Today DATE = CAST(GETDATE() AS DATE); SELECT $($Columnnames.Columnnames) FROM [$LoggingDB].[Inspector].[$($Tablename[$Pos])] WHERE Log_Date >= @Today AND Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$CurrentlyProcessedServer'"
            }
            $CollectedData = $Connection.Query($Query)

            
            #$CollectedData | Write-DbaDataTable @WriteTableOptions -KeepNull
            IF ($CollectedData){
            Write-DbaDataTable @WriteTableOptions -Inputobject $CollectedData -KeepNull
            }
            $Pos += 1

            #Remove data table for every iteration after the data has been inserted into the central server logging database
            Clear-Variable -Name CollectedData,Columnnames,Module
            
            
            }
            IF ($StageProcname) {
            Write-Host "[$CurrentlyProcessedServer] - Executing staging proc: $StageProcname on [$CentralServer]" -ForegroundColor White
            $Query = "EXEC [$LoggingDB].[Inspector].[$StageProcname] @Servername = '$CurrentlyProcessedServer';"
            $CentralConnection.Query($Query)
            }
            
        }
        IF ($CurrentlyProcessedServer -ne $CentralServer){
        Write-Host "[$CurrentlyProcessedServer] - Finished data retrieval loop" -ForegroundColor Cyan  
        }  
     }


#Run the Inspector report from the Central logging server
Write-Host $("[$CentralServer] - Executing [Inspector].[SQLUnderCoverInspectorReport] 
                    @EmailDistributionGroup = 'DBA', 
                    @ModuleDesc = $ModuleConfig, 
                    @EmailRedWarningsOnly = 0, 
                    @Theme = 'Dark', 
                    @PSCollection = 1") -ForegroundColor White

$Query = $("
EXEC [$LoggingDB].[Inspector].[SQLUnderCoverInspectorReport] 
@EmailDistributionGroup = 'DBA', 
@ModuleDesc = $ModuleConfig, 
@EmailRedWarningsOnly = 0, 
@Theme = 'Dark', 
@PSCollection = 1
")
$CentralConnection.Query($Query)
Write-Host "[$CentralServer] - SQLUndercover Report has completed" -ForegroundColor Green
#endregion For each active server run collection


#region opening of the report via powershell for testing purposes
#Retrieve the latest report
$Query = @"
SELECT TOP 1 ReportData
FROM [$LoggingDB].[Inspector].[ReportData]
ORDER BY ID DESC 
"@
$Report = $CentralConnection.Query($Query)

#Output the report to a html file
$Report | Format-Table -Wrap -HideTableHeaders | Out-File -FilePath $($Filename) -Width 4000

#Open html file in IE
$IE = new-object -com internetexplorer.application
$IE.navigate2($($Filename))
$IE.visible = $true
#endregion Optional opening of the report via powershell





