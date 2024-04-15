/*                                                                                                                      
                                                                                                                                                                                                                                             
              @     ,@                                                                                                  
             #@@   @@@                                                                                                  
             @@@@@@@@@;                                                                                                 
             @@@@@@@@@@                                                                                                 
            :@@@@@@@@@@                                                                                                 
            @@@@@@@@@@@                                                                                                 
            @@@@@@@@@@@;                                                                                                
            @@@@@@@@@@@@                                                                                                
            @@@@@@@@@@@@                                                                                                
           `+@@@@@@@@@@+                                                                                                
                                                                                                                        
                                                                                                                        
         .@@`           #@,                                                                                             
     .@@@@@@@@@@@@@@@@@@@@@@@@:                                                                                         
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@     @@   @@      #@   @           @                                         
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@   @@@@  @#      #@   @           @                                         
    ;@@@@@@@@@@@@@@@@@@@@@@@@@@'        @     @   @# @#      #@   @ #@@@   @@@@  @@@  @@@@@  @@@   @@  @   @  @@   @ @@     
        .+@@@@@@@@@@@@@@@@+.            @@@@  @   @@ @#      #@   @ #@  @ @@  @  @  @  @@   @  @  @ `@  @ @  @  @  @@    
       '`                  `,#           @@@@ @   @@ @#      #@   @ #@  @ @#  @ @@@@@  @    @     @  @  @ @  @@@@  @`     
     ,@@@@ '@@@@@@@@@@@@@ .@@@@;           @  @   @@ @#      #@   @ #@  @ @@  @ @@     @ `  @     @  @  @@@  @     @      
    #@@@@@@ @@@@@  +@@@@  +@@@@@@       @@@@   @@@@  @@@@@   `@@@@@ #@  @ #@ @@  @  @  @    @@ @  @  @   @   @  @  @      
   @@@@@@@@  ,#.    `#;   @@@@@@@@'      @@     @@   @@@@@     @@,  #@  @  @@ @   @@  @@     #@    @@    @    @@   @      
  ;#@@@@@@@@             @@@@@@@@@#,              @                                                                     
       ,@@@@+           @@@@@+`                                                                                         
          .@@`        `@@@@                                          www.sqlundercover.com                                                             
         +@@@@        @@@@@+                                                                                            
        @@@@@@@      @@@@@@@@#                                                                                          
         @@@@@@@    @@@@@@,                                                                                             
         @@@@@@@    @@@@@@,                                                                                             
           :@@@@@' ;@@@@`                                                                                               
             `@@@@ @@@+                                                                                                 
                @#:@@                                                                                                   
                  @@                                                                                                    
                  @`                                                                                                    
                  #                                                                                                     
                                                                                                                            
Sequential Upgrade - 0.4.4
David Fowler
15/04/2024

MIT License
------------

Copyright 2024 Sql Undercover

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

Change Log
----------

MODULE ENHANCEMENT - Database Snapshots removed from database collection
MODULE ENHANCEMENT - Last access time added to database module
NEW MODULE - Database snapshots now have their own module

*/


---------------------------------------------------
--Schema Changes
---------------------------------------------------

ALTER TABLE Catalogue.Databases
ADD LastAccessDate DATETIME

ALTER TABLE Catalogue.Databases_Stage
ADD LastAccessDate DATETIME

----------------------------------------------------
--Module Definition Changes
----------------------------------------------------

DECLARE @ModuleID INT

SELECT @ModuleID = ID 
FROM Catalogue.ConfigModules
WHERE ModuleName = 'Databases'

UPDATE Catalogue.ConfigModulesDefinitions
SET GetDefinition = '--Undercover Catalogue
--David Fowler
--Version 0.4.4 - 15 April 2024
--Module: Databases
--Script: Get
BEGIN
	--get all databases on server
	SELECT @@SERVERNAME AS ServerName
		,databases.name AS DBName
		,databases.database_id AS DatabaseID
		,server_principals.name AS OwnerName
		,databases.compatibility_level AS CompatibilityLevel
		,databases.collation_name AS CollationName
		,databases.recovery_model_desc AS RecoveryModelDesc
		,availability_groups.name AS AGName
		,files.FilePaths
		,files.DatabaseSizeMB
		,databases.state_desc AS StateDesc
		,lastaccess.last_user_access
	FROM sys.databases
	LEFT OUTER JOIN sys.server_principals ON server_principals.sid = databases.owner_sid
	LEFT OUTER JOIN sys.availability_replicas ON availability_replicas.replica_id = databases.replica_id
	LEFT OUTER JOIN sys.availability_groups ON availability_groups.group_id = availability_replicas.group_id
	JOIN (
		SELECT database_id
			,(SUM(CAST(size AS BIGINT)) * 8) / 1024 AS DatabaseSizeMB
			,STUFF((
					SELECT ''
						,'' + files2.physical_name
					FROM sys.master_files files2
					WHERE files2.database_id = files1.database_id
					FOR XML PATH('''')
					), 1, 2, '''') AS FilePaths
		FROM sys.master_files files1
		GROUP BY database_id
		) files ON files.database_id = databases.database_id
	JOIN (
		SELECT db_name(databases.database_id) AS DBName
			,(
				SELECT MAX(last_user_access)
				FROM (
					VALUES (MAX(last_user_seek))
						,(MAX(last_user_scan))
						,(MAX(last_user_lookup))
					) AS value(last_user_access)
				) AS last_user_access
		FROM sys.dm_db_index_usage_stats indexstats
		RIGHT OUTER JOIN sys.databases databases ON indexstats.database_id = databases.database_id
		GROUP BY databases.database_id
		) AS lastaccess ON databases.name = lastaccess.DBName
	WHERE databases.source_database_id IS NULL
END'
WHERE ModuleID = @ModuleID

UPDATE Catalogue.ConfigModulesDefinitions
SET UpdateDefinition = '
--Undercover Catalogue
--David Fowler
--Version 0.4.4 - 15 April 2024
--Module: Databases
--Script: Update


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
		LastRecorded = GETDATE(),
		StateDesc = Databases_Stage.StateDesc,
		LastAccessDate = Databases_Stage.LastAccessDate
FROM Catalogue.Databases_Stage
WHERE	Databases.ServerName = Databases_Stage.ServerName
		AND Databases.DBName = Databases_Stage.DBName

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Databases
(ServerName, DBName, DatabaseID, OwnerName, CompatibilityLevel, CollationName, RecoveryModelDesc, AGName,FilePaths,DatabaseSizeMB,FirstRecorded,LastRecorded, StateDesc, LastAccessDate)
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
		GETDATE(),
		StateDesc,
		LastAccessDate
FROM Catalogue.Databases_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Databases
		WHERE DBName = Databases_Stage.DBName
		AND Databases.ServerName = Databases_Stage.ServerName)

END'
WHERE ModuleID = @ModuleID


-------------------------------------------------------------------
--Snapshots Module
-------------------------------------------------------------------

--create tables

CREATE TABLE Catalogue.Snapshots_Stage
(ServerName SYSNAME NOT NULL,
DatabaseID INT NOT NULL,
SnapshotName SYSNAME NOT NULL,
SourceDBName SYSNAME NOT NULL,
CreateDate DATETIME NOT NULL,
CONSTRAINT PK_Snapshots_Stage PRIMARY KEY (ServerName, SnapshotName))


CREATE TABLE Catalogue.Snapshots
(ServerName SYSNAME NOT NULL,
DatabaseID INT NOT NULL,
SnapshotName SYSNAME NOT NULL,
SourceDBName SYSNAME NOT NULL,
CreateDate DATETIME NOT NULL,
FirstRecorded DATETIME NOT NULL,
LastRecorded DATETIME NOT NULL,
Notes VARCHAR(255)
CONSTRAINT PK_Snapshots PRIMARY KEY (ServerName, SnapshotName))

--insert module config

INSERT INTO Catalogue.ConfigModules ([ModuleName]
									  ,[GetProcName]
									  ,[UpdateProcName]
									  ,[StageTableName]
									  ,[MainTableName]
									  ,[Active])
VALUES ('Snapshots','GetSnapshots','UpdateSnapshots','Snapshots_Stage','Snapshots',1)


--insert module definition

SELECT @ModuleID = ID 
FROM Catalogue.ConfigModules
WHERE ModuleName = 'Snapshots'

INSERT INTO Catalogue.ConfigModulesDefinitions (ModuleID,Online,GetDefinition,UpdateDefinition,GetURL,UpdateURL)
VALUES(@ModuleID,
1,
'--Undercover Catalogue
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
WHERE source_database_id IS NOT NULL',
'--Undercover Catalogue
--David Fowler
--Version 0.4.4 - 15 April 2024
--Module: Snapshots
--Script: Update

BEGIN
--Update snapshots where they are known to the catalogue
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
END',
'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetSnapshots.sql',
'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateSnapshots.sql')





--update versions tables

UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '0.4.4'
WHERE ParameterName = 'CatalogueVersion'

--update history

INSERT INTO Catalogue.UpgradeHistory (UpgradeVersion, UpgradeDate)
VALUES ('0.4.4', GETDATE())