/******************************************************************

Author: David Fowler
Revision date: 25/09/2019
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

USE master
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'sp_LockDetails')
DROP PROC sp_LockDetails
GO

CREATE PROC sp_LockDetails (@DetailedView BIT = 0)
AS


BEGIN

IF OBJECT_ID('tempdb.dbo.#LockInfo') IS NOT NULL
DROP TABLE #LockInfo

--create table to stage locking data
CREATE TABLE #LockInfo( request_session_id int NOT NULL
						,DatabaseName nvarchar(128) NULL
						,login_name nvarchar(128) NOT NULL
						,status nvarchar(30) NOT NULL
						,request_mode nvarchar(60) NOT NULL
						,request_status nvarchar(60) NOT NULL
						,resource_type nvarchar(60) NOT NULL
						,resource_description nvarchar(256) NOT NULL
						,ObjectName nvarchar(128) NULL)


--populate #lockinfo
INSERT INTO #LockInfo
SELECT	tran_locks.request_session_id, 
		DB_NAME(tran_locks.resource_database_id) AS DatabaseName,
		sessions.login_name,
		sessions.status,
		tran_locks.request_mode,
		tran_locks.request_status,
		tran_locks.resource_type,
		tran_locks.resource_description,
		COALESCE(objects.name, OBJECT_NAME(partitions.object_id),DB_NAME(tran_locks.resource_database_id)) AS ObjectName
FROM sys.dm_tran_locks tran_locks
JOIN sys.dm_exec_sessions sessions ON sessions.session_id = tran_locks.request_session_id
LEFT OUTER JOIN sys.objects objects ON tran_locks.resource_associated_entity_id = objects.object_id
LEFT OUTER JOIN sys.partitions partitions ON tran_locks.resource_associated_entity_id = partitions.hobt_id
WHERE(resource_database_id) = DB_ID()

--return locking details
SELECT  request_session_id
		,DatabaseName 
		,login_name
		,status
		,request_mode
		,request_status 
		,resource_type 
		,resource_description
		,ObjectName 
FROM #LockInfo
ORDER BY request_session_id, ObjectName

IF @DetailedView = 1

BEGIN
	--if detailed view, create cursor to query all locked rows
	DECLARE KeyLockRows CURSOR STATIC FORWARD_ONLY FOR
	SELECT DISTINCT 'SELECT ''' + CAST(request_session_id AS NVARCHAR) +''' AS SPID, ''' + ObjectName + ''' AS ObjectName, + ''' + login_name + ''' AS LoginName, ''' + request_mode + ''' AS LockType, ''' + request_status + ''' AS status, * FROM ' + QUOTENAME(ObjectName) + ' WITH (NOLOCK)  WHERE %%lockres%% IN (' + STUFF((SELECT ''',''' + RTRIM(resource_description)
															FROM #LockInfo locksXML
															WHERE locksXML.request_session_id = Locks.request_session_id
															AND locksXML.request_status = Locks.request_status
															AND locksXML.ObjectName = Locks.ObjectName
															AND resource_type IN ('KEY','RID')
															FOR XML PATH ('')),1,2,'') + ''')'
	FROM #LockInfo Locks
	WHERE resource_type IN ('KEY','RID')
	--GROUP BY ObjectName, login_name, request_status, request_session_id, request_mode



	OPEN KeyLockRows

	DECLARE @cmd NVARCHAR(4000)

	FETCH NEXT FROM KeyLockRows INTO  @cmd

	--cursor through, returning all locked rows
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC sp_executesql @cmd
		FETCH NEXT FROM KeyLockRows INTO  @cmd
	END

	CLOSE KeyLockRows
	DEALLOCATE KeyLockRows
END

END

GO

EXEC sys.sp_MS_marksystemobject  sp_LockDetails
GO