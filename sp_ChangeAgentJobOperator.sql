USE [master]
GO


/******************************************************************

Author: Adrian Buckman
Revision date: 14/09/2017
Version: 1

© www.sqlundercover.com 

http://sqlundercover.com/2017/09/14/undercover-toolbox-sp_changeagentjoboperator-scripting-out-change-of-notification-operator-deleting-andor-creating/

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
 
SET ANSI_NULLS ON
GO
 
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[sp_ChangeAgentJobOperator]
(
@OldOperatorName NVARCHAR(128),
@NewOperatorName NVARCHAR(128),
@CreateNewOperatorIfNotExists BIT = 0,
@EmailAddress NVARCHAR(128) = NULL,
@DeleteOldOperator BIT = 0
)
AS
BEGIN
SET NOCOUNT ON;
 
IF EXISTS (SELECT Name FROM msdb.dbo.sysoperators WHERE name = @OldOperatorName)
BEGIN
    IF EXISTS (SELECT Name FROM msdb.dbo.sysoperators WHERE name = @NewOperatorName) OR @NewOperatorName IS NULL
        BEGIN
 
            IF OBJECT_ID('TempDB..#AgentJobs') IS NOT NULL
            DROP TABLE #AgentJobs;
 
            CREATE TABLE #AgentJobs
            (
            job_id uniqueidentifier NOT NULL
            ,name nvarchar(128) NOT NULL
            ,notify_level_email int NOT NULL
            ,notify_level_netsend int NOT NULL
            ,notify_level_page int NOT NULL
            );
 
            INSERT INTO #AgentJobs
            EXEC msdb.dbo.sp_help_operator_jobs @Operator_name= @OldOperatorName;
 
                IF @DeleteOldOperator = 1
                BEGIN
 
                        DECLARE @FailSafeOperator NVARCHAR(128)
                        EXEC SYS.XP_INSTANCE_REGREAD N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertFailSafeOperator',
                        @FailSafeOperator output
 
                        IF (@FailSafeOperator != @OldOperatorName OR @FailSafeOperator IS NULL)
                        BEGIN
                            INSERT INTO #AgentJobs (job_id,name,notify_level_email,notify_level_netsend,notify_level_page)
                            VALUES ('00000000-0000-0000-0000-000000000000','','','','')
                        END
                        ELSE
                            BEGIN
                                RAISERROR('@OldOperatorName Specified is set as the Failsafe Operator - change this in SQL Server Agent &amp;gt; Properties &amp;gt; Alert system. SET @DeleteOldOperator = 0 if you do not want to output the Delete Operator Statement',11,0)
                            END
                END
 
            SELECT #AgentJobs.name AS JobName,
            CASE WHEN @NewOperatorName IS NULL THEN
            'EXEC msdb.dbo.sp_update_job @job_id=N'''+CAST(#AgentJobs.Job_id AS VARCHAR(36))+''',
            @notify_level_netsend=0,
            @notify_level_page=0,
            @notify_level_email=0,
            @notify_email_operator_name=N''''' + CHAR(13)+CHAR(10)
            WHEN @NewOperatorName IS NOT NULL THEN
            'EXEC msdb.dbo.sp_update_job @job_id=N'''+CAST(#AgentJobs.Job_id AS VARCHAR(36))+''',
                    @notify_email_operator_name=N'''+@NewOperatorName+'''' + CHAR(13)+CHAR(10)
            END AS ChangeToNewOperator,
                    'EXEC msdb.dbo.sp_update_job @job_id=N'''+CAST(#AgentJobs.Job_id AS VARCHAR(36))+''',
                    @notify_email_operator_name=N'''+@OldOperatorName+'''' + CHAR(13)+CHAR(10) AS RevertBackToOldOperator,
                    CASE
                    #AgentJobs.Notify_Level_email
                    WHEN 0 THEN 'Never'
                    WHEN 1 THEN 'On success'
                    WHEN 2 THEN 'On failure'
                    WHEN 3 THEN 'Always'
                    END AS EmailNotification,
                    CASE
                    #AgentJobs.Notify_Level_netsend
                    WHEN 0 THEN 'Never'
                    WHEN 1 THEN 'On success'
                    WHEN 2 THEN 'On failure'
                    WHEN 3 THEN 'Always'
                    END AS NetSendNotification,
                    CASE
                    #AgentJobs.Notify_Level_page
                    WHEN 0 THEN 'Never'
                    WHEN 1 THEN 'On success'
                    WHEN 2 THEN 'On failure'
                    WHEN 3 THEN 'Always'
                    END AS PageNotification,
                    CAST(sysjobs.[Enabled] AS CHAR(1)) AS [Enabled]
            FROM #AgentJobs
            INNER JOIN msdb..sysjobs ON #AgentJobs.job_id = sysjobs.job_id
            WHERE #AgentJobs.job_id != '00000000-0000-0000-0000-000000000000'
            UNION ALL
            SELECT
                '',
                CASE WHEN @DeleteOldOperator = 1 THEN '--EXEC msdb.dbo.sp_delete_operator @name=N'''+@OldOperatorName+''''
                ELSE ''
                END,
                '',
                '',
                '',
                '',
                ''
            FROM #AgentJobs
            WHERE #AgentJobs.job_id = '00000000-0000-0000-0000-000000000000'
            ORDER BY JobName ASC
        END
        ELSE IF @NewOperatorName IS NOT NULL
            BEGIN
                RAISERROR('@NewOperatorName Specified does not exist SET @CreateNewOperatorIfNotExists = 1 or create via the Operators folder',1,0)
                IF @CreateNewOperatorIfNotExists = 1 AND @NewOperatorName IS NOT NULL
                    BEGIN
                    SELECT '/** Run the following Add Operator command then run the procedure again to see the list of agent jobs associated with the Old Operator **/'
                    AS Create_NewOperator
                    UNION ALL
                    SELECT 'EXEC msdb.dbo.sp_add_operator @name=N'''+@NewOperatorName+''',
        @enabled=1,
        @weekday_pager_start_time=90000,
        @weekday_pager_end_time=180000,
        @saturday_pager_start_time=90000,
        @saturday_pager_end_time=180000,
        @sunday_pager_start_time=90000,
        @sunday_pager_end_time=180000,
        @pager_days=0,
        @category_name=N''[Uncategorized]''
        '+CASE WHEN @EmailAddress IS NOT NULL THEN ',@email_address=N'''+@EmailAddress+''''
        ELSE ''
        END
         AS Create_NewOperator
                    END
            END
 
END
ELSE
    BEGIN
        RAISERROR('@OldOperatorName Specified does not exist',1,0)
    END
 
END
GO