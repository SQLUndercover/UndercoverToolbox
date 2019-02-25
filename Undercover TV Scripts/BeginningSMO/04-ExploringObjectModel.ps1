<#	
					Exploring the Object Model

Now let's get busy actually looking around the object model.
You can see a diagram of it here:
https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/smo-object-model-diagram?view=sql-server-2017

#>

##Load the assembly.
[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.Smo") | out-null

##Create a var as an SMO server object.
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server');

###Start with gm on $srv.
#$srv | gm;
#$srv.connectioncontext
###Now gm on databases.
#$srv.databases | gm;

###Get info on all DBs.
#$srv.databases | FT Name, Size, DataSpaceUsage, IndexSpaceUsage, SpaceAvailable -auto;

###Get info on a single DB.
#$srv.databases["Minion"] | FT Name, Size, DataSpaceUsage, IndexSpaceUsage, SpaceAvailable -auto;

###Get info on a single DB with var. This lets you pass it into the script.
#$DB = "Minion";
#$srv.databases[$DB] | FT Name, Size, DataSpaceUsage, IndexSpaceUsage, SpaceAvailable -auto;

###Get info on a list of specific DBs and put into grid.
#$srv.databases | ?{ $_.Name -match "^Min" } | select Name, Size, DataSpaceUsage, IndexSpaceUsage, SpaceAvailable | out-gridView;

###!!!The problem with the above is that SMO is horribly documented.
###Look at the sizes above. They're in diff metrics.
###Size is MB. Rest are in KB.

###Combine methods and get a list of all tables.
#$srv.databases["Minion"].Tables.Name;
###Now get the index names.
#$srv.databases["Minion"].Tables.Indexes.Name;
###Now get the names of the indexes for a single table.
###Notice it doesn't find the table cause it's not in dbo.
#$srv.databases["Minion"].Tables["TableProperties"].Indexes.Script();
###There's an overload for the tables collection that adds schema.
###However, I don't like it cause it comes after the table instead of before.
#$srv.databases["Minion"].Tables["TableProperties", "Collector"].Indexes.Script();
###Finally, script a single index for that table.
#$srv.databases["Minion"].Tables["TableProperties", "Collector"].Indexes["nonDBName"].Script();

###################Exploring Jobs##################
###See where it is in the OM... notice it's a collection.
#$srv | gm
###See everything the JobServer has to offer.
#$srv.JobServer | gm;
###Get names of all jobs.
#$srv.JobServer.Jobs.Name;

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


