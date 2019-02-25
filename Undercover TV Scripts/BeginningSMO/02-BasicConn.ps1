<#	
					Basic Connection

Connecting to a server is easy, so don't make it any harder
than it is.
There are a number of considerations when connecting, but the
basics are easy.  We'll be discussing some of these throughout
the session.

#>

##Load the assembly.
[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.Smo") | out-null

##Create a var as an SMO server object.
#$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server');
##It took me a long time to fully understand this, but it's
##basic OOP.  Here's what I hope is a good explanation.

##Vars have to have a datatype.  In fact, all vars are objects.
##Let's take a look at this real quick.

$a = 5;
$b = "Hello";
$c = dir .\*.ps1;

##Now let's run this in PS with dot-sourcing.
##We can now run a gm on each of the vars and see their members.
##You'll notice that each one of them had completely diff members
##and they're also listed as different types.

##Also, if we just print the $srv var to the screen, we can see
##its properties.  Pay special attention to the ConnectionContext
##property and you can see that it makes a default conn in the
##absence of any other params being passed in.  It also defaults
##to SSPI.

##Here are examples of connecting to remote servers.
  $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "bendycon";
#  $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "Server1\Inst1";

# $Instance = "bendycon";
# $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $Instance;





