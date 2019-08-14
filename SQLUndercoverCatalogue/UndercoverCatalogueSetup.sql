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
                                                                                                                            
Undercover Catalogue Installation 0.3.0                                                      
Written By David Fowler
14/08/2019

Fresh Installation and Upgrade
NOTE: We only support upgrades from version 0.2.0 and up

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

--Create Undercover Catalogue Objects

--If it doesn't already exist, create SQLUndercover database
--I'm not going to take responsibility for your default database settings so make sure that the SQLUndercover database is setup sensibly
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'SQLUndercover')
CREATE DATABASE SQLUndercover
GO

USE SQLUndercover
GO

--Create the catalogue schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Catalogue')
EXEC('CREATE SCHEMA Catalogue')
GO


--check for any currently installed versions
IF OBJECT_ID ('tempdb.dbo.#Version') IS NOT NULL
	DROP TABLE #Version

CREATE TABLE #Version (VersionNumber VARCHAR(100) NULL)

IF OBJECT_ID('SQLUndercover.Catalogue.ConfigPoSH') IS NOT NULL --get the currently installed version number, if there is one
BEGIN
	INSERT INTO #Version (VersionNumber)
	SELECT ParameterValue AS VersionNumber
	FROM Catalogue.ConfigPoSH
	WHERE ParameterName = 'CatalogueVersion'
END
ELSE
BEGIN
	INSERT INTO #Version
	VALUES ('0.0.0')
END


--goto appropriate section of the script, depending on the current version number

-----------------------------------------Catalogue Databases--------------------------------------------------------------
--create database table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Databases')
BEGIN
	CREATE TABLE [Catalogue].[Databases](
		[ServerName] [nvarchar](128) NOT NULL,
		[DBName] [sysname] NOT NULL,
		[DatabaseID] [int] NOT NULL,
		[OwnerName] [sysname] NULL,
		[CompatibilityLevel] [tinyint] NOT NULL,
		[CollationName] [sysname] NULL,
		[RecoveryModelDesc] [nvarchar](60) NULL,
		[AGName] [sysname] NULL,
		[FilePaths] [nvarchar](max) NULL,
		[DatabaseSizeMB] [bigint] NULL,
		[FirstRecorded] [datetime] NULL,
		[LastRecorded] [datetime] NULL,
		[CustomerName] [varchar](50) NULL,
		[ApplicationName] [varchar](50) NULL,
		[Notes] [varchar](255) NULL,
	 CONSTRAINT [PK_Databases] PRIMARY KEY CLUSTERED 
	(
		[ServerName] ASC,
		[DatabaseID] ASC
	))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.Databases.database_id', 'DatabaseID'
--	EXEC sp_rename 'Catalogue.Databases.compatibility_level', 'CompatibilityLevel'
--	EXEC sp_rename 'Catalogue.Databases.collation_name', 'CollationName'
--	EXEC sp_rename 'Catalogue.Databases.recovery_model_desc', 'RecoveryModelDesc'
--END
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Databases_Stage')
BEGIN
	CREATE TABLE [Catalogue].[Databases_Stage](
		[ServerName] [nvarchar](128) NOT NULL,
		[DBName] [sysname] NOT NULL,
		[DatabaseID] [int] NOT NULL,
		[OwnerName] [sysname] NULL,
		[CompatibilityLevel] [tinyint] NOT NULL,
		[CollationName] [sysname] NULL,
		[RecoveryModelDesc] [nvarchar](60) NULL,
		[AGName] [sysname] NULL,
		[FilePaths] [nvarchar](max) NULL,
		[DatabaseSizeMB] [bigint] NULL
	 CONSTRAINT [PK_Databases_Stage] PRIMARY KEY CLUSTERED 
	(
		[ServerName] ASC,
		[DatabaseID] ASC
	))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.Databases_Stage.database_id', 'DatabaseID'
--	EXEC sp_rename 'Catalogue.Databases_Stage.compatibility_level', 'CompatibilityLevel'
--	EXEC sp_rename 'Catalogue.Databases_Stage.collation_name', 'CollationName'
--	EXEC sp_rename 'Catalogue.Databases_Stage.recovery_model_desc', 'RecoveryModelDesc'
--END
GO

--create job to get database details

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetDatabases'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetDatabases
GO

CREATE PROC [Catalogue].[GetDatabases]
AS

BEGIN
--get all databases on server

SELECT	@@SERVERNAME AS ServerName,
		databases.name AS DBName,
		databases.database_id,
		server_principals.name AS OwnerName,
		databases.compatibility_level,
		databases.collation_name,
		databases.recovery_model_desc,
		availability_groups.name AS AGName,
		files.FilePaths,
		files.DatabaseSizeMB
FROM sys.databases
LEFT OUTER JOIN sys.server_principals ON server_principals.sid = databases.owner_sid
LEFT OUTER JOIN sys.availability_replicas ON availability_replicas.replica_id = databases.replica_id
LEFT OUTER JOIN sys.availability_groups ON availability_groups.group_id = availability_replicas.group_id
JOIN	(SELECT database_id, (SUM(CAST (size AS BIGINT)) * 8)/1024 AS DatabaseSizeMB,STUFF((SELECT ', ' + files2.physical_name
				FROM sys.master_files files2
				WHERE files2.database_id = files1.database_id
				FOR XML PATH('')
			), 1, 2, '') AS FilePaths
		FROM sys.master_files files1
		GROUP BY database_id) files ON files.database_id = databases.database_id
END


GO


--create catalogue database update procedure
IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateDatabases'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateDatabases
GO

CREATE PROC [Catalogue].[UpdateDatabases]
AS

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


GO

--------------------------------------Catalogue Servers----------------------------------------------------------------
--create servers staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Servers_Stage')
CREATE TABLE Catalogue.Servers_Stage
(ServerName nvarchar(128) NOT NULL,
Collation nvarchar(128) NOT NULL,
Edition nvarchar(128) NOT NULL,
VersionNo nvarchar(128) NOT NULL
 CONSTRAINT [PK_Servers_Stage] PRIMARY KEY CLUSTERED 
(
	[ServerName] ASC
))

--create servers table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Servers')
CREATE TABLE Catalogue.Servers
(ServerName nvarchar(128) NOT NULL,
Collation nvarchar(128) NOT NULL,
Edition nvarchar(128) NOT NULL,
VersionNo nvarchar(128) NOT NULL,
[FirstRecorded] datetime NULL,
[LastRecorded] datetime NULL,
[CustomerName] varchar(50) NULL,
[ApplicationName] varchar(50) NULL,
[Notes] varchar(255) NULL,
 CONSTRAINT [PK_Servers] PRIMARY KEY CLUSTERED 
(
	[ServerName] ASC
))
GO

--create proc to get server details

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetServers'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetServers
GO

CREATE PROC Catalogue.GetServers
AS
BEGIN

SELECT	@@SERVERNAME AS ServerName, 
		SERVERPROPERTY('collation') AS Collation,  --nvarchar(128)
		SERVERPROPERTY('Edition') AS Edition, --nvarchar(128)
		SERVERPROPERTY('ProductVersion') AS VersionNo
FROM sys.dm_os_sys_info
END
GO

--create proc to update server catalogue
IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateServers'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateServers
GO

CREATE PROC [Catalogue].[UpdateServers]
AS
BEGIN
--update servers where they are known to the catalogue
UPDATE Catalogue.Servers 
SET		ServerName = Servers_Stage.ServerName,
		Collation = Servers_Stage.Collation,
		Edition = Servers_Stage.Edition,
		VersionNo = Servers_Stage.VersionNo,
		LastRecorded = GETDATE()
FROM Catalogue.Servers_Stage
WHERE	Servers.ServerName = Servers_Stage.ServerName

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Servers
			([ServerName], 
			[Collation], 
			[Edition], 
			[VersionNo],
			FirstRecorded,
			LastRecorded)
SELECT	[ServerName], 
		[Collation], 
		[Edition], 
		[VersionNo],
		GETDATE(),
		GETDATE()
FROM Catalogue.Servers_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Servers
		WHERE Servers.ServerName = Servers_Stage.ServerName)
END
GO

------------------------------------------Catalogue Logins-----------------------------------------------------
--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Logins')
BEGIN
	CREATE TABLE [Catalogue].[Logins](
		[ServerName] [nvarchar](128) NULL,
		[LoginName] [sysname] NOT NULL,
		[SID] [varbinary](85) NULL,
		[RoleName] [sysname] NULL,
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[IsDisabled] [bit] NULL,
		[Notes] [varchar](255) NULL,
		[PasswordHash] [varbinary](256) NULL,
		[FirstRecorded] [datetime] NULL,
		[LastRecorded] [datetime] NULL,
	 CONSTRAINT [PK_Logins] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))
END
--ELSE
--BEGIN	
--	EXEC sp_rename 'Catalogue.Logins.sid', 'SID'
--END
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Logins_Stage')
BEGIN
	CREATE TABLE [Catalogue].[Logins_Stage](
		[ServerName] [nvarchar](128) NULL,
		[LoginName] [sysname] NOT NULL,
		[SID] [varbinary](85) NULL,
		[RoleName] [sysname] NULL,
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[IsDisabled] [bit] NULL,
		[PasswordHash] [varbinary](256) NULL
	 CONSTRAINT [PK_Logins_Stage] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.Logins_Stage.sid', 'SID'
--END
GO

--create proc to get logins

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetLogins'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetLogins
GO

CREATE PROC [Catalogue].GetLogins
AS
BEGIN

--get all logins on server
SELECT	@@SERVERNAME AS ServerName,
		principals_logins.name AS LoginName, 
		principals_logins.sid AS sid, 
		principals_roles.name AS RoleName,
		principals_logins.is_disabled AS IsDisabled, 
		NULL AS PasswordHash--LOGINPROPERTY(principals_logins.name, 'PasswordHash') AS PasswordHash   **the varbinary of password hash is erroring in powershell, something to be looked at
FROM sys.server_role_members
RIGHT OUTER JOIN sys.server_principals principals_roles 
	ON server_role_members.role_principal_id = principals_roles.principal_id
RIGHT OUTER JOIN sys.server_principals principals_logins 
	ON server_role_members.member_principal_id = principals_logins.principal_id
WHERE principals_logins.type IN ('G','S','U') --include only windows groups, windows logins and SQL logins
ORDER BY principals_logins.name

END
GO

--update logins

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateLogins'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateLogins
GO

CREATE PROC [Catalogue].UpdateLogins
AS
BEGIN

--update jobs where they are known
UPDATE	Catalogue.Logins 
SET		ServerName = [Logins_Stage].ServerName,
		LoginName = [Logins_Stage].LoginName,
		SID = [Logins_Stage].SID,
		RoleName = [Logins_Stage].RoleName,
		PasswordHash = [Logins_Stage].PasswordHash,
		LastRecorded = GETDATE(),
		IsDisabled = [Logins_Stage].IsDisabled
FROM	[Catalogue].[Logins_Stage]
WHERE	Logins.ServerName = [Logins_Stage].ServerName
		AND Logins.LoginName = [Logins_Stage].LoginName

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Logins
(ServerName,LoginName,SID,RoleName,FirstRecorded,LastRecorded, IsDisabled, PasswordHash)
SELECT ServerName,
		LoginName,
		SID,
		RoleName,
		GETDATE(),
		GETDATE(),
		IsDisabled,
		PasswordHash
FROM [Catalogue].[Logins_Stage]
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Logins
		WHERE SID = [Logins_Stage].SID
		AND Logins.ServerName = [Logins_Stage].ServerName)

END
GO

---------------------------------Catalogue Agent Jobs-----------------------------------------
--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'AgentJobs')
BEGIN
	CREATE TABLE [Catalogue].[AgentJobs](
		[ServerName] [nvarchar](128) NULL,
		[JobID] [uniqueidentifier] NOT NULL,
		[JobName] [sysname] NOT NULL,
		[Enabled] [tinyint] NOT NULL,
		[Description] [nvarchar](512) NULL,
		[Category] [sysname] NOT NULL,
		[DateCreated] [datetime] NOT NULL,
		[DateModified] [datetime] NOT NULL,
		[ScheduleEnabled] [int] NOT NULL,
		[ScheduleName] [sysname] NOT NULL,
		[ScheduleFrequency] [varchar](8000) NULL,
		[StepID] [int] NOT NULL,
		[StepName] [sysname] NOT NULL,
		[SubSystem] [nvarchar](40) NOT NULL,
		[Command] [nvarchar](max) NULL,
		[DatabaseName] [sysname] NULL,
		[FirstRecorded] [datetime] NULL,
		[LastRecorded] [datetime] NULL,
		[ID] [int] IDENTITY(1,1) NOT NULL,
	 CONSTRAINT [PK_AgentJobs] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.AgentJobs.job_id', 'JobID'
--	EXEC sp_rename 'Catalogue.AgentJobs.enabled', 'Enabled'
--	EXEC sp_rename 'Catalogue.AgentJobs.description', 'Description'
--	EXEC sp_rename 'Catalogue.AgentJobs.date_created', 'DateCreated'
--	EXEC sp_rename 'Catalogue.AgentJobs.date_modified', 'DateModified'
--	EXEC sp_rename 'Catalogue.AgentJobs.step_id', 'StepID'
--	EXEC sp_rename 'Catalogue.AgentJobs.step_name', 'StepName'
--	EXEC sp_rename 'Catalogue.AgentJobs.subsystem', 'SubSystem'
--	EXEC sp_rename 'Catalogue.AgentJobs.command', 'Command'
--END
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'AgentJobs_Stage')
BEGIN
	CREATE TABLE [Catalogue].[AgentJobs_Stage](
		[ServerName] [nvarchar](128) NOT NULL,
		[JobID] [uniqueidentifier] NOT NULL,
		[JobName] [sysname] NOT NULL,
		[Enabled] [tinyint] NOT NULL,
		[Description] [nvarchar](512) NULL,
		[Category] [sysname] NOT NULL,
		[DateCreated] [datetime] NOT NULL,
		[DateModified] [datetime] NOT NULL,
		[ScheduleEnabled] [int] NOT NULL,
		[ScheduleName] [sysname] NOT NULL,
		[ScheduleFrequency] [varchar](8000) NULL,
		[StepID] [int] NOT NULL,
		[StepName] [sysname] NOT NULL,
		[SubSystem] [nvarchar](40) NOT NULL,
		[Command] [nvarchar](max) NULL,
		[DatabaseName] [sysname] NULL
	 CONSTRAINT [PK_AgentJobs_Stage] PRIMARY KEY CLUSTERED 
	(
		[JobID],[ServerName],[StepID], [ScheduleName] ASC
	))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.job_id', 'JobID'
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.enabled', 'Enabled'
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.description', 'Description'
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.date_created', 'DateCreated'
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.date_modified', 'DateModified'
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.step_id', 'StepID'
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.step_name', 'StepName'
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.subsystem', 'SubSystem'
--	EXEC sp_rename 'Catalogue.AgentJobs_Stage.command', 'Command'
--END
GO

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetAgentJobs'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetAgentJobs
GO

CREATE PROC Catalogue.GetAgentJobs
AS
BEGIN
--get all agent jobs on server
SELECT	@@SERVERNAME AS ServerName,
		sysjobs.job_id, 
		sysjobs.name AS JobName,
		sysjobs.enabled, 
		sysjobs.description, 
		syscategories.name AS Category, 
		sysjobs.date_created, 
		sysjobs.date_modified, 
		sysschedules.enabled AS ScheduleEnabled,
		sysschedules.name AS ScheduleName,
		CASE freq_type
            WHEN 1 THEN 'Occurs on ' + STUFF(RIGHT(active_start_date, 4), 3,0, '/') + '/' + LEFT(active_start_date, 4) + ' at '
                + REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime) /* hh:mm:ss 24H */, 9), 14), ':000', ' ') /* HH:mm:ss:000AM/PM then replace the :000 with space.*/
            WHEN 4 THEN 'Occurs every ' + CAST(freq_interval as varchar(10)) + ' day(s) '
                + CASE freq_subday_type
                    WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
                    WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
                    WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
                    ELSE '' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                        + ' and '
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    ELSE ''
                    END
            WHEN 8 THEN 'Occurs every ' + CAST(freq_recurrence_factor as varchar(10))
                + ' week(s) on '
                +
                REPLACE( CASE WHEN freq_interval&1 = 1 THEN 'Sunday, ' ELSE '' END
                + CASE WHEN freq_interval&2 = 2 THEN 'Monday, ' ELSE '' END
                + CASE WHEN freq_interval&4 = 4 THEN 'Tuesday, ' ELSE '' END
                + CASE WHEN freq_interval&8 = 8 THEN 'Wednesday, ' ELSE '' END
                + CASE WHEN freq_interval&16 = 16 THEN 'Thursday, ' ELSE '' END
                + CASE WHEN freq_interval&32 = 32 THEN 'Friday, ' ELSE '' END
                + CASE WHEN freq_interval&64 = 64 THEN 'Saturday, ' ELSE '' END
                + '|', ', |', ' ') /* get rid of trailing comma */

                + CASE freq_subday_type
                    WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
                    WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
                    WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
                    ELSE '' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                        + ' and '
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    ELSE ''
                    END
            WHEN 16 THEN 'Occurs every ' + CAST(freq_recurrence_factor as varchar(10))
                + ' month(s) on '
                + 'day ' + CAST(freq_interval as varchar(10)) + ' of that month ' 
                + CASE freq_subday_type
                    WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
                    WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
                    WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
                    ELSE '' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                        + ' and '
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    ELSE ''
                    END
            WHEN 32 THEN 'Occurs ' 
                + CASE freq_relative_interval
                    WHEN 1 THEN 'every first '
                    WHEN 2 THEN 'every second '
                    WHEN 4 THEN 'every third '
                    WHEN 8 THEN 'every fourth '
                    WHEN 16 THEN 'on the last '
                    END
                + CASE freq_interval 
                    WHEN 1 THEN 'Sunday'
                    WHEN 2 THEN 'Monday'
                    WHEN 3 THEN 'Tuesday'
                    WHEN 4 THEN 'Wednesday'
                    WHEN 5 THEN 'Thursday'
                    WHEN 6 THEN 'Friday'
                    WHEN 7 THEN 'Saturday'
                    WHEN 8 THEN 'day'
                    WHEN 9 THEN 'weekday'
                    WHEN 10 THEN 'weekend'
                    END
                + ' of every ' + CAST(freq_recurrence_factor as varchar(10)) + ' month(s) '
                + CASE freq_subday_type
                    WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
                    WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
                    WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
                    ELSE '' 
                    END
                + CASE 
                    WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                        + ' and '
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    ELSE ''
                    END
            WHEN 64 THEN 'Runs when the SQL Server Agent service starts'
            WHEN 128 THEN 'Runs when the computer is idle'
            END 
		AS ScheduleFrequency,
		sysjobsteps.step_id,
		sysjobsteps.step_name,
		sysjobsteps.subsystem,
		sysjobsteps.command,
		sysjobsteps.database_name AS DatabaseName
FROM msdb.dbo.sysjobs
JOIN msdb.dbo.syscategories ON sysjobs.category_id = syscategories.category_id
JOIN msdb.dbo.sysjobschedules ON sysjobs.job_id = sysjobschedules.job_id
JOIN msdb.dbo.sysschedules ON sysjobschedules.schedule_id = sysschedules.schedule_id
JOIN msdb.dbo.sysjobsteps ON sysjobsteps.job_id = sysjobs.job_id
END
GO


IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateAgentJobs'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateAgentJobs
GO

CREATE PROC Catalogue.UpdateAgentJobs
AS
BEGIN

--update jobs where they are known
UPDATE Catalogue.AgentJobs 
SET JobName = AgentJobs_Stage.JobName,
	Enabled = AgentJobs_Stage.Enabled,
	Description = AgentJobs_Stage.Description,
	Category = AgentJobs_Stage.Category,
	DateCreated = AgentJobs_Stage.DateCreated,
	DateModified = AgentJobs_Stage.DateModified,
	ScheduleEnabled = AgentJobs_Stage.ScheduleEnabled,
	ScheduleName = AgentJobs_Stage.ScheduleName,
	ScheduleFrequency = AgentJobs_Stage.ScheduleFrequency,
	StepID = AgentJobs_Stage.StepID,
	StepName = AgentJobs_Stage.StepName,
	SubSystem = AgentJobs_Stage.SubSystem,
	Command = AgentJobs_Stage.Command,
	DatabaseName = AgentJobs_Stage.DatabaseName,
	LastRecorded = GETDATE()
FROM Catalogue.AgentJobs_Stage
WHERE	AgentJobs.ServerName = AgentJobs_Stage.ServerName
		AND AgentJobs.JobID = AgentJobs_Stage.JobID
		AND AgentJobs.StepID = AgentJobs_Stage.StepID

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.AgentJobs 
(ServerName,JobID,JobName,Enabled,Description,Category,DateCreated,DateModified,
ScheduleEnabled,ScheduleName,ScheduleFrequency,StepID, StepName,SubSystem,Command,DatabaseName,
FirstRecorded, LastRecorded)
SELECT	ServerName,
		JobID,
		JobName,
		Enabled,
		Description,
		Category,
		DateCreated,
		DateModified,
		ScheduleEnabled,
		ScheduleName,
		ScheduleFrequency,
		StepID,
		StepName,
		SubSystem,
		Command,
		DatabaseName,
		GETDATE(),
		GETDATE()
FROM Catalogue.AgentJobs_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.AgentJobs 
		WHERE JobID = AgentJobs_Stage.JobID 
		AND StepID = AgentJobs_Stage.StepID
		AND ServerName = AgentJobs_Stage.ServerName)

END
GO

---------------------------------------Catalogue Availability Groups-----------------------------------------------------

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'AvailabilityGroups')
CREATE TABLE [Catalogue].[AvailabilityGroups](
	[AGName] [sysname] NOT NULL,
	[ServerName] [nvarchar](256) NOT NULL,
	[Role] [nvarchar](60) NULL,
	[BackupPreference] [nvarchar](60) NULL,
	[AvailabilityMode] [nvarchar](60) NULL,
	[FailoverMode] [nvarchar](60) NULL,
	[ConnectionsToSecondary] [nvarchar](60) NULL,
	[FirstRecorded] [datetime] NULL,
	[LastRecorded] [datetime] NULL,
	[Notes] [varchar](255) NULL,
 CONSTRAINT [PK_AvailabilityGroups] PRIMARY KEY CLUSTERED 
 (
	[AGName] ASC,
	[ServerName] ASC
))
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'AvailabilityGroups_Stage')
CREATE TABLE [Catalogue].[AvailabilityGroups_Stage](
	[AGName] [sysname] NOT NULL,
	[ServerName] [nvarchar](256) NOT NULL,
	[Role] [nvarchar](60) NULL,
	[BackupPreference] [nvarchar](60) NULL,
	[AvailabilityMode] [nvarchar](60) NULL,
	[FailoverMode] [nvarchar](60) NULL,
	[ConnectionsToSecondary] [nvarchar](60) NULL,
 CONSTRAINT [PK_AvailabilityGroups_Stage] PRIMARY KEY CLUSTERED 
 (
	[AGName] ASC,
	[ServerName] ASC
))
GO

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetAvailabilityGroups'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetAvailabilityGroups
GO
CREATE PROC Catalogue.GetAvailabilityGroups
AS
BEGIN

--Get availability group details
SELECT	AGs.name AS AGName,
		replicas.replica_server_name AS ServerName,
		replica_states.role_desc AS Role,
		AGs.automated_backup_preference_desc AS BackupPreference,
		replicas.availability_mode_desc AS AvailabilityMode,
		replicas.failover_mode_desc AS FailoverMode,
		replicas.secondary_role_allow_connections_desc AS ConnectionsToSecondary
FROM sys.availability_groups AGs
JOIN sys.availability_replicas replicas ON replicas.group_id = AGs.group_id
JOIN sys.dm_hadr_availability_replica_states replica_states ON replica_states.replica_id = replicas.replica_id

END

GO

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateAvailabilityGroups'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateAvailabilityGroups
GO

CREATE PROC Catalogue.UpdateAvailabilityGroups
AS
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
GO

-----------------------------------------Catalogue Users--------------------------------------------------------

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Users')
BEGIN
	CREATE TABLE [Catalogue].[Users](
		[ServerName] [nvarchar](128) NULL,
		[DBName] [nvarchar](128) NULL,
		[UserName] [sysname] NOT NULL,
		[SID] [varbinary](85) NULL,
		[RoleName] [sysname] NULL,
		[MappedLoginName] [sysname] NOT NULL,
		[FirstRecorded] [datetime] NULL,
		[LastRecorded] [datetime] NULL,
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[Notes] [varchar](255) NULL,
	 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.Users.sid', 'SID'
--END
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Users_Stage')
BEGIN
	CREATE TABLE [Catalogue].[Users_Stage](
		[ServerName] [nvarchar](128) NULL,
		[DBName] [nvarchar](128) NULL,
		[UserName] [sysname] NOT NULL,
		[SID] [varbinary](85) NULL,
		[RoleName] [sysname] NULL,
		[MappedLoginName] [sysname] NOT NULL,
		[ID] [int] IDENTITY(1,1) NOT NULL
	 CONSTRAINT [PK_Users_Stage] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.Users_Stage.sid', 'SID'
--END
GO


IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetUsers'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetUsers
GO

CREATE PROC Catalogue.GetUsers
AS

BEGIN

DECLARE @DBName SYSNAME
DECLARE @cmd NVARCHAR(4000)

IF OBJECT_ID('tempdb.dbo.#Users_Tmp') IS NOT NULL
DROP TABLE #Users_Tmp

--create temp table to bulid up result set
CREATE TABLE #Users_Tmp(
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[UserName] [sysname] NOT NULL,
	[sid] [varbinary](85) NULL,
	[RoleName] [sysname] NULL,
	[MappedLoginName] [sysname] NOT NULL)


--cursor to cycle through all databases on the server
DECLARE DBCur CURSOR FOR
SELECT [name]
FROM sys.databases

OPEN DBCur

FETCH NEXT FROM DBCur INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

--get all users for the selected database

BEGIN TRY
	SET @cmd = 
	'USE ' + QUOTENAME(@DBName) + '

	SELECT	@@SERVERNAME AS ServerName,
			DB_NAME() AS DBName,
			principals_logins.name AS UserName, 
			principals_logins.sid, 
			principals_roles.name AS RoleName,
			ISNULL(server_principals.name, ''***ORPHANED USER***'') AS MappedLoginName
	FROM sys.database_role_members
	RIGHT OUTER JOIN sys.database_principals principals_roles 
		ON database_role_members.role_principal_id = principals_roles.principal_id
	RIGHT OUTER JOIN sys.database_principals principals_logins 
		ON database_role_members.member_principal_id = principals_logins.principal_id
	LEFT OUTER JOIN sys.server_principals 
		ON server_principals.sid = principals_logins.sid
	WHERE principals_logins.type IN (''G'',''S'',''U'') --include only windows groups, windows logins and SQL logins
		AND principals_logins.sid IS NOT NULL 
	ORDER BY principals_logins.name'

	INSERT INTO #Users_Tmp(ServerName,DBName,UserName,sid,RoleName,MappedLoginName) 
	EXEC sp_executesql @stmt = @cmd
END TRY
BEGIN CATCH
--if the database is inaccessable, do nothing and move on to the next one
END CATCH
FETCH NEXT FROM DBCur INTO @DBName

END

CLOSE DBCur
DEALLOCATE DBCur

SELECT * FROM #Users_Tmp

END
GO


IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateUsers'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateUsers
GO

CREATE PROCEDURE Catalogue.UpdateUsers
AS
BEGIN

--update users where they are known
UPDATE	Catalogue.Users 
SET		ServerName = Users_Stage.ServerName,
		DBName = Users_Stage.DBName,
		UserName = Users_Stage.UserName,
		SID = Users_Stage.SID,
		LastRecorded = GETDATE(),
		MappedLoginName = Users_Stage.MappedLoginName
FROM Catalogue.Users_Stage
WHERE	Users.UserName = Users_Stage.UserName
		AND Users.ServerName = Users_Stage.ServerName
		AND Users.DBName = Users_Stage.DBName
		AND ISNULL(Users.RoleName ,'') = ISNULL(Users_Stage.RoleName,'')

--insert users that are unknown to the catlogue
INSERT INTO Catalogue.Users
(ServerName, DBName, UserName, SID, RoleName,MappedLoginName,FirstRecorded,LastRecorded)
SELECT ServerName,
		DBName,
		UserName,
		SID,
		RoleName,
		MappedLoginName,
		GETDATE(),
		GETDATE()
FROM Catalogue.Users_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Users
		WHERE UserName = Users_Stage.UserName
		AND ServerName= Users_Stage.ServerName
		AND DBName = Users_Stage.DBName
		AND ISNULL(RoleName,'') = ISNULL(RoleName,''))

END
GO
--------------------------------------Catalogue Explicit Permissions-----------------------------------------------

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ExplicitPermissions')
BEGIN
	CREATE TABLE [Catalogue].[ExplicitPermissions](
		[Name] [sysname] NOT NULL,
		[PermissionName] [nvarchar](128) NULL,
		[StateDesc] [nvarchar](60) NULL,
		[ServerName] [nvarchar](128) NULL,
		[DBName] [nvarchar](128) NULL,
		[MajorObject] [nvarchar](128) NULL,
		[MinorObject] [nvarchar](128) NULL,
		[FirstRecorded] [datetime] NULL,
		[LastRecorded] [datetime] NULL,
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[Notes] [varchar](255) NULL,
	 CONSTRAINT [PK_ExplicitPermissions] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.ExplicitPermissions.name', 'Name'
--	EXEC sp_rename 'Catalogue.ExplicitPermissions.permission_name', 'PermissionName'
--	EXEC sp_rename 'Catalogue.ExplicitPermissions.state_desc', 'StateDesc'
--END
GO

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ExplicitPermissions_Stage')
BEGIN
CREATE TABLE [Catalogue].[ExplicitPermissions_Stage](
	[Name] [sysname] NOT NULL,
	[PermissionName] [nvarchar](128) NULL,
	[StateDesc] [nvarchar](60) NULL,
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[MajorObject] [nvarchar](128) NULL,
	[MinorObject] [nvarchar](128) NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL
 CONSTRAINT [PK_ExplicitPermissions_Stage] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
))
END
--ELSE
--BEGIN
--	EXEC sp_rename 'Catalogue.ExplicitPermissions_Stage.name', 'Name'
--	EXEC sp_rename 'Catalogue.ExplicitPermissions_Stage.permission_name', 'PermissionName'
--	EXEC sp_rename 'Catalogue.ExplicitPermissions_Stage.state_desc', 'StateDesc'
--END
GO


IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetExplicitPermissions'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetExplicitPermissions
GO

CREATE PROC Catalogue.GetExplicitPermissions
AS

BEGIN

DECLARE @DBName SYSNAME
DECLARE @cmd NVARCHAR(4000)

IF OBJECT_ID('tempdb.dbo.#ExplicitPermissions_tmp') IS NOT NULL
DROP TABLE #ExplicitPermissions_tmp

--create temp table to bulid up result set
CREATE TABLE #ExplicitPermissions_tmp(
	[Name] [sysname] NOT NULL,
	[PermissionName] [nvarchar](128) NULL,
	[StateDesc] [nvarchar](60) NULL,
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[MajorObject] [nvarchar](128) NULL,
	[MinorObject] [nvarchar](128) NULL)


--cursor to cycle through all databases on the server
DECLARE DBCur CURSOR FOR
SELECT [name]
FROM sys.databases

OPEN DBCur

FETCH NEXT FROM DBCur INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

--get all permissions for the selected database
BEGIN TRY
SET @cmd = 
'USE ' + QUOTENAME(@DBName) + '

SELECT	database_principals.name,
		database_permissions.permission_name,
		database_permissions.state_desc,
		@@SERVERNAME AS ServerName,
		DB_Name() AS DBName,
		OBJECT_NAME(database_permissions.major_id) AS MajorObject,
		OBJECT_NAME(database_permissions.minor_id) AS MinorObject
FROM sys.database_principals
JOIN sys.database_permissions ON database_principals.principal_id = database_permissions.grantee_principal_id
WHERE database_principals.name != ''public'''

INSERT INTO #ExplicitPermissions_tmp(Name,PermissionName,StateDesc,ServerName,DBName,MajorObject,MinorObject) 
EXEC sp_executesql @stmt = @cmd
END TRY
BEGIN CATCH
--if database in in accessible do nothing and move on to next database
END CATCH

FETCH NEXT FROM DBCur INTO @DBName

END

CLOSE DBCur
DEALLOCATE DBCur

SELECT * FROM #ExplicitPermissions_tmp

END
GO

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateExplicitPermissions'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateExplicitPermissions
GO

CREATE PROC Catalogue.UpdateExplicitPermissions
AS
BEGIN

--update permissions where they are known
UPDATE	Catalogue.ExplicitPermissions 
SET		Name = ExplicitPermissions_Stage.Name,
		PermissionName = ExplicitPermissions_Stage.PermissionName,
		StateDesc = ExplicitPermissions_Stage.StateDesc,
		ServerName = ExplicitPermissions_Stage.ServerName,
		DBName = ExplicitPermissions_Stage.DBName,
		MajorObject = ExplicitPermissions_Stage.MajorObject,
		MinorObject = ExplicitPermissions_Stage.MinorObject,
		LastRecorded = GETDATE()
FROM Catalogue.ExplicitPermissions_Stage
WHERE ExplicitPermissions.Name  = ExplicitPermissions_Stage.Name
		AND ExplicitPermissions.PermissionName = ExplicitPermissions_Stage.PermissionName
		AND ExplicitPermissions.StateDesc = ExplicitPermissions_Stage.StateDesc
		AND ExplicitPermissions.ServerName = ExplicitPermissions_Stage.ServerName
		AND ExplicitPermissions.DBName  = ExplicitPermissions_Stage.DBName
		AND ISNULL(ExplicitPermissions.MajorObject,'') = ISNULL(ExplicitPermissions_Stage.MajorObject,'')
		AND ISNULL(ExplicitPermissions.MinorObject,'') = ISNULL(ExplicitPermissions_Stage.MinorObject,'')

--insert permissions that are unknown to the catlogue
INSERT INTO Catalogue.ExplicitPermissions
(Name, PermissionName,StateDesc,ServerName,DBName,MajorObject,MinorObject,FirstRecorded,LastRecorded)
SELECT	Name,
		PermissionName,
		StateDesc,
		ServerName,
		DBName,
		MajorObject,
		MinorObject,
		GETDATE(),
		GETDATE()
FROM Catalogue.ExplicitPermissions_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.ExplicitPermissions
		WHERE ExplicitPermissions.Name = ExplicitPermissions_Stage.Name
		AND ExplicitPermissions.PermissionName = ExplicitPermissions_Stage.PermissionName
		AND ExplicitPermissions.StateDesc = ExplicitPermissions_Stage.StateDesc
		AND ExplicitPermissions.ServerName = ExplicitPermissions_Stage.ServerName
		AND ExplicitPermissions.DBName = ExplicitPermissions_Stage.DBName
		AND ISNULL(ExplicitPermissions.MajorObject,'') = ISNULL(ExplicitPermissions_Stage.MajorObject,'')
		AND ISNULL(ExplicitPermissions.MinorObject, '') = ISNULL(ExplicitPermissions_Stage.MinorObject,''))


END
GO
-------------------------------------create config tables--------------------------------------------------------

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ConfigModules')
BEGIN
	CREATE TABLE Catalogue.ConfigModules
	(ID INT IDENTITY(1,1) NOT NULL,
	ModuleName VARCHAR(20) NOT NULL,
	GetProcName VARCHAR(128) NOT NULL,
	UpdateProcName VARCHAR(128) NOT NULL,
	StageTableName VARCHAR(128) NOT NULL,
	MainTableName VARCHAR(128) NOT NULL,
	Active BIT NOT NULL DEFAULT 1
	 CONSTRAINT [PK_ConfigModules] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))

	INSERT INTO Catalogue.ConfigModules ([ModuleName], [GetProcName], [UpdateProcName], [StageTableName], [MainTableName], [Active])
	VALUES	('Databases','GetDatabases','UpdateDatabases','Databases_Stage','Databases',1),
			('Servers','GetServers','UpdateServers','Servers_Stage','Servers',1),
			('Logins','GetLogins','UpdateLogins','Logins_Stage','Logins',1),
			('Agent Jobs','GetAgentJobs','UpdateAgentJobs','AgentJobs_Stage','AgentJobs',1),
			('Availability Groups','GetAvailabilityGroups','UpdateAvailabilityGroups','AvailabilityGroups_Stage','AvailabilityGroups',1),
			('Users','GetUsers','UpdateUsers','Users_Stage','Users',1),
			('ExplicitPermissions','GetExplicitPermissions','UpdateExplicitPermissions','ExplicitPermissions_Stage','ExplicitPermissions',1)
END
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ConfigInstances')
BEGIN
	CREATE TABLE Catalogue.ConfigInstances
	(ID INT IDENTITY(1,1) NOT NULL,
	ServerName VARCHAR(128) NOT NULL,
	Active BIT NOT NULL DEFAULT 1
	 CONSTRAINT [PK_ConfigTables] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))

	INSERT INTO Catalogue.ConfigInstances ([ServerName])
	VALUES (@@SERVERNAME)
END
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ConfigPoSH')
BEGIN
	CREATE TABLE Catalogue.ConfigPoSH
	(ID INT IDENTITY(1,1) NOT NULL,
	ParameterName VARCHAR(100) NOT NULL,
	ParameterValue VARCHAR(100) NOT NULL
	CONSTRAINT [PK_ConfigPoSH] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	))

	INSERT INTO Catalogue.ConfigPoSH (ParameterName,ParameterValue)
	VALUES	('CatalogueVersion', '0.2.0'),
			('AutoDiscoverInstances','0'),
			('DBAToolsRequirement', '1.0.0'),
			('AutoInstall', '0'),
			('AutoUpdate', '0'),
			('InstallationScriptPath', '{script path}')
END
ELSE
BEGIN
	--EXEC sp_rename 'Catalogue.configPoSH', 'ConfigPoSH'

	--update the required version of dbatools to 0.9.750
	UPDATE Catalogue.ConfigPoSH
	SET ParameterValue = '1.0.0'
	WHERE ParameterName = 'DBAToolsRequirement'
END
GO





Patch021:
--------------------------------------------------------------------------------------------------------------
------------------Version 0.2.1 Changes-------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

--Server Module Enhancements

--alter server table to include new fields

--------------------------------------Catalogue Servers----------------------------------------------------------------


--change version number in ConfigPoSH to 0.2.1

UPDATE Catalogue.ConfigPoSH 
SET ParameterValue = '0.2.1'
WHERE ParameterName = 'CatalogueVersion'
GO


--add 0.2 columns to Servers_Stage

IF (SELECT VersionNumber FROM #Version) IN ('0.0.0','0.2.0')
BEGIN
	ALTER TABLE Catalogue.Servers_Stage
	ADD ServerStartTime DATETIME,
		CostThreshold INT,
		MaxWorkerThreads INT,
		[MaxDOP] INT,
		CPUCount INT,
		NUMACount INT,
		PhysicalMemoryMB INT,
		MaxMemoryMB INT,
		MinMemoryMB INT,
		MemoryModel NVARCHAR(128),
		IsClustered BIT,
		VMType NVARCHAR(60)

	--add 0.2 columns to Servers

	ALTER TABLE Catalogue.[Servers]
	ADD ServerStartTime DATETIME,
		CostThreshold INT,
		MaxWorkerThreads INT,
		[MaxDOP] INT,
		CPUCount INT,
		NUMACount INT,
		PhysicalMemoryMB INT,
		MaxMemoryMB INT,
		MinMemoryMB INT,
		MemoryModel NVARCHAR(128),
		IsClustered BIT,
		VMType NVARCHAR(60)
END
GO



--create proc to get server details

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetServers'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetServers
GO

CREATE PROC Catalogue.GetServers
AS
BEGIN


SELECT 
@@SERVERNAME AS ServerName, 
SERVERPROPERTY('collation') AS Collation,
SERVERPROPERTY('Edition') AS Edition, 
SERVERPROPERTY('ProductVersion') AS VersionNo,
sqlserver_start_time AS ServerStartTime,
[cost threshold for parallelism] AS CostThreshold,
[max worker threads] AS MaxWorkerThreads,
[max degree of parallelism] AS [MaxDOP],
cpu_count AS CPUCount,
NULL AS NUMACount, --not implemented, needs a version check
physical_memory_kb / 1024 AS PhysicalMemoryMB,
[max server memory (MB)] AS MaxMemoryMB,
[min server memory (MB)] AS MinMemoryMB,
NULL AS MemoryModel,  --not implemented, needs a version check
SERVERPROPERTY('IsClustered') AS IsClustered,
virtual_machine_type_desc AS VMType
FROM sys.dm_os_sys_info,
(
	SELECT [max worker threads],[cost threshold for parallelism],[max degree of parallelism],[min server memory (MB)],[max server memory (MB)]
	FROM 
	(SELECT name, value_in_use
	FROM sys.configurations
	WHERE name in ('max worker threads','cost threshold for parallelism','max degree of parallelism','min server memory (MB)','max server memory (MB)')) AS Source
	PIVOT
	(
	MAX(value_in_use)
	FOR name IN ([max worker threads],[cost threshold for parallelism],[max degree of parallelism],[min server memory (MB)],[max server memory (MB)])
	)AS PivotTable
) AS config
END
GO

--create proc to update server catalogue
IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateServers'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateServers
GO

CREATE PROC [Catalogue].[UpdateServers]
AS
BEGIN
--update servers where they are known to the catalogue
UPDATE Catalogue.Servers 
SET		ServerName = Servers_Stage.ServerName,
		Collation = Servers_Stage.Collation,
		Edition = Servers_Stage.Edition,
		VersionNo = Servers_Stage.VersionNo,
		LastRecorded = GETDATE(),
		ServerStartTime = Servers_Stage.ServerStartTime,
		CostThreshold = Servers_Stage.CostThreshold,
		MaxWorkerThreads = Servers_Stage.MaxWorkerThreads,
		[MaxDOP] = Servers_Stage.[MaxDOP],
		CPUCount = Servers_Stage.CPUCount,
		NUMACount = Servers_Stage.NUMACount,
		PhysicalMemoryMB = Servers_Stage.PhysicalMemoryMB,
		MaxMemoryMB = Servers_Stage.MaxMemoryMB,
		MinMemoryMB = Servers_Stage.MinMemoryMB,
		MemoryModel = Servers_Stage.MemoryModel,
		IsClustered = Servers_Stage.IsClustered,
		VMType = Servers_Stage.VMType
FROM Catalogue.Servers_Stage
WHERE	Servers.ServerName = Servers_Stage.ServerName

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Servers
			([ServerName], 
			[Collation], 
			[Edition], 
			[VersionNo],
			FirstRecorded,
			LastRecorded,
			ServerStartTime,
			CostThreshold,
			MaxWorkerThreads,
			[MaxDOP],
			CPUCount,
			NUMACount,
			PhysicalMemoryMB,
			MaxMemoryMB,
			MinMemoryMB,
			MemoryModel,
			IsClustered,
			VMType)
SELECT	[ServerName], 
		[Collation], 
		[Edition], 
		[VersionNo],
		GETDATE(),
		GETDATE(),
		ServerStartTime,
		CostThreshold,
		MaxWorkerThreads,
		[MaxDOP],
		CPUCount,
		NUMACount,
		PhysicalMemoryMB,
		MaxMemoryMB,
		MinMemoryMB,
		MemoryModel,
		IsClustered,
		VMType
FROM Catalogue.Servers_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Servers
		WHERE Servers.ServerName = Servers_Stage.ServerName)
END
GO



------------------------------------------------Catalogue Login------------------------------------------------------------------------

--alter tables, include type column
IF (SELECT VersionNumber FROM #Version) IN ('0.0.0','0.2.0')
BEGIN
	ALTER TABLE Catalogue.Logins_Stage
	ADD LoginType NVARCHAR(60)

	ALTER TABLE Catalogue.Logins
	ADD LoginType NVARCHAR(60)
END

--updates login procedures

--create proc to get logins

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetLogins'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC [Catalogue].GetLogins
GO

CREATE PROC [Catalogue].GetLogins
AS
BEGIN

--get all logins on server
SELECT	@@SERVERNAME AS ServerName,
		principals_logins.name AS LoginName, 
		principals_logins.sid AS sid, 
		principals_roles.name AS RoleName,
		NULL,
		principals_logins.is_disabled AS IsDisabled,
		LOGINPROPERTY(principals_logins.name, 'PasswordHash') AS PasswordHash,  -- **the varbinary of password hash is erroring in powershell, something to be looked at
		principals_logins.type_desc AS LoginType
FROM sys.server_role_members
RIGHT OUTER JOIN sys.server_principals principals_roles 
	ON server_role_members.role_principal_id = principals_roles.principal_id
RIGHT OUTER JOIN sys.server_principals principals_logins 
	ON server_role_members.member_principal_id = principals_logins.principal_id
WHERE principals_logins.type IN ('G','S','U') --include only windows groups, windows logins and SQL logins
ORDER BY principals_logins.name

END
GO

--update logins

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateLogins'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateLogins
GO

CREATE PROC [Catalogue].UpdateLogins
AS
BEGIN

--update logins where they are known
UPDATE	Catalogue.Logins 
SET		ServerName = [Logins_Stage].ServerName,
		LoginName = [Logins_Stage].LoginName,
		SID = [Logins_Stage].SID,
		RoleName = [Logins_Stage].RoleName,
		PasswordHash = [Logins_Stage].PasswordHash,
		LastRecorded = GETDATE(),
		IsDisabled = [Logins_Stage].IsDisabled,
		LoginType = [Logins_Stage].LoginType
FROM	[Catalogue].[Logins_Stage]
WHERE	Logins.ServerName = [Logins_Stage].ServerName
		AND Logins.LoginName = [Logins_Stage].LoginName

--insert logins that are unknown to the catlogue
INSERT INTO Catalogue.Logins
(ServerName,LoginName,SID,RoleName,FirstRecorded,LastRecorded, IsDisabled, PasswordHash,LoginType)
SELECT ServerName,
		LoginName,
		SID,
		RoleName,
		GETDATE(),
		GETDATE(),
		IsDisabled,
		PasswordHash,
		LoginType
FROM [Catalogue].[Logins_Stage]
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Logins
		WHERE SID = [Logins_Stage].SID
		AND Logins.ServerName = [Logins_Stage].ServerName)

END
GO

------------------------------------------Catalogue AD Groups------------------------------------------------------------------------------

--Create ADGroups Table

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ADGroups_Stage')
BEGIN
	CREATE TABLE [Catalogue].ADGroups_Stage(
		GroupName SYSNAME NOT NULL,
		AccountName SYSNAME NOT NULL,
		AccountType CHAR(8) NOT NULL,
	 CONSTRAINT [PK_ADGroups_Stage] PRIMARY KEY CLUSTERED 
	(
		[GroupName] ASC,
		[AccountName] ASC
	))
END


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ADGroups')
BEGIN
	CREATE TABLE [Catalogue].ADGroups(
		GroupName SYSNAME NOT NULL,
		AccountName SYSNAME NOT NULL,
		AccountType SYSNAME NOT NULL,
		FirstRecorded DATETIME NULL,
		LastRecorded DATETIME NULL,
		Notes VARCHAR(255) NULL,
	 CONSTRAINT [PK_ADGroups] PRIMARY KEY CLUSTERED 
	(
		[GroupName] ASC,
		[AccountName] ASC
	))
END


--create job to get group details

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetADGroups'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetADGroups
GO

--Get Proc

CREATE PROC [Catalogue].GetADGroups
AS
BEGIN

DECLARE @GroupName SYSNAME

--create temp table to hold results from xp_logininfo
IF OBJECT_ID('tempdb.dbo.#LoginInfo') IS NOT NULL
DROP TABLE #LoginInfo

CREATE TABLE #LoginInfo
(accountname SYSNAME NULL,
 type CHAR(8) NULL,
 privilege CHAR(9) NULL,
 mappedloginname SYSNAME NULL,
 permissionpath SYSNAME NULL)

--create temp table to hold final results
IF OBJECT_ID('tempdb.dbo.#FinalResults') IS NOT NULL
DROP TABLE #FinalResults

CREATE TABLE #FinalResults(
	GroupName SYSNAME NOT NULL,
	AccountName SYSNAME NOT NULL,
	AccountType CHAR(8) NOT NULL)
 

--cursor to hold all windows groups

DECLARE GroupsCur CURSOR FAST_FORWARD LOCAL FOR
	SELECT DISTINCT LoginName
	FROM Catalogue.Logins
	WHERE LoginType = 'WINDOWS_GROUP'

OPEN GroupsCur

FETCH NEXT FROM GroupsCur INTO @GroupName

WHILE @@FETCH_STATUS = 0
BEGIN
	TRUNCATE TABLE #LoginInfo  --truncate work table to prevent data from previous loop being carried through

	DECLARE @SQL VARCHAR(100)
	SET @SQL = 'EXEC xp_logininfo ''' + @GroupName + ''', ''members'''
	
	--populate #LoginInfo
	BEGIN TRY
		INSERT INTO #LoginInfo
		EXEC (@SQL)
	END TRY
	BEGIN CATCH --catch if there's an issue evaluating the group for some reason
		INSERT INTO #LoginInfo (accountname, type)
		VALUES (@GroupName, '*ERROR*')
	END CATCH

	--append to final results temp table
	INSERT INTO #FinalResults (GroupName,AccountName,AccountType)
	SELECT @GroupName, accountname, type
	FROM #LoginInfo

	FETCH NEXT FROM GroupsCur INTO @GroupName
END

SELECT GroupName,AccountName,AccountType
FROM #FinalResults

END
GO


--update AD groups


IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateADGroups'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateADGroups
GO


CREATE PROC Catalogue.UpdateADGroups
AS
BEGIN

--update LastRecorded date where the account and group is known to the catalogue
UPDATE	Catalogue.ADGroups 
SET		LastRecorded = GETDATE()
WHERE EXISTS 
		(SELECT 1 
		FROM [Catalogue].[ADGroups_Stage]
		WHERE	ADGroups.GroupName = ADGroups_Stage.GroupName
				AND ADGroups.AccountName = ADGroups_Stage.AccountName)

--insert ADGroup details where not known to the Catalogue
INSERT INTO Catalogue.ADGroups(GroupName,AccountName,AccountType,FirstRecorded,LastRecorded,Notes)
SELECT GroupName,
		AccountName,
		AccountType,
		GETDATE(),
		GETDATE(),
		NULL
FROM [Catalogue].[ADGroups_Stage]
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.ADGroups
		WHERE	ADGroups.GroupName = ADGroups_Stage.GroupName
				AND ADGroups.AccountName = ADGroups_Stage.AccountName)

END
GO

-------------------------------Linked Server Module------------------------------------------------

--Create Linked Server Tables

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'LinkedServers_Stage')
BEGIN
	CREATE TABLE Catalogue.LinkedServers_Stage(
		Server NVARCHAR(128) NOT NULL
		,LinkedServerName NVARCHAR(128) NOT NULL
		,DataSource NVARCHAR(4000) NULL
		,Provider NVARCHAR(128) NULL
		,Product NVARCHAR(128) NULL
		,Location NVARCHAR(4000) NULL
		,ProviderString NVARCHAR(4000) NULL
		,Catalog NVARCHAR(128) NULL
		,LocalUser NVARCHAR(128) NULL
		,Impersonate BIT NOT NULL
		,RemoteUser NVARCHAR(128) NULL
		)
END
GO

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'LinkedServers_Server')
BEGIN
	CREATE TABLE Catalogue.LinkedServers_Server(
		Server NVARCHAR(128) NOT NULL
		,LinkedServerName NVARCHAR(128) NOT NULL
		,DataSource NVARCHAR(4000) NULL
		,Provider NVARCHAR(128) NULL
		,Product NVARCHAR(128) NULL
		,Location NVARCHAR(4000) NULL
		,ProviderString NVARCHAR(4000) NULL
		,Catalog NVARCHAR(128) NULL
		,FirstRecorded DATETIME NULL
		,LastRecorded DATETIME NULL
		,Notes VARCHAR(255) NULL
	 CONSTRAINT [PK_LinkedServer_Server] PRIMARY KEY CLUSTERED 
	(
		Server ASC,
		LinkedServerName ASC
	))
END
GO

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'LinkedServers_Users')
BEGIN
	CREATE TABLE Catalogue.LinkedServers_Users(
		UserID INT IDENTITY(0,1)
		,Server NVARCHAR(128) NOT NULL
		,LinkedServerName NVARCHAR(128) NOT NULL
		,LocalUser NVARCHAR(128) NULL
		,Impersonate BIT NOT NULL
		,RemoteUser NVARCHAR(128) NULL
		,FirstRecorded DATETIME NULL
		,LastRecorded DATETIME NULL
		,Notes VARCHAR(255) NULL
	CONSTRAINT [PK_LinkedServer_Users] PRIMARY KEY CLUSTERED 
	(
		UserID ASC
	),
	CONSTRAINT [FK_LinkedServer_Server] FOREIGN KEY (Server, LinkedServerName) REFERENCES Catalogue.LinkedServers_Server(Server, LinkedServerName)
	)
END
GO
--Linked Server Get Procedure

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetLinkedServers'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetLinkedServers
GO

CREATE PROC Catalogue.GetLinkedServers
AS
BEGIN

SELECT	@@SERVERNAME AS Server, 
		servers.name AS LinkedServerName, 
		servers.data_source AS DataSource,
		servers.provider AS Provider, 
		servers.product AS Product, 
		servers.location AS Location,
		servers.provider_string AS ProviderString,
		servers.catalog AS Catalog,
		server_principals.name AS LocalUser,
		linked_logins.uses_self_credential AS Impersonate,
		linked_logins.remote_name AS RemoteUser
FROM sys.servers
JOIN sys.linked_logins ON servers.server_id = linked_logins.server_id
LEFT OUTER JOIN sys.server_principals ON linked_logins.local_principal_id = server_principals.principal_id
WHERE is_linked = 1

END
GO

--Linked Server Update Proc

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateLinkedServers'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateLinkedServers
GO

CREATE PROC Catalogue.UpdateLinkedServers
AS
BEGIN

--temp table used to prevent duplicate entries from the denormalised stage table
IF OBJECT_ID('tempdb.dbo.#LinkedServers') IS NOT NULL
DROP TABLE #LinkedServers

CREATE TABLE #LinkedServers(
				Server nvarchar(128) NOT NULL
				,LinkedServerName nvarchar(128) NOT NULL
				,DataSource nvarchar(4000) NULL
				,Provider nvarchar(128) NULL
				,Product nvarchar(128) NULL
				,Location nvarchar(4000) NULL
				,ProviderString nvarchar(4000) NULL
				,Catalog nvarchar(128) NULL)

--populate #LinkedServers 
INSERT INTO #LinkedServers
SELECT DISTINCT Server, 
				LinkedServerName, 
				DataSource, 
				Provider, 
				Product, 
				Location, 
				ProviderString, 
				Catalog
FROM Catalogue.LinkedServers_Stage

--update servers table where servers are known to the catalogue

UPDATE Catalogue.LinkedServers_Server 
	SET	Server = LinkedServers.Server
	,LinkedServerName = LinkedServers.LinkedServerName
	,DataSource = LinkedServers.DataSource
	,Provider = LinkedServers.Provider
	,Product = LinkedServers.Product
	,Location = LinkedServers.Location
	,ProviderString = LinkedServers.ProviderString
	,Catalog = LinkedServers.Catalog
	,LastRecorded = GETDATE()
FROM #LinkedServers LinkedServers
WHERE LinkedServers_Server.Server = LinkedServers.Server
	AND LinkedServers_Server.LinkedServerName = LinkedServers.LinkedServerName

--insert into servers table where servers are not known to the catalogue

INSERT INTO Catalogue.LinkedServers_Server(Server ,LinkedServerName,DataSource,Provider,Product,Location,ProviderString,Catalog,FirstRecorded,LastRecorded,Notes)
SELECT	Server 
		,LinkedServerName
		,DataSource
		,Provider
		,Product
		,Location
		,ProviderString
		,Catalog
		,GETDATE()
		,GETDATE()
		,NULL
FROM #LinkedServers LinkedServers
WHERE NOT EXISTS
	(SELECT 1
	FROM Catalogue.LinkedServers_Server
	WHERE LinkedServers_Server.Server = LinkedServers.Server
	AND LinkedServers_Server.LinkedServerName = LinkedServers.LinkedServerName)

--update users table where users are known to the catalogue

UPDATE Catalogue.LinkedServers_Users
SET 	Server = LinkedServers_Stage.Server
		,LinkedServerName = LinkedServers_Stage.LinkedServerName
		,LocalUser = LinkedServers_Stage.LocalUser
		,Impersonate = LinkedServers_Stage.Impersonate
		,RemoteUser = LinkedServers_Stage.RemoteUser
		,LastRecorded = GETDATE()
FROM Catalogue.LinkedServers_Stage
WHERE LinkedServers_Users.Server = LinkedServers_Stage.Server
	AND LinkedServers_Users.LinkedServerName = LinkedServers_Stage.LinkedServerName
	AND ISNULL(LinkedServers_Users.LocalUser, '') = ISNULL(LinkedServers_Stage.LocalUser,'')

--insert into users table where users are unkown to the catalogue

INSERT INTO Catalogue.LinkedServers_Users (Server,LinkedServerName,LocalUser,Impersonate,RemoteUser,FirstRecorded,LastRecorded,Notes)
SELECT	Server
		,LinkedServerName
		,LocalUser
		,Impersonate
		,RemoteUser
		,GETDATE()
		,GETDATE()
		,NULL
FROM Catalogue.LinkedServers_Stage
WHERE NOT EXISTS
	(SELECT 1
	FROM Catalogue.LinkedServers_Users
	WHERE LinkedServers_Users.Server = LinkedServers_Stage.Server
	AND LinkedServers_Users.LinkedServerName = LinkedServers_Stage.LinkedServerName
	AND ISNULL(LinkedServers_Users.LocalUser,'') = ISNULL(LinkedServers_Stage.LocalUser,''))

END

GO


-------------------------------DB Table Server Module------------------------------------------------

--Create 'Table' Tables
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Tables_Stage')
BEGIN
	CREATE TABLE Catalogue.Tables_Stage(
		ServerName NVARCHAR(128) NOT NULL,
		DatabaseName NVARCHAR(128) NOT NULL,
		SchemaName SYSNAME NOT NULL,
		TableName SYSNAME NOT NULL,
		Columns XML
		)
END
GO


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Tables')
BEGIN
	CREATE TABLE Catalogue.Tables(
		ID INT IDENTITY (1,1)
		,ServerName NVARCHAR(128) NOT NULL
		,DatabaseName NVARCHAR(128) NOT NULL
		,SchemaName SYSNAME NOT NULL
		,TableName SYSNAME NOT NULL
		,Columns XML
		,FirstRecorded DATETIME NULL
		,LastRecorded DATETIME NULL
		,Notes VARCHAR(255) NULL
	 CONSTRAINT [PK_Tables] PRIMARY KEY CLUSTERED
	 (ID ASC))
END
GO


-- Tables 'GET' Procedure 

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'GetTables'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.GetTables
GO

CREATE PROC Catalogue.GetTables
AS
BEGIN
	
	IF OBJECT_ID('tempdb.dbo.#Tables') IS NOT NULL
	DROP TABLE #Tables

	CREATE TABLE #Tables
		(ServerName NVARCHAR(128) NOT NULL,
		DatabaseName NVARCHAR(128) NOT NULL,
		SchemaName SYSNAME NOT NULL,
		TableName SYSNAME NOT NULL,
		Columns XML
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

		SET @cmd = N'USE ' + QUOTENAME(@DBName) + N';
			SELECT	@@SERVERNAME AS NameServer,
			DB_NAME() AS DatabaseName, 
			schemas.name AS SchemaName, 
			tables.name AS TableName,
			CAST((
				SELECT columns.name AS ColName,
				types.name AS DataType, 
				CASE 
					WHEN columns.max_length = -1 THEN ''MAX''
					WHEN types.name IN (''nchar'',''nvarchar'') THEN CAST(columns.max_length/2 AS VARCHAR)
					ELSE CAST(columns.max_length AS VARCHAR)
				END AS Length, 
				columns.is_nullable AS IsNullable,
				columns.is_identity AS IsIdentity,
				columns.is_computed AS IsComputed
				FROM sys.columns
				JOIN sys.types ON columns.user_type_id = types.user_type_id
				WHERE columns.object_id = tables.object_id		
				FOR XML RAW
			) AS XML) Cols
			FROM sys.tables
			JOIN sys.schemas ON tables.schema_id = schemas.schema_id'
	
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
	FROM #Tables

END
GO

--Tables Update Proc

IF EXISTS (	SELECT * 
			FROM sys.objects 
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.name = 'UpdateTables'
			AND schemas.name = 'Catalogue'
			AND type = 'P')
DROP PROC Catalogue.UpdateTables
GO

CREATE PROC [Catalogue].[UpdateTables]
AS

BEGIN

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

END


GO

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ExecutionLog')
-- Create Execution Log
BEGIN
	CREATE TABLE Catalogue.ExecutionLog
	(ID INT IDENTITY(1,1) NOT NULL,
	ExecutionDate DATETIME NULL,
	CompletedSuccessfully BIT DEFAULT 0
		 CONSTRAINT [PK_ExecutionLog] PRIMARY KEY CLUSTERED 
		(
			ID ASC
		))
END
-------------------------------------------------------------------------------------------------------
------------------------------update modules table with 0.2 modules------------------------------------
-------------------------------------------------------------------------------------------------------

IF (SELECT VersionNumber FROM #Version) IN ('0.0.0','0.2.0')
BEGIN
	INSERT INTO Catalogue.ConfigModules ([ModuleName], [GetProcName], [UpdateProcName], [StageTableName], [MainTableName], [Active])
	VALUES	('ADGroups','GetADGroups','UpdateADGroups','ADGroups_Stage','ADGroups',	1),
			('LinkedServers','GetLinkedServers','UpdateLinkedServers','LinkedServers_Stage','LinkedServers_Servers,LinkedServers_Users',1),
			('Tables','GetTables','UpdateTables','Tables_Stage','Tables',1)
END


Patch022:


-------------------------------------------------------------------------------------------------------------
--Version 0.2.2 Changes--------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

/*
Undercover Catalogue 0.2.2
SQL Undercover

Written by: David Fowler
Date: 20/06/2019

Description
Hot Fix to solve a problem with modules failing when the interrogation is run with certain versions of DBA Tools

Usage
Use this script to upgrade your catalogue from version 0.2.1 to 0.2.2
*/

UPDATE Catalogue.ConfigPoSH 
SET ParameterValue = '0.2.2'
WHERE ParameterName = 'CatalogueVersion'
GO

IF (SELECT VersionNumber FROM #Version) IN ('0.0.0','0.2.0','0.2.1')
BEGIN
	ALTER TABLE [Catalogue].[Users_Stage] DROP CONSTRAINT PK_Users_Stage
	ALTER TABLE [Catalogue].[Users_Stage] DROP COLUMN ID
END
GO

ALTER PROC [Catalogue].[GetUsers]
AS

BEGIN

DECLARE @DBName SYSNAME
DECLARE @cmd NVARCHAR(4000)

IF OBJECT_ID('tempdb.dbo.#Users_Tmp') IS NOT NULL
DROP TABLE #Users_Tmp

--create temp table to bulid up result set
CREATE TABLE #Users_Tmp(
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[UserName] [sysname] NOT NULL,
	[SID] [varbinary](85) NULL,
	[RoleName] [sysname] NULL,
	[MappedLoginName] [sysname] NOT NULL)


--cursor to cycle through all databases on the server
DECLARE DBCur CURSOR FOR
SELECT [name]
FROM sys.databases

OPEN DBCur

FETCH NEXT FROM DBCur INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

--get all users for the selected database

BEGIN TRY
	SET @cmd = 
	'USE ' + QUOTENAME(@DBName) + '

	SELECT	@@SERVERNAME AS ServerName,
			DB_NAME() AS DBName,
			principals_logins.name AS UserName, 
			principals_logins.sid AS SID, 
			principals_roles.name AS RoleName,
			ISNULL(server_principals.name, ''***ORPHANED USER***'') AS MappedLoginName
	FROM sys.database_role_members
	RIGHT OUTER JOIN sys.database_principals principals_roles 
		ON database_role_members.role_principal_id = principals_roles.principal_id
	RIGHT OUTER JOIN sys.database_principals principals_logins 
		ON database_role_members.member_principal_id = principals_logins.principal_id
	LEFT OUTER JOIN sys.server_principals 
		ON server_principals.sid = principals_logins.sid
	WHERE principals_logins.type IN (''G'',''S'',''U'') --include only windows groups, windows logins and SQL logins
		AND principals_logins.sid IS NOT NULL 
	ORDER BY principals_logins.name'

	INSERT INTO #Users_Tmp(ServerName,DBName,UserName,SID,RoleName,MappedLoginName) 
	EXEC sp_executesql @stmt = @cmd
END TRY
BEGIN CATCH
--if the database is inaccessable, do nothing and move on to the next one
END CATCH
FETCH NEXT FROM DBCur INTO @DBName

END

CLOSE DBCur
DEALLOCATE DBCur

SELECT * FROM #Users_Tmp

END
GO





ALTER PROC [Catalogue].[GetAgentJobs]
AS
BEGIN
--get all agent jobs on server
SELECT	@@SERVERNAME AS ServerName,
		sysjobs.job_id AS JobID, 
		sysjobs.name AS JobName,
		sysjobs.enabled AS Enabled, 
		sysjobs.description AS Description, 
		syscategories.name AS Category, 
		sysjobs.date_created AS DateCreated, 
		sysjobs.date_modified AS DateModified, 
		sysschedules.enabled AS ScheduleEnabled,
		sysschedules.name AS ScheduleName,
		CASE freq_type
            WHEN 1 THEN 'Occurs on ' + STUFF(RIGHT(active_start_date, 4), 3,0, '/') + '/' + LEFT(active_start_date, 4) + ' at '
                + REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime) /* hh:mm:ss 24H */, 9), 14), ':000', ' ') /* HH:mm:ss:000AM/PM then replace the :000 with space.*/
            WHEN 4 THEN 'Occurs every ' + CAST(freq_interval as varchar(10)) + ' day(s) '
                + CASE freq_subday_type
                    WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
                    WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
                    WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
                    ELSE '' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                        + ' and '
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    ELSE ''
                    END
            WHEN 8 THEN 'Occurs every ' + CAST(freq_recurrence_factor as varchar(10))
                + ' week(s) on '
                +
                REPLACE( CASE WHEN freq_interval&1 = 1 THEN 'Sunday, ' ELSE '' END
                + CASE WHEN freq_interval&2 = 2 THEN 'Monday, ' ELSE '' END
                + CASE WHEN freq_interval&4 = 4 THEN 'Tuesday, ' ELSE '' END
                + CASE WHEN freq_interval&8 = 8 THEN 'Wednesday, ' ELSE '' END
                + CASE WHEN freq_interval&16 = 16 THEN 'Thursday, ' ELSE '' END
                + CASE WHEN freq_interval&32 = 32 THEN 'Friday, ' ELSE '' END
                + CASE WHEN freq_interval&64 = 64 THEN 'Saturday, ' ELSE '' END
                + '|', ', |', ' ') /* get rid of trailing comma */

                + CASE freq_subday_type
                    WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
                    WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
                    WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
                    ELSE '' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                        + ' and '
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    ELSE ''
                    END
            WHEN 16 THEN 'Occurs every ' + CAST(freq_recurrence_factor as varchar(10))
                + ' month(s) on '
                + 'day ' + CAST(freq_interval as varchar(10)) + ' of that month ' 
                + CASE freq_subday_type
                    WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
                    WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
                    WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
                    ELSE '' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                        + ' and '
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    ELSE ''
                    END
            WHEN 32 THEN 'Occurs ' 
                + CASE freq_relative_interval
                    WHEN 1 THEN 'every first '
                    WHEN 2 THEN 'every second '
                    WHEN 4 THEN 'every third '
                    WHEN 8 THEN 'every fourth '
                    WHEN 16 THEN 'on the last '
                    END
                + CASE freq_interval 
                    WHEN 1 THEN 'Sunday'
                    WHEN 2 THEN 'Monday'
                    WHEN 3 THEN 'Tuesday'
                    WHEN 4 THEN 'Wednesday'
                    WHEN 5 THEN 'Thursday'
                    WHEN 6 THEN 'Friday'
                    WHEN 7 THEN 'Saturday'
                    WHEN 8 THEN 'day'
                    WHEN 9 THEN 'weekday'
                    WHEN 10 THEN 'weekend'
                    END
                + ' of every ' + CAST(freq_recurrence_factor as varchar(10)) + ' month(s) '
                + CASE freq_subday_type
                    WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
                    WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
                    WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
                    ELSE '' 
                    END
                + CASE 
                    WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                        + ' and '
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
                    ELSE ''
                    END
            WHEN 64 THEN 'Runs when the SQL Server Agent service starts'
            WHEN 128 THEN 'Runs when the computer is idle'
            END 
		AS ScheduleFrequency,
		sysjobsteps.step_id AS StepID,
		sysjobsteps.step_name AS StepName,
		sysjobsteps.subsystem AS SubSystem,
		sysjobsteps.command AS Command,
		sysjobsteps.database_name AS DatabaseName
FROM msdb.dbo.sysjobs
JOIN msdb.dbo.syscategories ON sysjobs.category_id = syscategories.category_id
JOIN msdb.dbo.sysjobschedules ON sysjobs.job_id = sysjobschedules.job_id
JOIN msdb.dbo.sysschedules ON sysjobschedules.schedule_id = sysschedules.schedule_id
JOIN msdb.dbo.sysjobsteps ON sysjobsteps.job_id = sysjobs.job_id
END
GO




ALTER PROC [Catalogue].[GetLogins]
AS
BEGIN

--get all logins on server
SELECT	@@SERVERNAME AS ServerName,
		principals_logins.name AS LoginName, 
		principals_logins.sid AS SID, 
		principals_roles.name AS RoleName,
		NULL AS ID,
		principals_logins.is_disabled AS IsDisabled,
		LOGINPROPERTY(principals_logins.name, 'PasswordHash') AS PasswordHash,  -- **the varbinary of password hash is erroring in powershell, something to be looked at
		principals_logins.type_desc AS LoginType
FROM sys.server_role_members
RIGHT OUTER JOIN sys.server_principals principals_roles 
	ON server_role_members.role_principal_id = principals_roles.principal_id
RIGHT OUTER JOIN sys.server_principals principals_logins 
	ON server_role_members.member_principal_id = principals_logins.principal_id
WHERE principals_logins.type IN ('G','S','U') --include only windows groups, windows logins and SQL logins
ORDER BY principals_logins.name

END
GO



ALTER PROC [Catalogue].[GetDatabases]
AS

BEGIN
--get all databases on server

SELECT	@@SERVERNAME AS ServerName,
		databases.name AS DBName,
		databases.database_id AS DatabaseID,
		server_principals.name AS OwnerName,
		databases.compatibility_level AS CompatibilityLevel,
		databases.collation_name AS CollationName,
		databases.recovery_model_desc AS RecoveryModelDesc,
		availability_groups.name AS AGName,
		files.FilePaths,
		files.DatabaseSizeMB
FROM sys.databases
LEFT OUTER JOIN sys.server_principals ON server_principals.sid = databases.owner_sid
LEFT OUTER JOIN sys.availability_replicas ON availability_replicas.replica_id = databases.replica_id
LEFT OUTER JOIN sys.availability_groups ON availability_groups.group_id = availability_replicas.group_id
JOIN	(SELECT database_id, (SUM(CAST (size AS BIGINT)) * 8)/1024 AS DatabaseSizeMB,STUFF((SELECT ', ' + files2.physical_name
				FROM sys.master_files files2
				WHERE files2.database_id = files1.database_id
				FOR XML PATH('')
			), 1, 2, '') AS FilePaths
		FROM sys.master_files files1
		GROUP BY database_id) files ON files.database_id = databases.database_id
END
GO


Patch030:

-------------------------------------------------------------------------------------------------------------------
--Version 0.3.0 Changes
-------------------------------------------------------------------------------------------------------------------

--create audit tables


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ADGroups_Audit')
BEGIN
	CREATE TABLE [Catalogue].[ADGroups_Audit](
		[GroupName] [sysname] NOT NULL,
		[AccountName] [sysname] NOT NULL,
		[AccountType] [sysname] NOT NULL,
		[Notes] [varchar](255) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY]
END

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'AgentJobs_Audit')
BEGIN
	CREATE TABLE [Catalogue].[AgentJobs_Audit](
		[ServerName] [nvarchar](128) NULL,
		[JobID] [uniqueidentifier] NOT NULL,
		[JobName] [sysname] NOT NULL,
		[Enabled] [tinyint] NOT NULL,
		[Description] [nvarchar](512) NULL,
		[Category] [sysname] NOT NULL,
		[DateCreated] [datetime] NOT NULL,
		[DateModified] [datetime] NOT NULL,
		[ScheduleEnabled] [int] NOT NULL,
		[ScheduleName] [sysname] NOT NULL,
		[ScheduleFrequency] [varchar](8000) NULL,
		[StepID] [int] NOT NULL,
		[StepName] [sysname] NOT NULL,
		[SubSystem] [nvarchar](40) NOT NULL,
		[Command] [nvarchar](max) NULL,
		[DatabaseName] [sysname] NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'AvailabilityGroups_Audit')
BEGIN
	CREATE TABLE [Catalogue].[AvailabilityGroups_Audit](
		[AGName] [sysname] NOT NULL,
		[ServerName] [nvarchar](256) NOT NULL,
		[Role] [nvarchar](60) NULL,
		[BackupPreference] [nvarchar](60) NULL,
		[AvailabilityMode] [nvarchar](60) NULL,
		[FailoverMode] [nvarchar](60) NULL,
		[ConnectionsToSecondary] [nvarchar](60) NULL,
		[Notes] [varchar](255) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY]
END

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Databases_Audit')
BEGIN
	CREATE TABLE [Catalogue].[Databases_Audit](
		[ServerName] [nvarchar](128) NOT NULL,
		[DBName] [sysname] NOT NULL,
		[DatabaseID] [int] NOT NULL,
		[OwnerName] [sysname] NULL,
		[CompatibilityLevel] [tinyint] NOT NULL,
		[CollationName] [sysname] NULL,
		[RecoveryModelDesc] [nvarchar](60) NULL,
		[AGName] [sysname] NULL,
		[FilePaths] [nvarchar](max) NULL,
		[DatabaseSizeMB] [bigint] NULL,
		[CustomerName] [varchar](50) NULL,
		[ApplicationName] [varchar](50) NULL,
		[Notes] [varchar](255) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ExplicitPermissions_Audit')
BEGIN
	CREATE TABLE [Catalogue].[ExplicitPermissions_Audit](
		[Name] [sysname] NOT NULL,
		[PermissionName] [nvarchar](128) NULL,
		[StateDesc] [nvarchar](60) NULL,
		[ServerName] [nvarchar](128) NULL,
		[DBName] [nvarchar](128) NULL,
		[MajorObject] [nvarchar](128) NULL,
		[MinorObject] [nvarchar](128) NULL,
		[Notes] [varchar](255) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY]
END

IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'LinkedServers_Server_Audit')
BEGIN
	CREATE TABLE [Catalogue].[LinkedServers_Server_Audit](
		[Server] [nvarchar](128) NOT NULL,
		[LinkedServerName] [nvarchar](128) NOT NULL,
		[DataSource] [nvarchar](4000) NULL,
		[Provider] [nvarchar](128) NULL,
		[Product] [nvarchar](128) NULL,
		[Location] [nvarchar](4000) NULL,
		[ProviderString] [nvarchar](4000) NULL,
		[Catalog] [nvarchar](128) NULL,
		[Notes] [varchar](255) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY]
END


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'LinkedServers_Users_Audit')
BEGIN
	CREATE TABLE [Catalogue].[LinkedServers_Users_Audit](
		[Server] [nvarchar](128) NOT NULL,
		[LinkedServerName] [nvarchar](128) NOT NULL,
		[LocalUser] [nvarchar](128) NULL,
		[Impersonate] [bit] NOT NULL,
		[RemoteUser] [nvarchar](128) NULL,
		[Notes] [varchar](255) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY]
END


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Logins_Audit')
BEGIN
	CREATE TABLE [Catalogue].[Logins_Audit](
		[ServerName] [nvarchar](128) NULL,
		[LoginName] [sysname] NOT NULL,
		[SID] [varbinary](85) NULL,
		[RoleName] [sysname] NULL,
		[IsDisabled] [bit] NULL,
		[Notes] [varchar](255) NULL,
		[PasswordHash] [varbinary](256) NULL,
		[LoginType] [nvarchar](60) NULL,
		[AuditDate] [datetime] NULL
	) ON [PRIMARY]
END


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Servers_Audit')
BEGIN
	CREATE TABLE [Catalogue].[Servers_Audit](
		[ServerName] [nvarchar](128) NOT NULL,
		[Collation] [nvarchar](128) NOT NULL,
		[Edition] [nvarchar](128) NOT NULL,
		[VersionNo] [nvarchar](128) NOT NULL,
		[CustomerName] [varchar](50) NULL,
		[ApplicationName] [varchar](50) NULL,
		[Notes] [varchar](255) NULL,
		[ServerStartTime] [datetime] NULL,
		[CostThreshold] [int] NULL,
		[MaxWorkerThreads] [int] NULL,
		[MaxDOP] [int] NULL,
		[CPUCount] [int] NULL,
		[NUMACount] [int] NULL,
		[PhysicalMemoryMB] [int] NULL,
		[MaxMemoryMB] [int] NULL,
		[MinMemoryMB] [int] NULL,
		[MemoryModel] [nvarchar](128) NULL,
		[IsClustered] [bit] NULL,
		[VMType] [nvarchar](60) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY]
END


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Tables_Audit')
BEGIN
	CREATE TABLE [Catalogue].[Tables_Audit](
		[ServerName] [nvarchar](128) NOT NULL,
		[DatabaseName] [nvarchar](128) NOT NULL,
		[SchemaName] [sysname] NOT NULL,
		[TableName] [sysname] NOT NULL,
		[Columns] [xml] NULL,
		[Notes] [varchar](255) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END


IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Users_Audit')
BEGIN
	CREATE TABLE [Catalogue].[Users_Audit](
		[ServerName] [nvarchar](128) NULL,
		[DBName] [nvarchar](128) NULL,
		[UserName] [sysname] NOT NULL,
		[SID] [varbinary](85) NULL,
		[RoleName] [sysname] NULL,
		[MappedLoginName] [sysname] NOT NULL,
		[Notes] [varchar](255) NULL,
		[AuditDate] [datetime] NOT NULL
	) ON [PRIMARY]
END

-- create audit triggers


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditADGroups')
DROP TRIGGER [Catalogue].[AuditADGroups]
GO

CREATE TRIGGER [Catalogue].[AuditADGroups]
ON [Catalogue].[ADGroups]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[ADGroups_Audit]
		([GroupName], [AccountName], [AccountType], [Notes], AuditDate)
		SELECT	[GroupName],
				[AccountName],
				[AccountType],
				[Notes],
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(inserted.[GroupName],
										inserted.[AccountName],
										inserted.[AccountType],
										inserted.[Notes])
										!= 
								CHECKSUM(deleted.[GroupName],
										deleted.[AccountName],
										deleted.[AccountType],
										deleted.[Notes])
							AND deleted.[GroupName] = inserted.[GroupName]
							AND deleted.[AccountName] = inserted.[AccountName])
END
GO

ALTER TABLE [Catalogue].[ADGroups] ENABLE TRIGGER [AuditADGroups]
GO


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditAgentJobs')
DROP TRIGGER [Catalogue].[AuditAgentJobs]
GO

CREATE TRIGGER [Catalogue].[AuditAgentJobs]
ON [Catalogue].[AgentJobs]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[AgentJobs_Audit]
		([ServerName], [JobID], [JobName], [Enabled], [Description], [Category], [DateCreated], [DateModified], [ScheduleEnabled], [ScheduleName], [ScheduleFrequency], [StepID], [StepName], [SubSystem], [Command], [DatabaseName], [AuditDate])
		SELECT	[ServerName], 
				[JobID], 
				[JobName], 
				[Enabled], 
				[Description], 
				[Category], 
				[DateCreated], 
				[DateModified], 
				[ScheduleEnabled], 
				[ScheduleName], 
				[ScheduleFrequency], 
				[StepID], 
				[StepName], 
				[SubSystem], 
				[Command], 
				[DatabaseName],
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[ServerName], 
											inserted.[JobID], 
											inserted.[JobName], 
											inserted.[Enabled], 
											inserted.[Description], 
											inserted.[Category], 
											inserted.[DateCreated], 
											inserted.[DateModified], 
											inserted.[ScheduleEnabled], 
											inserted.[ScheduleName], 
											inserted.[ScheduleFrequency], 
											inserted.[StepID], 
											inserted.[StepName], 
											inserted.[SubSystem], 
											inserted.[Command], 
											inserted.[DatabaseName])
										!= 
								CHECKSUM(	deleted.[ServerName], 
											deleted.[JobID], 
											deleted.[JobName], 
											deleted.[Enabled], 
											deleted.[Description], 
											deleted.[Category], 
											deleted.[DateCreated], 
											deleted.[DateModified], 
											deleted.[ScheduleEnabled], 
											deleted.[ScheduleName], 
											deleted.[ScheduleFrequency], 
											deleted.[StepID], 
											deleted.[StepName], 
											deleted.[SubSystem], 
											deleted.[Command], 
											deleted.[DatabaseName])
							AND deleted.[ServerName] = inserted.[ServerName]
							AND deleted.[JobID] = inserted.[JobID]
							AND deleted.[StepID] = inserted.[StepID])
END
GO

ALTER TABLE [Catalogue].[AgentJobs] ENABLE TRIGGER [AuditAgentJobs]
GO



IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditAvailabilityGroups')
DROP TRIGGER [Catalogue].[AuditAvailabilityGroups]
GO


CREATE TRIGGER [Catalogue].[AuditAvailabilityGroups]
ON [Catalogue].[AvailabilityGroups]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[AvailabilityGroups_Audit]
		([AGName], [ServerName], [Role], [BackupPreference], [AvailabilityMode], [FailoverMode], [ConnectionsToSecondary], [Notes], [AuditDate])
		SELECT	[AGName], 
				[ServerName], 
				[Role], 
				[BackupPreference], 
				[AvailabilityMode], 
				[FailoverMode], 
				[ConnectionsToSecondary], 
				[Notes], 
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[AGName], 
											inserted.[ServerName], 
											inserted.[Role], 
											inserted.[BackupPreference], 
											inserted.[AvailabilityMode], 
											inserted.[FailoverMode], 
											inserted.[ConnectionsToSecondary], 
											inserted.[Notes])
										!= 
								CHECKSUM(	deleted.[AGName], 
											deleted.[ServerName], 
											deleted.[Role], 
											deleted.[BackupPreference], 
											deleted.[AvailabilityMode], 
											deleted.[FailoverMode], 
											deleted.[ConnectionsToSecondary], 
											deleted.[Notes])
							AND deleted.[AGName] = inserted.[AGName]
							AND deleted.[ServerName] = inserted.[ServerName])
END
GO

ALTER TABLE [Catalogue].[AvailabilityGroups] ENABLE TRIGGER [AuditAvailabilityGroups]
GO


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditDatabases')
DROP TRIGGER [Catalogue].[AuditDatabases]
GO


CREATE TRIGGER [Catalogue].[AuditDatabases]
ON [Catalogue].[Databases]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[Databases_Audit]
		([ServerName], [DBName], [DatabaseID], [OwnerName], [CompatibilityLevel], [CollationName], [RecoveryModelDesc], [AGName], [FilePaths], [DatabaseSizeMB], [CustomerName], [ApplicationName], [Notes], [AuditDate])
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
				GETDATE()
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
											inserted.[Notes])
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
											deleted.[Notes])
							AND deleted.[DBName] = inserted.[DBName]
							AND deleted.[ServerName] = inserted.[ServerName])
END
GO

ALTER TABLE [Catalogue].[Databases] ENABLE TRIGGER [AuditDatabases]
GO


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditExplicitPermissions')
DROP TRIGGER [Catalogue].[AuditExplicitPermissions]
GO


CREATE TRIGGER [Catalogue].[AuditExplicitPermissions]
ON [Catalogue].[ExplicitPermissions]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[ExplicitPermissions_Audit]
		([Name], [PermissionName], [StateDesc], [ServerName], [DBName], [MajorObject], [MinorObject], [Notes], AuditDate)
		SELECT	[Name], 
				[PermissionName], 
				[StateDesc], 
				[ServerName], 
				[DBName], 
				[MajorObject], 
				[MinorObject], 
				[Notes], 
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[Name], 
											inserted.[PermissionName], 
											inserted.[StateDesc], 
											inserted.[ServerName], 
											inserted.[DBName], 
											inserted.[MajorObject], 
											inserted.[MinorObject], 
											inserted.[Notes])
																	!= 
								CHECKSUM(	deleted.[Name], 
											deleted.[PermissionName], 
											deleted.[StateDesc], 
											deleted.[ServerName], 
											deleted.[DBName], 
											deleted.[MajorObject], 
											deleted.[MinorObject], 
											deleted.[Notes])
							AND deleted.Name = inserted.Name
							AND deleted.PermissionName = inserted.PermissionName
							AND deleted.StateDesc = inserted.StateDesc
							AND deleted.ServerName = inserted.ServerName
							AND deleted.DBName = inserted.DBName
							AND ISNULL(deleted.MajorObject,'') = ISNULL(inserted.MajorObject,'')
							AND ISNULL(deleted.MinorObject,'') = ISNULL(inserted.MinorObject,'')
							)
END
GO

ALTER TABLE [Catalogue].[ExplicitPermissions] ENABLE TRIGGER [AuditExplicitPermissions]
GO


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditLinkedServers_Server')
DROP TRIGGER [Catalogue].[AuditLinkedServers_Server]
GO


CREATE TRIGGER [Catalogue].[AuditLinkedServers_Server]
ON [Catalogue].[LinkedServers_Server]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[LinkedServers_Server_Audit]
		([Server], [LinkedServerName], [DataSource], [Provider], [Product], [Location], [ProviderString], [Catalog], [Notes], [AuditDate])
		SELECT	[Server], 
				[LinkedServerName], 
				[DataSource], 
				[Provider], 
				[Product], 
				[Location], 
				[ProviderString], 
				[Catalog], 
				[Notes], 
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[Server], 
											inserted.[LinkedServerName], 
											inserted.[DataSource], 
											inserted.[Provider], 
											inserted.[Product], 
											inserted.[Location], 
											inserted.[ProviderString], 
											inserted.[Catalog], 
											inserted.[Notes])
											!= 
								CHECKSUM(	deleted.[Server], 
											deleted.[LinkedServerName], 
											deleted.[DataSource], 
											deleted.[Provider], 
											deleted.[Product], 
											deleted.[Location], 
											deleted.[ProviderString], 
											deleted.[Catalog], 
											deleted.[Notes])
							AND deleted.[Server] = inserted.[Server]
							AND deleted.[LinkedServerName] = inserted.[LinkedServerName]
							)
END
GO

ALTER TABLE [Catalogue].[LinkedServers_Server] ENABLE TRIGGER [AuditLinkedServers_Server]
GO


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditLinkedServers_Users')
DROP TRIGGER [Catalogue].[AuditLinkedServers_Users]
GO


CREATE TRIGGER [Catalogue].[AuditLinkedServers_Users]
ON [Catalogue].[LinkedServers_Users]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[LinkedServers_Users_Audit]
		([Server], [LinkedServerName], [LocalUser], [Impersonate], [RemoteUser], [Notes], [AuditDate])
		SELECT	[Server], 
				[LinkedServerName], 
				[LocalUser], 
				[Impersonate], 
				[RemoteUser], 
				[Notes],
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[Server], 
											inserted.[LinkedServerName], 
											inserted.[LocalUser], 
											inserted.[Impersonate], 
											inserted.[RemoteUser], 
											inserted.[Notes])
											!= 
								CHECKSUM(	deleted.[Server], 
											deleted.[LinkedServerName], 
											deleted.[LocalUser], 
											deleted.[Impersonate], 
											deleted.[RemoteUser], 
											deleted.[Notes])
							AND deleted.[Server] = inserted.[Server]
							AND deleted.[LinkedServerName] = inserted.[LinkedServerName]
							AND deleted.[LocalUser] = inserted.[LocalUser]
							)
END
GO

ALTER TABLE [Catalogue].[LinkedServers_Users] ENABLE TRIGGER [AuditLinkedServers_Users]
GO


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditLogins')
DROP TRIGGER [Catalogue].[AuditLogins]
GO


CREATE TRIGGER [Catalogue].[AuditLogins]
ON [Catalogue].[Logins]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[Logins_Audit]
		([ServerName], [LoginName], [SID], [RoleName], [IsDisabled], [Notes], [PasswordHash], [LoginType], [AuditDate])
		SELECT	ServerName,
				LoginName,
				SID,
				RoleName,
				IsDisabled,
				Notes,
				PasswordHash,
				LoginType,
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(inserted.LoginName,
										inserted.SID,
										inserted.RoleName,
										inserted.IsDisabled,
										inserted.Notes,
										inserted.PasswordHash,
										inserted.LoginType)
										!= 
								CHECKSUM(deleted.LoginName,
										deleted.SID,
										deleted.RoleName,
										deleted.IsDisabled,
										deleted.Notes,
										deleted.PasswordHash,
										deleted.LoginType)
							AND deleted.ServerName = inserted.ServerName
							AND deleted.LoginName = inserted.LoginName
							AND ISNULL(deleted.RoleName, '') = ISNULL(inserted.RoleName,''))
END
GO

ALTER TABLE [Catalogue].[Logins] ENABLE TRIGGER [AuditLogins]
GO



IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditServers')
DROP TRIGGER [Catalogue].[AuditServers]
GO


CREATE TRIGGER [Catalogue].[AuditServers]
ON [Catalogue].[Servers]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[Servers_Audit]
		([ServerName], [Collation], [Edition], [VersionNo], [CustomerName], [ApplicationName], [Notes], [ServerStartTime], [CostThreshold], [MaxWorkerThreads], [MaxDOP], [CPUCount], [NUMACount], [PhysicalMemoryMB], [MaxMemoryMB], [MinMemoryMB], [MemoryModel], [IsClustered], [VMType], [AuditDate])
		SELECT	[ServerName], 
				[Collation], 
				[Edition], 
				[VersionNo],
				[CustomerName], 
				[ApplicationName], 
				[Notes], 
				[ServerStartTime], 
				[CostThreshold], 
				[MaxWorkerThreads], 
				[MaxDOP], 
				[CPUCount], 
				[NUMACount], 
				[PhysicalMemoryMB], 
				[MaxMemoryMB], 
				[MinMemoryMB], 
				[MemoryModel], 
				[IsClustered], 
				[VMType],
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[ServerName], 
											inserted.[Collation], 
											inserted.[Edition], 
											inserted.[VersionNo],
											inserted.[CustomerName], 
											inserted.[ApplicationName], 
											inserted.[Notes], 
											inserted.[ServerStartTime], 
											inserted.[CostThreshold], 
											inserted.[MaxWorkerThreads], 
											inserted.[MaxDOP], 
											inserted.[CPUCount], 
											inserted.[NUMACount], 
											inserted.[PhysicalMemoryMB], 
											inserted.[MaxMemoryMB], 
											inserted.[MinMemoryMB], 
											inserted.[MemoryModel], 
											inserted.[IsClustered], 
											inserted.[VMType])
										!= 
								CHECKSUM(	deleted.[ServerName], 
											deleted.[Collation], 
											deleted.[Edition], 
											deleted.[VersionNo], 
											deleted.[FirstRecorded], 
											deleted.[LastRecorded], 
											deleted.[CustomerName], 
											deleted.[ApplicationName], 
											deleted.[Notes], 
											deleted.[ServerStartTime], 
											deleted.[CostThreshold], 
											deleted.[MaxWorkerThreads], 
											deleted.[MaxDOP], 
											deleted.[CPUCount], 
											deleted.[NUMACount], 
											deleted.[PhysicalMemoryMB], 
											deleted.[MaxMemoryMB], 
											deleted.[MinMemoryMB], 
											deleted.[MemoryModel], 
											deleted.[IsClustered], 
											deleted.[VMType])
							AND deleted.ServerName = inserted.ServerName)
END
GO

ALTER TABLE [Catalogue].[Servers] ENABLE TRIGGER [AuditServers]
GO


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditTables')
DROP TRIGGER [Catalogue].[AuditTables]
GO


CREATE TRIGGER [Catalogue].[AuditTables]
ON [Catalogue].[Tables]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[Tables_Audit]
		([ServerName], [DatabaseName], [SchemaName], [TableName], [Columns], [Notes], [AuditDate])
		SELECT	[ServerName], 
				[DatabaseName], 
				[SchemaName], 
				[TableName], 
				[Columns], 
				[Notes],
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[ServerName], 
											inserted.[DatabaseName], 
											inserted.[SchemaName], 
											inserted.[TableName], 
											CAST(inserted.[Columns] AS VARCHAR(MAX)), 
											inserted.[Notes])
										!= 
								CHECKSUM(	deleted.[ServerName], 
											deleted.[DatabaseName], 
											deleted.[SchemaName], 
											deleted.[TableName], 
											CAST(deleted.[Columns] AS VARCHAR(MAX)), 
											deleted.[Notes])
							AND deleted.ServerName = inserted.ServerName
							AND deleted.[DatabaseName] = inserted.DatabaseName
							AND deleted.[SchemaName] = inserted.SchemaName
							ANd deleted.[TableName] = inserted.TableName)
END
GO


ALTER TABLE [Catalogue].[Tables] ENABLE TRIGGER [AuditTables]
GO


IF EXISTS (	SELECT 1
			FROM sys.objects
			JOIN sys.schemas ON objects.schema_id = schemas.schema_id
			WHERE objects.type = 'TR'
				AND schemas.name = 'Catalogue' 
				AND objects.name = 'AuditUsers')
DROP TRIGGER [Catalogue].[AuditUsers]
GO


CREATE TRIGGER [Catalogue].[AuditUsers]
ON [Catalogue].[Users]
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[Users_Audit]
		([ServerName], [DBName], [UserName], [SID], [RoleName], [MappedLoginName], [Notes], [AuditDate])
		SELECT	[ServerName], 
				[DBName], 
				[UserName], 
				[SID], 
				[RoleName], 
				[MappedLoginName], 
				[Notes],
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[ServerName], 
											inserted.[DBName], 
											inserted.[UserName], 
											inserted.[SID], 
											inserted.[RoleName], 
											inserted.[MappedLoginName], 
											inserted.[Notes])
										!= 
								CHECKSUM(	deleted.[ServerName], 
											deleted.[DBName], 
											deleted.[UserName], 
											deleted.[SID], 
											deleted.[RoleName], 
											deleted.[MappedLoginName], 
											deleted.[Notes])
							AND deleted.ServerName = inserted.ServerName
							AND deleted.[DBName] = inserted.[DBName]
							AND deleted.[UserName] = inserted.[UserName]
							AND ISNULL(deleted.RoleName ,'') = ISNULL(inserted.RoleName ,''))
END
GO

ALTER TABLE [Catalogue].[Users] ENABLE TRIGGER [AuditUsers]
GO


--update version number
UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '0.3.0'
WHERE ParameterName = 'CatalogueVersion'

--update 
UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '1.0.0'
WHERE ParameterName = 'DBAToolsRequirement'



