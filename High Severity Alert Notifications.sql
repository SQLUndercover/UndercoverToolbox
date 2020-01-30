/******************************************************************

Your SQL Server's Screaming But Is Anyone Listening? - High Severity Alert Notifications
https://sqlundercover.com/2020/01/30/your-sql-servers-screaming-but-is-anyone-listening-high-severity-alert-notifications/

Author: David Fowler
Revision date: 30/01/2020
Version: 1.0

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

USE [msdb]
GO

--Create High Severity Error category
EXEC sp_add_category
@class = N'ALERT',
@type = N'NONE',
@name = N'High Severity Error'
GO

--Configure alerts
EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 17 Error:', 
		@message_id=0, 
		@severity=17, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO

EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 18 Error: Nonfatal Internal Error', 
		@message_id=0, 
		@severity=18, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO

EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 19 Error: Fatal Error in Resource', 
		@message_id=0, 
		@severity=19, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO

EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 20 Error: Fatal Error in Current Process', 
		@message_id=0, 
		@severity=20, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO

EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 21 Error: Fatal Error in Database Process', 
		@message_id=0, 
		@severity=21, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO

EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 22 Error Fatal Error: Table Integrity Suspect', 
		@message_id=0, 
		@severity=22, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO

EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 23 Error: Fatal Error Database Integrity Suspect', 
		@message_id=0, 
		@severity=23, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO

EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 24 Error: Fatal Hardware Error', 
		@message_id=0, 
		@severity=24, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO

EXEC msdb.dbo.sp_add_alert @name=N'URGENT: Severity 25 Error: Fatal Error', 
		@message_id=0, 
		@severity=25, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'High Severity Error'
GO


--Configure operator

USE msdb;
GO
EXEC msdb.dbo.sp_add_operator
@name = 'SQLUndercoverDBAs',
@enabled = 1,
@email_address = 'alerts@sqlundercover.com';
GO



--setup notifications

EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 17 Error:',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ;  

EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 18 Error: Nonfatal Internal Error',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ; 
 
EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 19 Error: Fatal Error in Resource',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ;  

EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 20 Error: Fatal Error in Current Process',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ;  

EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 21 Error: Fatal Error in Database Process',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ;  

EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 22 Error Fatal Error: Table Integrity Suspect',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ;  

EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 23 Error: Fatal Error Database Integrity Suspect',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ;  

EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 24 Error: Fatal Hardware Error',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ;  

EXEC dbo.sp_add_notification  
 @alert_name = N'URGENT: Severity 25 Error: Fatal Error',  @operator_name = N'SQLUndercoverDBAs',  @notification_method = 1 ;  