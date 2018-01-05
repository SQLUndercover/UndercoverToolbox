USE [master];
GO
 
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************

Author: Adrian Buckman
Revision date: 07/08/2017
Version: 2

Description: Show all currently running agent jobs including:
Started by
Date and time the job started
Date and time the current job step started
Total job duration
Current step duration
Currently running step

© www.sqlundercover.com 


This script is for personal, educational, and internal 
corporate purposes, provided that this header is preserved. Redistribution or sale 
of this script,in whole or in part, is prohibited without the author's express 
written consent. 

The software is provided "as is", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. in no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in the
software.

******************************************************************/
 
 
CREATE PROCEDURE [dbo].[sp_RunningJobs]
AS
BEGIN
DECLARE @CurrentDatetime DATETIME= GETDATE();
IF OBJECT_ID('TempDB..#CurrentlyRunningJobs') IS NOT NULL
DROP TABLE #CurrentlyRunningJobs;
CREATE TABLE #CurrentlyRunningJobs
(job_id UNIQUEIDENTIFIER NOT NULL,
last_run_date INT NOT NULL,
last_run_time INT NOT NULL,
next_run_date INT NOT NULL,
next_run_time INT NOT NULL,
next_run_schedule_id INT NOT NULL,
requested_to_run INT NOT NULL,
request_source INT NOT NULL,
request_source_id SYSNAME NULL,
running INT NOT NULL,
current_step INT NOT NULL,
current_retry_attempt INT NOT NULL,
job_state INT NOT NULL
);
INSERT INTO #CurrentlyRunningJobs
EXECUTE master.dbo.xp_sqlagent_enum_jobs 1,'';
SELECT Jobs.Name AS JobName,
CASE
WHEN run_requested_source = 4
THEN 'User '+ISNULL('('+StartedUser+')', '')
ELSE 'Agent'
END AS StartedBy,
CONVERT(VARCHAR(20), start_execution_date, 113) AS DateTimeJobStarted,
CONVERT(VARCHAR(20), DATEADD(SECOND, DATEDIFF(SECOND, DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(SECOND, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), @CurrentDatetime - start_execution_date), CAST('1900-01-01 00:00:00.000' AS DATETIME)), @CurrentDatetime), 113) AS DateTimeStepStarted,
CASE
WHEN DATEDIFF(Second, start_execution_date, @CurrentDatetime) >= 86400
THEN CAST(DATEDIFF(Second, start_execution_date, @CurrentDatetime) / 86400 AS VARCHAR(7))+' Days '+RIGHT('0'+CAST(DATEDIFF(Second, start_execution_date, @CurrentDatetime) % 86400 / 3600 AS VARCHAR(2)), 2)+' Hours '+RIGHT('0'+CAST(DATEDIFF(Second, start_execution_date, @CurrentDatetime) % 3600 / 60 AS VARCHAR(2)), 2)+' Minutes '+RIGHT('0'+CAST(DATEDIFF(Second, start_execution_date, @CurrentDatetime) % 60 AS VARCHAR(2)), 2)+' Seconds '
ELSE RIGHT('0'+CAST(DATEDIFF(Second, start_execution_date, @CurrentDatetime) / 3600 AS VARCHAR(2)), 2)+' Hours '+RIGHT('0'+CAST(DATEDIFF(Second, start_execution_date, @CurrentDatetime) % 3600 / 60 AS VARCHAR(2)), 2)+' Minutes '+RIGHT('0'+CAST(DATEDIFF(Second, start_execution_date, @CurrentDatetime) % 60 AS VARCHAR(2)), 2)+' Seconds '
END AS TotalJobDuration,
CASE
WHEN DATEDIFF(Second, '1900-01-01 00:00:00.000', DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(Second, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), (CAST(@CurrentDatetime - start_execution_date AS DATETIME)))) >= 86400
THEN CAST(DATEDIFF(Second, '1900-01-01 00:00:00.000', DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(Second, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), (CAST(@CurrentDatetime - start_execution_date AS DATETIME))))/86400 AS VARCHAR(7))+' Days '+RIGHT('0'+CAST(DATEDIFF(Second, '1900-01-01 00:00:00.000', DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(Second, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), (CAST(@CurrentDatetime - start_execution_date AS DATETIME))))%86400/3600 AS VARCHAR(2)), 2)+' Hours '+RIGHT('0'+CAST(DATEDIFF(Second, '1900-01-01 00:00:00.000', DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(Second, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), (CAST(@CurrentDatetime - start_execution_date AS DATETIME))))%3600/60 AS VARCHAR(2)), 2)+' Minutes '+RIGHT('0'+CAST(DATEDIFF(Second, '1900-01-01 00:00:00.000', DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(Second, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), (CAST(@CurrentDatetime - start_execution_date AS DATETIME))))%60 AS VARCHAR(2)), 2)+' Seconds '
ELSE RIGHT('0'+CAST(DATEDIFF(Second, '1900-01-01 00:00:00.000', DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(Second, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), (CAST(@CurrentDatetime - start_execution_date AS DATETIME))))/3600 AS VARCHAR(2)), 2)+' Hours '+RIGHT('0'+CAST(DATEDIFF(Second, '1900-01-01 00:00:00.000', DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(Second, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), (CAST(@CurrentDatetime - start_execution_date AS DATETIME))))%3600/60 AS VARCHAR(2)), 2)+' Minutes '+RIGHT('0'+CAST(DATEDIFF(Second, '1900-01-01 00:00:00.000', DATEADD(SECOND, -ISNULL(PreviousStepDurationInSecs, DATEDIFF(Second, start_execution_date, ISNULL(last_executed_step_date, start_execution_date))), (CAST(@CurrentDatetime - start_execution_date AS DATETIME))))%60 AS VARCHAR(2)), 2)+' Seconds '
END AS TotalStepDuration,
CASE
WHEN Start_Execution_Date IS NOT NULL
AND Last_Executed_Step_ID IS NULL
AND Last_Executed_Step_date IS NULL
AND Stop_Execution_Date IS NULL
THEN 'Job Started at step '+CAST(RunningJobs.Current_step AS VARCHAR(3))+' but not completed'
WHEN Start_Execution_Date IS NOT NULL
AND Last_Executed_Step_ID IS NOT NULL
AND Last_Executed_Step_date IS NOT NULL
AND Stop_Execution_Date IS NULL
THEN 'Job Running on step '+CAST(RunningJobs.Current_step AS VARCHAR(2))
ELSE 'Finished'
END AS JobState
FROM msdb.dbo.sysjobs Jobs
INNER JOIN msdb.dbo.syscategories Categories ON Jobs.category_id = Categories.category_id
INNER JOIN msdb.dbo.sysjobactivity Activity ON Jobs.job_id = Activity.job_id
INNER JOIN
(
SELECT Job_id,
Current_step,
CASE
WHEN Request_Source = 4
THEN Request_Source_ID
END AS StartedUser
FROM #CurrentlyRunningJobs RunningJobs
WHERE running = 1
) RunningJobs ON RunningJobs.job_id = Jobs.job_id
CROSS APPLY
(
SELECT SUM(DATEPART(SECOND, Duration) + DATEPART(MINUTE, Duration) * 60 + DATEPART(HOUR, Duration) * 3600) AS PreviousStepDurationInSecs
FROM
(
SELECT CAST(STUFF(STUFF(SUBSTRING(CAST(1000000+JobHistory.run_duration AS NCHAR(7)), 2, 6), 5, 0, ':'), 3, 0, ':') AS TIME) AS Duration
FROM msdb..sysjobhistory JobHistory
WHERE job_id = Jobs.job_id
AND instance_ID >
(
SELECT TOP 1 instance_ID AS [LastJobCompletion]
FROM msdb..sysjobhistory JobHistory
WHERE job_id = Jobs.job_id
AND step_id = 0
ORDER BY instance_id DESC
)
) Runtimes
) Runtimes
WHERE start_execution_date IS NOT NULL
AND stop_execution_date IS NULL
AND session_id =
(
SELECT MAX(session_id)
FROM msdb.dbo.syssessions
)
AND Categories.name NOT LIKE 'REPL%' --Ignore any Replication jobs
ORDER BY TotalJobDuration DESC;
END;