  /*                                                                                                                      
                                                                                                                                                                                                                                             
              @     ,@                                                                                                  
             #@@   @@@                                                                                                  
             @@@@@@@@@;                                                                                                 
             @@@@@@@@@@                                                                                                 
            :@@@@@@@@@@                                                                                                 
            @@@@@@@@@@@                                                                                                 
            @@@@@@@@@@@;                                                                                                
            @@@@@@@@@@@@                                                                                                
            @@@@@@@@@@@@                                                                                                
           `+@@@@@@@@@@+                                                                                                
                                                                                                                        
                                                                                                                        
         .@@`           #@,                                                                                             
     .@@@@@@@@@@@@@@@@@@@@@@@@:                                                                                         
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@     @@   @@      #@   @           @                                         
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@   @@@@  @#      #@   @           @                                         
    ;@@@@@@@@@@@@@@@@@@@@@@@@@@'        @     @   @# @#      #@   @ #@@@   @@@@  @@@  @@@@@  @@@   @@  @   @  @@   @ @@     
        .+@@@@@@@@@@@@@@@@+.            @@@@  @   @@ @#      #@   @ #@  @ @@  @  @  @  @@   @  @  @ `@  @ @  @  @  @@    
       '`                  `,#           @@@@ @   @@ @#      #@   @ #@  @ @#  @ @@@@@  @    @     @  @  @ @  @@@@  @`     
     ,@@@@ '@@@@@@@@@@@@@ .@@@@;           @  @   @@ @#      #@   @ #@  @ @@  @ @@     @ `  @     @  @  @@@  @     @      
    #@@@@@@ @@@@@  +@@@@  +@@@@@@       @@@@   @@@@  @@@@@   `@@@@@ #@  @ #@ @@  @  @  @    @@ @  @  @   @   @  @  @      
   @@@@@@@@  ,#.    `#;   @@@@@@@@'      @@     @@   @@@@@     @@,  #@  @  @@ @   @@  @@     #@    @@    @    @@   @      
  ;#@@@@@@@@             @@@@@@@@@#,              @                                                                     
       ,@@@@+           @@@@@+`                                                                                         
          .@@`        `@@@@                                          © www.sqlundercover.com                                                             
         +@@@@        @@@@@+                                                                                            
        @@@@@@@      @@@@@@@@#                                                                                          
         @@@@@@@    @@@@@@,                                                                                             
           :@@@@@' ;@@@@`                                                                                               
             `@@@@ @@@+                                                                                                 
                @#:@@                                                                                                   
                  @@                                                                                                    
                  @`                                                                                                    
                  #                                                                                                     
                                                                                                                            
sp_RestoreScript 2.0                                                                                                          
Written By David Fowler
28 May 2021

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

Parameters
==========

@DatabaseName -		A comma delimited list of databases to restore - DEFAULT: Current Database

@RestoreAsName -	A comma delimited list of name to restore databases as, the number of should correspond to the number of 
					databases in @DatabaseName.  

@RestoreToDate-		See @PointInTime for useage of @RestoreToDate. - DEFAULT: GETDATE()

@FirstLogToRestore-	If 'LogsOnly' restore option has been selected, this is the date of the first log to be restored. This 
					can't be left NULL if 'LogsOnly' has been selected.  If any other option has been selected it wil be ignored

@RestoreOptions-	'ToLog' - Script will generate statements including full, differential and log backups - DEFAULT
					'ToDiff'   Script will only include full and differential backups
					'ToFull'   Script will only include a full backup
					'LogsOnly' - Script will only include log backups between @FirstLogToRestore and @RestoreToDate
					'DiffOnly' - Script will include the nearest DIFF to @RestoreToDate

@PointInTime -		1 - Script will restore to a point in time specified in @RestoreToDate 
					0 - Script will to last backup before the date\time specified in @RestoreToDate - DEFAULT

@WithMoveDataPath -	WITH MOVE Path to move data files to. - DEFAULT: original path

@WithMoveLogPath -	WITH MOVE Path to move log files to. - DEFAULT:@ original path

@Replace -			1 - Databases will be restored WITH REPLACE
					0 - Database won't be restored WITH REPLACE - DEFAULT

@NoRecovery -		1 - Last file will be restored with NORECOVERY, leaving the database in 'restoring' state
					0 - Last file will be restored with RECOVERY and the database brought online - DEFAULT

@BrokerOptions -	Valid options - ENABLE_BROKER, ERROR_BROKER_CONVERSATIONS, NEW_BROKER

@StandBy -			Path for undo file, restores database in standby mode

@Credential -		Credential to access Azure blob storage

@IncludeCopyOnly -	1 - Copy only backups are included
					0 - Copy only backups are excluded

@SingleUser -		Put the database into single user mode before restoring

@StopAtMark -		Append stopatmark clause to any log restores

@StopBeforeMark -	Append stopbeforemark clause to any log restores

Full documentation and examples can be found at www.sqlundercover.com

*/
USE master
GO

IF OBJECT_ID('dbo.sp_RestoreScript') IS NOT NULL
	DROP PROC sp_RestoreScript
GO

CREATE PROC sp_RestoreScript
(
@AvailabilityGroupAware BIT = 0,
@DatabaseName VARCHAR(3000) = NULL,
@RestoreAsName VARCHAR(3000) = NULL, 
@RestoreToDate DATETIME = NULL,  
@FirstLogToRestore DATETIME = NULL, 
@RestoreOptions VARCHAR(11) = 'ToLog',  
@PointInTime BIT = 0,
@WithMoveDataPath VARCHAR(3000) = NULL,
@WithMoveLogPath VARCHAR(3000) = NULL,
@Replace BIT = 0,
@NoRecovery BIT = 0,
@BrokerOptions VARCHAR(30) = '',
@StandBy VARCHAR(260) = NULL,
@RestoreTimeEstimate BIT = 0,
@Credential VARCHAR(128) = NULL,
@IncludeCopyOnly BIT = 1,
@SingleUser BIT = 0,
@StopAtMark VARCHAR(128) = NULL,
@StopBeforeMark VARCHAR(128) = NULL
)

AS

BEGIN

DECLARE @WithMove VARCHAR(3000)

SET NOCOUNT ON
--Check that @RestoreOptions is a valid value
IF @RestoreOptions NOT IN ('ToLog','ToDiff','ToFull','LogsOnly', 'DiffOnly')
RAISERROR (N'Invalid Restore Option specified, please use ToLog, ToDiff, ToFull, DiffOnly or LogsOnly' , 15, 1)

--Check for valid broker options
IF @BrokerOptions NOT IN ('ENABLE_BROKER', 'ERROR_BROKER_CONVERSATIONS', 'NEW_BROKER','')
	RAISERROR (N'Invalid Broker Option specified' , 15, 1)
ELSE IF @BrokerOptions != ''
	SET @BrokerOptions = ',' + @BrokerOptions

--Check that both 'WithMove' parameters are either both null or both hold a value (why doens't SQL Server give us an XOR?)
IF ((@WithMoveDataPath IS NULL) AND (@WithMoveLogPath IS NOT NULL)) 
	OR
	((@WithMoveDataPath IS NOT NULL) AND (@WithMoveLogPath IS NULL)) 
RAISERROR (N'The ''WithMove'' parameters either both must be NULL or both must hold a value', 15,1) 

--set compatibility mode
DECLARE @compatibility BIT

--set compatibility to 1 if server version includes STRING_SPLIT
SELECT	@compatibility = CASE
			WHEN SERVERPROPERTY ('productversion') >= '13.0.4001.0' AND compatibility_level >= 130 THEN 1
			ELSE 0
		END
FROM sys.databases
WHERE name = DB_NAME()

--drop temp tables
IF  OBJECT_ID('tempdb..#BackupCommands') IS NOT NULL
	DROP TABLE #BackupCommands
CREATE TABLE #BackupCommands
(backup_finish_date DATETIME, DBName VARCHAR(255), command VARCHAR(MAX), BackupType VARCHAR(4), AlterCommand BIT)

IF OBJECT_ID('tempdb..#BackupCommandsFinal') IS NOT NULL
	DROP TABLE #BackupCommandsFinal
CREATE TABLE #BackupCommandsFinal
(backup_finish_date DATETIME, DBName VARCHAR(255), command VARCHAR(MAX), BackupType VARCHAR(4), AlterCommand BIT)

IF OBJECT_ID('tempdb..#RestoreDatabases') IS NOT NULL
	DROP TABLE #RestoreDatabases
CREATE TABLE #RestoreDatabases
(SourceDatabase SYSNAME NOT NULL,
DestinationDatabase SYSNAME NULL)

IF OBJECT_ID('tempdb..#LatestBackups') IS NOT NULL
	DROP TABLE #LatestBackups
CREATE TABLE #LatestBackups
(LatestDBName SYSNAME,
backup_finish_date DATETIME)

--remove any spaces in list of databases
SET @DatabaseName = REPLACE(@DatabaseName, ' ','')
SET @RestoreAsName = REPLACE(@RestoreAsName, ' ','')

--@PointInTime can only be true if @RestoreOptions is either 'ToLog' or 'LogsOnly' 
IF (@PointInTime = 1) AND (@RestoreOptions NOT IN ('ToLog','LogsOnly'))
BEGIN
RAISERROR (N'Point in time restore is not possible with selected restore options.  @PointInTime has been changed to 0', 15,1) 
SET @PointInTime = 0
END

--@PointInTime can only be true if @StopAtMark or @StopBeforeMark is false
IF(@PointInTime = 1) AND (@StopAtMark IS NOT NULL OR @StopBeforeMark IS NOT NULL)
RAISERROR (N'@PointInTime cannot be 1 when @StopAtMark or @StopBeforeMark is set', 15,1) 

--Both @StopAtMark and @StopBeforeMark can't be set
IF (@StopAtMark IS NOT NULL AND @StopBeforeMark IS NOT NULL)
RAISERROR (N'Only @StopAtMark or @StopBeforeMark can be set, not both', 15,1) 

--If @RestoreOptions is 'LogsOnly', a RestoreToDate value must be specified
IF (@RestoreOptions = 'LogsOnly') AND (@FirstLogToRestore IS NULL)
RAISERROR (N'When @RestoreOptions = LogsOnly, a @FirstLogToRestore date must be specified', 15,1) 

--Set default value for @RestoreToDate if unspecified
IF (@RestoreToDate IS NULL)
SET @RestoreToDate = GETDATE()

--Set default value for @DatabaseName if unspecified
IF (@DatabaseName IS NULL)
SET @DatabaseName = DB_NAME()

--Declare cursor containing database names
--if compatibility mode = 1 then it's safe to use STRING_SPLIT, otherwise use fn_SplitString
IF (@compatibility = 1)
BEGIN 
	--raise an error if there's a mismatch in the number of databases in @DatabaseName and @RestoreAsName
	IF ((SELECT COUNT(*) FROM  STRING_SPLIT(@DatabaseName,',')) 
		!= (SELECT COUNT(*) FROM  STRING_SPLIT(@RestoreAsName,',')))
		AND @RestoreAsName IS NOT NULL
	RAISERROR (N'There is a mismatch in the number of databases in @DatabaseName and @RestoreAsName', 15,1)

	--DECLARE DatabaseCur CURSOR STATIC FORWARD_ONLY FOR
	INSERT INTO #RestoreDatabases (SourceDatabase,DestinationDatabase)
	SELECT SourceDatabase.value AS SourceDatabase,DestinationDatabase.value AS DestinationDatabase
	FROM
		(SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT 1)) RowNumber
		FROM STRING_SPLIT(@DatabaseName,',') ) SourceDatabase
		LEFT JOIN
		(SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT 1)) RowNumber
		FROM STRING_SPLIT(@RestoreAsName,',') ) DestinationDatabase
		ON SourceDatabase.RowNumber = DestinationDatabase.RowNumber

	--check for the existance of wild cards
	IF @DatabaseName LIKE '%\%%' ESCAPE '\'
	BEGIN
		DECLARE @WildCardDB SYSNAME

		--wildcards cannot be used with @RestoreAsName
		IF (@RestoreAsName IS NOT NULL)
		RAISERROR (N'@RestoreAsName must be NULL when wildcards are used in @DatabaseName', 15,1)	

		--Cursor through wild card databases, selecting from sys.databases
		DECLARE WildCardCur CURSOR STATIC FORWARD_ONLY FOR 
			SELECT SourceDatabase
			FROM #RestoreDatabases
			WHERE SourceDatabase LIKE '%\%%' ESCAPE '\'

		OPEN WildCardCur
		FETCH NEXT FROM WildCardCur INTO @WildCardDB

		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO #RestoreDatabases(SourceDatabase)
			SELECT name
			FROM sys.databases
			WHERE name LIKE @WildCardDB

			FETCH NEXT FROM WildCardCur INTO @WildCardDB
		END

		--remove wild card entry from #restoredatabases, it's no longer needed
		DELETE FROM #RestoreDatabases
		WHERE SourceDatabase = @WildCardDB

		CLOSE WildCardCur
		DEALLOCATE WildCardCur
	END
END
ELSE BEGIN
	--raise an error if there's a mismatch in the number of databases in @DatabaseName and @RestoreAsName
	IF ((SELECT COUNT(*) FROM  fn_SplitString(@DatabaseName,',')) 
		!= (SELECT COUNT(*) FROM  fn_SplitString(@RestoreAsName,',')))
		AND @RestoreAsName IS NOT NULL
	RAISERROR (N'There is a mismatch in the number of databases in @DatabaseName and @RestoreAsName', 15,1)

	---DECLARE DatabaseCur CURSOR FOR
	INSERT INTO #RestoreDatabases (SourceDatabase,DestinationDatabase)
	SELECT SourceDatabase.StringElement AS SourceDatabase,DestinationDatabase.StringElement AS DestinationDatabase
	FROM
		(SELECT StringElement, ROW_NUMBER() OVER (ORDER BY (SELECT 1)) RowNumber
		FROM fn_SplitString(@DatabaseName,',') ) SourceDatabase
		LEFT JOIN
		(SELECT StringElement, ROW_NUMBER() OVER (ORDER BY (SELECT 1)) RowNumber
		FROM fn_SplitString(@RestoreAsName,',') ) DestinationDatabase
		ON SourceDatabase.RowNumber = DestinationDatabase.RowNumber

	--check for the existance of wild cards
	IF @DatabaseName LIKE '%\%%' ESCAPE '\'
	BEGIN

		--wildcards cannot be used with @RestoreAsName
		IF (@RestoreAsName IS NOT NULL)
		RAISERROR (N'@RestoreAsName must be NULL when wildcards are used in @DatabaseName', 15,1)	

		--Cursor through wild card databases, selecting from sys.databases
		DECLARE WildCardCur CURSOR STATIC FORWARD_ONLY FOR 
			SELECT SourceDatabase
			FROM #RestoreDatabases
			WHERE SourceDatabase LIKE '%\%%' ESCAPE '\'

		OPEN WildCardCur
		FETCH NEXT FROM WildCardCur INTO @WildCardDB

		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO #RestoreDatabases(SourceDatabase)
			SELECT name
			FROM sys.databases
			WHERE name LIKE @WildCardDB

			FETCH NEXT FROM WildCardCur INTO @WildCardDB
		END

		--remove wild card entry from #restoredatabases, it's no longer needed
		DELETE FROM #RestoreDatabases
		WHERE SourceDatabase = @WildCardDB

		CLOSE WildCardCur
		DEALLOCATE WildCardCur
	END

END

DECLARE DatabaseCur CURSOR FOR
SELECT SourceDatabase, DestinationDatabase
FROM #RestoreDatabases

--open cursor
OPEN DatabaseCur
FETCH NEXT FROM DatabaseCur INTO @DatabaseName, @RestoreAsName

WHILE @@FETCH_STATUS = 0 
BEGIN
	
	--get all AG replicas for current database
	IF @AvailabilityGroupAware = 1  
	BEGIN
		PRINT 'Holder for code to get AG replicas'
	END

	--Insert single user command
	IF @SingleUser = 1
	BEGIN
		INSERT INTO #BackupCommands (DBName, command, AlterCommand)
		VALUES (@DatabaseName, 'ALTER DATABASE ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE', 1)
	END


	--Get last full backup for required timeframe
	IF (@RestoreOptions IN ('PointInTime','ToLog','ToDiff','ToFull','DiffOnly'))
	BEGIN		
		WITH BackupFilesCTE (physical_device_name, position, StartDateRank, backup_finish_date)
		AS
			(SELECT CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 102 THEN  mediafamily.logical_device_name
							ELSE '***UNSUPPORTED DEVICE***'
					END, 
			position, 
			RANK() OVER (ORDER BY backup_finish_date DESC) AS StartDateRank, 
			backup_finish_date
			FROM msdb.dbo.backupset backupset
			INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
			WHERE backupset.database_name = @DatabaseName
			AND backupset.backup_finish_date < @RestoreToDate
			AND backupset.type = 'D'
            AND is_copy_only IN (0,@IncludeCopyOnly))

		INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand)
		SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
						'RESTORE DATABASE ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + STUFF ((SELECT ',' + physical_device_name,
						0
		FROM BackupFilesCTE
		WHERE StartDateRank = 1
		FOR XML PATH('')),1,1,'') + ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR) AS Command, 'FULL',0
		FROM BackupFilesCTE
		WHERE StartDateRank = 1
	END

	--if Replace is set, add to statement
	IF @Replace = 1
	BEGIN
		UPDATE #BackupCommands
		SET command = command + ', REPLACE'
		WHERE DBName = @DatabaseName
		AND AlterCommand = 0;
	END

	--if WithMove parameters are set, create WITH MOVE statements
	IF (@WithMoveDataPath IS NOT NULL) AND (@WithMoveLogPath IS NOT NULL) 
	BEGIN

		--append \ to the end of path if it's not already

		IF (SELECT SUBSTRING(@WithMoveDataPath,LEN(@WithMoveDataPath), 1)) != '\'
			SET @WithMoveDataPath =  @WithMoveDataPath + '\'

		IF (SELECT SUBSTRING(@WithMoveLogPath,LEN(@WithMoveLogPath), 1)) != '\'
			SET @WithMoveLogPath =  @WithMoveLogPath + '\'

		--generate MOVE statement
		DECLARE @WithMoveCmd VARCHAR(3000)

		SET @WithMoveCmd = ','

		SELECT @WithMoveCmd = @WithMoveCmd + STUFF((SELECT ',' + ' MOVE ''' + name + ''' TO ''' + 
		CASE 
			WHEN @RestoreAsName IS NULL THEN REPLACE(physical_name,REVERSE(SUBSTRING(REVERSE(physical_name),CHARINDEX('\',REVERSE(physical_name),0), LEN(physical_name))),@WithMoveDataPath) + ''''
			ELSE REPLACE(LEFT(physical_name,(LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name),0)+1)),LEFT(physical_name,(LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name),0)+1)),@WithMoveDataPath) /* Base Path */ 
				+REPLACE(RIGHT(physical_name,(CHARINDEX('\',REVERSE(physical_name))-1)),@DatabaseName,@RestoreAsName) + '''' /* append new filename and extension */
		END
		FROM sys.master_files
		WHERE database_id = DB_ID(@DatabaseName)
		AND type_desc = 'ROWS'
		FOR XML PATH('')) ,1,1,'')

		SET @WithMoveCmd = @WithMoveCmd + ','

		SELECT @WithMoveCmd = @WithMoveCmd + STUFF((SELECT ',' +  'MOVE ''' + name + ''' TO ''' +
		CASE 
			WHEN @RestoreAsName IS NULL THEN REPLACE(physical_name,REVERSE(SUBSTRING(REVERSE(physical_name),CHARINDEX('\',REVERSE(physical_name),0), LEN(physical_name))),@WithMoveLogPath) + ''''
			ELSE REPLACE(LEFT(physical_name,(LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name),0)+1)),LEFT(physical_name,(LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name),0)+1)),@WithMoveLogPath) /* Base Path */ 
				+REPLACE(RIGHT(physical_name,(CHARINDEX('\',REVERSE(physical_name))-1)),@DatabaseName,@RestoreAsName) + '''' /* append new filename and extension */
		END
		FROM sys.master_files
		WHERE database_id = DB_ID(@DatabaseName)
		AND type_desc = 'LOG'
		FOR XML PATH('')) ,1,1,'')

		--append MOVE statement to backup command
		UPDATE #BackupCommands
		SET command = command + @WithMoveCmd
		WHERE DBName = @DatabaseName
		AND AlterCommand = 0;
	END

	--Get last diff for required timeframe
	IF (@RestoreOptions IN ('PointInTime','ToLog','ToDiff','DiffOnly'))
	BEGIN
		WITH BackupFilesCTE (physical_device_name, position, StartDateRank, backup_finish_date)
		AS
			(SELECT CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 102 THEN  mediafamily.logical_device_name
							ELSE '***UNSUPPORTED DEVICE***'
					END,
			position, 
			RANK() OVER (ORDER BY backup_finish_date DESC) AS StartDateRank, 
			backup_finish_date
			FROM msdb.dbo.backupset backupset
			INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
			WHERE backupset.database_name = @DatabaseName
			AND backupset.backup_finish_date < @RestoreToDate
			AND backupset.type = 'I'
            AND is_copy_only IN (0,@IncludeCopyOnly))

		INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand)
		SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
						'RESTORE DATABASE ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + STUFF ((SELECT ',' + physical_device_name,
						0
		FROM BackupFilesCTE
		WHERE StartDateRank = 1
		FOR XML PATH('')),1,1,'') + ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR) AS Command, 'DIFF',0
		FROM BackupFilesCTE
		WHERE StartDateRank = 1
		AND backup_finish_date > (SELECT MAX(backup_finish_date) FROM #BackupCommands)
	END

	--Get all log backups since last full or diff
	IF (@RestoreOptions IN ('ToLog','LogsOnly'))
		WITH BackupFilesCTE (physical_device_name, position, StartDateRank, backup_finish_date)
		AS
			(SELECT CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 102 THEN  mediafamily.logical_device_name
							ELSE '***UNSUPPORTED DEVICE***'
					END, 
			position, 
			RANK() OVER (ORDER BY backup_finish_date DESC) AS StartDateRank, 
			backup_finish_date
			FROM msdb.dbo.backupset backupset
			INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
			WHERE backupset.database_name = @DatabaseName
			AND backupset.backup_finish_date >
				(SELECT COALESCE(MAX(backup_finish_date),@FirstLogToRestore) FROM #BackupCommands)
			AND backupset.backup_finish_date < @RestoreToDate
			AND backupset.type = 'L'
            AND is_copy_only IN (0,@IncludeCopyOnly))

		INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand)
		SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
						'RESTORE LOG ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + 
							STUFF ((SELECT DISTINCT ',' + physical_device_name
							FROM BackupFilesCTE a
							WHERE a.backup_finish_date = b.backup_finish_date
							FOR XML PATH('')),1,1,'') 
						+ ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR) 
						+ CASE  WHEN @StopAtMark IS NOT NULL THEN ', STOPATMARK = ''' + @StopAtMark + ''''
								WHEN @StopBeforeMark IS NOT NULL THEN ', STOPBEFOREMARK = ''' + @StopBeforeMark + ''''
								ELSE ''
						 END AS Command, 'LOG',0
		FROM BackupFilesCTE b
		ORDER BY backup_finish_date ASC

	--Get point in time if enabled
	IF (@PointInTime = 1) AND (EXISTS (SELECT * FROM #BackupCommands WHERE AlterCommand = 0))
	BEGIN
		WITH BackupFilesCTE (physical_device_name, position, StartDateRank, backup_finish_date)
		AS
			(SELECT CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 102 THEN  mediafamily.logical_device_name
							ELSE '***UNSUPPORTED DEVICE***'
					END, 
			position, 
			RANK() OVER (ORDER BY backup_finish_date ASC) AS StartDateRank, 
			backup_finish_date
			FROM msdb.dbo.backupset backupset
			INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
			WHERE backupset.database_name = @DatabaseName
			AND backupset.backup_finish_date > @RestoreToDate
			AND backupset.type = 'L'
            AND is_copy_only IN (0,@IncludeCopyOnly))

		INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand)
		SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
						'RESTORE DATABASE ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + STUFF ((SELECT ',' + physical_device_name
		FROM BackupFilesCTE
		WHERE StartDateRank = 1
		FOR XML PATH('')),1,1,'') + ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR)  + ', STOPAT = ''' + CAST(@RestoreToDate AS VARCHAR) + '''' AS Command, 'LOG',0
		FROM BackupFilesCTE
		WHERE StartDateRank = 1
	END

	INSERT INTO #BackupCommandsFinal (backup_finish_date, DBName, command, BackupType, AlterCommand)
	SELECT backup_finish_date, DBName, command, BackupType, AlterCommand FROM #BackupCommands;

	TRUNCATE TABLE #BackupCommands

	FETCH NEXT FROM DatabaseCur INTO @DatabaseName, @RestoreAsName
END

CLOSE DatabaseCur
DEALLOCATE DatabaseCur

--get list of latest backups for each database
INSERT INTO #LatestBackups(LatestDBName,backup_finish_date)
SELECT DBName, MAX(backup_finish_date)
FROM #BackupCommandsFinal
GROUP BY DBName;

IF @NoRecovery = 0 AND @StandBy IS NULL  --if restore with no recovery is off, remove NORECOVERY from the last restore command
BEGIN

	UPDATE #BackupCommandsFinal
	SET command = REPLACE(command,'NORECOVERY','RECOVERY') + @BrokerOptions
	WHERE backup_finish_date = (SELECT backup_finish_date FROM #LatestBackups WHERE DBName = LatestDBName);

END
ELSE IF @StandBy IS NOT NULL
BEGIN
	UPDATE #BackupCommandsFinal
	SET command = REPLACE(command,'NORECOVERY','STANDBY =''' + @StandBy + '''') 
	WHERE backup_finish_date = (SELECT backup_finish_date FROM #LatestBackups WHERE DBName = LatestDBName);
END

--if Credential is set, add to statement
IF @Credential IS NOT NULL
BEGIN
    UPDATE #BackupCommandsFinal
    SET command = command + ', CREDENTIAL = '''+@Credential+''''
    WHERE DBName = @DatabaseName
	AND AlterCommand = 0;
END

--if DiffOnly, delete full backup file from #BackupCommandsFinal
IF (@RestoreOptions = 'DiffOnly')
BEGIN
	DELETE FROM #BackupCommandsFinal
	WHERE backup_finish_date = 
					(SELECT MIN(backup_finish_date)
					FROM #BackupCommandsFinal)
END

SELECT backup_finish_date, DBName, command, BackupType
FROM #BackupCommandsFinal
ORDER BY DBName,backup_finish_date

--check for unsupported backup device and raise alert
IF EXISTS (SELECT command FROM #BackupCommandsFinal WHERE command LIKE '%***UNSUPPORTED DEVICE***%')
RAISERROR (N'One or more backups were taken to an unsupported device, possibly by a third party backup tool' , 15, 1)

END




