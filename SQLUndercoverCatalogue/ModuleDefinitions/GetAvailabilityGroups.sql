--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: AvailabilityGroups
--Script: Get

BEGIN

--Get availability group details
SELECT	AGs.name AS AGName,
		replicas.replica_server_name AS ServerName,
		replica_states.role_desc AS Role,
		AGs.automated_backup_preference_desc AS BackupPreference,
		replicas.availability_mode_desc AS AvailabilityMode,
		replicas.failover_mode_desc AS FailoverMode,
		replicas.secondary_role_allow_connections_desc AS ConnectionsToSecondary
FROM sys.availability_groups AGs
JOIN sys.availability_replicas replicas ON replicas.group_id = AGs.group_id
JOIN sys.dm_hadr_availability_replica_states replica_states ON replica_states.replica_id = replicas.replica_id

END

