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
          .@@`        `@@@@                                          ? www.sqlundercover.com                                                             
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
                                                                                                                            
Sequential Upgrade - 0.4.0
David Fowler

MIT License
------------

Copyright 2019 Sql Undercover

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

*/



--setup and populate ConfigModulesDefinitions table

CREATE TABLE Catalogue.ConfigModulesDefinitions
(ModuleID INT NOT NULL PRIMARY KEY,
Online BIT NOT NULL,
GetDefinition VARCHAR(MAX),
UpdateDefinition VARCHAR(MAX),
GetURL VARCHAR(2048) NULL,
UpdateURL VARCHAR(2048) NULL)
GO

--get module proc definitions and insert them into ConfigModuleDefinitions

INSERT INTO Catalogue.ConfigModulesDefinitions
SELECT ConfigModules.ID, 
		1, 
		SUBSTRING(OBJECT_DEFINITION(GetProcs.object_id), PATINDEX('%BEGIN%', OBJECT_DEFINITION(GetProcs.object_id)), LEN(OBJECT_DEFINITION(GetProcs.object_id))),
		SUBSTRING(OBJECT_DEFINITION(UpdateProcs.object_id), PATINDEX('%BEGIN%', OBJECT_DEFINITION(UpdateProcs.object_id)), LEN(OBJECT_DEFINITION(UpdateProcs.object_id)))
FROM Catalogue.ConfigModules
JOIN sys.procedures GetProcs ON GetProcs.name = ConfigModules.GetProcName
JOIN sys.procedures UpdateProcs ON UpdateProcs.name = ConfigModules.UpdateProcName
GO


--drop redundant module procs

DECLARE @DropGetProc NVARCHAR(1000)
DECLARE @DropUpdateProc NVARCHAR(1000)

DECLARE DropCur CURSOR LOCAL FAST_FORWARD
FOR
SELECT	N'DROP PROC ' + QUOTENAME(SCHEMA_NAME(GetProcs.schema_id)) + N'.' + QUOTENAME(GetProcs.name),
		N'DROP PROC ' + QUOTENAME(SCHEMA_NAME(UpdateProcs.schema_id)) + N'.' + QUOTENAME(UpdateProcs.name)
FROM Catalogue.ConfigModules
JOIN sys.procedures GetProcs ON GetProcs.name = ConfigModules.GetProcName
JOIN sys.procedures UpdateProcs ON UpdateProcs.name = ConfigModules.UpdateProcName

OPEN DropCur

FETCH NEXT FROM DropCur INTO @DropGetProc, @DropUpdateProc

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sp_executesql @DropGetProc
	EXEC sp_executesql @DropUpdateProc

	FETCH NEXT FROM DropCur INTO @DropGetProc, @DropUpdateProc
END

CLOSE DropCur
DEALLOCATE DropCur


--Fix issue for ADGroups module



update Catalogue.ConfigModulesDefinitions
set GetDefinition =

'BEGIN

DECLARE @GroupName SYSNAME

--create temp table to hold results from xp_logininfo
IF OBJECT_ID(''tempdb.dbo.#LoginInfo'') IS NOT NULL
DROP TABLE #LoginInfo

CREATE TABLE #LoginInfo
(accountname SYSNAME NULL,
 type CHAR(8) NULL,
 privilege CHAR(9) NULL,
 mappedloginname SYSNAME NULL,
 permissionpath SYSNAME NULL)

--create temp table to hold final results
IF OBJECT_ID(''tempdb.dbo.#FinalResults'') IS NOT NULL
DROP TABLE #FinalResults

CREATE TABLE #FinalResults(
	GroupName SYSNAME NOT NULL,
	AccountName SYSNAME NOT NULL,
	AccountType CHAR(8) NOT NULL)
 

--cursor to hold all windows groups

DECLARE GroupsCur CURSOR FAST_FORWARD LOCAL FOR
	SELECT name
	FROM sys.server_principals
	WHERE type_desc = ''WINDOWS_GROUP''

OPEN GroupsCur

FETCH NEXT FROM GroupsCur INTO @GroupName

WHILE @@FETCH_STATUS = 0
BEGIN
	TRUNCATE TABLE #LoginInfo  --truncate work table to prevent data from previous loop being carried through

	DECLARE @SQL VARCHAR(100)
	SET @SQL = ''EXEC xp_logininfo '''''' + @GroupName + '''''', ''''members''''''
	
	--populate #LoginInfo
	BEGIN TRY
		INSERT INTO #LoginInfo
		EXEC (@SQL)
	END TRY
	BEGIN CATCH --catch if there''s an issue evaluating the group for some reason
		INSERT INTO #LoginInfo (accountname, type)
		VALUES (@GroupName, ''*ERROR*'')
	END CATCH

	--append to final results temp table
	INSERT INTO #FinalResults (GroupName,AccountName,AccountType)
	SELECT @GroupName, accountname, type
	FROM #LoginInfo

	FETCH NEXT FROM GroupsCur INTO @GroupName
END

SELECT GroupName,AccountName,AccountType
FROM #FinalResults

END'

where ModuleID = 8


--fix issue with Tables module


UPDATE Catalogue.ConfigModulesDefinitions
SET UpdateDefinition = 
'BEGIN

--update tables where they are known to the catalogue
UPDATE Catalogue.Tables 
SET		ServerName = Tables_Stage.ServerName
		,DatabaseName = Tables_Stage.DatabaseName
		,SchemaName = Tables_Stage.SchemaName
		,TableName = Tables_Stage.TableName
		,Columns = Tables_Stage.Columns
		,LastRecorded = GETDATE()
FROM	Catalogue.Tables_Stage
WHERE	Tables.ServerName = Tables_Stage.ServerName
		AND Tables.SchemaName = Tables_Stage.SchemaName
		AND Tables.TableName = Tables_Stage.TableName
		AND Tables.DatabaseName = Tables_Stage.DatabaseName



--insert tables that are unknown to the catlogue
INSERT INTO Catalogue.Tables
(ServerName,DatabaseName,SchemaName,TableName,Columns,FirstRecorded,LastRecorded)
SELECT ServerName,
		DatabaseName,
		SchemaName,
		TableName,
		Columns,
		GETDATE(),
		GETDATE()
FROM Catalogue.Tables_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Tables
WHERE	Tables.ServerName = Tables_Stage.ServerName
		AND Tables.SchemaName = Tables_Stage.SchemaName
		AND Tables.TableName = Tables_Stage.TableName
		AND Tables.DatabaseName = Tables_Stage.DatabaseName)

END'

WHERE ModuleID = 10

