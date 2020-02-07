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
                                                                                                                            
Sequential Upgrade - 0.4.2
David Fowler
06/02/2020

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

--new modules - Trace Flags

CREATE TABLE Catalogue.TraceFlags
(ServerName SYSNAME NOT NULL,
TraceFlag INT NOT NULL,
Notes VARCHAR(MAX) NULL,
FirstRecorded DATETIME NOT NULL,
LastRecorded DATETIME NOT NULL
CONSTRAINT PK_TraceFlags PRIMARY KEY (ServerName, TraceFlag)
)
GO

CREATE TABLE Catalogue.TraceFlags_Stage
(ServerName SYSNAME NOT NULL,
TraceFlag INT NOT NULL)
GO

CREATE TABLE Catalogue.TraceFlags_Audit
(ServerName SYSNAME NOT NULL,
TraceFlag INT NOT NULL,
Notes VARCHAR(MAX) NULL,
AuditDate DATETIME NOT NULL)
GO

INSERT INTO Catalogue.ConfigModules (ModuleName,GetProcName,UpdateProcName,StageTableName,MainTableName,Active)
VALUES ('TraceFlags','DEPRECATED','DEPRECATED','TraceFlags_Stage','TraceFlags',1)
GO

DECLARE @ModuleID INT

SELECT @ModuleID = ID
FROM Catalogue.ConfigModules
WHERE ModuleName = 'TraceFlags'

INSERT INTO Catalogue.ConfigModulesDefinitions (ModuleID,Online,GetDefinition,UpdateDefinition,GetURL,UpdateURL)
VALUES (@ModuleID,
1,
'--Undercover Catalogue
--David Fowler
--Version 0.4.2 - 06 February 2020
--Module: TraceFlags
--Script: Get

CREATE TABLE #TraceFlags
(
TraceFlag INT,
Status BIT,
Global BIT,
Session BIT
)

INSERT INTO #TraceFlags
EXEC sp_executesql N''DBCC tracestatus''

SELECT @@SERVERNAME AS ServerName, TraceFlag
FROM #TraceFlags',
'--Undercover Catalogue
--David Fowler
--Version 0.4.2 - 6 February 2020
--Module: Databases
--Script: Update


BEGIN

--update trace flags where they are known to the catalogue
UPDATE	Catalogue.TraceFlags
SET		ServerName = TraceFlags_Stage.ServerName,
		TraceFlag = TraceFlags_Stage.TraceFlag,
		LastRecorded = GETDATE()
FROM	Catalogue.TraceFlags_Stage
WHERE	TraceFlags_Stage.ServerName = TraceFlags.ServerName
		AND TraceFlags_Stage.TraceFlag = TraceFlags.TraceFlag

--insert trace flags that are unknown to the catlogue
INSERT INTO Catalogue.TraceFlags (ServerName, TraceFlag, FirstRecorded, LastRecorded)
SELECT	ServerName,
		TraceFlag,
		GETDATE(),
		GETDATE()
FROM	Catalogue.TraceFlags_Stage
WHERE NOT EXISTS
(SELECT 1 FROM Catalogue.TraceFlags
		WHERE	TraceFlags_Stage.ServerName = TraceFlags.ServerName
		AND TraceFlags_Stage.TraceFlag = TraceFlags.TraceFlag)
END',
'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetTraceFlags.sql',
'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateTraceFlags.sql')
GO



--cluster module

CREATE TABLE Catalogue.Cluster
(ClusterName NVARCHAR(128), 
QuorumType VARCHAR(50),  
QuorumState VARCHAR(50),
MemberName NVARCHAR(128), 
MemberType NVARCHAR(50), 
QuorumVotes TINYINT,
Notes VARCHAR(MAX),
FirstRecorded DATETIME,
LastRecorded DATETIME,
CONSTRAINT PK_Cluster PRIMARY KEY (ClusterName, MemberName))
GO

CREATE TABLE Catalogue.Cluster_Stage
(ClusterName NVARCHAR(128), 
QuorumType VARCHAR(50),  
QuorumState VARCHAR(50),
MemberName NVARCHAR(128), 
MemberType NVARCHAR(50), 
QuorumVotes TINYINT)
GO

CREATE TABLE Catalogue.Cluster_Audit
(ClusterName NVARCHAR(128), 
QuorumType VARCHAR(50),  
QuorumState VARCHAR(50),
MemberName NVARCHAR(128), 
MemberType NVARCHAR(50), 
QuorumVotes TINYINT,
AuditDate DATETIME)
GO

CREATE TRIGGER [Catalogue].[AuditCluster]
ON [Catalogue].[Cluster]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[Cluster_Audit]
		([ClusterName], [QuorumType], [QuorumState], [MemberName], [MemberType], [QuorumVotes], [AuditDate])
		SELECT	[ClusterName], 
				[QuorumType], 
				[QuorumState], 
				[MemberName], 
				[MemberType], 
				[QuorumVotes],
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[ClusterName], 
											inserted.[QuorumType], 
											inserted.[QuorumState], 
											inserted.[MemberName], 
											inserted.[MemberType], 
											inserted.[QuorumVotes])
																	!= 
								CHECKSUM(	deleted.[ClusterName], 
											deleted.[QuorumType], 
											deleted.[QuorumState], 
											deleted.[MemberName], 
											deleted.[MemberType], 
											deleted.[QuorumVotes])
							AND deleted.[ClusterName] = inserted.[ClusterName]
							AND deleted.[MemberName] = inserted.[MemberName])
END
GO

ALTER TABLE [Catalogue].[Cluster] ENABLE TRIGGER [AuditCluster]
GO




INSERT INTO Catalogue.ConfigModules (ModuleName,GetProcName,UpdateProcName,StageTableName,MainTableName,Active)
VALUES ('Cluster','DEPRECATED','DEPRECATED','Cluster_Stage','Cluster',1)
GO

DECLARE @ModuleID INT

SELECT @ModuleID = ID
FROM Catalogue.ConfigModules
WHERE ModuleName = 'Cluster'

INSERT INTO Catalogue.ConfigModulesDefinitions (ModuleID,Online,GetDefinition,UpdateDefinition,GetURL,UpdateURL)
VALUES (@ModuleID,
1,
'--Undercover Catalogue
--David Fowler
--Version 0.4.2 - 07 February 2020
--Module: Cluster
--Script: Get

SELECT	cluster_name AS ClusterName, 
		quorum_type_desc AS QuorumType,  
		quorum_state_desc AS QuorumState,
		member_name AS MemberName, 
		member_type_desc AS MemberType, 
		number_of_quorum_votes AS QuorumVotes
FROM	sys.dm_hadr_cluster
		,sys.dm_hadr_cluster_members',
'--Undercover Catalogue
--David Fowler
--Version 0.4.2 - 7 February 2020
--Module: Cluster
--Script: Update


BEGIN

--update cluster flags where they are known to the catalogue
UPDATE	Catalogue.Cluster
SET		ClusterName = Cluster_Stage.ClusterName,
		QuorumType = Cluster_Stage.QuorumType,
		QuorumState = Cluster_Stage.QuorumState,
		MemberName = Cluster_Stage.MemberName,
		MemberType = Cluster_Stage.MemberType,
		QuorumVotes = Cluster_Stage.QuorumVotes,
		LastRecorded = GETDATE()
FROM	Catalogue.Cluster_Stage
WHERE	Cluster_Stage.ClusterName = Cluster.ClusterName
		AND Cluster_Stage.MemberName = Cluster.MemberName


--insert cluster flags that are unknown to the catlogue
INSERT INTO Catalogue.Cluster (ClusterName,QuorumType,QuorumState,MemberName,MemberType,QuorumVotes,FirstRecorded,LastRecorded)
SELECT	ClusterName,
		QuorumType,
		QuorumState,
		MemberName,
		MemberType,
		QuorumVotes,
		GETDATE(),
		GETDATE()
FROM	Catalogue.Cluster_Stage
WHERE NOT EXISTS
(SELECT 1 FROM Catalogue.Cluster
		WHERE	Cluster_Stage.ClusterName = Cluster.ClusterName
		AND Cluster_Stage.MemberName = Cluster.MemberName)

END',
'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetCluster.sql',
'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateCluster.sql')
GO




--update versions tables

UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '0.4.2'
WHERE ParameterName = 'CatalogueVersion'

--update history

INSERT INTO Catalogue.UpgradeHistory (UpgradeVersion, UpgradeDate)
VALUES ('0.4.2', GETDATE())