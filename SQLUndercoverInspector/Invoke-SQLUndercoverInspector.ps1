#requires -Modules dbatools
# SON: We'll create a .psm1 a .psd1 file and put the above into the $RequiredModules field there.

function Invoke-SQLUndercoverCollection {
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
        [String]$FileName = 'C:\Temp\Inspector.html'
    )
    
    begin {
        
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Initialising default values and parameters..."
        [int]$Pos = 0
        $InvalidServers = New-Object -TypeName System.Collections.Generic.List[int]
        $ActiveServers = New-Object -TypeName System.Collections.Generic.List[string]
        $Builds = New-Object -TypeName System.Collections.Generic.List[psobject]
        [string]$ModuleConfig = 'NULL' # SON: Has to be a string NULL or is $null okay?

        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] [$CentralServer] - Checking central server connectivity."
        $CentralConnection = Get-DbaDatabase -SqlInstance $CentralServer -Database $LoggingDb -ErrorAction Stop -WarningAction Stop
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] [$CentralServer] - Central server connectivity ok."

        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Checking for the existance of the database: $LoggingDb."
        if (-not $CentralConnection.Name) {
            Write-Warning "[$CentralServer] - Logging database specified does not exist."
            break
        }

        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Getting a list of active servers from the Inspector Currentservers table..."
        $ActiveServersQry = "EXEC [$LoggingDb].[Inspector].[PSGetServers];"
        $ActiveServers = $CentralConnection.Query($ActiveServersQry)
    }
    
    process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing active servers..."
        $ActiveServers.Servername |
            ForEach-Object -Begin {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Setting $InspectorBuildQry variable."
                $InspectorBuildQry = "EXEC [$LoggingDb].[Inspector].[PSGetInspectorBuild];"
            } -Process {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$($_)] - Getting Inspector build info..."
                $ConnectionCurrent = Get-DbaDatabase -SqlInstance $_ -Database $LoggingDb -ErrorAction Stop -WarningAction Stop

                if (-not $ConnectionCurrent.Name) {
                    Write-Warning "[$((Get-Date).TimeOfDay) PROCESS] [$($_)] - Logging database [$LoggingDb] does not exist."
                    $InvalidServers.Add($Pos)
                    $Pos++
                    break
                }

                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Adding build for $ConnectionCurrent and $($ConnectionCurrent.Name)."
                $Builds.Add($ConnectionCurrent.Query($InspectorBuildQry))
                $Pos++
            }

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Removing invalid servers from ActiveServers array..."
        if ($InvalidServers) {
            $InvalidServers.Servername |
                ForEach-Object -Process {
                    $BadServername = $_
                    Write-Warning "[Validation] - Removing Invalid Server [$_] from the Active Server list."
                    $ActiveServers = $ActiveServers | Where-Object { $_.Servername -ne $BadServername }
                }
        }

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Checking minimum build and build comparison..."
        $BuildVersions = $Builds | Measure-Object -Property Build -Maximum -Minimum
        if ($BuildVersions.Minimum -lt 1.2) {
            Write-Warning "[Validation] - Inspector builds do not match."
            $Builds | Where-Object Build -lt 1.2 | Format-Table -Property Servername, Build
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

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Collecting settings data for syncing between servers..."
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$CentralServer] - Getting centralised settings..."
        $SettingsTables = 'Settings', 'CurrentServers', 'EmailRecipients', 'EmailConfig', 'Modules'
        foreach ($Setting in $SettingsTables) {
            $ColumnNamesQry = "EXEC [$LoggingDb].[Inspector].[PSGetColumns] @Tablename = '$Setting'"
            $ColumnNameResults = $CentralConnection.Query($ColumnNamesQry)
            $ColumnNamesFromTableQry = "SELECT $($ColumnNameResults.Columnnames) FROM [$LoggingDb].[Inspector].[$Setting]"
            Set-Variable -Name "Central$($Setting)" -Value ($CentralConnection.Query($ColumnNamesFromTableQry))
        }

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Validating $ModuleConfig..."
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
        foreach ($Servername in $ActiveServers.Servername) {
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Initialising collection variables..."
            $CollectedData = @()
            $ColumnNames = @()
            $ExecutedModules = @()

            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Connecting..."
            $CurrentConnection = Get-DbaDatabase -SqlInstance $Servername -Database $LoggingDb

            if ($Servername -ne $CentralServer) {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Starting settings sync..."
                $WriteTableOptions.SqlInstance = $Servername
                
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Truncating or deleting from Settings table..."
                $SettingsTables | Sort-Object | ForEach-Object -Process {
                    $SettingsTableName = $_
                    $WriteTableOptions.Table = $SettingsTableName

                    if ($SettingsTableName -eq 'Modules') {
                        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Deleting from table [Inspector].[$SettingsTableName]"
                        $TruncateDeleteQry = "DELETE FROM [$LoggingDb].[Inspector].[$SettingsTableName];"
                    } else {
                        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Truncating table [Inspector].[$SettingsTableName]"
                        $TruncateDeleteQry = "TRUNCATE TABLE [$LoggingDb].[Inspector].[$SettingsTableName];"
                    }
                    $CurrentConnection.Query($TruncateDeleteQry)
                }

                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Syncing data in settings table in reverse order due to foreign key relationship between CurrentServers and Modules..."
                $SettingsTables | Sort-Object -Descending | ForEach-Object -Process {
                    $SettingsTableName = $_
                    $WriteTableOptions.Table = $SettingsTableName

                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Syncing data for table [Inspector].[$SettingsTableName]"
                    Write-DbaDataTable @WriteTableOptions -InputObject $(Get-Variable $("Central$($SettingsTableName)") -ValueOnly)
                }
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Finished settings sync"
            }   

            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Executing [Inspector].[InspectorDataCollection] @ModuleConfig = $($ModuleConfig). @PSCollection = 1"
            $DataCollectionQry = "EXEC [$LoggingDb].[Inspector].[InspectorDataCollection] @ModuleConfig = $ModuleConfig, @PSCollection = 1;"
            $ExecutedModules = $CurrentConnection.Query($DataCollectionQry)

            $ExecutedModules = $ExecutedModules |
                Where-Object { $_.Servername -ne $CentralServer } |
                Select-Object -Property Servername, Module, Tablename, StageTablename, StageProcname, TableAction, InsertAction, RetentionInDays

            if ($Servername -ne $CentralServer) {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Starting data retrieval loop..."
            }

            foreach ($Module in $ExecutedModules) {
                $ModuleName = $Module.Module
                $Tablename = $Module.Tablename.ToString().split(',')
                $TableAction = $Module.TableAction.ToString().split(',')
                $StageTablename = $Module.StageTablename.ToString().split(',')
                $StageProcname = $Module.StageProcname.ToString()
                $InsertAction = $Module.InsertAction.ToString().split(',')
                $RetentionInDays = $Module.RetentionInDays.ToString().split(',')
                $Pos = 0
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Getting data for: $Modulename"
                $Tablename | ForEach-Object -Process {
                    $BaseTable = $_
                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Switching destination to central server."
                    $WriteTableOptions.SqlInstance = $CentralServer

                    [int]$TableActionPos = $TableAction[$Pos]
                    switch ($TableActionPos) {
                        { $_ -lt 3 } {
                            $WriteTableOptions.Table = $Tablename[$Pos]
                            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Delete logged info for server from Central Db."

                            $DeleteQry = "EXEC sp_executesql N'DELETE FROM [$LoggingDb].[Inspector].[$($Tablename[$Pos])] WHERE [Servername] = @Servername"
                        }
                        { $_ -eq 2 } {
                            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Append the retention period to the WHERE clause."
                            $DeleteQry = $DeleteQry + "AND [Log_Date] < DATEADD(DAY, -@Retention, GETDATE())', N'@Servername nvarchar(128), @Retention int', @Servername = '$Servername', @Retention = $($ReetentionInDays[$Pos]);"
                        }
                        { $_ -eq 1 } {
                            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Delete all data in table for server from..."
                            $DeleteQry = $DeleteQry + "', N'@Servername nvarchar(128)', @Servername = '$Servername'"
                        }
                        { $_ -eq 3 } {
                            $WriteTableOptions.Table = $($StageTablename[$Pos])
                            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Truncate stage table."
                            $DeleteQry = "TRUNCATE TABLE [$LoggingDb].[Inspector].[$($StageTablename[$Pos])];"
                        }
                    }
                    $CollectedData = $CurrentConnection.Query($DeleteQry)

                    if ($CollectedData) {
                        Write-DbaDataTable @WriteTableOptions -InputObject $CollectedData -KeepNull
                    }
                    $Pos += 1

                    Clear-Variable -Name CollectedData, Columnnames, Module
                }

                if ($StageProcname) {
                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Executing staging proc: $StageProcname on [$CentralServer]"
                    $ProcQry = "EXEC [$LoggingDb].[Inspector].[$StageProcname] @Servername = '$Servername';"
                    $CentralConnection.Query($ProcQry)
                }

                if ($Servername -ne $CentralServer) {
                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$Servername] - Finished data retrieval loop."
                }
            }
            #endregion
            
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$CentralServer] - Executing [Inspector].[SQLUnderCoverInspectorReport] @EmailDistribution 'DBA', @ModuleDesc = $ModuleConfig, @EmailRedWarningsOnly = 0, @Theme = 'Dark', @PSCollection = 1"
            $ReportQry = @"
            EXEC [$LoggingDb].[Inspector].[SQLUnderCoverInspectorReport]
                @EmailDistributionGroup = 'DBA',
                @ModuleDesc = $ModuleConfig,
                @EmailRedWarningsOnly = 0,
                @Theme = 'Dark',
                @PSCollection = 1          
"@
            $CentralConnection.Query($ReportQry)
            
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] [$CentralServer] - SQLUndercover Report has completed."
        }
    }
    end {
        $FinalReportQry = "SELECT TOP (1) ReportData FROM [$LoggingDb].[Inspector].[ReportData] ORDER BY ID DESC;"
        $Report = $CentralConnection.Query($FinalReportQry)
        $Report | Format-Table -Wrap -HideTableHeaders | Out-File -FilePath $FileName -Width 4000
    }
}
