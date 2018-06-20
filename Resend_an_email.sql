/*
Author: Adrian Buckman
Created Date: 05/06/2018
Revision date: 05/06/2018
Version: 1
Description: Resend an email by MailitemID.
URL: https://https://github.com/SQLUndercover/UndercoverToolbox/blob/master/Resend_an_email.sql
© www.sqlundercover.com 
MIT License
------------
Copyright 2018 Sql Undercover
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


--Set mail item id you want to re send
DECLARE @mailitemID INT = 	-- MailItem_Id here e.g 2041


DECLARE @profilename NVARCHAR(128);
DECLARE @recipients	VARCHAR(MAX);
DECLARE @copy_recipients VARCHAR(MAX);
DECLARE @blind_copy_recipients VARCHAR(MAX);
DECLARE @subject NVARCHAR(510);
DECLARE @body VARCHAR(MAX);
DECLARE @body_format VARCHAR(20);
DECLARE @importance VARCHAR(6);
DECLARE @sensitivity VARCHAR(12);
DECLARE @query BIT;
DECLARE @attachment BIT;


--Get the information for the email
SELECT 
@profilename = [profiles].[name],
@recipients = [mail].[recipients],
@copy_recipients = [mail].[copy_recipients],
@blind_copy_recipients = [mail].[blind_copy_recipients],
@subject = [mail].[subject],
@body = [mail].[body],
@body_format = [mail].[body_format],
@importance = [mail].[importance] ,
@sensitivity = [mail].[sensitivity],
@query = CASE WHEN [mail].[query] IS NULL THEN 0 ELSE 1 END,
@attachment = CASE WHEN [mail].[file_attachments] IS NULL THEN 0 ELSE 1 END  
FROM msdb.dbo.sysmail_allitems mail
INNER JOIN msdb.dbo.sysmail_profile profiles ON mail.profile_id = profiles.profile_id
WHERE mailitem_id = @mailitemID;


IF @query = 0 AND @attachment = 0 
BEGIN 

--Re send the email
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = @profilename,
@recipients = @recipients,
@copy_recipients = @copy_recipients,
@blind_copy_recipients = @blind_copy_recipients,
@subject = @subject,
@body = @body,
@body_format = @body_format,
@importance = @importance,
@sensitivity = @sensitivity

END
	ELSE
	BEGIN
		RAISERROR('The mailitem_id specified (%d) uses a query or attachments, unfortunately this script cannot send your email',11,0,@mailitemID)
	END





