--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: AvailabilityGroups
--Script: Update


BEGIN

--update AGs where they are known
UPDATE  Catalogue.AvailabilityGroups 
SET		AGName = AvailabilityGroups_Stage.AGName,
		ServerName = AvailabilityGroups_Stage.ServerName,
		Role = AvailabilityGroups_Stage.Role,
		BackupPreference = AvailabilityGroups_Stage.BackupPreference,
		AvailabilityMode = AvailabilityGroups_Stage.AvailabilityMode,
		FailoverMode = AvailabilityGroups_Stage.FailoverMode,
		ConnectionsToSecondary = AvailabilityGroups_Stage.ConnectionsToSecondary,
		LastRecorded = GETDATE()
FROM Catalogue.AvailabilityGroups_Stage
WHERE	AvailabilityGroups.AGName = AvailabilityGroups_Stage.AGName
		AND AvailabilityGroups.ServerName = AvailabilityGroups_Stage.ServerName

--insert AGs that are unknown to the catalogue
INSERT INTO Catalogue.AvailabilityGroups
(AGName, ServerName, Role, BackupPreference, AvailabilityMode, FailoverMode, ConnectionsToSecondary,FirstRecorded, LastRecorded)
SELECT	AGName,
		ServerName,
		Role,
		BackupPreference,
		AvailabilityMode,
		FailoverMode,
		ConnectionsToSecondary,
		GETDATE(),
		GETDATE()
FROM Catalogue.AvailabilityGroups_Stage AvailabilityGroups_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.AvailabilityGroups
		WHERE AGName = AvailabilityGroups_Stage.AGName 
		AND ServerName = AvailabilityGroups_Stage.ServerName)
--AND AGName IN (	SELECT AvailabilityGroups_Stage_sub.AGName 
--				FROM AvailabilityGroups_Stage AvailabilityGroups_Stage_sub 
--				WHERE AvailabilityGroups_Stage_sub.ServerName = AvailabilityGroups_Stage.ServerName 
--					AND Role = 'Primary')

END
