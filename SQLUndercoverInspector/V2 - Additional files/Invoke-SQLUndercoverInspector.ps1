#requires -Modules dbatools
# SON: We'll create a .psm1 a .psd1 file and put the above into the $RequiredModules field there.

#Script version 1.3
#Revision date: 31/01/2020
#Minimum Inspector version 2.1

<#
If you are running the ps1 from an agent job in SQL server (cmdexec) then you can use the following samples to help you get started

--Let the Inspector check for all Module config to run
powershell.exe " cd <Path containing SQLUndercoverInspector.ps1>; import-module .\Invoke-SQLUndercoverInspector.ps1; Invoke-SQLUndercoverInspector -LoggingDB SQLUndercover -CentralServer SQL02 -ModuleConfig Default -NoClutter $true";

--Force the inspector to check for only the Default Moduleconfig, replace default for others that you wish to run on their own i.e PeriodicBackupCheck
powershell.exe " cd <Path containing SQLUndercoverInspector.ps1>; import-module .\Invoke-SQLUndercoverInspector.ps1; Invoke-SQLUndercoverInspector -LoggingDB SQLUndercover -CentralServer SQL02 -ModuleConfig Default -NoClutter $true"

There are two new parameters due to the nature of V2 and the way it now polls for executions/reports that are due every minute, the powershell collection by default will now only centralise what is currently due to run however
you can use these two new parameters to change the behaviour: 

-RunCollection $true - this will ignore schedules and force execution
-CreateReport $true - will generate a report at run time and ignore report schedules
#>

function Invoke-SQLUndercoverInspector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('SqlInstance', 'ServerName', 'Server')]
        [String]$CentralServer,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('Database', 'DatabaseName')]
        [String]$LoggingDb,

        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('File')]
        [String]$FileName = 'C:\Temp\Inspector.html',

        [Parameter(Position = 3, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Module')]
        [String]$ModuleConfig = 'NULL',

        [Parameter(Position = 4, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('ClutterOff')]
        [Bool]$NoClutter = $false,

        [Parameter(Position = 5, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('WarningsOnly')]
        [Bool]$ShowWarningsOnly = $false,

        [Parameter(Position = 6, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('ExecModules')]
        [Bool]$RunCollection = $false, 

        [Parameter(Position = 7, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('GenerateReport')]
        [Bool]$CreateReport = $false,

        [Parameter(Position = 8, ValueFromPipelineByPropertyName)]
        #[ValidateNotNullOrEmpty()]
        [Alias('OfflineUpdatePath')]
        [String]$Offlinefilepath
        )
    
    begin {
        IF (($Offlinefilepath.Length) -eq 0) {
            $Offlinefilepath = "URL";
        }

        #Import Inspector update function from the same directory as Invoke-SQLundercoverInspector
        try {
            import-module -Name ($(Get-location).ToString()+"\InspectorAutoUpdate.psm1") -Force;
        } Catch {
            write-host "There was an issue importing InspectorAutoUpdate.psm1 from ($(Get-location).ToString()), the psm1 must be in the same folder as Invoke-SQLUndercoverInspector" -ForegroundColor Red
            write-host "$_.Exception.Message" -ForegroundColor Red;
        }

        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Initialising default values and parameters..." 
        [int]$Pos = 0
        $InstallStatus = New-Object -TypeName System.Collections.Generic.List[int]
        $InvalidServers = @()
        $ActiveServers = @()
        $ActiveServersFiltered = @()
        $Builds = New-Object -TypeName System.Collections.Generic.List[psobject]
        $RequiredInspectorBuild = "2.1"
        [string]$Path = split-path $FileName;
        
        write-host "Checking central server connectivity.";

        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] [$CentralServer] - Checking central server connectivity."
        $CentralConnection = Get-DbaDatabase -SqlInstance $CentralServer -Database $LoggingDb -ErrorAction Stop -WarningAction Stop
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] [$CentralServer] - Central server connectivity ok."

        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] [$CentralServer] - Checking for the existance of the database: $LoggingDb."
        if (-not $CentralConnection.Name) {
            Write-Warning "[$CentralServer] - Logging database specified does not exist."
            break
        }


        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] [$CentralServer] - Database: $LoggingDb exists, validating Inspector installation..."
        $ValidateInstallQry = "SELECT CASE WHEN OBJECT_ID('Inspector.Settings') IS NOT NULL THEN 1 ELSE 0 END AS Outcome;"
        $InstallStatus = $CentralConnection.Query($ValidateInstallQry)

        if($InstallStatus[0] -ne 1) {
            Write-Warning "[$CentralServer] - Settings table does not exist in database [$LoggingDb] - please install/reinstall the Inspector."
            break
        }

        if($InstallStatus[0] -eq 1) {
            $ValidateInstallQry = "SELECT CASE WHEN (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'InspectorBuild') = 1 THEN 1 ELSE 0 END AS Outcome;"
            $InstallStatus = $CentralConnection.Query($ValidateInstallQry)
            
            if($InstallStatus[0] -ne 1) {      
            Write-Warning "[$CentralServer] - Settings table exists in database [$LoggingDb] - but no config is present please install/reinstall the Inspector."
            break
            }

        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] [$CentralServer] - Database: $LoggingDb exists, validating Inspector installation OK"
        }


        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Getting a list of active servers from the Inspector Currentservers table..."
        $ActiveServersQry = "EXEC [$LoggingDb].[Inspector].[PSGetServers];"
        $CurrentServers = $CentralConnection.Query($ActiveServersQry)

        $CurrentServers.Servername | ForEach-Object {
            $ActiveServers += ($_);
        }

        IF(!$CurrentServers) {
            Write-Warning "[$CentralServer] - No servers specified in [Inspector].[CurrentServers]";
            Return;
        }

        #AutoUpdate
        write-host "Running AutoUpdate Function";
        InspectorAutoUpdate -CentralServer $CentralServer -LoggingDb $LoggingDb -Scriptfilepath $(split-path $FileName) -Offlinefilepath $Offlinefilepath;
    }

    process {
        write-host "Processing active servers...";
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing active servers..."
        $ActiveServers |
            ForEach-Object -Process {
                write-host "    Confirming connection and validating install for server [$_]";
                $InstallStatus[0] = 0 

                IF($ConnectionCurrent) {
                    clear-variable ConnectionCurrent;
                }

                 $ConnectionCurrent = Get-DbaDatabase -SqlInstance $_ -Database $LoggingDb -WarningAction SilentlyContinue;

                 IF (!$ConnectionCurrent) {
                    write-host "        Unable to connect to $_, skipping the server" -ForegroundColor Red;
                    $InvalidServers += $($_);
                    Return;
                 }

                 Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$($_)] - Database: $LoggingDb exists, validating Inspector installation..."
                 $ValidateInstallQry = "SELECT CASE WHEN OBJECT_ID('Inspector.Settings') IS NOT NULL THEN 1 ELSE 0 END AS Outcome;"
                 $InstallStatus = $ConnectionCurrent.Query($ValidateInstallQry)
                 

                 if($InstallStatus[0] -eq 0) {
                    write-host "        Unable to validate the Inspector installation, skipping the server" -ForegroundColor Red;
                    $InvalidServers += $($_);
                    Return;
                 }


                 if($InstallStatus[0] -eq 1) {
                     $ValidateInstallQry = "SELECT CASE WHEN (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'InspectorBuild') = 1 THEN 1 ELSE 0 END AS Outcome;"
                     $InstallStatus = $ConnectionCurrent.Query($ValidateInstallQry)
  
                     if($InstallStatus[0] -ne 1) {      
                        Write-Warning "[$CentralServer] [$($_)] - Settings table exists in database [$LoggingDb] - but no config is present please install/reinstall the Inspector."
                        $InvalidServers += $($_);
                     Return
                     }

                 Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$($_)] - Database: $LoggingDb exists, validating Inspector installation OK"
                 }


                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Setting $InspectorBuildQry variable."
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$($_)] - Getting Inspector build info..."
                $InspectorBuildQry = "EXEC [$LoggingDb].[Inspector].[PSGetInspectorBuild];"                

                if (-not $ConnectionCurrent.Name) {
                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$($_)] - Adding server to exclusion list."
                    $InvalidServers += ($($_));
                }
                ELSE {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$($_)] - Adding Inspector build."
                $Builds.Add($ConnectionCurrent.Query($InspectorBuildQry))
                $Pos++
                    IF ($_ -eq $CentralServer) {
                    $CentralInspectorBuild = $Builds[-1] | Select-Object Build
                    }
                }


            }

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Removing invalid servers from ActiveServers array..."

        #Remove bad servers 
        #For every position in the invalid server array check every position in the Active servers array and build a new array where Invalidservers are not present.
        IF($($InvalidServers.Length) -gt 0) {
            $ActiveServersFiltered =  $ActiveServers | Where-Object -FilterScript { $_ -notin $InvalidServers }
        }

        IF ($InvalidServers.Length -gt 0) {
            write-host "Invalid servers: $InvalidServers";
        }

        #If there were no invalid servers to remove the set the Filtered list to match the Active server array
        IF($ActiveServersFiltered.Length -eq 0) {
            $ActiveServersFiltered = $ActiveServers;
        }
        #write-host "Active Servers: $ActiveServersFiltered";

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Checking minimum build and build comparison..."
        $BuildVersions = $Builds | Measure-Object -Property Build -Maximum -Minimum
        if ($BuildVersions.Minimum -lt 2.00) {
            Write-Warning "[Validation] - Inspector build(s) detected that do not meet the minimum version required for this script (Build: $RequiredInspectorBuild)"
            $Builds | Where-Object Build -lt 2.00 | Format-Table -Property Servername, Build
            break
        }
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [Validation] - Minimum build check ok."

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Comparing minimum build and maximum build..."
        if ($BuildVersions.Minimum -ne $BuildVersions.Maximum) {
            Write-Warning "[Validation] - Inspector builds do not match."
            $Builds | Format-Table -Property Servername, Build
            break
        }
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [Validation] - Active Server Inspector builds match."

        if ($BuildVersions.Maximum -lt "2.00") {
            Write-Warning "[Validation] - Inspector build does not meet minimum build for this script (2.00)"
            $Builds | Format-Table -Property Servername, Build
            break
        }
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [Validation] - Active Server Inspector build correct for this script version"

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Collecting settings data for syncing between servers..."
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$CentralServer] - Getting centralised settings..."
        $SettingsTableQry = "EXEC [$LoggingDb].[Inspector].[PSGetSettingsTables] @SortOrder = 0, @PSCollection = 1;"
        $SettingsTables = $CentralConnection.Query($SettingsTableQry)
        foreach ($Setting in $SettingsTables.Tablename) {
            $ColumnNamesQry = "EXEC [$LoggingDb].[Inspector].[PSGetColumns] @Tablename = '$Setting'"
            $ColumnNameResults = $CentralConnection.Query($ColumnNamesQry)
            $ColumnNamesFromTableQry = "SELECT $($ColumnNameResults.Columnnames) FROM [$LoggingDb].[Inspector].[$Setting]"
            Set-Variable -Name "Central$($Setting)" -Value ($CentralConnection.Query($ColumnNamesFromTableQry))
        }

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Validating ModuleConfig parameter passed..."
        if ($ModuleConfig -eq 'NULL') {
            Write-Warning '[Validation] - ModuleConfig = NULL (Auto determined)'
        } elseif ($ModuleConfig -notin $CentralModules.ModuleConfig_Desc) {
            Write-Warning "[Validation] - ModuleConfig does not exist, valid options are: $($CentralModules.ModuleConfig_Desc) or leave blank for auto determined ModuleConfig"
            break
        }
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [Validation] - ModuleConfig ok."

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Populating LinkedServername variable from the Settings table..."
        $LinkedServername = ($CentralSettings | Where-Object Description -eq LinkedServername).Value
        if ($LinkedServername.Length -gt 1) {
            Write-Warning "[Validation] - The Inspector has been configured for use with a Linked server please reinstall the Inspector with @LinkedServername = NULL"
            break
        }
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [Validation] - Inspector configured correctly for PS collection."

        #region SON: Potential to make this a separate function
        $WriteTableOptions = @{
            SqlInstance = ''
            Database = $LoggingDb
            Schema = 'Inspector'
            Table = ''
            NoTableLock = $true
        }
        #$OuterTotal = $ActiveServers.Servername.Count;
        #$OuterCurrent = 0;

        #Central server needs to be processed last
        foreach ($Servername in $($ActiveServersFiltered | Sort-Object -Unique | Sort-Object -Property @{Expression = {IF($_ -eq $CentralServer) {2} ELSE {1}}; Descending = $False})) {
            Write-Output "Processing server $Servername";
            #Write-Progress -id 0 -Activity "Processing servers" -PercentComplete $(($OuterCurrent/$OuterTotal)*100) -CurrentOperation $("Processing $Servername")
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Initialising collection variables..."
            $CollectedData = @()
            $ColumnNames = @()
            $ExecutedModules = @()

            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Connecting..."
            $ConnectionCurrent = Get-DbaDatabase -SqlInstance $Servername -Database $LoggingDb

            if ($Servername -ne $CentralServer) {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Starting settings sync..."
                $WriteTableOptions.SqlInstance = $Servername
                
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Truncating or deleting from Settings table..."
                $SettingsTableQry = "EXEC [$LoggingDb].[Inspector].[PSGetSettingsTables] @SortOrder = 0, @PSCollection = 1;"
                $SettingsTables = $CentralConnection.Query($SettingsTableQry)
                $SettingsTables | ForEach-Object -Process {
                    $SettingsTableName = $_.Tablename
                    $WriteTableOptions.Table = $SettingsTableName

                    switch ($_.TruncateTable) {
                        { $_ -eq 0 } {
                        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Creating delete query for table [Inspector].[$SettingsTableName]"
                        $TruncateDeleteQry = "DELETE FROM [$LoggingDb].[Inspector].[$SettingsTableName];"
                        }

                        { $_ -eq 1 } {
                        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Creating truncate query for table [Inspector].[$SettingsTableName]"
                        $TruncateDeleteQry = "TRUNCATE TABLE [$LoggingDb].[Inspector].[$SettingsTableName];"
                        }
                        }

                    switch ($_.ReseedTable) {
                        { $_ -eq 1 } {
                        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Appending Reseed indentity command for table [Inspector].[$SettingsTableName]"
                        $TruncateDeleteQry = $TruncateDeleteQry + " DBCC CHECKIDENT ('Inspector.$SettingsTableName', RESEED, 1);" 
                        }
                        } 
                    $ConnectionCurrent.Query($TruncateDeleteQry)
                }

                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Syncing data in settings table in reverse order due to foreign key relationship between CurrentServers and Modules..."
                $SettingsTableQry = "EXEC [$LoggingDb].[Inspector].[PSGetSettingsTables] @SortOrder = 1;"
                $SettingsTables = $CentralConnection.Query($SettingsTableQry)
                $SettingsTables.Tablename | ForEach-Object -Process {
                    $SettingsTableName = $_
                    $WriteTableOptions.Table = $SettingsTableName

                    
                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Syncing data for table [Inspector].[$SettingsTableName]"

                    IF ($(Get-Variable $("Central$($SettingsTableName)") -ValueOnly).count -ne 0) {
                    Write-DbaDataTable @WriteTableOptions -InputObject $(Get-Variable $("Central$($SettingsTableName)") -ValueOnly)
                    }

                }
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Finished settings sync"
            }   

            write-output "    Executing Inspector data collection stored proc";
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Executing [Inspector].[InspectorDataCollection] @ModuleConfig = $($ModuleConfig),@PSCentralServer = '$Centralserver', @PSCollection = 1,@PSExecModules = $(IF($RunCollection -eq $false){0} ELSE{1})"
            $DataCollectionQry = "EXEC [$LoggingDb].[Inspector].[InspectorDataCollection] @ModuleConfig = $ModuleConfig,@PSCentralServer = '$Centralserver', @PSCollection = 1,@PSExecModules = $(IF($RunCollection -eq $false){0} ELSE{1}),@PSGenerateReport = $(IF($CreateReport -eq $false){0} ELSE{1});"
            $ExecutedModules = $ConnectionCurrent.Query($DataCollectionQry)

            $ExecutedModules = $ExecutedModules |
                Where-Object { $_.Servername -ne $CentralServer } |
                Select-Object -Property Servername, Modulename, Tablename, StageTablename, StageProcname, TableAction, InsertAction, RetentionInDays

            if ($Servername -ne $CentralServer) {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Starting data retrieval loop..."
            }
            $InnerTotal = $ExecutedModules.count;
            $InnerCurrent = 0; 
            foreach ($Module in $ExecutedModules) {
                $ModuleName = $Module.Modulename
                $Tablename = $Module.Tablename.ToString().split(',')
                $TableAction = $Module.TableAction.ToString().split(',')
                $StageTablename = $Module.StageTablename.ToString().split(',')
                $StageProcname = $Module.StageProcname.ToString().split(',')
                $InsertAction = $Module.InsertAction.ToString().split(',')
                $RetentionInDays = $Module.RetentionInDays.ToString().split(',')
                $Pos = 0
                write-output "    Centralising data for Module $Modulename"
                #Write-Progress -id 1 -Activity "Processing Modules" -CurrentOperation $("Processing Module $Modulename") -PercentComplete $(($InnerCurrent/$InnerTotal)*100)

                #If it is a report only module then skip the centralisation of data for it and move onto the next module
                IF(!$Tablename) {
                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Skipping data for: $Modulename as no data collection is in use for this module"
                    Continue;
                }

                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Getting data for: $Modulename"

                $Tablename | ForEach-Object -Process {
                    $BaseTable = $_
                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Switching destination to central server."
                    $WriteTableOptions.SqlInstance = $CentralServer

                    [int]$TableActionPos = $TableAction[$Pos]
                    switch ($TableActionPos) {
                        { $_ -lt 3 } {
                            $WriteTableOptions.Table = $Tablename[$Pos]
                            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Delete logged info for server from Central Db, [Inspector].[$($Tablename[$Pos])] on [$CentralServer]"

                            $DeleteQry = "EXEC sp_executesql N'DELETE FROM [$LoggingDb].[Inspector].[$($Tablename[$Pos])] WHERE [Servername] = @Servername"
                        }
                        { $_ -eq 2 } {
                            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Append the retention period to the WHERE clause."
                            $DeleteQry = $DeleteQry + "AND [Log_Date] < DATEADD(DAY, -@Retention, GETDATE())', N'@Servername nvarchar(128), @Retention int', @Servername = '$Servername', @Retention = $($RetentionInDays[$Pos]);"
                        }
                        { $_ -eq 1 } {
                            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Append params to statement with no retention"
                            $DeleteQry = $DeleteQry + "', N'@Servername nvarchar(128)', @Servername = '$Servername'"
                        }
                        { $_ -eq 3 } {
                            if (($($StageTablename[$Pos]) -and $($StageTablename[$Pos]) -ne "N/A")) {
                            $WriteTableOptions.Table = $($StageTablename[$Pos])
                            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Truncate stage table."
                            $DeleteQry = "TRUNCATE TABLE [$LoggingDb].[Inspector].[$($StageTablename[$Pos])];"
                            }
                        }
                    }
                    Write-Verbose $DeleteQry
                   
                    $CentralConnection.Query($DeleteQry)
 

                    [int]$InsertActionPos = $InsertAction[$Pos]
                        #Retrieve data from local server table
                        $ColumnNamesQry = "EXEC [$LoggingDB].[Inspector].[PSGetColumns] @Tablename = '$($Tablename[$Pos])'"
                        $Columnnames = $ConnectionCurrent.Query($ColumnNamesQry) 
                    switch ($InsertActionPos) {
                        { $_ -eq 1 } {
                        #Get all data for the current server
                        $InsertQuery = "EXEC sp_executesql N'SELECT $($Columnnames.Columnnames) FROM [$LoggingDB].[Inspector].[$($Tablename[$Pos])] WHERE Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$Servername'"
                        }
                        { $_ -eq 2 } {
                        #Get data recorded for today only for the current server
                        $InsertQuery = "EXEC sp_executesql N'DECLARE @Today DATE = CAST(GETDATE() AS DATE); SELECT $($Columnnames.Columnnames) FROM [$LoggingDB].[Inspector].[$($Tablename[$Pos])] WHERE Log_Date >= @Today AND Servername = @Servername',N'@Servername NVARCHAR(128)',@Servername = '$Servername'"
                        }
                        }
                    $CollectedData = $ConnectionCurrent.Query($InsertQuery)

                    if ($CollectedData) {
                        Write-DbaDataTable @WriteTableOptions -InputObject $CollectedData -KeepNull
                    }

                    if (($($StageProcname[$Pos]) -and $($StageProcname[$Pos]) -ne "N/A")) {
                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Executing staging proc: $($StageProcname[$Pos]) on [$CentralServer]"
                    $ProcQry = "EXEC [$LoggingDb].[Inspector].[$($StageProcname[$Pos])] @Servername = '$Servername';"
                    $CentralConnection.Query($ProcQry)
                    }

                    if ($Servername -ne $CentralServer) {
                        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Finished data retrieval loop."
                    }
                    
                    $Pos += 1

                    Clear-Variable -Name CollectedData, Columnnames, Module
                }
            $InnerCurrent += 1;
            #Write-Progress -id 1 -Activity "Processing Modules" -CurrentOperation $("Processing Module $Modulename") -PercentComplete $(($InnerCurrent/$InnerTotal)*100) 
            }
            #endregion
            $OuterCurrent += 1;
            #Write-Progress -id 0 -Activity "Processing servers" -PercentComplete $(($OuterCurrent/$OuterTotal)*100) -CurrentOperation $("Processing $Servername") -Completed
        }

            $ReportQry = @"
            EXEC [$LoggingDb].[Inspector].[SQLUnderCoverInspectorReport]
                @EmailDistributionGroup = 'DBA',
                @ModuleDesc = $ModuleConfig,
                @EmailRedWarningsOnly = $(IF($ShowWarningsOnly -eq $false){0} ELSE{1}),
                @Theme = 'Dark',
                @PSCollection = 1,
                @NoClutter = $(IF($NoClutter -eq $false){0} ELSE{1});   
"@
            IF ($CreateReport -eq $true) {
                write-output "    Executing SQLUnderCoverInspectorReport stored proc"
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$CentralServer] - Executing [Inspector].[SQLUnderCoverInspectorReport] @EmailDistribution 'DBA', @ModuleDesc = $ModuleConfig, @EmailRedWarningsOnly = $(IF($ShowWarningsOnly -eq $false){0} ELSE{1}), @Theme = 'Dark', @PSCollection = 1,@NoClutter = $(IF($NoClutter -eq $false){0} ELSE{1})"
                $CentralConnection.Query($ReportQry)
            }
            
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$CentralServer] - SQLUndercover Report has completed."
    }
    end {
        IF ((test-path -path $Path) -eq $false) {
            New-item -Path $Path -ItemType "directory" | out-null;
        }

        $FinalReportQry = "SELECT TOP (1) ReportData FROM [$LoggingDb].[Inspector].[ReportData] WHERE [ModuleConfig] = '$ModuleConfig' ORDER BY ID DESC;"
        IF ($CreateReport -eq $true) {
            $Report = $CentralConnection.Query($FinalReportQry)
            $Report | Format-Table -Wrap -HideTableHeaders | Out-File -FilePath $FileName -Width 4000
        }

        IF ($CreateReport -eq $true) {
            Write-Output "The latest Inspector report has been saved to a html file here: $FileName";
        }
    }
}