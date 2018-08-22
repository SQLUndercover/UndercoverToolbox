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
          .@@`        `@@@@                                          © www.sqlundercover.com                                                             
         +@@@@        @@@@@+                                                                                            
        @@@@@@@      @@@@@@@@#                                                                                          
         @@@@@@@    @@@@@@,                                                                                             
           :@@@@@' ;@@@@`                                                                                               
             `@@@@ @@@+                                                                                                 
                @#:@@                                                                                                   
                  @@                                                                                                    
                  @`                                                                                                    
                  #                                                                                                     
                                                                                                                            
Undercover Catalogue Installation 0.1.0                                                      
Written By David Fowler
22/08/2018

MIT License
------------

Copyright 2018 Sql Undrcover

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

-----------------------------------------Catalogue Databases--------------------------------------------------------------
--create database table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Databases')
CREATE TABLE [Catalogue].[Databases](
	[ServerName] [nvarchar](128) NOT NULL,
	[DBName] [sysname] NOT NULL,
	[database_id] [int] NOT NULL,
	[OwnerName] [sysname] NULL,
	[compatibility_level] [tinyint] NOT NULL,
	[collation_name] [sysname] NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
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
	[database_id] ASC
))
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Databases_Stage')
CREATE TABLE [Catalogue].[Databases_Stage](
	[ServerName] [nvarchar](128) NOT NULL,
	[DBName] [sysname] NOT NULL,
	[database_id] [int] NOT NULL,
	[OwnerName] [sysname] NULL,
	[compatibility_level] [tinyint] NOT NULL,
	[collation_name] [sysname] NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
	[AGName] [sysname] NULL,
	[FilePaths] [nvarchar](max) NULL,
	[DatabaseSizeMB] [bigint] NULL
 CONSTRAINT [PK_Databases_Stage] PRIMARY KEY CLUSTERED 
(
	[ServerName] ASC,
	[database_id] ASC
))
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
		database_id = Databases_Stage.database_id,
		OwnerName = Databases_Stage.OwnerName,
		compatibility_level = Databases_Stage.compatibility_level,
		collation_name = Databases_Stage.collation_name,
		recovery_model_desc = Databases_Stage.recovery_model_desc,
		AGName = Databases_Stage.AGName,
		FilePaths = Databases_Stage.FilePaths,
		DatabaseSizeMB= Databases_Stage.DatabaseSizeMB,
		LastRecorded = GETDATE()
FROM Catalogue.Databases_Stage
WHERE	Databases.ServerName = Databases_Stage.ServerName
		AND Databases.database_id = Databases_Stage.database_id

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Databases
(ServerName, DBName, database_id, OwnerName, Compatibility_level, collation_name, recovery_model_desc, AGName,FilePaths,DatabaseSizeMB,FirstRecorded,LastRecorded)
SELECT ServerName,
		DBName,
		database_id,
		OwnerName,
		compatibility_level,
		collation_name,
		recovery_model_desc,
		AGName,
		FilePaths,
		DatabaseSizeMB,
		GETDATE(),
		GETDATE()
FROM Catalogue.Databases_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Databases
		WHERE database_id = Databases_Stage.database_id
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
CREATE TABLE [Catalogue].[Logins](
	[ServerName] [nvarchar](128) NULL,
	[LoginName] [sysname] NOT NULL,
	[sid] [varbinary](85) NULL,
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
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Logins_Stage')
CREATE TABLE [Catalogue].[Logins_Stage](
	[ServerName] [nvarchar](128) NULL,
	[LoginName] [sysname] NOT NULL,
	[sid] [varbinary](85) NULL,
	[RoleName] [sysname] NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[IsDisabled] [bit] NULL,
	[PasswordHash] [varbinary](256) NULL
 CONSTRAINT [PK_Logins_Stage] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
))
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
		sid = [Logins_Stage].sid,
		RoleName = [Logins_Stage].RoleName,
		PasswordHash = [Logins_Stage].PasswordHash,
		LastRecorded = GETDATE(),
		IsDisabled = [Logins_Stage].IsDisabled
FROM	[Catalogue].[Logins_Stage]
WHERE	Logins.ServerName = [Logins_Stage].ServerName
		AND Logins.LoginName = [Logins_Stage].LoginName

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Logins
(ServerName,LoginName,sid,Rolename,FirstRecorded,LastRecorded, IsDisabled, PasswordHash)
SELECT ServerName,
		LoginName,
		sid,
		RoleName,
		GETDATE(),
		GETDATE(),
		IsDisabled,
		PasswordHash
FROM [Catalogue].[Logins_Stage]
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Logins
		WHERE sid = [Logins_Stage].sid
		AND Logins.ServerName = [Logins_Stage].ServerName)

END
GO

---------------------------------Catalogue Agent Jobs-----------------------------------------
--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'AgentJobs')
CREATE TABLE [Catalogue].[AgentJobs](
	[ServerName] [nvarchar](128) NULL,
	[job_id] [uniqueidentifier] NOT NULL,
	[JobName] [sysname] NOT NULL,
	[enabled] [tinyint] NOT NULL,
	[description] [nvarchar](512) NULL,
	[Category] [sysname] NOT NULL,
	[date_created] [datetime] NOT NULL,
	[date_modified] [datetime] NOT NULL,
	[ScheduleEnabled] [int] NOT NULL,
	[ScheduleName] [sysname] NOT NULL,
	[ScheduleFrequency] [varchar](8000) NULL,
	[step_id] [int] NOT NULL,
	[step_name] [sysname] NOT NULL,
	[subsystem] [nvarchar](40) NOT NULL,
	[command] [nvarchar](max) NULL,
	[DatabaseName] [sysname] NULL,
	[FirstRecorded] [datetime] NULL,
	[LastRecorded] [datetime] NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_AgentJobs] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
))

GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'AgentJobs_Stage')
CREATE TABLE [Catalogue].[AgentJobs_Stage](
	[ServerName] [nvarchar](128) NOT NULL,
	[job_id] [uniqueidentifier] NOT NULL,
	[JobName] [sysname] NOT NULL,
	[enabled] [tinyint] NOT NULL,
	[description] [nvarchar](512) NULL,
	[Category] [sysname] NOT NULL,
	[date_created] [datetime] NOT NULL,
	[date_modified] [datetime] NOT NULL,
	[ScheduleEnabled] [int] NOT NULL,
	[ScheduleName] [sysname] NOT NULL,
	[ScheduleFrequency] [varchar](8000) NULL,
	[step_id] [int] NOT NULL,
	[step_name] [sysname] NOT NULL,
	[subsystem] [nvarchar](40) NOT NULL,
	[command] [nvarchar](max) NULL,
	[DatabaseName] [sysname] NULL
 CONSTRAINT [PK_AgentJobs_Stage] PRIMARY KEY CLUSTERED 
(
	[job_id],[ServerName],[step_id] ASC
))

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
	enabled = AgentJobs_Stage.enabled,
	description = AgentJobs_Stage.description,
	category = AgentJobs_Stage.Category,
	date_created = AgentJobs_Stage.date_created,
	date_modified = AgentJobs_Stage.date_modified,
	scheduleEnabled = AgentJobs_Stage.ScheduleEnabled,
	ScheduleName = AgentJobs_Stage.ScheduleName,
	ScheduleFrequency = AgentJobs_Stage.ScheduleFrequency,
	step_id = AgentJobs_Stage.step_id,
	step_name = AgentJobs_Stage.step_name,
	subsystem = AgentJobs_Stage.subsystem,
	command = AgentJobs_Stage.command,
	databaseName = AgentJobs_Stage.DatabaseName,
	LastRecorded = GETDATE()
FROM Catalogue.AgentJobs_Stage
WHERE	AgentJobs.ServerName = AgentJobs_Stage.ServerName
		AND AgentJobs.job_id = AgentJobs_Stage.job_id
		AND AgentJobs.step_id = AgentJobs_Stage.step_id

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.AgentJobs 
(ServerName,job_id,JobName,enabled,description,Category,date_created,date_modified,
ScheduleEnabled,ScheduleName,ScheduleFrequency,step_id, step_name,subsystem,command,DatabaseName,
FirstRecorded, LastRecorded)
SELECT	ServerName,
		job_id,
		JobName,
		enabled,
		description,
		Category,
		date_created,
		date_modified,
		ScheduleEnabled,
		ScheduleName,
		ScheduleFrequency,
		step_id,
		step_name,
		subsystem,
		command,
		DatabaseName,
		GETDATE(),
		GETDATE()
FROM Catalogue.AgentJobs_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.AgentJobs 
		WHERE job_id = AgentJobs_Stage.job_id 
		AND step_id = AgentJobs_Stage.step_id 
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
		Replicas.replica_server_name AS ServerName,
		replica_states.role_desc AS Role,
		AGs.automated_backup_preference_desc AS BackupPreference,
		Replicas.availability_mode_desc AS AvailabilityMode,
		Replicas.failover_mode_desc AS FailoverMode,
		Replicas.secondary_role_allow_connections_desc AS ConnectionsToSecondary
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
AND AGName IN (	SELECT AvailabilityGroups_Stage_sub.AGName 
				FROM AvailabilityGroups_Stage AvailabilityGroups_Stage_sub 
				WHERE AvailabilityGroups_Stage_sub.ServerName = AvailabilityGroups_Stage.ServerName 
					AND Role = 'Primary')

END
GO

-----------------------------------------Catalogue Users--------------------------------------------------------

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Users')
CREATE TABLE [Catalogue].[Users](
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[UserName] [sysname] NOT NULL,
	[sid] [varbinary](85) NULL,
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
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'Users_Stage')
CREATE TABLE [Catalogue].[Users_Stage](
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[UserName] [sysname] NOT NULL,
	[sid] [varbinary](85) NULL,
	[RoleName] [sysname] NULL,
	[MappedLoginName] [sysname] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL
 CONSTRAINT [PK_Users_Stage] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
))
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
		sid = Users_Stage.sid,
		LastRecorded = GETDATE(),
		MappedLoginName = Users_Stage.MappedLoginName
FROM Catalogue.Users_Stage
WHERE	Users.UserName = Users_Stage.UserName
		AND Users.ServerName = Users_Stage.ServerName
		AND Users.DBName = Users_Stage.DBName
		AND ISNULL(Users.RoleName ,'') = ISNULL(Users_Stage.RoleName,'')

--insert users that are unknown to the catlogue
INSERT INTO Catalogue.Users
(ServerName, DBName, UserName, sid, RoleName,MappedLoginName,FirstRecorded,LastRecorded)
SELECT ServerName,
		DBName,
		UserName,
		sid,
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

--------------------------------------Catalogue Explicit Permissions-----------------------------------------------
--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ExplicitPermissions')
CREATE TABLE [Catalogue].[ExplicitPermissions](
	[name] [sysname] NOT NULL,
	[permission_name] [nvarchar](128) NULL,
	[state_desc] [nvarchar](60) NULL,
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
GO

--create database staging table
IF NOT EXISTS (	SELECT 1
				FROM sys.tables
				JOIN sys.schemas ON tables.schema_id = schemas.schema_id
				WHERE schemas.name = 'Catalogue' AND tables.name = 'ExplicitPermissions_Stage')
CREATE TABLE [Catalogue].[ExplicitPermissions_Stage](
	[name] [sysname] NOT NULL,
	[permission_name] [nvarchar](128) NULL,
	[state_desc] [nvarchar](60) NULL,
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[MajorObject] [nvarchar](128) NULL,
	[MinorObject] [nvarchar](128) NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL
 CONSTRAINT [PK_ExplicitPermissions_Stage] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
))
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
	[name] [sysname] NOT NULL,
	[permission_name] [nvarchar](128) NULL,
	[state_desc] [nvarchar](60) NULL,
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

INSERT INTO #ExplicitPermissions_tmp(name,permission_name,state_desc,ServerName,DBName,MajorObject,MinorObject) 
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
SET		name = ExplicitPermissions_Stage.name,
		permission_name = ExplicitPermissions_Stage.permission_name,
		state_desc = ExplicitPermissions_Stage.state_desc,
		ServerName = ExplicitPermissions_Stage.ServerName,
		DBName = ExplicitPermissions_Stage.DBName,
		MajorObject = ExplicitPermissions_Stage.MajorObject,
		MinorObject = ExplicitPermissions_Stage.MinorObject,
		LastRecorded = GETDATE()
FROM Catalogue.ExplicitPermissions_Stage
WHERE ExplicitPermissions.name  = ExplicitPermissions_Stage.name
		AND ExplicitPermissions.permission_name = ExplicitPermissions_Stage.permission_name
		AND ExplicitPermissions.state_desc = ExplicitPermissions_Stage.state_desc
		AND ExplicitPermissions.ServerName = ExplicitPermissions_Stage.ServerName
		AND ExplicitPermissions.DBName  = ExplicitPermissions_Stage.DBName
		AND ISNULL(ExplicitPermissions.MajorObject,'') = ISNULL(ExplicitPermissions_Stage.MajorObject,'')
		AND ISNULL(ExplicitPermissions.MinorObject,'') = ISNULL(ExplicitPermissions_Stage.MinorObject,'')

--insert permissions that are unknown to the catlogue
INSERT INTO Catalogue.ExplicitPermissions
(name, permission_name,state_desc,ServerName,DBName,MajorObject,MinorObject,FirstRecorded,LastRecorded)
SELECT	name,
		permission_name,
		state_desc,
		ServerName,
		DBName,
		MajorObject,
		MinorObject,
		GETDATE(),
		GETDATE()
FROM Catalogue.ExplicitPermissions_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.ExplicitPermissions
		WHERE ExplicitPermissions.name = ExplicitPermissions_Stage.name
		AND ExplicitPermissions.permission_name = ExplicitPermissions_Stage.permission_name
		AND ExplicitPermissions.state_desc = ExplicitPermissions_Stage.state_desc
		AND ExplicitPermissions.ServerName = ExplicitPermissions_Stage.ServerName
		AND ExplicitPermissions.DBName = ExplicitPermissions_Stage.DBName
		AND ISNULL(ExplicitPermissions.MajorObject,'') = ISNULL(ExplicitPermissions_Stage.MajorObject,'')
		AND ISNULL(ExplicitPermissions.MinorObject, '') = ISNULL(ExplicitPermissions_Stage.MinorObject,''))


END

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
	InstanceName VARCHAR(128) NULL,
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

	INSERT INTO catalogue.configPosh (ParameterName,ParameterValue)
	VALUES	('CatalogueVersion', '0.1.0'),
			('AutoDiscoverInstances','0'),
			('DBAToolsRequirement', '0.9.385'),
			('AutoInstall', '0'),
			('AutoUpdate', '0'),
			('InstallationScriptPath', '{script path}')
END
GO







