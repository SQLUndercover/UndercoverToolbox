
[string]$Server = 'localhost';
[string]$DBName = 'Minion';
[string]$SchemaName = 'Collector';
[string]$TableName = 'DBUsers';
[string]$FileBase = "C:\MyDBs"

<#	
					Scripting Data 2

You can also separate the schema and data collections by putting them
in separate scripts.

!!Legal Disclaimer: Don't do anything on a production system 
without testing it first and you know the ramifications.
I am NOT responsible for any use or misuse of anything you 
see here.
#>

##Load the assembly.
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;

$srv = New-Object "Microsoft.SqlServer.Management.SMO.Server" #$server
##Create a var to hold the scripting options.
$so = New-Object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions');

	$so.ScriptDrops = 1;
	$so.IncludeIfNotExists = 1;

# Get the database and table objects
$DBList = $srv.Databases[$DBName]
$TableList = $DBList.Tables | ?{ $_.Schema -eq $SchemaName -and $_.name -eq $TableName }
$TableList | %{
	
	###Script Exists and Drop.
	"-- $(Get-Date)" | Out-File "$FileBase\$SchemaName`.$TableName.txt";
	$so.ScriptDrops = 1;
	$so.IncludeIfNotExists = 1;
	$_.Script($so) | Out-File "$FileBase\$SchemaName`.$TableName.txt" -Append;
	###Script Schema.
	$so.ScriptDrops = 0;
	$so.IncludeIfNotExists = 0;
	$_.Script($so) | Out-File "$FileBase\$SchemaName`.$TableName.txt" -Append;
	
	###Script data. Calling external script.
	##Set the path cause we're calling the script from a diff path.
	##If we were calling the script from it's path we wouldn't
	##need to do this.
	$Path = Split-Path -parent $PSCommandPath;
	Set-Location "$Path";
	./DataScripter.ps1 $Server $DBName $SchemaName $TableName $FileBase;
}