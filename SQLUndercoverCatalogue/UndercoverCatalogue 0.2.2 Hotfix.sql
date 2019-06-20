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

USE [SQLUndercover]
GO

ALTER TABLE [Catalogue].[Users_Stage] DROP CONSTRAINT PK_Users_Stage
ALTER TABLE [Catalogue].[Users_Stage] DROP COLUMN ID
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

--update version number
UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '0.2.2'
WHERE ParameterName = 'CatalogueVersion'

--update 
UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '1.0.0'
WHERE ParameterName = 'DBAToolsRequirement'