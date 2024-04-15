--Undercover Catalogue
--David Fowler
--Version 0.4.4 - 15 April 2024
--Module: Snapshots
--Script: Get

SELECT	@@SERVERNAME AS ServerName,
		database_id AS DatabaseID,
		name AS SnapshotName,
		DB_NAME(source_database_id) AS SourceDBName,
		create_date AS CreateDate
FROM sys.databases
WHERE source_database_id IS NOT NULL