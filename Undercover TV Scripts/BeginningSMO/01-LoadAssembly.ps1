<#	
					Loading the assembly

In order to use SMO you need to load the assembly.
An assembly is basically a fancy way of saying a .net DLL
that gets loaded into memory.

#>

##Now you'll notice that we're using LoadWithPartialName here.
##The PS team doesn't like us using that anymore because they prefer
##that we load the full assembly name.  It avoids problems with
##multiple versions of DLLs that may be loaded into the GAC.
##As DBAs we usually don't have those types of issues cause we tend
##to only have 1 version of SQL loaded at a time.
##So I believe that it's ok when dealing with SMO unless you
##specifically have issues.
[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.Smo") | out-null

##Here's an example of loading with the full name.
##You can see why we prefer the other way.
[reflection.assembly]::load("Microsoft.SqlServer.SMO, Version=10.0.0.0, culture=neutral, publickeytoken=89845dcd8080cc91")

