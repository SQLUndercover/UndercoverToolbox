USE [master]
GO


/******************************************************************

Author: Adrian Buckman
Last Revision: David Fowler
Revision date: 12/08/2019
Version: 3

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
IF @ToDate  IS NULL BEGIN SET @ToDate = GETDATE() END  
  
SELECT   
Jobs.name,  
Jobs.job_id,
JobHistory.step_id,  
JobHistory.FailedRunDate,  
CAST(JobHistory.LastError AS VARCHAR(250)) AS LastError  
FROM msdb.dbo.sysjobs Jobs
--Get the most recent Failure Datetime for each failed job within @FromDate and @ToDate
CROSS APPLY (Select TOP 1 
			JobHistory.step_id,
			JobHistory.run_date,  
			CASE JobHistory.run_date WHEN 0 THEN NULL ELSE  
			CONVERT(datetime,   
			            STUFF(STUFF(CAST(JobHistory.run_date as nchar(8)), 7, 0, '-'), 5, 0, '-') + N' ' +   
			            STUFF(STUFF(SUBSTRING(CAST(1000000 + JobHistory.run_time as nchar(7)), 2, 6), 5, 0, ':'), 3, 0, ':'),   
			            120) END AS [FailedRunDate] ,
			[message] AS LastError  
			FROM msdb.dbo.sysjobhistory JobHistory  
			WHERE   
			run_status = 0   
			AND  Jobs.job_id = JobHistory.job_id  
			ORDER BY   
			[FailedRunDate] DESC,step_id DESC) JobHistory  
          
WHERE Jobs.enabled = 1  
AND JobHistory.FailedRunDate >= @FromDate AND JobHistory.FailedRunDate <= @ToDate  
--Check that each job has not succeeded since the last failure
AND NOT EXISTS (SELECT [LastSuccessfulrunDate]   
				FROM(  
				SELECT CASE JobHistory.run_date WHEN 0 THEN NULL ELSE  
				convert(datetime,   
				stuff(stuff(cast(JobHistory.run_date as nchar(8)), 7, 0, '-'), 5, 0, '-') + N' ' +   
				stuff(stuff(substring(cast(1000000 + JobHistory.run_time as nchar(7)), 2, 6), 5, 0, ':'), 3, 0, ':'),   
				 120) END AS [LastSuccessfulrunDate]   
				FROM msdb.dbo.sysjobhistory JobHistory  
				WHERE   
				run_status = 1  
				AND  Jobs.job_id = JobHistory.job_id  
				  ) JobHistory2  
WHERE JobHistory2.[LastSuccessfulrunDate] > JobHistory.[FailedRunDate])  
--Ensure that the job is not currently running
AND NOT EXISTS (SELECT session_id
				From msdb.dbo.sysjobactivity JobActivity
				where Jobs.job_id = JobActivity.job_id 
				AND stop_execution_date is null
				AND session_id = (Select MAX(session_id) From msdb.dbo.sysjobactivity JobActivity
				where Jobs.job_id = JobActivity.job_id)
				)  
--Only show failed jobs where the Failed step is NOT configured to quit reporting success on error
AND NOT EXISTS (SELECT 1
				FROM msdb..sysjobsteps ReportingSuccessSteps
				WHERE Jobs.job_id = ReportingSuccessSteps.job_id
				AND JobHistory.step_id = ReportingSuccessSteps.step_id
				AND on_fail_action = 1 -- quit job reporting success
				) 

  
ORDER BY name  ASC
END