cls
<#
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
#Version: 2.00
#Revision date: 04/11/2019
 
#set variables
#if you are using a Github URL this must be the raw URL.

#$ScriptPath = "https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverInspector/SQLUndercoverinspectorV2.sql"
$ScriptPath = "C:\Temp\SQLUndercoverinspectorV2.sql"
$SQLInstances = "SQL01,SQL02,SQL03" #if this is a linked server install ensure that the central server appears first in the list
$LoggingDB = "SQLUndercover"
$UseWindowsAuth = "Y"  #"Y" or "N"

$DataDrive = "S,U"
$LogDrive = "T,V"

#Optional Parameters
$BackupsPath = "NULL" #"NULL" or backups Path
$LinkedServername = "NULL" #"NULL" or Linked server name if you are not using the powershell collection but do need to centralise data into the central server - Linked server must exist.
$EmailRecipients = "NULL" #Semi colon delimited eg "Email@domain.com;Email2@domain.com"


#Do not change anything beyond this point
$TempDir = "C:\Temp\"

IF ($TempDir.EndsWith("\") -eq $falsw) {
    $TempDir = $TempDir+"\";
}

IF ($(test-path -Path $TempDir) -eq $false) {
    New-Item -ItemType Directory -Path $TempDir | out-null;
}

$TempFilename = $TempDir+"InspectorInstall.sql";


IF ($UseWindowsAuth -eq "N") {
$SQLCred = Get-Credential -Message "Please provide SQL Authentication credentials to connect";
$SQLUser = $SQLCred.UserName;
$SQLPassword = $SQLCred.GetNetworkCredential().password
}

$Confirmation = "";

IF ($ScriptPath -eq $null) {
    write-host "You must specify a Script Path" -ForegroundColor Red;
    RETURN;
}

#Determine if the path is a directory or a url
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


#Retrieve the Inspector Installation SQL from URL
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
        write-host "Invalid Path specified" -ForegroundColor Red;
    }ELSE {
        write-host "Script path - Ok" -ForegroundColor Green;
    }
}


#Validate script contents
write-host "Validating script contents";

$InspectorURL = (Get-content -Path $(IF ($ScriptPathType -eq "URL") {$TempFilename} ELSE {$ScriptPath}) -TotalCount 72)[-1]
$Build = (Get-content -Path $(IF ($ScriptPathType -eq "URL") {$TempFilename} ELSE {$ScriptPath}) -TotalCount 68)[-1]
$Build = $Build.Replace("Version: ","");

IF ($InspectorURL -notlike "*SQLUndercover*") {
    Write-host "Script contents failed validation" -ForegroundColor Red
    RETURN;
}

IF ($([decimal]::TryParse($Build,[ref]0.00)) -eq $false) {
    Write-host "Inspector build failed validation" -ForegroundColor Red
    RETURN;
}

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

IF ($BackupsPath -ne "NULL") {
$BackupsPath = "'"+$BackupsPath+"'";
};

IF ($LinkedServername -ne "NULL") {
$LinkedServername = "'"+$LinkedServername+"'";
};


$InstallScript = "
EXEC [Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = '$LoggingDB',	
@DataDrive = '$DataDrive',	
@LogDrive = '$LogDrive',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = $BackupsPath,
@LinkedServername = $LinkedServername,  
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
@DiffBackupThreshold = 2,		
@LogBackupThreshold = 20,		
@DatabaseOwnerExclusions = 'sa',  
@LongRunningTransactionThreshold = 300,	
@InitialSetup = 0; 
";

$DBExistsQry = "SELECT CASE WHEN DB_ID('$LoggingDB') IS NOT NULL THEN 1 ELSE 0 END AS DB_ID;";


#For Each server create the InspectorSetup stored proc and execute it to install
ForEach ($SQLInstance in $SQLInstances.Split(","))
{
    switch ($UseWindowsAuth) {
    "Y" {   $DBExists = Invoke-Sqlcmd -Query $DBExistsQry -ServerInstance $SQLInstance -database "master" -ConnectionTimeout 10;
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
            Invoke-Sqlcmd -Query $InstallScript -ServerInstance $SQLInstance -database $LoggingDB -ConnectionTimeout 10 -Verbose;
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
            Invoke-Sqlcmd -Query $InstallScript -ServerInstance $SQLInstance -database $LoggingDB -Username $SQLUser -Password $SQLPassword -ConnectionTimeout 10 -Verbose;
        }
    }
    
}


#Remove the Installation file
IF ($ScriptPathType -eq "URL") {
    Remove-Item -Path $TempFilename;
}

Clear-Variable ScriptPathType,ScriptPath,SQLInstances,LoggingDB,TempDir,DataDrive,LogDrive,BackupsPath,LinkedServername,UseWindowsAuth,InspectorURL,Build;