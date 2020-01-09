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
23/12/2019

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
ALTER TABLE Catalogue.ConfigPoSH
ALTER COLUMN ParameterValue VARCHAR(256)
GO

ALTER TABLE Catalogue.Logins_Stage
DROP CONSTRAINT PK_Logins_Stage
GO

ALTER TABLE Catalogue.Logins_Stage
DROP COLUMN ID
GO

ALTER TABLE Catalogue.Databases_Stage
ADD StateDesc NVARCHAR(60)
GO

ALTER TABLE Catalogue.Databases
ADD StateDesc NVARCHAR(60)
GO

ALTER TABLE Catalogue.Databases_Audit
ADD StateDesc NVARCHAR(60)
GO


------------------------------------------------------------------------
--ConfigModulesInstances

CREATE TABLE [Catalogue].[ConfigModulesInstances](
	[ServerName] [varchar](128) NULL,
	[ModuleName] [varchar](20) NULL,
	[Active] [bit] NULL
) ON [PRIMARY]
GO




----------------------------------------------------------------------
--ConfigModuleDefinitions
----------------------------------------------------------------------


CREATE TABLE [Catalogue].[ConfigModulesDefinitions](
	[ModuleID] [int] NOT NULL,
	[Online] [bit] NOT NULL,
	[GetDefinition] [varchar](max) NULL,
	[UpdateDefinition] [varchar](max) NULL,
	[GetURL] [varchar](2048) NULL,
	[UpdateURL] [varchar](2048) NULL,
PRIMARY KEY CLUSTERED 
(
	[ModuleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (1, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Databases
--Script: Get

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
		files.DatabaseSizeMB,
		databases.state_desc AS StateDesc
FROM sys.databases
LEFT OUTER JOIN sys.server_principals ON server_principals.sid = databases.owner_sid
LEFT OUTER JOIN sys.availability_replicas ON availability_replicas.replica_id = databases.replica_id
LEFT OUTER JOIN sys.availability_groups ON availability_groups.group_id = availability_replicas.group_id
JOIN	(SELECT database_id, (SUM(CAST (size AS BIGINT)) * 8)/1024 AS DatabaseSizeMB,STUFF((SELECT '', '' + files2.physical_name
				FROM sys.master_files files2
				WHERE files2.database_id = files1.database_id
				FOR XML PATH('''')
			), 1, 2, '''') AS FilePaths
		FROM sys.master_files files1
		GROUP BY database_id) files ON files.database_id = databases.database_id
END

', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
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
		StateDesc = Databases_Stage.StateDesc
FROM Catalogue.Databases_Stage
WHERE	Databases.ServerName = Databases_Stage.ServerName
		AND Databases.DBName = Databases_Stage.DBName

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Databases
(ServerName, DBName, DatabaseID, OwnerName, CompatibilityLevel, CollationName, RecoveryModelDesc, AGName,FilePaths,DatabaseSizeMB,FirstRecorded,LastRecorded, StateDesc)
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
		StateDesc
FROM Catalogue.Databases_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Databases
		WHERE DBName = Databases_Stage.DBName
		AND Databases.ServerName = Databases_Stage.ServerName)

END


', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetDatabases.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateDatabases.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (2, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Servers
--Script: Get

BEGIN


SELECT 
@@SERVERNAME AS ServerName, 
CAST(SERVERPROPERTY(''collation'') AS NVARCHAR(128)) AS Collation,
CAST(SERVERPROPERTY(''Edition'') AS NVARCHAR(128)) AS Edition, 
CAST(SERVERPROPERTY(''ProductVersion'') AS NVARCHAR(128)) AS VersionNo,
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
CAST(SERVERPROPERTY(''IsClustered'') AS BIT) AS IsClustered,
virtual_machine_type_desc AS VMType
FROM sys.dm_os_sys_info,
(
	SELECT [max worker threads],[cost threshold for parallelism],[max degree of parallelism],[min server memory (MB)],[max server memory (MB)]
	FROM 
	(SELECT name, CAST(value_in_use AS INT) AS value_in_use
	FROM sys.configurations
	WHERE name in (''max worker threads'',''cost threshold for parallelism'',''max degree of parallelism'',''min server memory (MB)'',''max server memory (MB)'')) AS Source
	PIVOT
	(
	MAX(value_in_use)
	FOR name IN ([max worker threads],[cost threshold for parallelism],[max degree of parallelism],[min server memory (MB)],[max server memory (MB)])
	)AS PivotTable
) AS config
END
', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Servers
--Script: Update


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
', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetServers.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateServers.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (3, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Logins
--Script: Get

BEGIN

--get all logins on server
SELECT	@@SERVERNAME AS ServerName,
		principals_logins.name AS LoginName, 
		principals_logins.sid AS SID, 
		principals_roles.name AS RoleName,
		principals_logins.is_disabled AS IsDisabled,
		CAST(LOGINPROPERTY(principals_logins.name, ''PasswordHash'') AS VARBINARY(256))AS PasswordHash,  -- **the varbinary of password hash is erroring in powershell, something to be looked at
		principals_logins.type_desc AS LoginType
FROM sys.server_role_members
RIGHT OUTER JOIN sys.server_principals principals_roles 
	ON server_role_members.role_principal_id = principals_roles.principal_id
RIGHT OUTER JOIN sys.server_principals principals_logins 
	ON server_role_members.member_principal_id = principals_logins.principal_id
WHERE principals_logins.type IN (''G'',''S'',''U'') --include only windows groups, windows logins and SQL logins
ORDER BY principals_logins.name

END
', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Logins
--Script: Update


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
		AND ISNULL(Logins.RoleName, '''') = ISNULL([Logins_Stage].RoleName, '''')

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
		WHERE Logins.ServerName = [Logins_Stage].ServerName
		AND Logins.LoginName = [Logins_Stage].LoginName
		AND ISNULL(Logins.RoleName, '''') = ISNULL([Logins_Stage].RoleName, ''''))

END
', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetLogins.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateLogins.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (4, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: AgentJobs
--Script: Get

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
            WHEN 1 THEN ''Occurs on '' + STUFF(RIGHT(active_start_date, 4), 3,0, ''/'') + ''/'' + LEFT(active_start_date, 4) + '' at ''
                + REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime) /* hh:mm:ss 24H */, 9), 14), '':000'', '' '') /* HH:mm:ss:000AM/PM then replace the :000 with space.*/
            WHEN 4 THEN ''Occurs every '' + CAST(freq_interval as varchar(10)) + '' day(s) ''
                + CASE freq_subday_type
                    WHEN 1 THEN ''at ''+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                    WHEN 2 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' second(s)''
                    WHEN 4 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' minute(s)''
                    WHEN 8 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' hour(s)''
                    ELSE '''' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN '' between ''+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                        + '' and ''
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_end_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                    ELSE ''''
                    END
            WHEN 8 THEN ''Occurs every '' + CAST(freq_recurrence_factor as varchar(10))
                + '' week(s) on ''
                +
                REPLACE( CASE WHEN freq_interval&1 = 1 THEN ''Sunday, '' ELSE '''' END
                + CASE WHEN freq_interval&2 = 2 THEN ''Monday, '' ELSE '''' END
                + CASE WHEN freq_interval&4 = 4 THEN ''Tuesday, '' ELSE '''' END
                + CASE WHEN freq_interval&8 = 8 THEN ''Wednesday, '' ELSE '''' END
                + CASE WHEN freq_interval&16 = 16 THEN ''Thursday, '' ELSE '''' END
                + CASE WHEN freq_interval&32 = 32 THEN ''Friday, '' ELSE '''' END
                + CASE WHEN freq_interval&64 = 64 THEN ''Saturday, '' ELSE '''' END
                + ''|'', '', |'', '' '') /* get rid of trailing comma */

                + CASE freq_subday_type
                    WHEN 1 THEN ''at ''+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                    WHEN 2 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' second(s)''
                    WHEN 4 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' minute(s)''
                    WHEN 8 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' hour(s)''
                    ELSE '''' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN '' between ''+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                        + '' and ''
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_end_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                    ELSE ''''
                    END
            WHEN 16 THEN ''Occurs every '' + CAST(freq_recurrence_factor as varchar(10))
                + '' month(s) on ''
                + ''day '' + CAST(freq_interval as varchar(10)) + '' of that month '' 
                + CASE freq_subday_type
                    WHEN 1 THEN ''at ''+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                    WHEN 2 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' second(s)''
                    WHEN 4 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' minute(s)''
                    WHEN 8 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' hour(s)''
                    ELSE '''' 
                    END
                + CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN '' between ''+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                        + '' and ''
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_end_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                    ELSE ''''
                    END
            WHEN 32 THEN ''Occurs '' 
                + CASE freq_relative_interval
                    WHEN 1 THEN ''every first ''
                    WHEN 2 THEN ''every second ''
                    WHEN 4 THEN ''every third ''
                    WHEN 8 THEN ''every fourth ''
                    WHEN 16 THEN ''on the last ''
                    END
                + CASE freq_interval 
                    WHEN 1 THEN ''Sunday''
                    WHEN 2 THEN ''Monday''
                    WHEN 3 THEN ''Tuesday''
                    WHEN 4 THEN ''Wednesday''
                    WHEN 5 THEN ''Thursday''
                    WHEN 6 THEN ''Friday''
                    WHEN 7 THEN ''Saturday''
                    WHEN 8 THEN ''day''
                    WHEN 9 THEN ''weekday''
                    WHEN 10 THEN ''weekend''
                    END
                + '' of every '' + CAST(freq_recurrence_factor as varchar(10)) + '' month(s) ''
                + CASE freq_subday_type
                    WHEN 1 THEN ''at ''+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                    WHEN 2 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' second(s)''
                    WHEN 4 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' minute(s)''
                    WHEN 8 THEN ''every '' + CAST(freq_subday_interval as varchar(10)) + '' hour(s)''
                    ELSE '''' 
                    END
                + CASE 
                    WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
                        THEN '' between ''+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_start_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                        + '' and ''
                        + LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT(''000000'' + CAST(active_end_time as varchar(10)), 6), 3, 0, '':'' ), 6, 0, '':'' ), 8) as datetime), 9), 14), '':000'', '' ''))
                    ELSE ''''
                    END
            WHEN 64 THEN ''Runs when the SQL Server Agent service starts''
            WHEN 128 THEN ''Runs when the computer is idle''
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
', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: AgentJobs
--Script: Update


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
', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetAgentJobs.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateAgentJobs.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (5, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: AvailabilityGroups
--Script: Get

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

', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: AvailabilityGroups
--Script: Update


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
--					AND Role = ''Primary'')

END
', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetAvailabilityGroups.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateAvailabilityGroups.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (6, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Users
--Script: Get


BEGIN

DECLARE @DBName SYSNAME
DECLARE @cmd NVARCHAR(4000)

IF OBJECT_ID(''tempdb.dbo.#Users_Tmp'') IS NOT NULL
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
	''USE '' + QUOTENAME(@DBName) + ''

	SELECT	@@SERVERNAME AS ServerName,
			DB_NAME() AS DBName,
			principals_logins.name AS UserName, 
			principals_logins.sid AS SID, 
			principals_roles.name AS RoleName,
			ISNULL(server_principals.name, ''''***ORPHANED USER***'''') AS MappedLoginName
	FROM sys.database_role_members
	RIGHT OUTER JOIN sys.database_principals principals_roles 
		ON database_role_members.role_principal_id = principals_roles.principal_id
	RIGHT OUTER JOIN sys.database_principals principals_logins 
		ON database_role_members.member_principal_id = principals_logins.principal_id
	LEFT OUTER JOIN sys.server_principals 
		ON server_principals.sid = principals_logins.sid
	WHERE principals_logins.type IN (''''G'''',''''S'''',''''U'''') --include only windows groups, windows logins and SQL logins
		AND principals_logins.sid IS NOT NULL 
	ORDER BY principals_logins.name''

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
', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Users
--Script: Update



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
		AND ISNULL(Users.RoleName ,'''') = ISNULL(Users_Stage.RoleName,'''')

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
		AND ISNULL(RoleName,'''') = ISNULL(RoleName,''''))

END
', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetUsers.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateUsers.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (7, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: ExplicitPermissions
--Script: Get

BEGIN

DECLARE @DBName SYSNAME
DECLARE @cmd NVARCHAR(4000)

IF OBJECT_ID(''tempdb.dbo.#ExplicitPermissions_tmp'') IS NOT NULL
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
''USE '' + QUOTENAME(@DBName) + ''

SELECT	database_principals.name,
		database_permissions.permission_name,
		database_permissions.state_desc,
		@@SERVERNAME AS ServerName,
		DB_Name() AS DBName,
		OBJECT_NAME(database_permissions.major_id) AS MajorObject,
		OBJECT_NAME(database_permissions.minor_id) AS MinorObject
FROM sys.database_principals
JOIN sys.database_permissions ON database_principals.principal_id = database_permissions.grantee_principal_id
WHERE database_principals.name != ''''public''''''

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
', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: ExplicitPermissions
--Script: Update


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
		AND ISNULL(ExplicitPermissions.MajorObject,'''') = ISNULL(ExplicitPermissions_Stage.MajorObject,'''')
		AND ISNULL(ExplicitPermissions.MinorObject,'''') = ISNULL(ExplicitPermissions_Stage.MinorObject,'''')

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
		AND ISNULL(ExplicitPermissions.MajorObject,'''') = ISNULL(ExplicitPermissions_Stage.MajorObject,'''')
		AND ISNULL(ExplicitPermissions.MinorObject, '''') = ISNULL(ExplicitPermissions_Stage.MinorObject,''''))


END
', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetExplicitPermissions.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateExplicitPermissions.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (8, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: ADGroups
--Script: Get

BEGIN

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

END
', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: ADGroups
--Script: Update


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
', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetADGroups.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateADGroups.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (9, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: LinkedServers
--Script: Get

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
', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Linked Server
--Script: Update


BEGIN

--temp table used to prevent duplicate entries from the denormalised stage table
IF OBJECT_ID(''tempdb.dbo.#LinkedServers'') IS NOT NULL
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
	AND ISNULL(LinkedServers_Users.LocalUser, '''') = ISNULL(LinkedServers_Stage.LocalUser,'''')

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
	AND ISNULL(LinkedServers_Users.LocalUser,'''') = ISNULL(LinkedServers_Stage.LocalUser,''''))

END

', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetLinkedServers.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateLinkedServers.sql')
GO

INSERT [Catalogue].[ConfigModulesDefinitions] ([ModuleID], [Online], [GetDefinition], [UpdateDefinition], [GetURL], [UpdateURL]) VALUES (10, 1, N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
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

		SET @cmd = N''USE '' + QUOTENAME(@DBName) + N'';
			SELECT	@@SERVERNAME AS NameServer,
			DB_NAME() AS DatabaseName, 
			schemas.name AS SchemaName, 
			tables.name AS TableName,
			CAST((
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
			) AS XML) Cols
			FROM sys.tables
			JOIN sys.schemas ON tables.schema_id = schemas.schema_id''
	
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
', N'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
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


', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetTables.sql', N'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateTables.sql')
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
GO


------------------------------------
--Update Version Info

UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '0.4.0'
WHERE ParameterName = 'CatalogueVersion'
GO

UPDATE Catalogue.ConfigPoSH
SET ParameterValue = 'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/Updates/'
WHERE ParameterName = 'InstallationScriptPath'
GO

Update Catalogue.ConfigPoSH
SET ParameterValue = 1
WHERE ParameterName = 'AutoUpdate'
GO



CREATE PROC Catalogue.GetModuleDetails (@ServerName VARCHAR(128))
AS

BEGIN

SELECT	ConfigModules.[ModuleName], 
		ConfigModules.[GetProcName], 
		ConfigModules.[UpdateProcName], 
		ConfigModules.[StageTableName], 
		ConfigModules.[MainTableName], 
		ConfigModulesDefinitions.[GetDefinition],
		ConfigModulesDefinitions.[UpdateDefinition],
		ConfigModulesDefinitions.[GetURL],
		ConfigModulesDefinitions.[UpdateURL],
		ConfigModulesDefinitions.[Online], 
		ConfigModulesDefinitions.[ModuleID]
FROM	Catalogue.ConfigModules 
JOIN Catalogue.ConfigModulesDefinitions 
		ON ConfigModules.ID = ConfigModulesDefinitions.ModuleID
LEFT OUTER JOIN Catalogue.ConfigModulesInstances
		ON Catalogue.ConfigModules.ModuleName = ConfigModulesInstances.ModuleName 
		AND ConfigModulesInstances.ServerName = @ServerName
WHERE ISNULL(ConfigModulesInstances.Active, ConfigModules.Active) = 1

END
GO


--Services Module


CREATE TABLE Catalogue.Services_Stage
(
	ServerName		SYSNAME,
	ServiceName		NVARCHAR(256),
	StartupType		NVARCHAR(256),
	StatusDesc		NVARCHAR(256),
	ServiceAccount	NVARCHAR(256),
	InstantFileInit	NVARCHAR(1)
)
GO

CREATE TABLE Catalogue.Services
(
	ServerName		SYSNAME,
	ServiceName		NVARCHAR(256),
	StartupType		NVARCHAR(256),
	StatusDesc		NVARCHAR(256),
	ServiceAccount	NVARCHAR(256),
	InstantFileInit	NVARCHAR(1),
	FirstRecorded	DATETIME,
	LastRecorded	DATETIME,
	CONSTRAINT PK_Services PRIMARY KEY (ServerName, ServiceName)
)
GO

CREATE TABLE Catalogue.Services_Audit
(
	ServerName		SYSNAME,
	ServiceName		NVARCHAR(256),
	StartupType		NVARCHAR(256),
	StatusDesc		NVARCHAR(256),
	ServiceAccount	NVARCHAR(256),
	InstantFileInit	NVARCHAR(1),
	AuditDate	DATETIME
)
GO

INSERT INTO Catalogue.ConfigModules (ModuleName,GetProcName,UpdateProcName,StageTableName,MainTableName,Active)
VALUES ('Services','GetServices','UpdateServices','Services_Stage','Services',1)
GO




DECLARE @ModuleID INT

SELECT @ModuleID = ID
FROM	Catalogue.ConfigModules
WHERE ConfigModules.ModuleName = 'Services'



INSERT INTO Catalogue.ConfigModulesDefinitions (ModuleID,Online,GetDefinition,UpdateDefinition,GetURL,UpdateURL)
VALUES	(@ModuleID,
		1,
		'--Undercover Catalogue
		--David Fowler
		--Version 0.4.0 - 10 December 2019
		--Module: Services
		--Script: Get

		SELECT	@@SERVERNAME AS ServerName, 
				servicename AS ServiceName, 
				startup_type_desc AS StartupType, 
				status_desc AS StatusDesc, 
				service_account AS ServiceAccount, 
				instant_file_initialization_enabled AS InstantFileInit
		FROM sys.dm_server_services
		',
		'--Undercover Catalogue
		--David Fowler
		--Version 0.4.0 - 10 December 2019
		--Module: Services
		--Script: Update

		--update where known to catalogue
		UPDATE Catalogue.Services
		SET		ServerName = Services_Stage.ServerName,
				ServiceName = Services_Stage.ServiceName,
				StartupType = Services_Stage.StartupType,
				StatusDesc = Services_Stage.StatusDesc,
				ServiceAccount = Services_Stage.ServiceAccount,
				InstantFileInit = Services_Stage.InstantFileInit,
				LastRecorded = GETDATE()
		FROM	Catalogue.Services_Stage
		WHERE	Services.ServerName = Services_Stage.ServerName
		AND		Services.ServiceName = Services_Stage.ServiceName

		--insert where not known to catalogue
		INSERT INTO Catalogue.Services 
		(ServerName, ServiceName, StartupType,StatusDesc, ServiceAccount, InstantFileInit, FirstRecorded, LastRecorded)
		SELECT	ServerName,
				ServiceName,
				StartupType,
				StatusDesc,
				ServiceAccount, 
				InstantFileInit, 
				GETDATE(),
				GETDATE()
		FROM	Catalogue.Services_Stage
		WHERE NOT EXISTS 
		(SELECT 1 FROM Catalogue.Services
		WHERE	Services.ServerName = Services_Stage.ServerName
		AND		Services.ServiceName = Services_Stage.ServiceName)',
		'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetServices.sql',
		'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateServices.sql')

GO





CREATE TRIGGER [Catalogue].[AuditServices]
ON [Catalogue].Services
AFTER UPDATE
AS
BEGIN
		--audit old record
		INSERT INTO [Catalogue].[Services_Audit]
		([ServerName], [ServiceName], [StartupType], [StatusDesc], [ServiceAccount], [InstantFileInit], [AuditDate])
		SELECT	[ServerName], 
				[ServiceName], 
				[StartupType], 
				[StatusDesc], 
				[ServiceAccount], 
				[InstantFileInit], 
				GETDATE()
			FROM deleted
			WHERE EXISTS (SELECT 1 
						  FROM inserted 
						  WHERE CHECKSUM(	inserted.[StartupType], 
											inserted.[StatusDesc], 
											inserted.[ServiceAccount], 
											inserted.[InstantFileInit])
								!= 
								CHECKSUM(	deleted.[StartupType], 
											deleted.[StatusDesc], 
											deleted.[ServiceAccount],
											deleted.[InstantFileInit])
							AND deleted.[ServiceName] = inserted.[ServiceName]
							AND deleted.[ServerName] = inserted.[ServerName])
END
GO

--enhanced services module - this on piggy backs on the services module's tables.  
--The code's a little dirty and it breaks out into xp_cmdshell so starts off disabled by default

INSERT INTO Catalogue.ConfigModules (ModuleName,GetProcName,UpdateProcName,StageTableName,MainTableName,Active)
VALUES ('ServicesEnhanced','GetServicesEnhanced','UpdateServicesEnhanced','Services_Stage','Services',0)
GO


DECLARE @ModuleID INT

SELECT @ModuleID = ID
FROM	Catalogue.ConfigModules
WHERE ConfigModules.ModuleName = 'ServicesEnhanced'


INSERT INTO Catalogue.ConfigModulesDefinitions (ModuleID,Online,GetDefinition,UpdateDefinition,GetURL,UpdateURL)
VALUES	(@ModuleID,
		1,'--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 11 December 2019
--Module: ServicesEnhanced
--Script: Get

IF (OBJECT_ID(''tempdb.dbo.#RawServices'') IS NOT NULL)
DROP TABLE #RawServices

IF (OBJECT_ID(''tempdb.dbo.#Services'') IS NOT NULL)
DROP TABLE #Services

DECLARE @ServiceName VARCHAR(256)
DECLARE @cmd NVARCHAR(500)

CREATE TABLE #RawServices
(	ServiceName VARCHAR(256) NULL,
	RowNo INT IDENTITY(1,1))

CREATE TABLE #Services
(
    ServerName SYSNAME NULL,
    ServiceName NVARCHAR(256) NULL,
    StartupType NVARCHAR(256) NULL,
    StatusDesc NVARCHAR(256) NULL,
    ServiceAccount NVARCHAR(256) NULL,
    InstantFileInit INT NULL
)


--populate #RawServices with SQL related services

INSERT INTO #RawServices(ServiceName)
EXEC xp_cmdshell ''sc query type= service state= all''


--sanitise data
DELETE FROM #RawServices 
WHERE	ServiceName IS NULL
	OR	(ServiceName NOT LIKE ''SERVICE_NAME:%'' AND ServiceName NOT LIKE ''%STATE%:%'')

UPDATE #RawServices
SET ServiceName = CASE	WHEN CHARINDEX(''RUNNING'', ServiceName) > 0 THEN ''Running''
						WHEN CHARINDEX(''STOPPED'', ServiceName) > 0 THEN ''Stopped''
						ELSE ''Other'' 
				END
WHERE ServiceName NOT LIKE ''SERVICE_NAME:%''

UPDATE #RawServices
SET ServiceName = REPLACE(ServiceName, ''SERVICE_NAME: '','''')

--Get running state
INSERT INTO #Services(ServerName,ServiceName,StatusDesc)
SELECT @@SERVERNAME, ServiceName, State
FROM
	(SELECT ServiceName, ROW_NUMBER() OVER (ORDER BY RowNo) AS ServiceID 
	FROM #RawServices
	WHERE ServiceName NOT IN (''RUNNING'',''STOPPED'',''START_PENDING'',''STOP_PENDING'',''UNKNOWN'')) AS ServicesNames
JOIN 
	(SELECT ServiceName AS State, ROW_NUMBER() OVER (ORDER BY RowNo) AS ServiceID 
	FROM #RawServices
	WHERE ServiceName IN (''RUNNING'',''STOPPED'',''START_PENDING'',''STOP_PENDING'',''UNKNOWN'')) AS States ON States.ServiceID = ServicesNames.ServiceID

--remove the services that we''re no worried about

DELETE FROM #Services
WHERE   ServiceName NOT LIKE ''MS%OLAP%''
    AND  ServiceName NOT LIKE ''MsDtsServer%''
    AND  ServiceName != ''SQLServerReportingServices''
    AND  ServiceName NOT LIKE ''ReportServer%''
    AND  ServiceName != ''SQL Server Distributed Replay Client''
    AND  ServiceName != ''SQL Server Distributed Replay Controller''



DECLARE ServicesCur CURSOR STATIC FORWARD_ONLY FOR
SELECT ServiceName
FROM #Services

OPEN ServicesCur

--fetch service details
FETCH NEXT FROM ServicesCur INTO @ServiceName

WHILE @@FETCH_STATUS = 0
BEGIN

    TRUNCATE TABLE #RawServices

	SET @cmd = ''sc qc "'' + @ServiceName + ''"''

    INSERT #RawServices(ServiceName)
	EXEC xp_cmdshell @cmd

    --Update with Startup Type
    UPDATE #Services
    SET StartupType = CASE  WHEN CHARINDEX(''DISABLED'', RawServices.ServiceName) > 0 THEN ''Disabled''
                            WHEN CHARINDEX(''AUTO_START'', RawServices.ServiceName) > 0 THEN ''Automatic''
                            WHEN CHARINDEX(''DEMAND_START'', RawServices.ServiceName) > 0 THEN ''Manual''
                            ELSE ''Other''
                        END
    FROM #RawServices RawServices
    WHERE RawServices.ServiceName LIKE ''%START_TYPE%''
    AND #Services.ServiceName = @ServiceName

    --Update with Service Account
    UPDATE #Services
    SET ServiceAccount = REPLACE(RawServices.ServiceName,''        SERVICE_START_NAME : '', '''')
    FROM #RawServices RawServices
    WHERE RawServices.ServiceName LIKE ''%SERVICE_START_NAME%''
    AND #Services.ServiceName = @ServiceName


    --Update with service display name
    UPDATE #Services
    SET ServiceName = REPLACE(RawServices.ServiceName, ''        DISPLAY_NAME       : '','''')
    FROM #RawServices RawServices
    WHERE RawServices.ServiceName LIKE ''%DISPLAY_NAME%:%''
    AND #Services.ServiceName = @ServiceName


FETCH NEXT FROM ServicesCur INTO @ServiceName

END

CLOSE ServicesCur
DEALLOCATE ServicesCur

SELECT  ServerName,
        ServiceName,
        StartupType,
        StatusDesc,
        ServiceAccount,
        ''N'' AS InstantFileInit 
FROM #Services

',
		'--Undercover Catalogue
		--David Fowler
		--Version 0.4.0 - 10 December 2019
		--Module: Services
		--Script: Update

		--update where known to catalogue
		UPDATE Catalogue.Services
		SET		ServerName = Services_Stage.ServerName,
				ServiceName = Services_Stage.ServiceName,
				StartupType = Services_Stage.StartupType,
				StatusDesc = Services_Stage.StatusDesc,
				ServiceAccount = Services_Stage.ServiceAccount,
				InstantFileInit = Services_Stage.InstantFileInit,
				LastRecorded = GETDATE()
		FROM	Catalogue.Services_Stage
		WHERE	Services.ServerName = Services_Stage.ServerName
		AND		Services.ServiceName = Services_Stage.ServiceName

		--insert where not known to catalogue
		INSERT INTO Catalogue.Services 
		(ServerName, ServiceName, StartupType,StatusDesc, ServiceAccount, InstantFileInit, FirstRecorded, LastRecorded)
		SELECT	ServerName,
				ServiceName,
				StartupType,
				StatusDesc,
				ServiceAccount, 
				InstantFileInit, 
				GETDATE(),
				GETDATE()
		FROM	Catalogue.Services_Stage
		WHERE NOT EXISTS 
		(SELECT 1 FROM Catalogue.Services
		WHERE	Services.ServerName = Services_Stage.ServerName
		AND		Services.ServiceName = Services_Stage.ServiceName)',
		'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/GetServicesEnhanced.sql',
		'https://raw.githubusercontent.com/SQLUndercover/UndercoverToolbox/master/SQLUndercoverCatalogue/ModuleDefinitions/UpdateServicesEnhanced.sql')

GO

