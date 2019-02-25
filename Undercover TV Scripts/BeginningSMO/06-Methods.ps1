<#	
					Calling Methods

Now it's time to do some work.  Until now we've only been
looking at things... auditing.  But now we're going to be making
changes.

!!Legal Disclaimer: Don't do anything on a production system 
without testing it first and you know the ramifications.
I am NOT responsible for any use or misuse of anything you 
see here.
#>

##Load the assembly.
[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.Smo") | out-null

##Create a var as an SMO server object.
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server');
$so = New-Object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions');
$s = New-Object ('Microsoft.SqlServer.Management.Smo.Scripter') ($srv);

$Begin = Get-Date;

###Again, as usual we'll start with gm on databases.
#$srv.databases | gm;

###Let's see the RecoveryModel for all DBs.
#$srv.Databases | FT Name, RecoveryModel -auto;

### It's too convoluted to look through all the objects,
###so let's limit it to what we're interested in.
#$srv.databases | gm | ?{$_.Name -eq "RecoveryModel"};

###Change all RecoveryModels to Full/Simple, whichever it needs.
###Depending on the version you're on, you may need to use the
###number.
###It's easy to figure out which one it is because they go in order
###from most protective to least.
##1 - Full
##2 - Bulk
##3 - Simple
#$srv.Databases | %{
#	$_.RecoveryModel = "Simple";
#	#$_.RecoveryModel = 1;
#	$_.Name;
#}

#$srv.Databases | FT Name, RecoveryModel -auto;

###So if we restart the PS shell and query again, you'll see
###that the changes don't appear to have been made.  Why not?
###
###Notice there's a method called ALTER().
###Let's have a look.
#$srv.databases | gm;
#$srv.databases | gm | ?{$_.Name -eq "Alter"} | FL;

###Now let's try again.
#$srv.Databases | %{
#	$_.RecoveryModel = "Simple";
#	#$_.RecoveryModel = 1;
#	$_.Alter();
#	$_.Name;
#}

###Restart the shell and try again.
#$srv.Databases | FT Name, RecoveryModel -auto;

###Basic scripting
del C:\MyDBs\Tables.txt;
$so.ScriptDrops = 1;
$so.EnforceScriptingOptions = 0;
$so.Indexes = 1;
$TableList = $srv.databases["Minion"].Tables;

#$s.Options.ScriptData = $true;
$TableList | ?{$_.Name -eq "DBUsers" } | %{
#	$_.Script($so) | Out-File "C:\MyDBs\Tables.txt" -Append;
#	$so.ScriptDrops = 0;
#	$so.IncludeIfNotExists = 0;
#	$_.Script($so) | Out-File "C:\MyDBs\Tables.txt" -Append;
	$so.ScriptData = 1;
	$s.EnumScript($_) | Out-File "C:\MyDBs\Tables.txt" -Append;
	#$s.script($_)
	
	$_.Name;
}
$so
notepad.exe C:\MyDBs\Tables.txt;
