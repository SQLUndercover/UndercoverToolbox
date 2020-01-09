--Undercover Catalogue
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
