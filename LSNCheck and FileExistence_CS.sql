/**********************************************
Author: Adrian Buckman
Revision date: 10/12/2017
Version: 1

URL: https://github.com/SQLUndercover/UndercoverToolbox/blob/master/LSNCheck%20and%20FileExistence_CS.sql


Description: Check backup information , backup file existence and check the restore chain is in tact 

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

*********************************************/

SET NOCOUNT ON;

DECLARE @DaysAgoToCheck TINYINT 
DECLARE @ExcludeDiffBackup BIT 
DECLARE @LastFullBackup DATETIME
DECLARE @RestoreSinceLastFULL VARCHAR(256) 
DECLARE @File_Exists INT
DECLARE @ID INT
DECLARE @Filename NVARCHAR(260)
DECLARE @FullCutoff DATETIME
DECLARE @Databasename NVARCHAR(128)


SET @Databasename = 'SQLUndercoverDB' --Set database name to check, NULL for current DB context
SET @DaysAgoToCheck = 30 --Set the amount of days back you want to search for a FULL backup
SET @ExcludeDiffBackup = 1 --Include or Exclude the Differential backup if there is one
SET @FullCutoff = NULL --Set a datetime here if you need to exclude certain full backups from your search 
				   -- e.g you want a backup from the last 30 days but older than the most recent FULL , set @Fullcutoff to a datetime before that full backup start date

IF @FullCutoff IS NULL BEGIN SET @FullCutoff = GETDATE() END;

IF @Databasename IS NULL BEGIN SET @Databasename = DB_NAME() END;

--Backup information table
IF OBJECT_ID('tempdb.dbo.#BackupInfo') IS NOT NULL 
DROP TABLE #BackupInfo;

CREATE TABLE #BackupInfo 
(
ID INT IDENTITY(1,1),
[database_name] NVARCHAR(128),
[type] VARCHAR(4),
[backup_start_date] DATETIME,
[backup_finish_date] DATETIME,
[first_lsn] NUMERIC(25,0),
[last_lsn] NUMERIC(25,0),
physical_device_name NVARCHAR(260),
fileexists INT  
);


--Get Latest FULL backup date
SELECT @LastFullBackup = MAX(backup_start_date)
FROM msdb.dbo.backupset Backupset
WHERE backup_start_date > DATEADD(DAY,-@DaysAgoToCheck,CAST(GETDATE() AS DATE))
AND database_name = @Databasename
AND [type] = 'D'
AND backup_start_date < @FullCutoff;

IF @LastFullBackup IS NOT NULL
BEGIN


	--Obtain more information about the FULL backup
	INSERT INTO #BackupInfo ([database_name],type,backup_start_date,backup_finish_date,first_lsn,last_lsn,physical_device_name)
	SELECT
	backupset.[database_name], 
	'FULL',
	backupset.[backup_start_date],
	backupset.[backup_finish_date] ,
	backupset.[first_lsn] ,
	backupset.[last_lsn],
	backupmediafamily.physical_device_name
	FROM msdb.dbo.backupset 
	INNER JOIN msdb.dbo.backupmediafamily ON backupset.media_set_id = backupmediafamily.media_set_id
	WHERE database_name = @Databasename
	AND type = 'D'
	AND backup_start_date = @LastFullBackup;
	


	--Last Restore check, has there been a Database restore since the last FULL backup was taken
	SELECT TOP 1 @RestoreSinceLastFULL = 
	COALESCE(CONVERT(VARCHAR(17),[LastRestore].[restore_date],113),'N/A') + ' - ' +
	COALESCE('['+COALESCE([LastRestore].[user_name],'') +']' + ' - [' + [backupmediafamily].[physical_device_name]+ ']','No Restore since the last full backup')  --AS Restore_Since_Full_Backup
	FROM msdb..restorehistory LastRestore
	INNER JOIN msdb..backupset 
	ON [LastRestore].[backup_set_id] = [backupset].[backup_set_id]
	INNER JOIN msdb..backupmediafamily  
	ON [backupset].[media_set_id] = [backupmediafamily].[media_set_id] 
	WHERE [LastRestore].[destination_database_name] = @Databasename
	AND [LastRestore].restore_date > @LastFullBackup
	ORDER BY [LastRestore].[restore_date] DESC;
	
	
	--Show Restore information if there has been a restore since the last FULL backup.
	SELECT ISNULL(@RestoreSinceLastFULL,'No Restores since the Last FULL backup') AS Restore_Since_Last_FULL_Backup;

	--Show created snapshots for the Database
	IF EXISTS (SELECT name FROM sys.databases WHERE source_database_id = DB_ID(@Databasename))
	BEGIN
	   SELECT name AS Snapshotname,
	   CONVERT(VARCHAR(17),create_date,113) AS DateCreated 
	   FROM sys.databases 
	   WHERE source_database_id = DB_ID(@Databasename);
     END
	   ELSE
	   BEGIN
		  SELECT 'No Snapshots are created against this database' AS Snapshots;
	   END

     IF @ExcludeDiffBackup = 0
	BEGIN
	   --Check for the most recent DIFF backup since the last FULL
	   INSERT INTO #BackupInfo ([database_name],type,backup_start_date,backup_finish_date,first_lsn,last_lsn,physical_device_name)
	   SELECT TOP 1 
	   database_name, 
	   'DIFF',
	   backupset.backup_start_date,
	   backupset.backup_finish_date,
	   backupset.first_lsn,
	   backupset.last_lsn,
	   backupmediafamily.physical_device_name
	   FROM msdb.dbo.backupset
	   INNER JOIN msdb..backupmediafamily ON backupset.media_set_id = backupmediafamily.media_set_id
	   WHERE backup_start_date > @LastFullBackup 
	   AND database_name = @Databasename
	   AND type = 'I'
	   ORDER BY backup_start_date DESC;
	END

	IF EXISTS (SELECT ID FROM #BackupInfo WHERE type = 'DIFF')
		BEGIN
				--Get the Transaction Log backup information since the last DIFF backup.
				INSERT INTO #BackupInfo ([database_name],type,backup_start_date,backup_finish_date,first_lsn,last_lsn,physical_device_name)
				SELECT 
				database_name, 
				'LOG',
				backupset.backup_start_date,
				backupset.backup_finish_date,
				backupset.first_lsn,
				backupset.last_lsn,
				backupmediafamily.physical_device_name
				FROM msdb.dbo.backupset
				INNER JOIN msdb.dbo.backupmediafamily ON backupset.media_set_id = backupmediafamily.media_set_id
				WHERE backup_start_date >= (SELECT backup_start_date FROM #BackupInfo WHERE type = 'DIFF') --LOGS after the last DIFF 
				AND database_name = @Databasename
				AND type = 'L';
		END
			ELSE
			BEGIN
				--Get the Transaction Log backup information since the last FULL backup.
				INSERT INTO #BackupInfo ([database_name],type,backup_start_date,backup_finish_date,first_lsn,last_lsn,physical_device_name)
				SELECT 
				database_name, 
				'LOG',
				backupset.backup_start_date,
				backupset.backup_finish_date,
				backupset.first_lsn,
				backupset.last_lsn,
				backupmediafamily.physical_device_name
				FROM msdb.dbo.backupset
				INNER JOIN msdb.dbo.backupmediafamily ON backupset.media_set_id = backupmediafamily.media_set_id
				WHERE backup_start_date >= @LastFullBackup --LOGS after the last FULL 
				AND database_name = @Databasename
				AND type = 'L'
				ORDER BY backup_start_date ASC;
			END

	
				  
	

	--File Existence Check
	DECLARE FileExist_Cur CURSOR LOCAL FAST_FORWARD
	FOR 
	SELECT ID,physical_device_name
	FROM #BackupInfo
	ORDER BY ID ASC
	
	OPEN FileExist_Cur
	
	FETCH NEXT FROM FileExist_Cur INTO @ID,@Filename
	
	WHILE @@FETCH_STATUS = 0 
	
		BEGIN
	
	
			EXEC master.dbo.xp_fileexist @Filename, @File_Exists OUT;
	
	 
			UPDATE #BackupInfo
			SET fileexists = @File_Exists
			WHERE ID = @ID;
	
				IF @File_Exists = 0 --0 means file is not found, 1 means it is found
	
					BEGIN
						PRINT 'File Not Found: ' + @Filename 
						PRINT ''
					END
	
	
			FETCH NEXT FROM FileExist_Cur INTO @ID,@Filename

		END

CLOSE FileExist_Cur
DEALLOCATE FileExist_Cur

--Last Backups by type
    SELECT 
    Backuptype,
    BackupDateTime,
    CASE 
    WHEN DATEDIFF(SECOND,BackupDateTime,BackupFinishDateTime)/60 >= 1
    THEN CAST(CAST(CAST(DATEDIFF(SECOND,BackupDateTime,BackupFinishDateTime) AS DECIMAL(8,2))/60 AS DECIMAL(8,2)) AS VARCHAR(10))
    ELSE '< 1 Minute' 
    END AS [LastDuration(Mins)],
    CASE 
    WHEN Backuptype IN ('FULL','DIFF') 
    THEN CAST(DATEDIFF(SECOND,BackupDateTime,GETDATE())/60/60 AS VARCHAR(8))+' Hours ('+CAST(CAST(CAST(DATEDIFF(SECOND,BackupDateTime,GETDATE()) as DECIMAL(20,2))/60/60/24 AS DECIMAL(20,2)) AS VARCHAR(8))+' Days)'
    ELSE CAST(DATEDIFF(SECOND,BackupDateTime,GETDATE())/60 AS VARCHAR(8))+' minutes ('+CAST(CAST(CAST(DATEDIFF(SECOND,BackupDateTime,GETDATE()) as DECIMAL(20,2))/60/60 AS DECIMAL(20,2)) AS VARCHAR(8))+' Hour/s)'
    END AS BackupAge
    FROM
    (
		SELECT 
		[type] as Backuptype,
		MAX(backup_start_date) AS BackupDateTime,
		MAX(backup_finish_date) AS BackupFinishDateTime
		FROM #BackupInfo
		GROUP BY [type]
	) LastBackups
	ORDER BY BackupDateTime ASC;


--Check for breaks in the LSN Chain and display results including if the file exists
SELECT 
	#BackupInfo.ID,
	#BackupInfo.database_name,
	#BackupInfo.type,
	CONVERT(VARCHAR(17),#BackupInfo.backup_start_date ,113) AS backup_start_date,
	CONVERT(VARCHAR(17),#BackupInfo.backup_finish_date ,113) AS backup_finish_date,
	#BackupInfo.physical_device_name AS BackupFilename,
	#BackupInfo.first_lsn,
	#BackupInfo.last_lsn,
	CASE 
	WHEN fileexists = 1 AND [type] = 'FULL' THEN 'OK'
	WHEN fileexists = 1 AND [type] = 'DIFF' AND NOT EXISTS (SELECT ID FROM #BackupInfo WHERE fileexists = 0 AND [type] = 'FULL') 
	THEN 'OK'   
	ELSE 'LOG CHAIN BROKEN' END AS LSNStatus,
	CASE 
	WHEN #BackupInfo.fileexists = 1 
	THEN 'Y'
	ELSE 'N'
	END AS fileexists
	FROM #BackupInfo
	WHERE #BackupInfo.type IN ('FULL','DIFF') --FULL and DIFF ONLY
	
	UNION ALL
	
	SELECT 
	LSNCHECK.ID,
	LSNCHECK.database_name,
	LSNCHECK.type,
	CONVERT(VARCHAR(17),LSNCHECK.backup_start_date ,113) AS backup_start_date,
	CONVERT(VARCHAR(17),LSNCHECK.backup_finish_date ,113) AS backup_finish_date,
	LSNCHECK.physical_device_name AS BackupFilename,
	LSNCHECK.first_lsn ,
	LSNCHECK.last_lsn ,
	CASE 
	   WHEN EXISTS (SELECT ID FROM #BackupInfo WHERE fileexists = 0 AND [type] IN ('FULL','DIFF')) THEN 'LOG CHAIN BROKEN'
	   WHEN first_lsn != prev_lsn THEN 'LOG CHAIN BROKEN'
	   WHEN EXISTS (SELECT ID FROM #BackupInfo WHERE fileexists = 0 AND [type] = 'LOG') 
	THEN 
		  CASE 
		  WHEN backup_start_date = (SELECT MIN(backup_start_date) FROM #BackupInfo WHERE fileexists = 0 AND [type] = 'LOG') THEN 'LOG CHAIN BROKEN' --Oldest Log which does not exist on disk
		  WHEN backup_start_date < (SELECT MIN(backup_start_date) FROM #BackupInfo WHERE fileexists = 0 AND [type] = 'LOG') AND fileexists = 1  --Any previous Logs that exist on Disk are OK
		  THEN 'OK'
			 ELSE 'LOG CHAIN BROKEN' --Any logs which follow the Break in the chain are considered broken even if they exist
		  END 
	ELSE 'OK'
	   END AS [Status],
     CASE 
	   WHEN LSNCHECK.fileexists = 1 
	THEN 'Y'
	   ELSE 'N'
	END AS fileexists
	FROM(
		SELECT 
		#BackupInfo.ID,
		#BackupInfo.database_name,
		#BackupInfo.type,
		#BackupInfo.backup_start_date,
		#BackupInfo.backup_finish_date,
		#BackupInfo.physical_device_name,
		#BackupInfo.first_lsn,
		#BackupInfo.last_lsn, 
		#BackupInfo.fileexists,
		(SELECT last_lsn FROM #BackupInfo LaggedLSN WHERE LaggedLSN.ID = #BackupInfo.ID-1 AND LaggedLSN.type = 'LOG') AS prev_lsn
		FROM #BackupInfo 
		WHERE #BackupInfo.type = 'LOG'  --LOGS ONLY
		) LSNCHECK
	ORDER BY ID ASC;


END
ELSE
	BEGIN
		SELECT 'No Full backup found within the last '+CAST(@DaysAgoToCheck AS VARCHAR(3))+' Day/s for database ['+@Databasename+']' AS NoBackupFound
		UNION ALL
		SELECT 'Try changing the value of @DaysAgoToCheck to increase the search window';
	END
