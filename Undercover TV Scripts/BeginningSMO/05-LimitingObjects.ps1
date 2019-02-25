<#	
					Limiting Objects

Here we're going to work on limiting the info we're bringing back.
Some methods are better than others, but oddly, for pulling from multiple
objects, there's no obviously fast method.
#>

##Load the assembly.
[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.Smo") | out-null

##Create a var as an SMO server object.
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server');

$Begin = Get-Date;

###Get info on a single DB.
###We've already seen this but it's a good review.
$srv.databases["SSISDB"] | FT Name, Size, DataSpaceUsage, IndexSpaceUsage, SpaceAvailable -auto;

#$srv.databases | ?{$_.Name -eq "MinionTest"} | FT Name, Size, DataSpaceUsage, IndexSpaceUsage, SpaceAvailable -auto;


###What if you need to pull from a list of DBs?
###Like everything else, there's more than 1 way.
###Here we're seeing which of these DBs has a specific table.
#$DBList = "Minion", "MinionDev", "MM11", "MinionDemoOld";
#$DBList | %{
#	$DBName = $_;
#	
#	IF ($srv.databases[$DBName].Tables.Contains("Servers", "dbo"))
#	{
#		"$DBName";
#	}
#	
#}

###What if you need to pull from a list of DBs?
###Here we're seeing which of these DBs DON'T have a specific table.
#$DBList = "Minion", "MinionDev", "MM11", "MinionDemoOld";
#$DBList | %{
#	$DBName = $_;
#	
#	IF (!($srv.databases[$DBName].Tables.Contains("Servers", "dbo")))
#	{
#		"$DBName";
#		#$srv.databases[$DBName].Tables.Contains("Servers", "dbo")
#	}
#	
#}

###Let's get all the DBs and whether they contain that table.
###While we're at it, let's get some sizing info.
$DBList = "Minion", "MinionDev", "MM11", "MinionDemoOld";
$results = @();
$DBList | %{
	$DBName = $_;
	[int]$Exists = $srv.databases[$DBName].Tables.Contains("Servers", "dbo");
	[int]$Size = $srv.databases[$DBName].Tables["Servers", "dbo"].Size;
	[int]$DataSpace = $srv.databases[$DBName].Tables["Servers", "dbo"].DataSpaceUsed;
		$row = @{ }

		$row["DBName"] = $DBName;
		$row["Exists"] = $Exists;
		$row["Size"] = $Size;
		$row["DataSpace"] = $DataSpace;

		$results += new-object psobject -property $row;
	}	
$results | select DBName, Exists, DataSpace, Size;



$End = Get-Date;
#New-TimeSpan $Begin $End;
<#
This has just been a walkthrough of the model and some of the syntax.
There are obvious problems with this:
-You can't list schemas along with the objects
-You can't limit by schema or object name.
-Since you're dealing with entire collections it can take longer
to get going and it may take up lots more memory on the server
to hold all of the scripted objects before it spits them out.

Next we're going to look at some more useful methods for working
with SMO.
#>


