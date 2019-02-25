param
(
[string]$Server = 'localhost',
[string]$DBName = 'Minion',
[string]$SchemaName = 'Collector',
[string]$TableName = 'DBUsers',
[string]$FileBase = "C:\MyDBs"
)
<#	
					Data Scripter

You can also separate the schema and data collections by putting them
in separate scripts.
This can be used as a plugin for many processes so you don't
have to keep re-writing the code.

!!Legal Disclaimer: Don't do anything on a production system 
without testing it first and you know the ramifications.
I am NOT responsible for any use or misuse of anything you 
see here.
#>

$FileName = "$FileBase\$SchemaName`.$TableName`.txt";
##Load the assembly.
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;

$srv = New-Object "Microsoft.SqlServer.Management.SMO.Server" $Server
$scripter = New-Object ("Microsoft.SqlServer.Management.SMO.Scripter") ($srv)

# Get the database and table objects
$DBList = $srv.Databases[$DBName]
$TableList = $DBList.Tables | ?{ $_.Schema -eq $SchemaName -and $_.Name -eq $TableName }

# Set scripter options to ensure only data is scripted
$scripter.Options.ScriptSchema = $false;
$scripter.Options.ScriptData = $true;

	#$scripter.Options.FileName = "$FileName";
	$scripter.Options.ToFileOnly = $true

# Output the script
foreach ($s in $scripter.EnumScript($TableList.Urn))
{
	write-host $s;
	$s | Out-File $FileName -Append;
	
}
