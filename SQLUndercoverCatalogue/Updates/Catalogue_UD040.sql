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

--schema changes

ALTER TABLE Catalogue.Logins_Stage
DROP CONSTRAINT PK_Logins_Stage

ALTER TABLE Catalogue.Logins_Stage
DROP COLUMN ID

ALTER TABLE Catalogue.Databases_Stage
ADD StateDesc NVARCHAR(60)

ALTER TABLE Catalogue.Databases
ADD StateDesc NVARCHAR(60)

ALTER TABLE Catalogue.Databases_Audit
ADD StateDesc NVARCHAR(60)
GO

--BCP Import\Export proc


CREATE PROC Catalogue.BCPCopy
@ExportFileLocation VARCHAR(MAX),  --BCP file location
@Direction VARCHAR(3) = 'out',	--out = export, in = import
@TruncateDestination BIT = 0, --truncate tables at destination, ignored if exporting
@ImportConfig BIT = 1, --import config tables, ignored if importing
@IncludeExecutionLog BIT = 1 --exclude the execution log table from the import\export

AS

BEGIN

DECLARE @Module VARCHAR(50)
DECLARE @BCP VARCHAR(4000)

IF @ImportConfig = 1
BEGIN
	--truncate config tables if import
	IF @Direction = 'IN' AND @TruncateDestination = 1 
	BEGIN
		TRUNCATE TABLE Catalogue.ConfigInstances
		TRUNCATE TABLE Catalogue.ConfigModules
		TRUNCATE TABLE Catalogue.ConfigPoSH
	END

	--import\export config tables
	SET @BCP = 'bcp ' + QUOTENAME(DB_NAME()) + '.Catalogue.ConfigInstances ' + @Direction + ' ' + @ExportFileLocation + 'ConfigInstances.bcp -c -T'
	EXEC xp_cmdshell @BCP

	SET @BCP = 'bcp ' + QUOTENAME(DB_NAME()) + '.Catalogue.ConfigModules ' + @Direction + ' ' + @ExportFileLocation + 'ConfigModules.bcp -c -T'
	EXEC xp_cmdshell @BCP

	SET @BCP = 'bcp ' + QUOTENAME(DB_NAME()) + '.Catalogue.ConfigPoSH ' + @Direction + ' ' + @ExportFileLocation + 'ConfigPoSH.bcp -c -T'
	EXEC xp_cmdshell @BCP
END

IF @IncludeExecutionLog = 1
BEGIN
		IF @Direction = 'IN' AND @TruncateDestination = 1 
	BEGIN
		TRUNCATE TABLE Catalogue.ExecutionLog
	END

	SET @BCP = 'bcp ' + QUOTENAME(DB_NAME()) + '.Catalogue.ExecutionLog ' + @Direction + ' ' + @ExportFileLocation + 'ExecutionLog.bcp -c -T'
	EXEC xp_cmdshell @BCP
END

--carry out import\export
DECLARE ModulesCur CURSOR STATIC FORWARD_ONLY
FOR
SELECT MainTableName 
FROM Catalogue.ConfigModules
WHERE ModuleName != 'LinkedServers'

OPEN ModulesCur

FETCH NEXT FROM ModulesCur INTO @Module

WHILE @@FETCH_STATUS = 0
BEGIN
	
	IF @Direction = 'IN' AND @TruncateDestination = 1
	BEGIN
		SET @BCP = 'TRUNCATE TABLE Catalogue.' + @Module
		EXEC (@BCP)
	END

	SET @BCP = 'bcp " ' + QUOTENAME(DB_NAME()) + '.Catalogue.' + @Module + '" ' + @Direction + ' "' + @ExportFileLocation + @Module + '.bcp" -c -T'
	EXEC xp_cmdshell @BCP

	SET @BCP = 'bcp " ' + QUOTENAME(DB_NAME()) + '.Catalogue.' + @Module + '_Audit" ' + @Direction + ' "' + @ExportFileLocation + @Module + '_Audit.bcp" -c -T'
	EXEC xp_cmdshell @BCP

	FETCH NEXT FROM ModulesCur INTO @Module

END

CLOSE ModulesCur
DEALLOCATE ModulesCur



END
GO

--local interrogation proc

CREATE PROC Catalogue.LocalInterrogation
AS


BEGIN

SET NOCOUNT ON

DECLARE @GetDefinition NVARCHAR(MAX)
DECLARE @UpdateDefinition NVARCHAR(MAX)
DECLARE @StageTableName NVARCHAR(128)
DECLARE @cmd NVARCHAR(MAX)

DECLARE Modules CURSOR STATIC FORWARD_ONLY
FOR
	SELECT GetDefinition, UpdateDefinition, StageTableName
	FROM Catalogue.ConfigModules
	JOIN Catalogue.ConfigModulesDefinitions ON ConfigModules.ID = ConfigModulesDefinitions.ModuleID
	WHERE Active = 1
	--AND ModuleName = 'Databases'

OPEN Modules

FETCH NEXT FROM Modules INTO @GetDefinition, @UpdateDefinition, @StageTableName

WHILE @@FETCH_STATUS = 0
BEGIN
	--truncate stage tables
	EXEC ('TRUNCATE TABLE Catalogue.' + @StageTableName )

	--insert into stage tables
	SET @cmd = N'INSERT INTO Catalogue.' + @StageTableName + '
				EXEC (@GetDefinition)'

	EXEC sp_executesql @cmd, N'@GetDefinition VARCHAR(MAX)', @GetDefinition = @GetDefinition
	
	--execute update code
	EXEC sp_executesql @UpdateDefinition

	FETCH NEXT FROM Modules INTO @GetDefinition, @UpdateDefinition, @StageTableName

END

CLOSE Modules
DEALLOCATE Modules

END
GO


-- Databases audit trigger changes


ALTER TRIGGER [Catalogue].[AuditDatabases]
ON [Catalogue].[Databases]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[Databases_Audit]
		([ServerName], [DBName], [DatabaseID], [OwnerName], [CompatibilityLevel], [CollationName], [RecoveryModelDesc], [AGName], [FilePaths], [DatabaseSizeMB], [CustomerName], [ApplicationName], [Notes], [AuditDate], [StateDesc])
		SELECT	[ServerName], 
				[DBName], 
				[DatabaseID], 
				[OwnerName], 
				[CompatibilityLevel], 
				[CollationName], 
				[RecoveryModelDesc], 
				[AGName], 
				[FilePaths], 
				[DatabaseSizeMB], 
				[CustomerName], 
				[ApplicationName], 
				[Notes], 
				GETDATE(),
				[StateDesc]
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[ServerName], 
											inserted.[DBName], 
											inserted.[DatabaseID], 
											inserted.[OwnerName], 
											inserted.[CompatibilityLevel], 
											inserted.[CollationName], 
											inserted.[RecoveryModelDesc], 
											inserted.[AGName], 
											inserted.[FilePaths], 
											inserted.[DatabaseSizeMB], 
											inserted.[CustomerName], 
											inserted.[ApplicationName], 
											inserted.[Notes],
											inserted.[StateDesc])
																	!= 
								CHECKSUM(	deleted.[ServerName], 
											deleted.[DBName], 
											deleted.[DatabaseID], 
											deleted.[OwnerName], 
											deleted.[CompatibilityLevel], 
											deleted.[CollationName], 
											deleted.[RecoveryModelDesc], 
											deleted.[AGName], 
											deleted.[FilePaths], 
											deleted.[DatabaseSizeMB], 
											deleted.[CustomerName], 
											deleted.[ApplicationName], 
											deleted.[Notes],
											deleted.[StateDesc])
							AND deleted.[DBName] = inserted.[DBName]
							AND deleted.[ServerName] = inserted.[ServerName])
END
