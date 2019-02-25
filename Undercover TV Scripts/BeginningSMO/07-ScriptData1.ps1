<#	
					Scripting Data 1

Here we're going to use the scripter class for some basic data
scripting. It never gets more complicated than this using this
class, but as scripts go, it's not very good.

!!Legal Disclaimer: Don't do anything on a production system 
without testing it first and you know the ramifications.
I am NOT responsible for any use or misuse of anything you 
see here.
#>

##Load the assembly.
[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.Smo") | out-null

##Create a var as an SMO server object.
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server');
##Create a var to hold the scripting options.
$so = New-Object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions');
##Create a var as a Scripter object.
##Notice that we have to pass it the $srv object so it knows
##which server to connect to so it can fetch the data.
$s = New-Object ('Microsoft.SqlServer.Management.Smo.Scripter') ($srv);

$BasePath = "C:\MyDBs";
$FileName = "$BasePath\Tables.txt";
$Begin = Get-Date;

###Basic scripting
IF (Test-Path $FileName)
{
	del $FileName;
}

$TableList = $srv.databases["Minion"].Tables;

$s.Options.ScriptData = 1;
$TableList | ?{$_.Name -eq "DBUsers" } | %{

	$s.EnumScript($_) | Out-File "$FileName" -Append;	
	$_.Name;
}

notepad.exe $FileName;
