USE [master]
GO


/******************************************************************

Author: Adrian Buckman
Revision date: 16/06/2017
Version: 1

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
 

CREATE PROCEDURE sp_FailedJobs
(
@FromDate DATETIME = NULL,
@ToDate DATETIME = NULL
)
AS
BEGIN
 
IF @FromDate IS NULL BEGIN SET @FromDate = DATEADD(Minute,-720,GETDATE()) END
IF @ToDate IS NULL BEGIN SET @ToDate = GETDATE() END
 
SELECT
Jobs.name,
JobHistory.step_id,
JobHistory.FailedRunDate,
CAST(JobHistory.LastError AS VARCHAR(250)) AS LastError
FROM msdb.dbo.sysjobs Jobs
CROSS APPLY (Select TOP 1 JobHistory.step_id,JobHistory.run_date,
CASE JobHistory.run_date WHEN 0 THEN NULL ELSE
convert(datetime,
stuff(stuff(cast(JobHistory.run_date as nchar(8)), 7, 0, '-'), 5, 0, '-') + N' ' +
stuff(stuff(substring(cast(1000000 + JobHistory.run_time as nchar(7)), 2, 6), 5, 0, ':'), 3, 0, ':'),
120) END AS [FailedRunDate] ,[Message] AS LastError
FROM msdb.dbo.sysjobhistory JobHistory
WHERE
Run_status = 0
and Jobs.job_id = JobHistory.job_id
ORDER BY
[FailedRunDate] DESC,step_id DESC) JobHistory
 
WHERE Jobs.enabled = 1
AND JobHistory.FailedRunDate >= @FromDate AND JobHistory.FailedRunDate <= @ToDate
AND NOT EXISTS (SELECT [LastSuccessfulrunDate]
FROM(
SELECT CASE JobHistory.run_date WHEN 0 THEN NULL ELSE
convert(datetime,
stuff(stuff(cast(JobHistory.run_date as nchar(8)), 7, 0, '-'), 5, 0, '-') + N' ' +
stuff(stuff(substring(cast(1000000 + JobHistory.run_time as nchar(7)), 2, 6), 5, 0, ':'), 3, 0, ':'),
120) END AS [LastSuccessfulrunDate]
FROM msdb.dbo.sysjobhistory JobHistory
WHERE
Run_status = 1
AND Jobs.job_id = JobHistory.job_id
) JobHistory2
WHERE JobHistory2.[LastSuccessfulrunDate] > JobHistory.[FailedRunDate])
AND NOT EXISTS (SELECT Session_id
From msdb.dbo.sysjobactivity JobActivity
where Jobs.job_id = JobActivity.job_id
AND stop_execution_date is null
AND SESSION_id = (Select MAX(Session_ID) From msdb.dbo.sysjobactivity JobActivity
where Jobs.job_id = JobActivity.job_id)
)
AND Jobs.Name != 'syspolicy_purge_history'
 
ORDER BY name
 
END