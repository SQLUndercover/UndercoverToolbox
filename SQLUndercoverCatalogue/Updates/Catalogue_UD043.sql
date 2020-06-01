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
                                                                                                                            
Sequential Upgrade - 0.4.3
David Fowler
01/06/2020

MIT License
------------

Copyright 2020 Sql Undercover

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

BUG FIX - Local interrogation proc now updates the execution logs
MODULE ENHANCEMENT - Add row counts and sizes to tables module

*/

--Change Log
--local interrogation proc
--add update to execution logs

ALTER PROC [Catalogue].[LocalInterrogation]
AS

BEGIN

SET NOCOUNT ON

DECLARE @GetDefinition NVARCHAR(MAX)
DECLARE @UpdateDefinition NVARCHAR(MAX)
DECLARE @StageTableName NVARCHAR(128)
DECLARE @cmd NVARCHAR(MAX)

--Update execution audit
INSERT INTO Catalogue.ExecutionLog(ExecutionDate) VALUES(GETDATE())

DECLARE Modules CURSOR STATIC FORWARD_ONLY
FOR
	SELECT GetDefinition, UpdateDefinition, StageTableName
	FROM Catalogue.ConfigModules
	JOIN Catalogue.ConfigModulesDefinitions 
		ON ConfigModules.ID = ConfigModulesDefinitions.ModuleID
	LEFT OUTER JOIN Catalogue.ConfigModulesInstances
		ON Catalogue.ConfigModules.ModuleName = ConfigModulesInstances.ModuleName 
		AND ConfigModulesInstances.ServerName = @@SERVERNAME
	WHERE ISNULL(ConfigModulesInstances.Active, ConfigModules.Active) = 1
	--AND ModuleName = 'Databases'

OPEN Modules

FETCH NEXT FROM Modules INTO @GetDefinition, @UpdateDefinition, @StageTableName

WHILE @@FETCH_STATUS = 0
BEGIN
	--truncate stage tables
	EXEC ('TRUNCATE TABLE Catalogue.' + @StageTableName )

	--insert into stage tables
	SET @cmd = N'INSERT INTO Catalogue.' + @StageTableName + ' EXEC (@GetDefinition)'

	EXEC sp_executesql @cmd, N'@GetDefinition VARCHAR(MAX)', @GetDefinition = @GetDefinition
	
	--execute update code
	EXEC sp_executesql @UpdateDefinition

	FETCH NEXT FROM Modules INTO @GetDefinition, @UpdateDefinition, @StageTableName

END

CLOSE Modules
DEALLOCATE Modules

--Mark execution complete
UPDATE Catalogue.ExecutionLog SET CompletedSuccessfully = 1 FROM Catalogue.ExecutionLog WHERE ID = (SELECT MAX(ID) FROM Catalogue.ExecutionLog)

END
GO

----------------------------------------------------------------------------
--Schema Changes
----------------------------------------------------------------------------

ALTER TABLE Catalogue.Tables 
ADD Rows BIGINT NULL,
	TotalSizeMB BIGINT NULL,
	UsedSizeMB BIGINT NULL
GO

ALTER TABLE Catalogue.Tables_Stage
ADD Rows BIGINT NULL,
	TotalSizeMB BIGINT NULL,
	UsedSizeMB BIGINT NULL
GO

--------------------------------------------------------------------------------
--=Module definition changes
--------------------------------------------------------------------------------

DECLARE @ModuleID INT

SELECT @ModuleID = ID 
FROM Catalogue.ConfigModules
WHERE ModuleName = 'Tables'

UPDATE Catalogue.ConfigModulesDefinitions
SET GetDefinition = '--Undercover Catalogue
--David Fowler
--Version 0.4.3 - 01 June 2020
--Module: Tables
--Script: Get

BEGIN
	
	IF OBJECT_ID(''tempdb.dbo.#Tables'') IS NOT NULL
	DROP TABLE #Tables

	CREATE TABLE #Tables
		(ServerName NVARCHAR(128) NOT NULL,
		DatabaseName NVARCHAR(128) NOT NULL,
		SchemaName SYSNAME NOT NULL,
		TableName SYSNAME NOT NULL,
		Columns XML,
		Rows BIGINT,
		TotalSizeMB BIGINT,
		UsedSizeMB BIGINT
		)

	DECLARE @DBName SYSNAME

	--cursor to hold database
	DECLARE DBCur CURSOR FAST_FORWARD LOCAL FOR
	SELECT name 
	FROM sys.databases

	DECLARE @cmd NVARCHAR(2000)

	OPEN DBCur

	FETCH NEXT FROM DBCur INTO @DBName

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @cmd = N''USE '' + QUOTENAME(@DBName) + N'';
					SELECT NameServer, DatabaseName, SchemaName, TableName, Cols, SUM(rows) AS Rows, SUM(total_pages) * 8 / 1024  AS TotalSizeMB, SUM(used_pages) * 8 / 1024 AS UsedSizeMB
					FROM
					(SELECT	@@SERVERNAME AS NameServer,
								DB_NAME() AS DatabaseName, 
								schemas.name AS SchemaName, 
								tables.name AS TableName,
								--CAST((
								(
									SELECT columns.name AS ColName,
									types.name AS DataType, 
									CASE 
										WHEN columns.max_length = -1 THEN ''''MAX''''
										WHEN types.name IN (''''nchar'''',''''nvarchar'''') THEN CAST(columns.max_length/2 AS VARCHAR)
										ELSE CAST(columns.max_length AS VARCHAR)
									END AS Length, 
									columns.is_nullable AS IsNullable,
									columns.is_identity AS IsIdentity,
									columns.is_computed AS IsComputed
									FROM sys.columns
									JOIN sys.types ON columns.user_type_id = types.user_type_id
									WHERE columns.object_id = tables.object_id		
									FOR XML RAW
									) AS Cols,
								--) AS XML) Cols,
								CASE WHEN indexes.type IN (0,1) THEN partitions.rows
									ELSE 0
								END rows,
								allocUnits.total_pages,
								allocUnits.used_pages
								FROM sys.tables
								JOIN sys.schemas ON tables.schema_id = schemas.schema_id
								JOIN sys.indexes ON tables.object_id = indexes.object_id
								JOIN sys.partitions  ON indexes.object_id = partitions.object_id AND indexes.index_id = partitions.index_id
								CROSS APPLY (SELECT SUM(total_pages) AS total_pages, SUM(used_pages) AS used_pages FROM sys.allocation_units WHERE container_id = partitions.partition_id) AS allocUnits) a
					GROUP BY NameServer, DatabaseName, SchemaName, TableName, Cols

''
	
	BEGIN TRY
		INSERT INTO #Tables
		EXEC sp_executesql @cmd
	END TRY
	BEGIN CATCH
		--if database in in accessible do nothing and move on to next database
	END CATCH

	FETCH NEXT FROM DBCur INTO @DBName

	END

	SELECT	ServerName
			,DatabaseName
			,SchemaName
			,TableName
			,Columns
			,Rows
			,TotalSizeMB
			,UsedSizeMB
	FROM #Tables

END',
UpdateDefinition = 
'--Undercover Catalogue
--David Fowler
--Version 0.4.3 - 01 June 2020
--Module: Tables
--Script: Update



BEGIN

--update tables where they are known to the catalogue
UPDATE Catalogue.Tables 
SET		ServerName = Tables_Stage.ServerName
		,DatabaseName = Tables_Stage.DatabaseName
		,SchemaName = Tables_Stage.SchemaName
		,TableName = Tables_Stage.TableName
		,Columns = Tables_Stage.Columns
		,LastRecorded = GETDATE()
		,Rows = Tables_Stage.Rows
		,TotalSizeMB = Tables_Stage.TotalSizeMB
		,UsedSizeMB = Tables_Stage.UsedSizeMB
FROM	Catalogue.Tables_Stage
WHERE	Tables.ServerName = Tables_Stage.ServerName
		AND Tables.SchemaName = Tables_Stage.SchemaName
		AND Tables.TableName = Tables_Stage.TableName
		AND Tables.DatabaseName = Tables_Stage.DatabaseName



--insert tables that are unknown to the catlogue
INSERT INTO Catalogue.Tables
(ServerName,DatabaseName,SchemaName,TableName,Columns,FirstRecorded,LastRecorded, Rows, TotalSizeMB, UsedSizeMB)
SELECT ServerName,
		DatabaseName,
		SchemaName,
		TableName,
		Columns,
		GETDATE(),
		GETDATE()
		,Rows
		,TotalSizeMB
		,UsedSizeMB
FROM Catalogue.Tables_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Tables
WHERE	Tables.ServerName = Tables_Stage.ServerName
		AND Tables.SchemaName = Tables_Stage.SchemaName
		AND Tables.TableName = Tables_Stage.TableName
		AND Tables.DatabaseName = Tables_Stage.DatabaseName)

END'
WHERE ModuleID = @ModuleID


--update versions tables

UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '0.4.3'
WHERE ParameterName = 'CatalogueVersion'

--update history

INSERT INTO Catalogue.UpgradeHistory (UpgradeVersion, UpgradeDate)
VALUES ('0.4.3', GETDATE())