cls
<#\
MIT License
------------

Copyright 2019 Sql Undercover

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.    
#>

#THIS SCRIPT IS STILL A WORK IN PROGRESS!
#Author: Adrian Buckman
#Revision date: 23/06/2021
 
#set variables
#if you are using a Github URL this must be the raw URL.

#region set tls version to use
$TLSAvailable = [enum]::GetNames([Net.SecurityProtocolType]) | where-object {$_ -in ("Tls","Tls11","Tls12")}

#Select the most recent TLs version available
$TLSToUse = $TLSAvailable | Sort-Object -Descending | select-object  -First 1

#Set the Tls protocol to use 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::$($TLSToUse)

write-host "Security protocol selected: $TLSToUse" -ForegroundColor Cyan;
#endregion


#region clear variables 
if($Branch) {
    clear-variable Branch;
}
if($PathType) {
    clear-variable PathType;
}

$ValidatedServers = @{};
#endregion

#region read inputs 
while ($PathType -cnotin ("File","URL")) {
    $PathType = Read-host "Install from local files 'File' or 'URL'? Default answer is 'URL'"

    if($PathType -eq ""){
        write-host "No selection made, defaulting to URL" -ForegroundColor Cyan;
        $PathType = "URL";
        Break;
    }

    if($PathType -cin ("master","Inspector-Dev")){
        Break;
    }
}

if($PathType -eq "URL"){
    while ($Branch -cnotin ("master","Inspector-Dev")) {
        $Branch = Read-host "Which branch of Inspector would you like to install , 'master' or 'Inspector-Dev'? Default answer is 'master'"

        if($Branch -eq ""){
            write-host "No selection made, defaulting to master branch" -ForegroundColor Cyan;
            $Branch = "master";
            Break;
        }
       
        if($Branch -cin ("master","Inspector-Dev")){
            Break;
        }
    }
}

#Set a URL or local path where the SQLUndercoverinspectorV2.sql file exists
if($PathType -eq "URL") {
    $ScriptPath = "https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/$Branch/SQLUndercoverInspector/SQLUndercoverinspectorV2.sql"
    $ManifestPath = "https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/$Branch/SQLUndercoverInspector/V2%20-%20Additional%20files/Manifest.csv";

} ELSE {
    $ScriptPath = Read-host "Enter folder location where the installation files are stored"

    if($ScriptPath.EndsWith("\")) {
        $ScriptPath = $ScriptPath+"SQLUndercoverinspectorV2.sql"
        $ManifestPath = $ScriptPath+"Manifest.csv"
    } else {
        $ScriptPath = $ScriptPath+"\SQLUndercoverinspectorV2.sql"
        $ManifestPath = $ScriptPath+"\Manifest.csv"
    }
}

$SQLInstances = "";
while ($SQLInstances -eq ""){
    $SQLInstances = read-host "Server(s) (pipe delimited) e.g SQL01|SQL02?";

    if($SQLInstances -ne ""){
        #Remove any spaces
        $SQLInstances = $SQLInstances.Replace(" ","");
        break;
    }
}

$LoggingDB = "";
while ($LoggingDB -eq ""){
    $LoggingDB = read-host "Database name";
    if($LoggingDB -ne ""){
        break;
    }
}

[string]$CustomModulesSelection = "";
while ($CustomModulesSelection -eq ""){
    $CustomModulesSelection =  read-host "Custom modules to install, options are 'NONE', 'ALL' , or comma delimit from the list: CPU BlitzWaits Catalogue BlitzFileStats";
    if($CustomModulesSelection -ne ""){
        break;
    }
}

[string]$UseWindowsAuth = "";
while ($UseWindowsAuth -eq ""){
    $UseWindowsAuth = read-host "Use windows auth Y/N?";

    $UseWindowsAuth = $UseWindowsAuth.ToUpper();
    if($UseWindowsAuth -in ("Y","N")){
        break;
    }
}


$EmailRecipients = read-host "Email address for recieving reports, Semi colon delimited eg 'Email@domain.com;Email2@domain.com'. Press enter to skip";


#endregion
if($EmailRecipients -eq "")  {
    $EmailRecipients = "NULL";
}


$DataDrive = "S,U"
$LogDrive = "T,V"
#Optional Parameters
$BackupsPath = "NULL" #"NULL" or backups Path


$CustomModules = [System.Collections.ArrayList]@()
foreach ($CustomModule in $CustomModulesSelection.split(",")) {
    $CustomModules+=$CustomModule
}

$CustomModules = $CustomModules.ToUpper();
IF(!$CustomModules) {
    $CustomModules = "NONE";
}

#region Validate UseWindowsAuth value
$UseWindowsAuth = $UseWindowsAuth.ToUpper();

IF ($UseWindowsAuth -notin ("Y","N")) {
    write-host "Parameter: UseWindowsAuth must have a value of 'Y' or 'N'";
    Return;
    }

#endregion

#region check temp dir exists and create if required
$TempDir = "C:\Temp\"

IF ($TempDir.EndsWith("\") -eq $false) {
    $TempDir = $TempDir+"\";
}

IF ($(test-path -Path $TempDir) -eq $false) {
    New-Item -ItemType Directory -Path $TempDir | out-null;
}

$TempFilename = $TempDir+"InspectorInstall.sql";
#endregion

#region Windows auth check and set SQL Auth password if required
IF ($UseWindowsAuth -eq "N") {
$SQLCred = Get-Credential -Message "Please provide SQL Authentication credentials to connect";
$SQLUser = $SQLCred.UserName;
$SQLPassword = $SQLCred.GetNetworkCredential().password
}
#endregion

$Confirmation = "";

#region $ScriptPath validation
IF ($ScriptPath -eq $null) {
    write-host "You must specify a Script Path" -ForegroundColor Red;
    RETURN;
}
#endregion

#region Determine if the path is a directory or a url
IF ($ScriptPath -like "Http*" -or $ScriptPath -like "www.*") { 
    $ScriptPathType = "URL";
    IF($ScriptPath -notlike "https://raw.githubusercontent.com*") {
    write-host "Github URL must be a raw type URL link e.g https://raw.githubusercontent.com..." -ForegroundColor Red;
    Return;
    }

} 
ELSE {
    $ScriptPathType = "Filesystem";
}
#endregion

#region $ScriptPath validation
IF ($ManifestPath -eq $null) {
    write-host "You must specify a Manifest Path" -ForegroundColor Red;
    RETURN;
}
#endregion

#region Determine if the Manifest path is a directory or a url
IF ($ManifestPath -like "Http*" -or $ManifestPath -like "www.*") { 
    $ManifestPathType = "URL";
    IF($ManifestPath -notlike "https://raw.githubusercontent.com*") {
    write-host "Github URL must be a raw type URL link e.g https://raw.githubusercontent.com..." -ForegroundColor Red;
    Return;
    }

} 
ELSE {
    $ManifestPathType = "Filesystem";
}
#endregion


#region Retrieve the Inspector Installation SQL from URL
IF ($ScriptPathType -eq "URL") {
    Try {
    Invoke-WebRequest $ScriptPath -Outfile $TempFilename -ContentType 'sql';
    }
    Catch {
    write-host $_.Exception.Message -ForegroundColor Red;
    Return;
    }
} ELSE {
    IF ($(Test-Path -Path $ScriptPath) -ne $true) {
        write-host "Invalid Path specified: $ScriptPath" -ForegroundColor Red;
        Return;
    }ELSE {
        write-host "Script path - Ok" -ForegroundColor Green;
    }
}
#endregion

#region Validate script contents
write-host "Validating script contents";

#$InspectorURL = (Get-content -Path $(IF ($ScriptPathType -eq "URL") {$TempFilename} ELSE {$ScriptPath}) -TotalCount 74)[-1]
$InspectorURL = (Select-String -Pattern "URL: " -Path $(IF ($ScriptPathType -eq "URL") {$TempFilename} ELSE {$ScriptPath}) -list -SimpleMatch | select-object -First 1)
$InspectorURL = $InspectorURL.Line;
#$Build = (Get-content -Path $(IF ($ScriptPathType -eq "URL") {$TempFilename} ELSE {$ScriptPath}) -TotalCount 69)[-1]
$Build = (Select-String -Pattern "Version: " -Path $(IF ($ScriptPathType -eq "URL") {$TempFilename} ELSE {$ScriptPath}) -list -SimpleMatch | select-object -First 1)
$Build = $Build.Line.Replace("Version: ","");

IF ($InspectorURL -notlike "*SQLUndercover*") {
    Write-host "Script contents failed validation" -ForegroundColor Red
    RETURN;
}

IF ($([decimal]::TryParse($Build,[ref]0.00)) -eq $false) {
    Write-host "Inspector build failed validation" -ForegroundColor Red
    RETURN;
}
#endregion

#region confirm before continuing
While ($Confirmation -notin ("Y","N")) {
    $Confirmation = Read-host -Prompt "You are about to install Undercover Inspector Build: $Build in Database: $LoggingDB on servers: $SQLInstances
are you happy to continue Y/N?";

    $Confirmation = $Confirmation.ToUpper();

    IF ($Confirmation -eq "Y") {
        BREAK;
    }

    IF ($Confirmation -eq "N") {
        RETURN;
    }
}

$Confirmation = "";
#endregion

#region sanitise additional params
IF ($BackupsPath -ne "NULL") {
$BackupsPath = "'"+$BackupsPath+"'";
};


IF ($EmailRecipients -ne "NULL") {
$EmailRecipients = "'"+$EmailRecipients+"'";
};
#endregion

#region Set SQL statement text
$InstallScript = "
EXEC [Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = '$LoggingDB',	
@DataDrive = '$DataDrive',	
@LogDrive = '$LogDrive',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = $BackupsPath,
@StackNameForEmailSubject = 'SQLUndercover',	
@EmailRecipientList = $EmailRecipients,	  
@DriveSpaceHistoryRetentionInDays = 90, 
@DaysUntilDriveFullThreshold = 56, 
@FreeSpaceRemainingPercent = 10,
@DriveLetterExcludes = NULL, 
@DatabaseGrowthsAllowedPerDay = 1,  
@MAXDatabaseGrowthsAllowedPerDay = 10, 
@AgentJobOwnerExclusions = 'sa', 
@FullBackupThreshold = 8,		
@DiffBackupThreshold = 48,		
@LogBackupThreshold = 20,		
@DatabaseOwnerExclusions = 'sa',  
@LongRunningTransactionThreshold = 300,	
@InitialSetup = 0; 
";

$DBExistsQry = "SELECT CASE WHEN DB_ID('$LoggingDB') IS NOT NULL THEN 1 ELSE 0 END AS DB_ID;";
$ServerConnQry = "SELECT 1 AS Outcome;";
#endregion


ForEach ($SQLInstance in $SQLInstances.Split("|"))
{
    if($ServerValid) {
        clear-variable ServerValid;
    }
    
    write-host "Testing connection to: $SQLInstance";

    switch ($UseWindowsAuth) {

        "Y" {
                $ServerValid = Invoke-Sqlcmd -Query $ServerConnQry -ServerInstance $SQLInstance -database "master" -ConnectionTimeout 10;
         }

        "N" {
                $ServerValid = Invoke-Sqlcmd -Query $ServerConnQry -ServerInstance $SQLInstance -database "master" -Username $SQLUser -Password $SQLPassword -ConnectionTimeout 10;
        }
    }

    if($ServerValid) {
        write-host "$SQLInstance - OK" -ForegroundColor DarkGreen;
        $ValidatedServers.add($SQLInstance,1);
    } else {
        write-host "$SQLInstance - Unable to connect" -ForegroundColor Red;
        $ValidatedServers.add($SQLInstance,0);
    }
}

#Remove any servers that cannot be connected to
foreach ($ValidatedServer in $ValidatedServers.GetEnumerator()){
    if($ValidatedServer.Value -eq 0){
        $SQLInstances = $SQLInstances.Replace($ValidatedServer.Key,"");
    }
}

while ($SQLInstances.EndsWith("|")) {
   $LastCommaPos = $SQLInstances.LastIndexOf("|");
   $SQLInstances = $SQLInstances.Substring(0,$($LastCommaPos)); 
   #$SQLInstances;
}
    

#region For Each server create the InspectorSetup stored proc and execute it to install
ForEach ($SQLInstance in $SQLInstances.Split("|"))
{
    switch ($UseWindowsAuth) {
    "Y" {   $DBExists = Invoke-Sqlcmd -Query $DBExistsQry -ServerInstance $SQLInstance -database "master" -ConnectionTimeout 10 -OutputSqlErrors $false
            IF ($DBExists.DB_ID -eq 0) {
                While ($Confirmation -notin ("Y","N")) {
                    $Confirmation = Read-host -Prompt "Database $LoggingDB does not exist on server $SQLInstance - would you like to create it now Y/N?"
        
                    $Confirmation.ToUpper();
        
                    IF ($Confirmation -eq "Y") {
                        write-host "Creating database $LoggingDB using default Data and Log paths" -ForegroundColor DarkYellow;
                        Invoke-Sqlcmd -Query "CREATE DATABASE [$LoggingDB];" -ServerInstance $SQLInstance -database "master" -ConnectionTimeout 10;
                        $Confirmation = "";
                        BREAK;
                    }
        
                    IF ($Confirmation -eq "N") {
                        $Confirmation = "";
                        RETURN;
                    }
                }    
            }
            write-host "Creating [Inspector].[InspectorSetup] on [$SQLInstance]";
            Invoke-Sqlcmd -InputFile $(IF ($ScriptPathType -eq "URL") {$TempFilename} ELSE {$ScriptPath}) -ServerInstance $SQLInstance -database $LoggingDB -ConnectionTimeout 10;
            write-host "Running [Inspector].[InspectorSetup] on [$SQLInstance]";
            write-host "";
            Invoke-Sqlcmd -Query $InstallScript -ServerInstance $SQLInstance -database $LoggingDB -ConnectionTimeout 10; # -Verbose;
            }
        
    "N" {   $DBExists = Invoke-Sqlcmd -Query $DBExistsQry -ServerInstance $SQLInstance -database "master" -Username $SQLUser -Password $SQLPassword -ConnectionTimeout 10
            IF ($DBExists.DB_ID -eq 0) {
                While ($Confirmation -notin ("Y","N")) {
                    $Confirmation = Read-host -Prompt "Database $LoggingDB does not exist on server $SQLInstance - would you like to create it now Y/N?"
        
                    $Confirmation.ToUpper();
        
                    IF ($Confirmation -eq "Y") {
                        write-host "Creating $LoggingDB using default Data and Log paths" -ForegroundColor DarkYellow;
                        Invoke-Sqlcmd -Query "CREATE DATABASE [$LoggingDB];" -ServerInstance $SQLInstance -database "master" -Username $SQLUser -Password $SQLPassword -ConnectionTimeout 10
                        $Confirmation = "";
                        BREAK;
                    }
        
                    IF ($Confirmation -eq "N") {
                        $Confirmation = "";
                        RETURN;
                    }
                }    
            }
            write-host "Creating [Inspector].[InspectorSetup] on [$SQLInstance]";
            Invoke-Sqlcmd -InputFile $(IF ($ScriptPathType -eq "URL") {$TempFilename} ELSE {$ScriptPath}) -ServerInstance $SQLInstance -database $LoggingDB -Username $SQLUser -Password $SQLPassword -ConnectionTimeout 10;
            write-host "Running [Inspector].[InspectorSetup] on [$SQLInstance]";
            write-host "";
            Invoke-Sqlcmd -Query $InstallScript -ServerInstance $SQLInstance -database $LoggingDB -Username $SQLUser -Password $SQLPassword -ConnectionTimeout 10; #-Verbose;
        }
    }
    
}
#endregion

#region start custom module install 
ForEach ($SQLInstance in $SQLInstances.Split("|"))
{

IF ($ManifestPathType -eq "URL") {
    Try{
        invoke-webrequest -Uri $ManifestPath -Outfile $TempFilename -ContentType 'csv';
        $ManifestContents = import-csv -Path $TempFilename
    }
    Catch {
        write-host $_.Exception.Message -ForegroundColor Red;
        Return;
    }

    #Grab the contents of the manifest excluding the Inpector Install file
    foreach($ManifestItem in $($ManifestContents | ?{$_.Modulename -ne "SQLUndercoverinspectorV2.sql"})) {
        $ModuleFilename = $ManifestItem.Modulename;
        $ModuleURL = $ManifestItem.URL;
        $Modulename = $($ManifestItem.Modulename).Replace("Inspector_","").Replace("_CustomModule.sql","");

        IF((($CustomModules -eq "ALL") -or $($CustomModules -contains $Modulename)) -eq $true) {

            write-host "Installing $ModuleFilename on Instance: $SQLInstance";
            Try {
                invoke-webrequest -Uri $ModuleURL -Outfile $TempFilename -ContentType 'sql';
            } 
            Catch {
                write-host "Installing $Modulename failed: "$_.Exception.Message -ForegroundColor Red;
                Continue;
            }

            IF ($(test-path -Path $TempFilename) -eq $true) {

                switch ($UseWindowsAuth) {
                "Y" { 
                        Invoke-Sqlcmd -InputFile $TempFilename -ServerInstance $SQLInstance -database $LoggingDB -ConnectionTimeout 10;
                     }
                    
                "N" {  
                        Invoke-Sqlcmd -InputFile $TempFilename -ServerInstance $SQLInstance -database $LoggingDB -Username $SQLUser -Password $SQLPassword -ConnectionTimeout 10;
                    }
                }
            } ELSE {
                write-host "File: $TempFilename does not exist - unable to install module: $ModuleFilename" -ForegroundColor Red;
            }
        }
    }
} ELSE {
    IF ($(test-path -Path $ManifestPath) -eq $true) {
        $ManifestContents = import-csv -Path $ManifestPath;

        #Grab the contents of the manifest excluding the Inpector Install file
        foreach($ManifestItem in $($ManifestContents | ?{$_.Modulename -ne "SQLUndercoverinspectorV2.sql"})) {
            $ModuleFilename = $ManifestItem.Modulename;
            $ModulePath = $(split-path -Path $ManifestPath)+"\"+$ModuleFilename;
            $Modulename = $($ManifestItem.Modulename).Replace("Inspector_","").Replace("_CustomModule.sql","");

        IF((($CustomModules -eq "ALL") -or $($CustomModules -contains $Modulename)) -eq $true) {

            write-host "Installing $ModuleFilename on Instance: $SQLInstance";
            
            IF ($(test-path -Path $ModulePath) -eq $true) {

                switch ($UseWindowsAuth) {
                "Y" { 
                        Invoke-Sqlcmd -InputFile $ModulePath -ServerInstance $SQLInstance -database $LoggingDB -ConnectionTimeout 10;
                     }
                    
                "N" {  
                        Invoke-Sqlcmd -InputFile $ModulePath -ServerInstance $SQLInstance -database $LoggingDB -Username $SQLUser -Password $SQLPassword -ConnectionTimeout 10;
                    }
                }
            } ELSE {
                write-host "File: $ModulePath does not exist - unable to install module: $ModuleFilename" -ForegroundColor Red;
            }

            }

        }
    }

}

}

#endregion

#region Remove the Installation file
IF ($ScriptPathType -eq "URL") {
    Remove-Item -Path $TempFilename;
}
#endregion 

#region clear variables
Clear-Variable ScriptPathType,ScriptPath,SQLInstances,LoggingDB,TempDir,DataDrive,LogDrive,BackupsPath,UseWindowsAuth,InspectorURL,Build;
#endregion

read-host "press any key to exit";