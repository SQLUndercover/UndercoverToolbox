/*
Managing Agent Jobs on Availability Group Servers
David Fowler
16/01/2020

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

*/

--category enabeld jobs

------------------------------------------------------------------------------------------------------------------------------

--create job categories

IF OBJECT_ID('tempdb..#Cats') IS NOT NULL
DROP TABLE #Cats

IF OBJECT_ID('tempdb..#Cmds') IS NOT NULL
DROP TABLE #Cmds

--create temp tables
CREATE TABLE #Cats
(CatName VARCHAR(35))

CREATE TABLE #Cmds
(Cmd VARCHAR(4000))

--insert category prefixes
INSERT INTO #Cats
VALUES ('Execute On Primary Only: '),
('Execute On Secondary Only: '),
('Execute On All Nodes: ')

--fetch all ags and build up category names
INSERT INTO #Cmds
SELECT 'EXEC msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''' + CatName + name + ''''
from sys.availability_groups, #Cats

INSERT INTO #Cmds
SELECT 'EXEC msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''' + CatName + 'All AGs'''
from #Cats

INSERT INTO #Cmds
VALUES ('EXEC msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Execute On Disabled''')



--cursor for commands
DECLARE CmdCur CURSOR FOR
SELECT Cmd
FROM #Cmds

DECLARE @Command VARCHAR(4000)

OPEN CmdCur

FETCH NEXT FROM CmdCur INTO @Command

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC (@Command)
	FETCH NEXT FROM CmdCur INTO @Command
END

CLOSE CmdCur
DEALLOCATE CmdCur


------------------------------------------------------------------------------------------------
------------------------------Create Enable\Disable Proc----------------------------------------
------------------------------------------------------------------------------------------------

 USE master
 GO

 --create maintenance schema is not already exists

CREATE PROC EnableDisableJobs
AS

BEGIN

IF OBJECT_ID('tempdb..#JobList') IS NOT NULL
	DROP TABLE #JobList

CREATE TABLE #JobList
(JobId UNIQUEIDENTIFIER,
AGName SYSNAME,
ReplicaName SYSNAME,
AGRole VARCHAR(120),
AGName_Cat VARCHAR(120),
State_Cat VARCHAR(120),
IsEnabled BIT,
EnableFlag BIT)


--get status of AGs and job parameters
INSERT INTO #JobList (JobId,AGName,ReplicaName,AGRole,AGName_Cat,State_Cat,IsEnabled)
SELECT	sysjobs.job_id AS JobId,
		AGs.name AS AGName,
		Replicas.replica_server_name AS ReplicaName,
		ReplicaStats.role_desc AS AGRole,
		CASE 
			WHEN syscategories.name = 'Execute On Disabled' THEN 'All AGs'
			ELSE SUBSTRING(syscategories.name,CHARINDEX(':',syscategories.name,0) + 2,LEN(syscategories.name))
		END AS AGName_Cat,
		CASE 
			WHEN syscategories.name = 'Execute On Disabled' THEN 'Disabled'
			ELSE REPLACE(SUBSTRING(syscategories.name,12,CHARINDEX(':',syscategories.name,0) - 12),' Only','')
		END AS State_Cat,
		sysjobs.enabled
FROM msdb.dbo.sysjobs
JOIN msdb.dbo.syscategories ON syscategories.category_id = sysjobs.category_id,
sys.availability_groups AGs
JOIN sys.availability_replicas Replicas ON AGs.group_id = Replicas.group_id
JOIN sys.dm_hadr_availability_replica_states ReplicaStats ON ReplicaStats.replica_id = Replicas.replica_id
WHERE syscategories.name LIKE 'Execute On%'
AND Replicas.replica_server_name = @@SERVERNAME


--remove rows where AGs don't match
DELETE FROM #JobList
WHERE AGName != AGName_Cat
	 AND AGName_Cat != 'All AGs'


--set EnableFlag
UPDATE #JobList
SET EnableFlag = CASE 
					WHEN State_Cat = 'Disabled' THEN '0'
					WHEN State_Cat = 'All Nodes' THEN '1'
					WHEN AGrole = State_Cat THEN '1'
					WHEN AGrole != State_Cat THEN '0'
				END 


--create alter job statements and cursor through them
DECLARE CmdCur CURSOR STATIC FORWARD_ONLY FOR
SELECT DISTINCT 'USE msdb EXEC sp_update_job @job_id = ''' + CAST(JobId AS VARCHAR(50)) + ''', @Enabled = ' + CAST(EnableFlag AS CHAR(1))
FROM #JobList
WHERE IsEnabled != EnableFlag --ignore jobs that don't need an enable state change


OPEN CmdCur

DECLARE @Cmd VARCHAR(8000)

FETCH NEXT FROM CmdCur INTO @Cmd

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC (@cmd)
	FETCH NEXT FROM CmdCur INTO @Cmd
END

CLOSE CmdCur
DEALLOCATE CmdCur

END



GO



---------------------------------------------------------------------------------------
----------------------CREATE ENABLE\DISABLE AGENT JOB----------------------------------
---------------------------------------------------------------------------------------

/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.5634)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [msdb]
GO

/****** Object:  Job [_Enable\Disable Jobs]    Script Date: 6/26/2018 10:26:57 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Execute On All Nodes: All AGs]    Script Date: 6/26/2018 10:26:57 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Execute On All Nodes: All AGs' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Execute On All Nodes: All AGs'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'_Enable\Disable Jobs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'enable or disable agent job dependant on the job''s category', 
		@category_name=N'Execute On All Nodes: All AGs', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [enable or disable jobs]    Script Date: 6/26/2018 10:26:57 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'enable or disable jobs', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC EnableDisableJobs', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'5 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180626, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

