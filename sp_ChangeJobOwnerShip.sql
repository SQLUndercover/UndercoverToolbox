USE [master]
GO
 
 /******************************************************************

Author: Adrian Buckman
Revision date: 22/09/2017
Version: 1

© www.sqlundercover.com 

Description: Produce a script that will provide ALTER statements to change the Agent Job
ownerships to the new owner and also ALTER statements to revert back to the old owner


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


 
CREATE PROCEDURE [dbo].[sp_ChangeJobOwnerShip]
(@JobOwner NVARCHAR(128) = NULL,
@Help     BIT           = 0
)
AS
IF @Help = 1
BEGIN
PRINT 'Parameters:
@@JobOwner NVARCHAR(128) - Set the new owner name here';
END;
IF @Help = 0
BEGIN
 
DECLARE @UserSid VARBINARY= SUSER_SID(@JobOwner);
 
IF @UserSid IS NOT NULL
BEGIN
 
SELECT [Name] AS [JobName],
COALESCE(SUSER_SNAME([Jobs].[owner_sid]),'') AS [CurrentOwner],
'EXEC msdb.dbo.sp_update_job @job_name=N'''+[Name]+''', @owner_login_name=N'''+@JobOwner+''';' AS [ChangeToNewOwner],
'EXEC msdb.dbo.sp_update_job @job_name=N'''+[Name]+''', @owner_login_name=N'''+COALESCE(SUSER_SNAME([Jobs].[owner_sid]),'')+''';' AS [RevertToOriginalOwner]
FROM   [MSDB].[dbo].[sysjobs] [Jobs]
WHERE  [Jobs].[owner_sid] != @UserSid;
 
END;
ELSE
BEGIN
RAISERROR('No SID found for the owner name you have provided - please check the owner name and try again',11,1);
END;
 
END;