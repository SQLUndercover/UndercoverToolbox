--Undercover Catalogue
--David Fowler
--Version 0.4.4 - 15 April 2024
--Module: Snapshots
--Script: Update

BEGIN
--Update snapshots where they're known to the catalogue
UPDATE Catalogue.Snapshots
SET		ServerName = Snapshots_Stage.ServerName,
		DatabaseID = Snapshots_Stage.DatabaseID,
		SnapshotName = Snapshots_Stage.SnapshotName,
		SourceDBName = Snapshots_Stage.SourceDBName,
		CreateDate = Snapshots_Stage.CreateDate,
		LastRecorded = GETDATE()
FROM Catalogue.Snapshots_Stage
WHERE Snapshots.ServerName = Snapshots_Stage.ServerName 
		AND Snapshots.SnapshotName = Snapshots_Stage.SnapshotName
		
--Insert snapshots that are unknown to the catalogue
INSERT INTO Catalogue.Snapshots
	(ServerName,
	DatabaseID,
	SnapshotName,
	SourceDBName,
	CreateDate,
	FirstRecorded,
	LastRecorded)
SELECT	ServerName,
		DatabaseID,
		SnapshotName,
		SourceDBName,
		CreateDate,
		GETDATE(),
		GETDATE()
FROM Catalogue.Snapshots_Stage
WHERE NOT EXISTS
(SELECT 1 FROM Catalogue.Snapshots 
		WHERE Snapshots.ServerName = Snapshots_Stage.ServerName 
		AND Snapshots.SnapshotName = Snapshots_Stage.SnapshotName)
END