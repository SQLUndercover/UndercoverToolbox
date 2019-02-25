<#	
					SQL Authentication

Sometimes you may need to use sql auth.

!!!And despite what I do here, you shouldn't keep pwords in scripts.
You should keep it encrypted somewhere and decrypt it in the
script instead.!!!

#>

##Load the assembly.
[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.Smo") | out-null

##Create a var as an SMO server object.
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server');
$srv.ConnectionContext.LoginSecure = false;
$srv.ConnectionContext.Login = "sa";
$srv.ConnectionContext.Password = "Silversurfer1!";
$srv.ConnectionContext.ApplicationName = "SMO from PS";
