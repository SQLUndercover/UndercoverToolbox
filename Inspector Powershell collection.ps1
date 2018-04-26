# ensure this doesn't run without dbatools
# the '#' is necessary, not a comment :)
#requires -module dbatools

# Report Filename
$ReportFile = 'C:\temp\Report1.html'

# Central logging server
$CentralServer = 'SQL01'
$LoggingDB = 'SQLUndercover'

# Connect to the database
$CentralConnection = Get-DbaDatabase -SqlInstance $CentralServer -Database $LoggingDB

#Get list of active servers from the Inspector Currentservers table
$Query = "SELECT Servername FROM [$LoggingDB].[Inspector].[CurrentServers] WHERE IsActive = 1"
$ActiveServers = $CentralConnection.Query($Query)

Write-Output "Retrieving centralised settings from $CentralServer"

#Get list of settings from the Central server logging database
$Query = "SELECT [ID],[Description],[Value] FROM [$LoggingDB].[Inspector].[Settings]"
$CurrentSettings = $CentralConnection.Query($Query)

#For each active server get a list of enabled Modules
$ActiveServers.Servername |
    ForEach-Object -Begin {

        #Initalise the variable as an array
        $EnabledModules = @()
        $CentralDriveSpace = @()
        $CentralGrowths = @()

    } -Process {

        Write-Output "Retreiving Enabled modules config for Server: $_"

        $Query = @"
EXEC sp_executesql N'DECLARE @ModuleConfig VARCHAR(20)

SELECT @ModuleConfig = ModuleConfig_Desc
FROM [$LoggingDB].[Inspector].[CurrentServers]
WHERE IsActive = 1 
AND Servername = @Servername

IF @ModuleConfig IS NULL BEGIN SET @ModuleConfig = ''Default'' END;

SELECT [Server],[Module],[Enabled]
FROM 
(
    SELECT
    @Servername AS Server,							
    ISNULL(EnableAGCheck,0) AS AGCheck,					
    ISNULL(EnableBackupsCheck,0) AS BackupsCheck,					
    ISNULL(EnableBackupSizesCheck,0) AS BackupSizesByDay,			
    ISNULL(EnableDatabaseGrowthCheck,0) AS DatabaseGrowths,			
    ISNULL(EnableDatabaseFileCheck,0) AS DatabaseFiles,			
    ISNULL(EnableDatabaseOwnershipCheck,0) AS DatabaseOwnership,		
    ISNULL(EnableDatabaseStatesCheck,0) AS DatabaseStates,			
    ISNULL(EnableDriveSpaceCheck,0) AS DriveSpace,				
    ISNULL(EnableFailedAgentJobCheck,0) AS FailedAgentJobs,			
    ISNULL(EnableJobOwnerCheck,0) AS JobOwner,				
    ISNULL(EnableFailedLoginsCheck,0) AS LoginAttempts,			
    ISNULL(EnableTopFiveDatabaseSizeCheck,0) AS TopFiveDatabases,		
    ISNULL(EnableADHocDatabaseCreationCheck,0) AS ADHocDatabaseCreations,	
    ISNULL(EnableDatabaseSettings,0) AS DatabaseSettings
    FROM [$LoggingDB].[Inspector].[Modules]
    WHERE ModuleConfig_Desc = @ModuleConfig
) Modules
UNPIVOT
([Enabled] FOR Module IN 
(AGCheck
,BackupsCheck
,BackupSizesByDay
,DatabaseGrowths
,DatabaseFiles
,DatabaseOwnership
,DatabaseStates
,DriveSpace
,FailedAgentJobs
,JobOwner
,LoginAttempts
,TopFiveDatabases
,ADHocDatabaseCreations
,DatabaseSettings
)) AS [Enabled]
',N'@Servername NVARCHAR(128)',@Servername = '$_'
"@

        $EnabledModules += $CentralConnection.Query($Query)

    }

#For each active server run the collection
$ActiveServers.Servername |
    ForEach-Object -Process {

        $Connection = Get-DbaDatabase -SqlInstance $_ -Database $LoggingDB

        #Store Currently processed server 
        $CurrentlyProcessedServer = $_

        #Store enabled modules for currently processed server
        $EnabledModuleList = $EnabledModules | Where-Object { $_.Server -eq $CurrentlyProcessedServer -and $_.Enabled -eq 1 }

        #Build a list of Stored procedure names to be included in the collection for this server
        $CollectionProcedures = $EnabledModuleList | ForEach-Object -Process { "$($_.Module)Insert" }

        #Reset $Query Variable 
        Clear-Variable -Name Query

        Write-Output "Started Collection on Server: $CurrentlyProcessedServer"

        if ($CurrentlyProcessedServer -ne $CentralServer) {
            
            #Truncate local settings and insert settings from central logging database
			Write-Output "Syncing Settings on Server: $CurrentlyProcessedServer"
            $Connection.Query("TRUNCATE TABLE [$LoggingDB].[Inspector].[Settings]")

            $WriteTableOptions = @{
                SqlInstance = $CurrentlyProcessedServer
                Database = $LoggingDB
                Schema = 'Inspector'
                Table = 'Settings'
                NoTableLock = $true
            }
            $CurrentSettings | Write-DbaDataTable @WriteTableOptions
            
        }

        #Build Execute statements for the 
        #For each enabled Module run the collection
        $CollectionProcedures | 
            ForEach-Object -Process {
                $Query = "EXEC [$LoggingDB].[Inspector].[$_];"
                $Tablename = $_ -replace 'Insert', '' 

                switch ($_) {
                    #Do not delete file size info or Growth info.
                    { $_ -notin 'DatabaseGrowthsInsert', 'DriveSpaceInsert' } {
                        $CleanupQuery = "EXEC sp_executesql N'DELETE FROM [$LoggingDB].[Inspector].[$Tablename] WHERE Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$CurrentlyProcessedServer'"
                        $CentralConnection.Query($CleanupQuery)
                    }
                    #Delete old records only
                    { $_ -eq 'DriveSpaceInsert' } {
                        $CleanupQuery = "EXEC sp_executesql N'DECLARE @Retention INT = (SELECT Value From [$LoggingDB].[Inspector].[Settings] Where Description = ''DriveSpaceRetentionPeriodInDays''); DELETE FROM [$LoggingDB].[Inspector].[DriveSpace] WHERE Log_Date < DATEADD(DAY,-@Retention,DATEADD(DAY,1,CAST(GETDATE() AS DATE))) AND Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$CurrentlyProcessedServer';"
                        $CentralConnection.Query($CleanupQuery)
                    }
                }

                Write-Output "    Executing [Inspector].[$_]"
                $Connection.Query($Query)

                if ($_ -ne 'DatabaseGrowthsInsert' -and $CurrentlyProcessedServer -ne $CentralServer) {
                    if ($_ -ne 'DriveSpaceInsert') {
                        #Get the contents of the collection and insert into the Central server
                        $Query = "SELECT * FROM [$LoggingDB].[Inspector].[$Tablename]" 
                        $CollectedData = $Connection.Query($Query)
                        
                        $CollectedDataOption = @{
                            SqlInstance = $CentralServer
                            Database = $LoggingDB
                            Schema = 'Inspector'
                            Table = $Tablename
                            NoTableLock = $true
                        }
                        $CollectedData | Write-DbaDataTable @CollectedDataOption
                    }
                    if ($_ -eq 'DriveSpaceInsert') {
                        #Get the contents of the collection
                        $Query = "EXEC sp_executesql N'DECLARE @Today DATE = CAST(GETDATE() AS DATE); SELECT * FROM [$LoggingDB].[Inspector].[DriveSpace] WHERE Log_Date >= @Today;'"
                        $CollectedData = $Connection.Query($Query)
                        
                        #Get Drive info for today from Central server - this is to ensure that if the collection is re ran duplicate rows are not inserted.
                        $Query = "EXEC sp_executesql N'DECLARE @Today DATE = CAST(GETDATE() AS DATE); SELECT [Servername], [Log_Date], [Drive], [Capacity_GB], [AvailableSpace_GB] FROM [$LoggingDB].[Inspector].[DriveSpace] WHERE Log_Date >= @Today AND Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$CurrentlyProcessedServer'" 
                        $CentralDriveSpace = $CentralConnection.Query($Query)

                        #If there is are Drive space records logged centrally then compare and insert missing info
                        if ($CentralDriveSpace.Length -gt 0) {
                            $CollectedData = $CollectedData |
                                Select-Object -Property Servername, Log_Date, Drive, Capacity_GB, AvailableSpace_GB | 
                                Where-Object {$_.Servername -eq $CentralDriveSpace.Servername -and $_.Log_Date -ne $CentralDriveSpace.Log_Date -and $_.Drive -eq $CentralDriveSpace.Drive}
                        }
                        #We can define this out here rather than write it twice in the "if"s
                        $DriveSpaceOption = @{
                            SqlInstance = $CentralServer
                            Database    = $LoggingDB
                            Schema      = 'Inspector'
                            Table       = 'DriveSpace'
                            NoTableLock = $true
                        }
                        $CollectedData | Write-DbaDataTable @DriveSpaceOption
                    } #end of DriveSpaceInsert
                    
                    #Clean up
                    Clear-Variable -Name CentralDriveSpace, CollectedData
                } #end of ne DatabaseGrowthsInsert etc...
                    
                if ($CurrentlyProcessedServer -ne $CentralServer -and $_ -eq 'DatabaseGrowthsInsert') {
                    #Delete data for server from the central logging table
                    $Query = "EXEC sp_executesql N'DELETE FROM [$LoggingDB].[Inspector].[DatabaseFileSizes] WHERE Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$CurrentlyProcessedServer'"
                    $CentralConnection.Query($Query)
                    
                    #Get the contents of the File and database growth collection and insert into the Central server
                    $Query = "EXEC sp_executesql N'SELECT [Servername], [Database_id], [Database_name], [OriginalDateLogged], [OriginalSize_MB], [Type_desc], [File_id], [Filename], [PostGrowthSize_MB], [GrowthRate], [Is_percent_growth], [NextGrowth],[LastUpdated] FROM [$LoggingDB].[Inspector].[DatabaseFileSizes]'" 
                    $CollectedData = $Connection.Query($Query)

                    $DatabaseFileSizesOption = @{
                            SqlInstance = $CentralServer
                            Database    = $LoggingDB
                            Schema      = 'Inspector'
                            Table       = 'DatabaseFileSizes'
                            NoTableLock = $true
                        }
                    $CollectedData | Write-DbaDataTable @DatabaseFileSizesOption

                    #Create Data table for every iteration so that the table schema refreshed
                    Clear-Variable -Name CollectedData

                    #Get Database growth data for the currently processed server from the local server where Log_Date is today or greater
                    $Query = "EXEC sp_executesql N'DECLARE @Today DATE = CAST(GETDATE() AS DATE); SELECT [GrowthID],[Servername], [Database_id], [Database_name], [Log_Date], [Type_Desc], [File_id], [FileName], [PreGrowthSize_MB], [GrowthRate_MB], [GrowthIncrements], [PostGrowthSize_MB] FROM [$LoggingDB].[Inspector].[DatabaseFileSizeHistory] WHERE Log_Date >= @Today'" 
                    $CollectedData = $Connection.Query($Query)

                    #If there is a growth logged locally proceed
                    if ($CollectedData) {
                        #Get Database growth data for currently processed server on the Central server where the Log_Date is today or greater (we will use this to ensure that no duplicates are inserted).
                        $Query = "EXEC sp_executesql N'DECLARE @Today DATE = CAST(GETDATE() AS DATE); SELECT [GrowthID],[Servername], [Database_id], [Database_name], [Log_Date], [Type_Desc], [File_id], [FileName], [PreGrowthSize_MB], [GrowthRate_MB], [GrowthIncrements], [PostGrowthSize_MB] FROM [$LoggingDB].[Inspector].[DatabaseFileSizeHistory] WHERE Log_Date >= @Today AND Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$CurrentlyProcessedServer'" 
                        $CentralGrowths = $CentralConnection.Query($Query)

                        #If there is are growths logged centrally then compare and insert missing info
                        if ($CentralGrowths.Length -gt 0) {
                            $CollectedData = $CollectedData |
                                Select-Object -Property GrowthID, Servername, Database_id, Database_name, Log_Date, Type_Desc, File_id, FileName, PreGrowthSize_MB, GrowthRate_MB, GrowthIncrements, PostGrowthSize_MB |
                                Where-Object {$_.Database_name -eq $CentralGrowths.Database_name -and $_.Log_Date -ne $CentralGrowths.Log_Date}                        
                        }

                        $DatabaseFileSizeHistoryOption = @{
                            SqlInstance = $CentralServer
                            Database    = $LoggingDB
                            Schema      = 'Inspector'
                            Table       = 'DatabaseFileSizeHistory'
                            NoTableLock = $true
                        }
                        $CollectedData | Write-DbaDataTable @DatabaseFileSizeHistoryOption
                    }

                    #Remove Comparison variable
                    Clear-Variable -Name CentralGrowths
                }
            #Remove data table for every iteration after the data has been inserted into the central server logging database
            Clear-Variable -Name CollectedData
        }
    }

#Run the Inspector report from the Central logging server
Write-Output "Building SQLUndercover Report on Server: $CentralServer"
$Query = @"
EXEC $LoggingDB.[Inspector].[SQLUnderCoverInspectorReport]
@EmailDistributionGroup = 'DBA',
@TestMode = 1,
@ModuleDesc = NULL,
@EmailRedWarningsOnly = 0,
@Theme = 'Dark'
"@
$CentralConnection.Query($Query)
Write-Output "SQLUndercover Report has completed on Server: $CentralServer"

#Retrive the latest report
$Query = @"
SELECT TOP 1 ReportData
FROM [$LoggingDB].[Inspector].[ReportData]
ORDER BY ID DESC 
"@
$Report = $CentralConnection.Query($Query)

#Output the report to a html file
$Report | Format-Table -Wrap -HideTableHeaders | Out-File -FilePath $ReportFile

#Open html file in IE
$IE = new-object -com internetexplorer.application
$IE.navigate2($ReportFile)
$IE.visible = $true 
