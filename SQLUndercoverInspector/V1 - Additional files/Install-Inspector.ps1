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
 
#set variables
$ScriptURL="https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverInspector/SQLUndercoverinspectorV1.sql"
$CentralServer = "SQL02"
$SQLInstances = "SQL01,SQL03"
$DefaultDatabase = "SQLUndercoverDB"
$TempDir = "C:\Temp\InspectorInstall"
$DataDrive = "S,U"
$LogDrive = "T,V"
#Optional Parameters
$BackupsPath = "NULL" #"NULL" or backups Path
$LinkedServername = "NULL" #"NULL" or Linked server name


IF ($BackupsPath -ne "NULL") {
$BackupsPath = "'"+$BackupsPath+"'";
}

IF ($LinkedServername -ne "NULL") {
$LinkedServername = "'"+$LinkedServername+"'";
}

$InstallScript = "
EXEC [Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = '$DefaultDatabase',	
@DataDrive = '$DataDrive',	
@LogDrive = '$LogDrive',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = $BackupsPath,
@LinkedServername = $LinkedServername,  
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
@InitialSetup = 0; 
"

#Retrieve the Inspector Installation SQL
Try {
Invoke-WebRequest $ScriptURL -Outfile $TempDir -ContentType 'sql'
}
Catch {
write-host $_.Exception.Message -ForegroundColor Red
Return;
}


#For The Central server create the InspectorSetup stored proc and execute it to install

Try {
write-host "Creating [Inspector].[InspectorSetup] on [$CentralServer]";
Invoke-Sqlcmd -InputFile $TempDir -ServerInstance $CentralServer -database $DefaultDatabase
write-host "Running [Inspector].[InspectorSetup] on [$CentralServer]";
Invoke-Sqlcmd -Query $InstallScript -ServerInstance $CentralServer -database $DefaultDatabase
}
Catch {
write-host $_.Exception.Message
write-host "Inspector install failed on [$CentralServer]" -ForegroundColor Red
Return;    
}


write-host "Inspector install successful on [$CentralServer]" -ForegroundColor Green




#For Each server create the InspectorSetup stored proc and execute it to install
ForEach ($SQLInstance in $SQLInstances.Split(","))
{

    Try {
    write-host "Creating [Inspector].[InspectorSetup] on [$SQLInstance]";
    Invoke-Sqlcmd -InputFile $TempDir -ServerInstance $SQLInstance -database $DefaultDatabase
    write-host "Running [Inspector].[InspectorSetup] on [$SQLInstance]";
    Invoke-Sqlcmd -Query $InstallScript -ServerInstance $SQLInstance -database $DefaultDatabase
    }
    Catch {
    write-host $_.Exception.Message
    write-host "Inspector install failed on [$SQLInstance]" -ForegroundColor Red
    Break;    
    }

    write-host "Inspector install successful on [$SQLInstance]" -ForegroundColor Green
    

}


#Remove the Installation file
Remove-Item -Path $TempDir 


