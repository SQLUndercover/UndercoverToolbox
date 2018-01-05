USE [master]
GO


/******************************************************************

Author: Adrian Buckman	
Revision date: 06/06/2017
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
 
CREATE PROCEDURE [dbo].[sp_FailedLogins]
 
(
@FromDate DATETIME = NULL,
@ToDate DATETIME = NULL
)
AS
 
BEGIN
--Failed login attempts in the last 60 minutes
 
IF @FromDate IS NULL BEGIN SET @FromDate = DATEADD(MINUTE,-60,GETDATE()) END
IF @ToDate IS NULL BEGIN SET @ToDate = GETDATE() END
 
IF OBJECT_ID('Tempdb..#Errors') IS NOT NULL
DROP TABLE #Errors
 
CREATE TABLE #Errors
(
Logdate Datetime,
Processinfo Varchar(30),
Text Varchar (255)
)
INSERT INTO #Errors
EXEC xp_ReadErrorLog 0, 1, N'FAILED',N'login',@FromDate,@ToDate;
 
SELECT
REPLACE(LoginErrors.Username,'''','') AS Username,
CAST(LoginErrors.Attempts AS NVARCHAR(6)) AS Attempts,
LatestDate.Logdate,
Latestdate.LastError
from (
Select SUBSTRING(text,Patindex('%''%''%',Text),charindex('.',Text)-(Patindex('%''%''%',Text))) as Username,Count(*) AS Attempts
From #Errors Errors
GROUP BY SUBSTRING(text,Patindex('%''%''%',Text),charindex('.',Text)-(Patindex('%''%''%',Text)))
) LoginErrors
CROSS APPLY (SELECT TOP 1 Logdate,text as LastError
FROM #Errors LatestDate
where LoginErrors.Username = SUBSTRING(text,Patindex('%''%''%',Text),charindex('.',Text)-(Patindex('%''%''%',Text)))
ORDER by Logdate DESC) LatestDate
 
Order by LoginErrors.Attempts DESC
 
END
GO