BEGIN

--update databases where they are known to the catalogue
UPDATE Catalogue.Databases 
SET		ServerName = Databases_Stage.ServerName,
		DBName = Databases_Stage.DBName,
		DatabaseID = Databases_Stage.DatabaseID,
		OwnerName = Databases_Stage.OwnerName,
		CompatibilityLevel = Databases_Stage.CompatibilityLevel,
		CollationName = Databases_Stage.CollationName,
		RecoveryModelDesc = Databases_Stage.RecoveryModelDesc,
		AGName = Databases_Stage.AGName,
		FilePaths = Databases_Stage.FilePaths,
		DatabaseSizeMB= Databases_Stage.DatabaseSizeMB,
		LastRecorded = GETDATE()
FROM Catalogue.Databases_Stage
WHERE	Databases.ServerName = Databases_Stage.ServerName
		AND Databases.DBName = Databases_Stage.DBName

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Databases
(ServerName, DBName, DatabaseID, OwnerName, CompatibilityLevel, CollationName, RecoveryModelDesc, AGName,FilePaths,DatabaseSizeMB,FirstRecorded,LastRecorded)
SELECT ServerName,
		DBName,
		DatabaseID,
		OwnerName,
		CompatibilityLevel,
		CollationName,
		RecoveryModelDesc,
		AGName,
		FilePaths,
		DatabaseSizeMB,
		GETDATE(),
		GETDATE()
FROM Catalogue.Databases_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Databases
		WHERE DBName = Databases_Stage.DBName
		AND Databases.ServerName = Databases_Stage.ServerName)

END


