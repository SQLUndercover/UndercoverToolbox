#Script version 1
#Revision date: 26/03/2020
#Minimum Inspector version 2.2

function InspectorAutoUpdate {
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
        [Alias('ScriptPath')]
        [String]$Scriptfilepath = 'C:\Temp\',

        [Parameter(Position = 3, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('OfflineUpdatetPath')]
        [String]$Offlinefilepath
        )

        [double]$RequiredInspectorBuild = 2.1
        $Branch = "master" #"Inspector-Dev"

        $Serverlist = @();

        IF($Offlinefilepath -ne "URL") {
            $ScriptSource = "File";
        }

        #Verify the Sctipt source type, if its a file check the files exist
        IF($Offlinefilepath -eq "URL") {
            $ScriptSource = "URL";
        } ELSE {
            $ScriptSource = "File";

            IF ($Offlinefilepath.EndsWith("\") -eq $false) {
                $Offlinefilepath = $Offlinefilepath+"\";
            }

        }
        
        #region Set SQL Statement text 

        #Set config query
        $ConfigQuery = "
        SELECT 
        [Description],
        CASE
            WHEN [Description] = 'PSAutoUpdateModules' AND [Value] IS NULL THEN '1'
            WHEN [Description] = 'PSAutoUpdateModulesFrequencyMins' AND [Value] IS NULL THEN '1440'
        ELSE [Value]
        END AS [Value]
        FROM [Inspector].[Settings] 
        WHERE [Description] IN ('InspectorBuild','PSAutoUpdateModules','PSAutoUpdateModulesFrequencyMins')
        UNION ALL
        SELECT 
        [Updatename],
        ISNULL(CONVERT(VARCHAR(20),[LastUpdated],113),'01/01/1900 00:00:00')
        FROM [Inspector].[PSAutoUpdate]
        WHERE [Updatename] = 'PSAutoUpdate';"

        #Set Installed build query
        $InstalledVersioncmd = "SELECT 
        CASE 
        	WHEN [SetupCommand] LIKE 'EXEC \[Inspector\].\[InspectorSetup\]%' ESCAPE '\' THEN 'SQLUndercoverinspectorV2.sql'
        	ELSE [SetupCommand]
        END AS Modulename,
        ISNULL(CONVERT(VARCHAR(20),MAX([RevisionDate]),113),'01/01/1900 00:00:00') AS RevisionDate
        FROM [Inspector].[InspectorUpgradeHistory] 
        GROUP BY 
        CASE 
        	WHEN [SetupCommand] LIKE 'EXEC \[Inspector\].\[InspectorSetup\]%' ESCAPE '\' THEN 'SQLUndercoverinspectorV2.sql'
        	ELSE [SetupCommand]
        END;"

        #Inspector setup stored procedure query.
        $ExecInspectorSetupProc = "EXEC [Inspector].[InspectorSetup]
        --Required Parameters						     
        @Databasename = '$LoggingDb',	
        @DataDrive = 'S,U',	
        @LogDrive = 'T,V',	
        --Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
        @BackupsPath = 'F:\Backups',
        @LinkedServername = NULL,  
        @StackNameForEmailSubject = 'SQLUndercover',	
        @EmailRecipientList = NULL,	  
        @DriveSpaceHistoryRetentionInDays = 90, 
        @DaysUntilDriveFullThreshold = 56, 
        @FreeSpaceRemainingPercent = 10,
        @DriveLetterExcludes = NULL, 
        @DatabaseGrowthsAllowedPerDay = 1,  
        @MAXDatabaseGrowthsAllowedPerDay = 10, 
        @AgentJobOwnerExclusions = 'sa', 
        @FullBackupThreshold = 8,		
        @DiffBackupThreshold = 2,		
        @LogBackupThreshold = 20,		
        @DatabaseOwnerExclusions = 'sa',  
        @LongRunningTransactionThreshold = 300,	
        @StartTime = '08:55',
        @EndTime = '17:30',
        @EnableAgentJob = 1,
        @InitialSetup = 0;"

        #endregion

        #Get Active server list
        $Serverlist = Invoke-sqlcmd -ServerInstance $CentralServer -Database $LoggingDb -Query "SELECT [Servername] FROM [Inspector].[CurrentServers] WHERE [IsActive] = 1 ORDER BY CASE WHEN [Servername] = @@SERVERNAME THEN 1 ELSE 2 END ASC;"

        #Get Inspector build to ensure that the version installed has the PSUpdate table - if not then skip the config query
        $CentralInspectorVersion = Invoke-sqlcmd -ServerInstance $CentralServer -Database $LoggingDb -Query "EXEC [Inspector].[PSGetInspectorBuild];"
        [double]$CentralInspectorVersion = $($CentralInspectorVersion.Build);

        IF ($CentralInspectorVersion -ge $RequiredInspectorBuild) {
            $Config = @();

            #Get config from the central server
            $Config = Invoke-sqlcmd -ServerInstance $CentralServer -Database $LoggingDb -Query $ConfigQuery;
            
            #If there is an issue getting the config then break out
            IF ($($Config.Length) -eq 0) {
                write-host "There was an issue getting the config on the Central server" -ForegroundColor Red;
                Break;
            }
               
            #Assign values to config variables.
            [double]$CentralInspectorVersion = ($Config | ?{$_.Description -eq "InspectorBuild"}).Value
            $AutoUpdate = ($Config | ?{$_.Description -eq "PSAutoUpdateModules"}).Value
            [int]$PSAutoUpdateModulesFrequencyMins = ($Config | ?{$_.Description -eq "PSAutoUpdateModulesFrequencyMins"}).Value
            [datetime]$PSAutoUpdateLastUpdated = ($Config | ?{$_.Description -eq "PSAutoUpdate"}).Value           
        }
        
        #Set some defaults if these do not exist (earlier V2 versions)
        IF ($CentralInspectorVersion -lt $RequiredInspectorBuild) {
            $AutoUpdate = 1;
            $PSAutoUpdateModulesFrequencyMins = 1440;
            [datetime]$PSAutoUpdateLastUpdated = (get-date "01/01/1900" -Format "dd/MM/yyyy");
        }

        #If auto update is enabled and the last updated datetime is NULL or less than the current time run through the update check and apply updates
        if (($AutoUpdate -eq 1) -and ((get-date -Format yyyyMMddHHmmss)) -ge (get-date $($PSAutoUpdateLastUpdated.AddMinutes($PSAutoUpdateModulesFrequencyMins)) -Format yyyyMMddHHmmss)) {

            #region check Scriptfilelocation exists and create if not
            IF ($Scriptfilepath.EndsWith("\") -eq $false) {
                $Scriptfilepath = $Scriptfilepath+"\";
            }
            
            IF ($(test-path -Path $Scriptfilepath) -eq $false) {
                New-Item -ItemType Directory -Path $Scriptfilepath | out-null;
            }
            #endregion

            Write-Host "Auto Update: Enabled" -ForegroundColor Yellow;

            IF((get-date $PSAutoUpdateLastUpdated -format yyyyMMdd) -eq "19000101"){
                write-host "Last Updated: Never"-ForegroundColor Yellow;
            } ELSE {
                write-host "Update Frequency: Every $($PSAutoUpdateModulesFrequencyMins) mins" -ForegroundColor Yellow;
                write-host "Last Updated: $(get-date $PSAutoUpdateLastUpdated -Format "dd/MM/yyyy HH:mm:ss")" -ForegroundColor Yellow;
                write-host "Next Update: $(get-date $($PSAutoUpdateLastUpdated.AddMinutes($PSAutoUpdateModulesFrequencyMins)) -Format "dd/MM/yyyy HH:mm:ss")" -ForegroundColor Yellow;
            }

            Write-Host "Checking for updates from $ScriptSource..." -ForegroundColor Yellow;
            write-host "" -ForegroundColor Yellow
 
            #Download Manifest
            write-host "Retrieving the manifest file from $ScriptSource..." -ForegroundColor Yellow;

            IF ($ScriptSource -eq "URL") {
                $ManifestPath = $($Scriptfilepath)+"Manifest.csv";
                Try {
                    Invoke-WebRequest "https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/$Branch/SQLUndercoverInspector/V2%20-%20Additional%20files/Manifest.csv" -OutFile $ManifestPath;       
                    $Manifest = import-csv -Path $ManifestPath;
                } Catch{
                    write-host "Error retrieving the manifest file" -ForegroundColor Red;
                    write-host "$_.Exception.Message" -ForegroundColor Red;

                    IF($(test-path $ManifestPath) -eq $true) {
                        remove-item -LiteralPath $ManifestPath;
                    }

                    Return;
                }
            } ELSE {
                $ManifestPath = $($Offlinefilepath)+"Manifest.csv";
                Try {
                    $Manifest = import-csv -Path $ManifestPath;
                } Catch{
                    write-host "$_.Exception.Message" -ForegroundColor Red;
                    write-host "Quitting AutoUpdate" -ForegroundColor Red;
                    Return;
                }
            }

            

            #For each server check the current build an update accordingly
            $Serverlist | ForEach-Object{
                write-host "Checking version information for server $($_.Servername)" -ForegroundColor Yellow;

                $InspectorVersion = @();

                #region Check local Inspector build meets the minimum requirement
                $InspectorVersion = Invoke-sqlcmd -ServerInstance $($_.Servername) -Database $LoggingDb -Query "EXEC [Inspector].[PSGetInspectorBuild];"

                #If there is an issue getting the config then break out
                IF ($($InspectorVersion.Length) -eq 0) {
                    write-host "There was an issue determining the Inspector build for $($_.Servername), skiping auto updates for the server" -ForegroundColor Red;
                    Return;
                }
                
                #if the local version is less than $RequiredInspectorBuild then set the MinVersionUpdateRequired flag to install the latest Inspector version
                IF($($InspectorVersion.Build) -lt $RequiredInspectorBuild) {
                    write-host "    Local server Inspector build does not meet the minumum required version ($RequiredInspectorBuild), this server will be updated." -ForegroundColor Red
                    #Continue;
                }
            
            
                    #check for updates
                    foreach($Manifestitem in $Manifest) {
                        $Modulename = $Manifestitem.Modulename
                        $LastUpdated = $Manifestitem.LastUpdated
                        $URL = $Manifestitem.URL
                        $Servername = $_.Servername
                        $UpdateMessage = "";
                        $InstalledVersion = @();
                        $UpdateStmt = "";
                        $Scriptfile = ($Scriptfilepath+$Modulename.Replace(".sql",""))+".sql";
                        [string]$LocalRevisionDate = (get-date "01/01/1900" -Format "dd/MM/yyyy");

                        #If this is an offline install use the offline path and check the file exists.
                        IF ($ScriptSource -eq "File") {
                            $Filename = $Offlinefilepath+$($Manifestitem.Modulename);

                            IF((test-path $Filename) -eq $false) {
                                write-host "Unable to find the file $Filename" -ForegroundColor Red
                                Continue;
                            }
                        }
        
                        IF($LocalModule) {
                            Clear-Variable LocalModule
                        }
                        
                        IF ($($InspectorVersion.Build) -ge $RequiredInspectorBuild) {
                            #Get Modules i.e Inspector and any custom modules and revision dates locally installed
                            $InstalledVersion = Invoke-sqlcmd -ServerInstance $Servername -Database $LoggingDb -Query $InstalledVersioncmd;
                        }

                        #Is Module installed locally
                        $LocalModule = ($InstalledVersion | ?{$_.Modulename -eq $Modulename}).Modulename
        
                        #Get the local Module revision date
                        $LocalRevisionDate = ($InstalledVersion | ?{$_.Modulename -eq $Modulename}).RevisionDate

                        #If no local revisio found then assume its not up to date
                        IF (!$LocalRevisionDate) {
                            [datetime]$LocalRevisionDate = (get-date "01/01/1900" -Format "dd/MM/yyyy");
                        }

                        #If the module cannot be found then skip it, excludes Inspector setup
                        IF(($LocalModule -eq $null) -and $Modulename -ne "SQLUndercoverinspectorV2.sql") {
                            write-host "    No history of $Modulename installed, skipping this module" -ForegroundColor DarkYellow
                            Continue;
                        }
                        
                        #If the module is found check the revision date and if it is older than the latest or it is null (01/01/1900) then update it
                        IF((get-date $LocalRevisionDate -Format yyyyMMddHHmmss) -lt (get-date $LastUpdated -Format yyyyMMddHHmmss)) {
                            write-host "    Updates found for $Modulename, installing update..." -ForegroundColor Cyan
                            
                        switch ($ScriptSource) {
                        {$_ -eq "URL"} {
                            #Get the SQL update script from URL
                            Try{
                                write-host "        Retrieving file contents from URL" -ForegroundColor White
                                Invoke-WebRequest -Uri $URL -Outfile $Scriptfile -ContentType 'sql';         
                                
                            } Catch{
                                write-host "$_.Exception.Message" -ForegroundColor Red;

                                IF($(test-path $Scriptfile) -eq $true) {
                                    remove-item -LiteralPath $Scriptfile;
                                }
                                
                                Return;
                            }
        
                            #Execute the SQL retreived from URL
                            Try{
                                write-host "        Executing the SQL update script" -ForegroundColor White
                                Invoke-sqlcmd -ServerInstance $Servername -Database $LoggingDb -InputFile $Scriptfile -ConnectionTimeout 15

                                IF($(test-path $Scriptfile) -eq $true) {
                                    remove-item -LiteralPath $Scriptfile;
                                }
        
                                #If the Inspector build needs updating then the Setup proc needs to be executed following the above revision to the setup proc.
                                IF($Modulename -eq "SQLUndercoverinspectorV2.sql"){
                                    write-host "        Executing [Inspector].[InspectorSetup] stored procedure" -ForegroundColor White
                                            
                                    Invoke-sqlcmd -ServerInstance $Servername -Database $LoggingDb -Query $ExecInspectorSetupProc -ConnectionTimeout 15;
                                }
                            } Catch{
                                write-host "$_.Exception.Message" -ForegroundColor Red;

                                IF($(test-path $Scriptfile) -eq $true) {
                                    remove-item -LiteralPath $Scriptfile;
                                }

                                Return;
                            }
                        }

                        {$_ -eq "File"} {
                            #Execute the SQL retreived from file
                            Try{
                                write-host "        Executing $Filename" -ForegroundColor White
                                Invoke-sqlcmd -ServerInstance $Servername -Database $LoggingDb -InputFile $Filename -ConnectionTimeout 15         

                                #If the Inspector build needs updating then the Setup proc needs to be executed following the above revision to the setup proc.
                                IF($Modulename -eq "SQLUndercoverinspectorV2.sql"){
                                    write-host "        Executing [Inspector].[InspectorSetup] stored procedure" -ForegroundColor White
                                            
                                    Invoke-sqlcmd -ServerInstance $Servername -Database $LoggingDb -Query $ExecInspectorSetupProc -ConnectionTimeout 15;
                                }
                                                                
                            } Catch{
                                write-host "$_.Exception.Message" -ForegroundColor Red;
                                #remove-item -LiteralPath $Filename;
                                Return;
                            }
        
                           
                        }

                        }

        
                        } ELSE {
                            write-host "    $Modulename up to date" -ForegroundColor Green    
                        }

        
                    }


            }

        #Update LastUpdated in the AutoUpdate table
        #IF($($CentralInspectorVersion.Build) -ge $RequiredInspectorBuild) {
            Invoke-sqlcmd -ServerInstance $CentralServer -Database $LoggingDb -Query "UPDATE [Inspector].[PSAutoUpdate]  SET [LastUpdated] = GETDATE() WHERE [Updatename] = 'PSAutoUpdate';"
        #}

        } ELSE {
            IF($AutoUpdate -eq 0) {
                Write-Host "Auto Update: Disabled" -ForegroundColor Yellow;
            } ELSE {
                Write-Host "Auto Update: Enabled but Not due yet" -ForegroundColor Yellow;
                write-host "Update Frequency: Every $($PSAutoUpdateModulesFrequencyMins) mins" -ForegroundColor Yellow;
                write-host "Last Updated: $(get-date $PSAutoUpdateLastUpdated -Format "dd/MM/yyyy HH:mm:ss")" -ForegroundColor Yellow;
                write-host "Next Update: $(get-date $($PSAutoUpdateLastUpdated.AddMinutes($PSAutoUpdateModulesFrequencyMins)) -Format "dd/MM/yyyy HH:mm:ss")" -ForegroundColor Yellow;
            }
        }
        #endregion
}
    Export-ModuleMember -Function InspectorAutoUpdate