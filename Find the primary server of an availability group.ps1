#Find an availability group's primary server
#set $ServerName to any node that's part of the AG that you're interested in

$ServerName = 'SQL01'

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
$svr = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName;
$svr.ConnectionContext.StatementTimeout = 0;

foreach ($AvailabilityGroup in $svr.AvailabilityGroups)
{
    Write-Host "$($AvailabilityGroup.Name) : $($AvailabilityGroup.PrimaryReplicaServerName)"
}