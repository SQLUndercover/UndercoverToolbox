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
                                                                                                                            
Sequential Upgrade - 0.4.1
David Fowler
14/01/2020

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

--create upgrade history table
CREATE TABLE Catalogue.UpgradeHistory
(ID INT IDENTITY(1,1),
UpgradeVersion VARCHAR(20),
UpgradeDate DATETIME,
CONSTRAINT PK_UpgradeHistory PRIMARY KEY(ID))
GO

--create ServerConfig module tables

CREATE TABLE Catalogue.ServerConfig_Stage
(
	ServerName SYSNAME,
	SettingName NVARCHAR(35),
	SettingValue INT,
	SettingValueInUse INT,
	CONSTRAINT PK_ServerConfig_Stage PRIMARY KEY(ServerName, SettingName)
)
GO

CREATE TABLE Catalogue.ServerConfig
(
	ServerName SYSNAME,
	SettingName NVARCHAR(35),
	SettingValue INT,
	SettingValueInUse INT,
	Notes VARCHAR(255),
	FirstRecorded DATETIME,
	LastRecorded DATETIME,
	CONSTRAINT PK_ServerConfig PRIMARY KEY(ServerName, SettingName)
)
GO

CREATE TABLE Catalogue.ServerConfig_Audit
(
	ServerName SYSNAME,
	SettingName NVARCHAR(35),
	SettingValue INT,
	SettingValueInUse INT,
	Notes VARCHAR(255),
	AuditDate DATETIME
)
GO

--new modules

--insert into module config tables

INSERT INTO Catalogue.ConfigModules (ModuleName, GetProcName, UpdateProcName, StageTableName, MainTableName, Active)
VALUES ('ServerConfig','DEPRECATED','DEPRECATED','ServerConfig_Stage','ServerConfig',1)
GO

DECLARE @ModuleID INT

SELECT @ModuleID = ID
FROM Catalogue.ConfigModules
WHERE ModuleName = 'ServerConfig'

INSERT INTO Catalogue.ConfigModulesDefinitions (ModuleID,Online,GetDefinition,UpdateDefinition,GetURL,UpdateURL)
VALUES (@ModuleID,
		1,
		'--Undercover Catalogue
--David Fowler
--Version 0.4.1 - 14 January 2020
--Module: ServerConfig
--Script: Get

BEGIN
--get server configuration settings

SELECT	@@SERVERNAME AS ServerName,
		[name] AS SettingName, 
		CAST([value] AS INT) AS SettingValue, 
		CAST(value_in_use AS int) AS SettingValueInUse
FROM sys.configurations

END',
'--Undercover Catalogue
--David Fowler
--Version 0.4.1 - 14 January 2020
--Module: ServerConfig
--Script: Update


BEGIN

--update settings where known to the catalogue
UPDATE Catalogue.ServerConfig
SET ServerName = ServerConfig_Stage.ServerName,
	SettingName = ServerConfig_Stage.SettingName,
	SettingValue = ServerConfig_Stage.SettingValue,
	SettingValueInUse = ServerConfig_Stage.SettingValueInUse,
	LastRecorded = GETDATE()
FROM Catalogue.ServerConfig_Stage
WHERE ServerConfig.ServerName = ServerConfig_Stage.ServerName
	AND ServerConfig.SettingName = ServerConfig_Stage.SettingName

--insert settings where unknown to the catalogue
INSERT INTO Catalogue.ServerConfig
(ServerName, SettingName, SettingValue, SettingValueInUse, FirstRecorded, LastRecorded)
SELECT	ServerName, 
		SettingName, 
		SettingValue, 
		SettingValueInUse,
		GETDATE(),
		GETDATE()
FROM	Catalogue.ServerConfig_Stage
WHERE NOT EXISTS (SELECT 1
					FROM Catalogue.ServerConfig
					WHERE ServerConfig.ServerName = ServerConfig_Stage.ServerName
					AND ServerConfig.SettingName = ServerConfig_Stage.SettingName)

END',
'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetServerConfig.sql',
'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateServerConfig.sql')

GO


--ServerConfig Audit Trigger
CREATE TRIGGER [Catalogue].[AuditServerConfig]
ON [Catalogue].[ServerConfig]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[ServerConfig_Audit]
		([ServerName], [SettingName], [SettingValue], [SettingValueInUse], [Notes], [AuditDate])
		SELECT	ServerName,
				[SettingName],
				[SettingValue],
				[SettingValueInUse],
				[Notes],
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(inserted.[SettingValue],
										inserted.[SettingValueInUse],
										inserted.[Notes])
										!= 
								CHECKSUM(deleted.[SettingValue],
										deleted.[SettingValueInUse],
										deleted.[Notes])
							AND deleted.ServerName = inserted.ServerName
							AND deleted.[SettingName] = inserted.[SettingName])
END
GO


--Update upgrade history
INSERT INTO Catalogue.UpgradeHistory (UpgradeVersion,UpgradeDate)
VALUES ('0.4.1',GETDATE())
GO

--Update ConfigPoSH
UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '0.4.1'
WHERE ParameterName = 'CatalogueVersion'
GO