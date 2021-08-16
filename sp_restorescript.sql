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
                                                                                                                            
sp_RestoreScript 2.0 BETA                                                                                                        
Written By David Fowler
03 June 2021

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

@AvailabilityGroupAware -	0 - Only backups taken on the local server will be returned - DEFAULT
							1 - Backups from all AG nodes will be returned, great if you offload your backups

Full documentation and examples can be found at www.sqlundercover.com

*/
USE master
GO

IF OBJECT_ID('dbo.sp_RestoreScript') IS NOT NULL
	DROP PROC sp_RestoreScript
GO

CREATE PROC sp_RestoreScript
(
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
@StopBeforeMark VARCHAR(128) = NULL,
@AvailabilityGroupAware BIT = 0,
@BackupDir VARCHAR(8000) = NULL
)



AS

BEGIN

DECLARE @WithMove VARCHAR(3000)
DECLARE @IsAGDatabase BIT
DECLARE @ReplicaName SYSNAME
DECLARE @LastestBackupInSet DATETIME
DECLARE @Cmd NVARCHAR(4000)
DECLARE @Error VARCHAR(5000)
DECLARE @ConnectionString VARCHAR(4000)
DECLARE @LastFullDiff DATETIME

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
(backup_finish_date DATETIME, DBName VARCHAR(255), command VARCHAR(MAX), BackupType VARCHAR(4), AlterCommand BIT, takenOnServer SYSNAME NULL)

IF OBJECT_ID('tempdb..#BackupCommandsFinal') IS NOT NULL
	DROP TABLE #BackupCommandsFinal
CREATE TABLE #BackupCommandsFinal
(backup_finish_date DATETIME, DBName VARCHAR(255), command VARCHAR(MAX), BackupType VARCHAR(4), AlterCommand BIT, takenOnServer SYSNAME NULL)

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

IF OBJECT_ID('tempdb..#BackupDetails') IS NOT NULL
DROP TABLE #BackupDetails

CREATE TABLE #BackupDetails
(physical_device_name NVARCHAR(270),
position  INT,
backup_start_date DATETIME,
backup_finish_date DATETIME,
takenOnServer SYSNAME,
StartDateRank INT)

IF OBJECT_ID('tempdb..#FileBackups') IS NOT NULL
DROP TABLE #FileBackups
CREATE TABLE #FileBackups 
(   subdirectory VARCHAR(8000), 
    depth INT, 
    [file] BIT
);

IF OBJECT_ID(N'tempdb..#BackupHeaders') IS NOT NULL 
DROP TABLE #BackupHeaders;
CREATE TABLE #BackupHeaders
(	FilePath VARCHAR(4000) NULL,
	BackupName NVARCHAR(256),
    BackupDescription NVARCHAR(256),
    BackupType NVARCHAR(256),
    ExpirationDate NVARCHAR(256),
    Compressed NVARCHAR(256),
    Position NVARCHAR(256),
    DeviceType NVARCHAR(256),
    UserName NVARCHAR(256),
    ServerName NVARCHAR(256),
    DatabaseName NVARCHAR(256),
    DatabaseVersion NVARCHAR(256),
    DatabaseCreationDate NVARCHAR(256),
    BackupSize NVARCHAR(256),
    FirstLSN NVARCHAR(256),
    LastLSN NVARCHAR(256),
    CheckpointLSN NVARCHAR(256),
    DatabaseBackupLSN NVARCHAR(256),
    BackupStartDate NVARCHAR(256),
    BackupFinishDate NVARCHAR(256),
    SortOrder NVARCHAR(256),
    [CodePage] NVARCHAR(256),
    UnicodeLocaleId NVARCHAR(256),
    UnicodeComparisonStyle NVARCHAR(256),
    CompatibilityLevel NVARCHAR(256),
    SoftwareVendorId NVARCHAR(256),
    SoftwareVersionMajor NVARCHAR(256),
    SoftwareVersionMinor NVARCHAR(256),
    SoftwareVersionBuild NVARCHAR(256),
    MachineName NVARCHAR(256),
    Flags NVARCHAR(256),
    BindingID NVARCHAR(256),
    RecoveryForkID NVARCHAR(256),
    Collation NVARCHAR(256),
    FamilyGUID NVARCHAR(256),
    HasBulkLoggedData NVARCHAR(256),
    IsSnapshot NVARCHAR(256),
    IsReadOnly NVARCHAR(256),
    IsSingleUser NVARCHAR(256),
    HasBackupChecksums NVARCHAR(256),
    IsDamaged NVARCHAR(256),
    BeginsLogChain NVARCHAR(256),
    HasIncompleteMetaData NVARCHAR(256),
    IsForceOffline NVARCHAR(256),
    IsCopyOnly NVARCHAR(256),
    FirstRecoveryForkID NVARCHAR(256),
    ForkPointLSN NVARCHAR(256),
    RecoveryModel NVARCHAR(256),
    DifferentialBaseLSN NVARCHAR(256),
    DifferentialBaseGUID NVARCHAR(256),
    BackupTypeDescription NVARCHAR(256),
    BackupSetGUID NVARCHAR(256),
    CompressedBackupSize NVARCHAR(256))

--add in aditional columns for later versions of SQL

IF CAST(PARSENAME(CAST(SERVERPROPERTY('productversion') AS VARCHAR), 4) AS INT) >= 11
BEGIN
	ALTER TABLE #BackupHeaders
	ADD containment TINYINT
END

IF CAST(PARSENAME(CAST(SERVERPROPERTY('productversion') AS VARCHAR), 4) AS INT) >= 12
BEGIN
	ALTER TABLE #BackupHeaders
	ADD KeyAlgorithm NVARCHAR(32),
	EncryptorThumbprint VARBINARY(20),
	EncryptorType NVARCHAR(32)
END

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

--if @BackupHistory is not 'msdb' then get deatails of backups from specified location
IF (@BackupDir IS NOT NULL) 
BEGIN
	--sanitise the @BackupDir and add trailing \ if needed
	IF (SUBSTRING(REVERSE(@BackupDir), 0, 1) != '\')
	BEGIN
		SET @BackupDir = @BackupDir + '\'
	END


	INSERT INTO #FileBackups(subdirectory, depth, [file])
	EXEC master.sys.xp_dirtree @BackupDir, 0, 1

	DECLARE @FileBackupPath NVARCHAR(4000)
	DECLARE @HeaderOnlyCmd NVARCHAR(4000) = ''

	DECLARE FileBackupsCur CURSOR STATIC LOCAL FOR
	SELECT subdirectory 
	FROM #FileBackups

	OPEN FileBackupsCur

	FETCH NEXT FROM FileBackupsCur INTO @FileBackupPath

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @FileBackupPath = @BackupDir + @FileBackupPath
		SET @HeaderOnlyCmd = N'RESTORE HEADERONLY FROM DISK = ''' + @FileBackupPath + N''''

		IF CAST(PARSENAME(CAST(SERVERPROPERTY('productversion') AS VARCHAR), 4) AS INT) >= 12 --run for SQL2014 onwards
		BEGIN
			INSERT INTO #BackupHeaders (BackupName, BackupDescription, BackupType, ExpirationDate, Compressed, Position, DeviceType, UserName, ServerName, DatabaseName, DatabaseVersion, DatabaseCreationDate, BackupSize, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN, BackupStartDate, BackupFinishDate, SortOrder, CodePage, UnicodeLocaleId, UnicodeComparisonStyle, CompatibilityLevel, SoftwareVendorId, SoftwareVersionMajor, SoftwareVersionMinor, SoftwareVersionBuild, MachineName, Flags, BindingID, RecoveryForkID, Collation, FamilyGUID, HasBulkLoggedData, IsSnapshot, IsReadOnly, IsSingleUser, HasBackupChecksums, IsDamaged, BeginsLogChain, HasIncompleteMetaData, IsForceOffline, IsCopyOnly, FirstRecoveryForkID, ForkPointLSN, RecoveryModel, DifferentialBaseLSN, DifferentialBaseGUID, BackupTypeDescription, BackupSetGUID, CompressedBackupSize, Containment, KeyAlgorithm, EncryptorThumbprint, EncryptorType)
			EXEC sp_executesql @HeaderOnlyCmd
		END
		ELSE IF CAST(PARSENAME(CAST(SERVERPROPERTY('productversion') AS VARCHAR), 4) AS INT) >= 11 --run for SQL2012 
		BEGIN
			INSERT INTO #BackupHeaders (BackupName, BackupDescription, BackupType, ExpirationDate, Compressed, Position, DeviceType, UserName, ServerName, DatabaseName, DatabaseVersion, DatabaseCreationDate, BackupSize, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN, BackupStartDate, BackupFinishDate, SortOrder, CodePage, UnicodeLocaleId, UnicodeComparisonStyle, CompatibilityLevel, SoftwareVendorId, SoftwareVersionMajor, SoftwareVersionMinor, SoftwareVersionBuild, MachineName, Flags, BindingID, RecoveryForkID, Collation, FamilyGUID, HasBulkLoggedData, IsSnapshot, IsReadOnly, IsSingleUser, HasBackupChecksums, IsDamaged, BeginsLogChain, HasIncompleteMetaData, IsForceOffline, IsCopyOnly, FirstRecoveryForkID, ForkPointLSN, RecoveryModel, DifferentialBaseLSN, DifferentialBaseGUID, BackupTypeDescription, BackupSetGUID, CompressedBackupSize, Containment)
			EXEC sp_executesql @HeaderOnlyCmd
		END
		ELSE --run for version prior to SQL2012
		BEGIN
			INSERT INTO #BackupHeaders (BackupName, BackupDescription, BackupType, ExpirationDate, Compressed, Position, DeviceType, UserName, ServerName, DatabaseName, DatabaseVersion, DatabaseCreationDate, BackupSize, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN, BackupStartDate, BackupFinishDate, SortOrder, CodePage, UnicodeLocaleId, UnicodeComparisonStyle, CompatibilityLevel, SoftwareVendorId, SoftwareVersionMajor, SoftwareVersionMinor, SoftwareVersionBuild, MachineName, Flags, BindingID, RecoveryForkID, Collation, FamilyGUID, HasBulkLoggedData, IsSnapshot, IsReadOnly, IsSingleUser, HasBackupChecksums, IsDamaged, BeginsLogChain, HasIncompleteMetaData, IsForceOffline, IsCopyOnly, FirstRecoveryForkID, ForkPointLSN, RecoveryModel, DifferentialBaseLSN, DifferentialBaseGUID, BackupTypeDescription, BackupSetGUID, CompressedBackupSize)
			EXEC sp_executesql @HeaderOnlyCmd
		END

		--add in the file path, we're going to assume that only the latest entry is going to have a NULL file path
		UPDATE #BackupHeaders
		SET FilePath = @FileBackupPath
		WHERE FilePath IS NULL

		FETCH NEXT FROM FileBackupsCur INTO @FileBackupPath
	END

	CLOSE FileBackupsCur
	DEALLOCATE FileBackupsCur

	SELECT * FROM #BackupHeaders

END


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
	
	
	SET @IsAGDatabase = 0
	SET @ReplicaName = ''

	--get all AG replicas for current database
	IF @AvailabilityGroupAware = 1  
	BEGIN
		IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName AND replica_id IS NOT NULL)
		BEGIN
			SET @IsAGDatabase = 1

			DECLARE ReplicaCur CURSOR LOCAL SCROLL STATIC READ_ONLY FOR 
					SELECT replica_server_name
					FROM sys.availability_databases_cluster databases
					JOIN sys.availability_replicas replicas ON databases.group_id = replicas.group_id
					WHERE database_name = @DatabaseName
					AND replica_server_name != @@SERVERNAME

			OPEN ReplicaCur
		END
		ELSE
		BEGIN
			SET @IsAGDatabase = 0
			RAISERROR('Selected database is not part of an availability group, only the local server''s backup history will be checked',9,1)
		END
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

		TRUNCATE TABLE #BackupDetails

		--if using a backup directory then get details from #BackupHeaders
		IF @BackupDir IS NOT NULL
		BEGIN
			INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
			SELECT TOP 1 'DISK = ''' + FilePath + '''',
			Position,
			BackupStartDate,
			BackupFinishDate,
			ServerName
			FROM #BackupHeaders
			WHERE DatabaseName = @DatabaseName
			AND BackupFinishDate < @RestoreToDate
			AND BackupType = 1
			AND IsCopyOnly IN (0,@IncludeCopyOnly)
			ORDER BY FirstLSN DESC
		END
		ELSE BEGIN  --get backup info from msdb
			--get latest backup from the local server
			INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
				SELECT TOP 1 CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
						WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
						WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
						WHEN device_type = 102 THEN  mediafamily.logical_device_name
						ELSE '***UNSUPPORTED DEVICE***'
				END, 
				position, 
				backup_start_date, 
				backup_finish_date,
				@@SERVERNAME
				FROM msdb.dbo.backupset backupset
				INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
				WHERE backupset.database_name = @DatabaseName
				AND backupset.backup_finish_date < @RestoreToDate
				AND backupset.type = 'D'
				AND is_copy_only IN (0,@IncludeCopyOnly)
				ORDER BY backup_finish_date DESC

			--if database is in an AG, cursor through other replicas and pull back ful back details
			IF @IsAGDatabase = 1
			BEGIN

				FETCH FIRST FROM ReplicaCur INTO @ReplicaName

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @Cmd = N'SELECT * FROM OPENROWSET(''SQLNCLI'',  ''Server=' + @ReplicaName + N';Trusted_Connection=yes;'', 
					''SELECT TOP 1 CASE	WHEN device_type = 2 THEN ''''DISK = '''' + mediafamily.physical_device_name + ''''''''
						WHEN device_type = 5 THEN ''''TAPE = '''' + mediafamily.physical_device_name + ''''''''
						WHEN device_type = 9 THEN ''''URL = '''' + mediafamily.physical_device_name + ''''''''
						WHEN device_type = 102 THEN  mediafamily.logical_device_name
						ELSE ''''***UNSUPPORTED DEVICE***''''
					END, 
					position, 
					backup_start_date, 
					backup_finish_date,
					@@SERVERNAME
					FROM msdb.dbo.backupset backupset
					INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
					WHERE backupset.database_name = ''''' + @DatabaseName + '''''
					AND backupset.backup_finish_date < ''''' + CONVERT(VARCHAR,@RestoreToDate, 112) + ' ' + CONVERT(VARCHAR, @RestoreToDate, 14) + '''''
					AND backupset.type = ''''D''''
					AND is_copy_only IN (0,''''' + CAST(@IncludeCopyOnly AS char(1)) + ''''')
					ORDER BY backup_finish_date DESC'')'


					BEGIN TRY
						INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
						EXEC (@Cmd)
					END TRY
					BEGIN CATCH
						SET @Error = 'Getting full backups; ' + @ReplicaName + ' is currently uncontactable and will be skipped. MSG: ' + ERROR_MESSAGE()
						RAISERROR (@Error,12, 1)
					END CATCH

					FETCH NEXT FROM ReplicaCur INTO @ReplicaName
				END

			END
		END

		SELECT @LastestBackupInSet = MAX(backup_start_date)
		FROM #BackupDetails


		INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand, takenOnServer)
		SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
						'RESTORE DATABASE ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + STUFF ((SELECT ',' + physical_device_name,
						0
		FROM #BackupDetails
		WHERE backup_start_date = @LastestBackupInSet
		FOR XML PATH('')),1,1,'') + ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR) AS Command, 'FULL',0, takenOnServer
		FROM #BackupDetails
		WHERE backup_start_date = @LastestBackupInSet
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

		TRUNCATE TABLE #BackupDetails

		--if using a backup directory then get details from #BackupHeaders
		IF @BackupDir IS NOT NULL
		BEGIN
			INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
			SELECT TOP 1 'DISK = ''' + FilePath + '''',
			Position,
			BackupStartDate,
			BackupFinishDate,
			ServerName
			FROM #BackupHeaders
			WHERE DatabaseName = @DatabaseName
			AND BackupFinishDate < @RestoreToDate
			AND BackupType = 5
			AND IsCopyOnly IN (0,@IncludeCopyOnly)
			ORDER BY FirstLSN DESC
		END
		ELSE BEGIN  --get backup info from msdb

			INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
			SELECT TOP 1 CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
								WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
								WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
								WHEN device_type = 102 THEN  mediafamily.logical_device_name
								ELSE '***UNSUPPORTED DEVICE***'
						END,
				position, 
				--RANK() OVER (ORDER BY backup_finish_date DESC) AS StartDateRank, 
				backup_start_date,
				backup_finish_date,
				@@SERVERNAME
				FROM msdb.dbo.backupset backupset
				INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
				WHERE backupset.database_name = @DatabaseName
				AND backupset.backup_finish_date < @RestoreToDate
				AND backupset.type = 'I'
				AND is_copy_only IN (0,@IncludeCopyOnly)
				ORDER BY backup_finish_date DESC

				--if database is in an AG, cursor through other replicas and pull back ful back details
				IF @IsAGDatabase = 1
				BEGIN

					FETCH FIRST FROM ReplicaCur INTO @ReplicaName

					WHILE @@FETCH_STATUS = 0
					BEGIN
						SET @Cmd = N'SELECT * FROM OPENROWSET(''SQLNCLI'',  ''Server=' + @ReplicaName + N';Trusted_Connection=yes;'', 
						''SELECT TOP 1 CASE	WHEN device_type = 2 THEN ''''DISK = '''' + mediafamily.physical_device_name + ''''''''
							WHEN device_type = 5 THEN ''''TAPE = '''' + mediafamily.physical_device_name + ''''''''
							WHEN device_type = 9 THEN ''''URL = '''' + mediafamily.physical_device_name + ''''''''
							WHEN device_type = 102 THEN  mediafamily.logical_device_name
							ELSE ''''***UNSUPPORTED DEVICE***''''
						END, 
						position, 
						backup_start_date, 
						backup_finish_date,
						@@SERVERNAME
						FROM msdb.dbo.backupset backupset
						INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
						WHERE backupset.database_name = ''''' + @DatabaseName + '''''
						AND backupset.backup_finish_date < ''''' + CONVERT(VARCHAR,@RestoreToDate, 112) + ' ' + CONVERT(VARCHAR, @RestoreToDate, 14) + '''''
						AND backupset.type = ''''I''''
						AND is_copy_only IN (0,''''' + CAST(@IncludeCopyOnly AS char(1)) + ''''')
						ORDER BY backup_finish_date DESC'')'

						BEGIN TRY
							INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
							EXEC (@Cmd)
						END TRY
						BEGIN CATCH
							SET @Error = 'Getting diff backups; ' + @ReplicaName + ' is currently uncontactable and will be skipped. MSG: ' + ERROR_MESSAGE()
							RAISERROR (@Error,12, 1)
						END CATCH

					FETCH NEXT FROM ReplicaCur INTO @ReplicaName
				END
			END
		END

		SELECT @LastestBackupInSet = MAX(backup_start_date)
		FROM #BackupDetails

		INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand, takenOnServer)
		SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
						'RESTORE DATABASE ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + STUFF ((SELECT ',' + physical_device_name,
						0
		FROM #BackupDetails
		WHERE backup_start_date = @LastestBackupInSet
		FOR XML PATH('')),1,1,'') + ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR) AS Command, 'DIFF',0, takenOnServer
		FROM #BackupDetails
		WHERE backup_start_date = @LastestBackupInSet
	END

	--get latest full or diff backup finish date
	SELECT @LastFullDiff = COALESCE(MAX(backup_finish_date),@FirstLogToRestore) FROM #BackupCommands

	--Get all log backups since last full or diff
	IF (@RestoreOptions IN ('ToLog','LogsOnly'))
	BEGIN

		TRUNCATE TABLE #BackupDetails

				--if using a backup directory then get details from #BackupHeaders
		IF @BackupDir IS NOT NULL
		BEGIN
			INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
			SELECT 'DISK = ''' + FilePath + '''',
			Position,
			BackupStartDate,
			BackupFinishDate,
			ServerName
			FROM #BackupHeaders
			WHERE DatabaseName = @DatabaseName
			AND BackupFinishDate < @RestoreToDate
			AND BackupType = 2
			AND IsCopyOnly IN (0,@IncludeCopyOnly)
		END
		ELSE BEGIN  --get backup info from msdb
			
			INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
			SELECT CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 102 THEN  mediafamily.logical_device_name
							ELSE '***UNSUPPORTED DEVICE***'
					END, 
			position, 
			backup_start_date, 
			backup_finish_date,
			@@SERVERNAME
			FROM msdb.dbo.backupset backupset
			INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
			WHERE backupset.database_name = @DatabaseName
			AND backupset.backup_finish_date > @LastFullDiff
			AND backupset.backup_finish_date < @RestoreToDate
			AND backupset.type = 'L'
            AND is_copy_only IN (0,@IncludeCopyOnly)

		--if database is in an AG, cursor through other replicas and pull back ful back details
			IF @IsAGDatabase = 1
			BEGIN

				FETCH FIRST FROM ReplicaCur INTO @ReplicaName

				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @Cmd = N'SELECT * FROM OPENROWSET(''SQLNCLI'',  ''Server=' + @ReplicaName + N';Trusted_Connection=yes;'', 
					''SELECT CASE	WHEN device_type = 2 THEN ''''DISK = '''' + mediafamily.physical_device_name + ''''''''
						WHEN device_type = 5 THEN ''''TAPE = '''' + mediafamily.physical_device_name + ''''''''
						WHEN device_type = 9 THEN ''''URL = '''' + mediafamily.physical_device_name + ''''''''
						WHEN device_type = 102 THEN  mediafamily.logical_device_name
						ELSE ''''***UNSUPPORTED DEVICE***''''
					END, 
					position, 
					backup_start_date, 
					backup_finish_date,
					@@SERVERNAME
					FROM msdb.dbo.backupset backupset
					INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
					WHERE backupset.database_name = ''''' + @DatabaseName + '''''
					AND backupset.backup_finish_date > ''''' + CONVERT(VARCHAR,@LastestBackupInSet, 112) + ' ' + CONVERT(VARCHAR, @LastestBackupInSet, 14) + '''''
					AND backupset.backup_finish_date < ''''' + CONVERT(VARCHAR,@RestoreToDate, 112) + ' ' + CONVERT(VARCHAR, @RestoreToDate, 14) + '''''
					AND backupset.type = ''''L''''
					AND is_copy_only IN (0,''''' + CAST(@IncludeCopyOnly AS char(1)) + ''''')'')'


					BEGIN TRY
						INSERT INTO #BackupDetails (physical_device_name, position, backup_start_date, backup_finish_date, takenOnServer)
						EXEC (@Cmd)
					END TRY
					BEGIN CATCH
						SET @Error = 'Getting log backups; ' + @ReplicaName + ' is currently uncontactable and will be skipped. MSG: ' + ERROR_MESSAGE()
						RAISERROR (@Error,12, 1)
					END CATCH

					FETCH NEXT FROM ReplicaCur INTO @ReplicaName
				END

			END
		END

		INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand, takenOnServer)
		SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
						'RESTORE LOG ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + 
							STUFF ((SELECT DISTINCT ',' + physical_device_name
							FROM #BackupDetails a
							WHERE a.backup_finish_date = b.backup_finish_date
							FOR XML PATH('')),1,1,'') 
						+ ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR) 
						+ CASE  WHEN @StopAtMark IS NOT NULL THEN ', STOPATMARK = ''' + @StopAtMark + ''''
								WHEN @StopBeforeMark IS NOT NULL THEN ', STOPBEFOREMARK = ''' + @StopBeforeMark + ''''
								ELSE ''
						 END AS Command, 'LOG',0, takenOnServer
		FROM #BackupDetails b
		ORDER BY backup_finish_date ASC
	END


	--Get point in time if enabled
	IF (@PointInTime = 1) AND (EXISTS (SELECT * FROM #BackupCommands WHERE AlterCommand = 0))
	BEGIN

		TRUNCATE TABLE #BackupDetails

		--if using a backup directory then get details from #BackupHeaders
		IF @BackupDir IS NOT NULL
		BEGIN
			INSERT INTO #BackupDetails (physical_device_name, position, StartDateRank, backup_finish_date, takenOnServer)
			SELECT 'DISK = ''' + FilePath + '''',
			Position,
			RANK() OVER (ORDER BY BackupFinishDate ASC) AS StartDateRank, 
			BackupFinishDate,
			ServerName
			FROM #BackupHeaders
			WHERE DatabaseName = @DatabaseName
			AND BackupFinishDate > @RestoreToDate
			AND BackupType = 2
			AND IsCopyOnly IN (0,@IncludeCopyOnly)
		END
		ELSE BEGIN  --get backup info from msdb
			INSERT INTO #BackupDetails (physical_device_name, position, StartDateRank, backup_finish_date, takenOnServer)
			SELECT CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
							WHEN device_type = 102 THEN  mediafamily.logical_device_name
							ELSE '***UNSUPPORTED DEVICE***'
					END, 
			position, 
			RANK() OVER (ORDER BY backup_finish_date ASC) AS StartDateRank, 
			backup_finish_date,
			@@SERVERNAME
			FROM msdb.dbo.backupset backupset
			INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
			WHERE backupset.database_name = @DatabaseName
			AND backupset.backup_finish_date > @RestoreToDate
			AND backupset.type = 'L'
			AND is_copy_only IN (0,@IncludeCopyOnly)
		END


		INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand)
		SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
						'RESTORE DATABASE ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + STUFF ((SELECT ',' + physical_device_name
		FROM #BackupCommands
		WHERE StartDateRank = 1
		FOR XML PATH('')),1,1,'') + ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR)  + ', STOPAT = ''' + CAST(@RestoreToDate AS VARCHAR) + '''' AS Command, 'LOG',0
		FROM #BackupDetails
		WHERE StartDateRank = 1

		--WITH BackupFilesCTE (physical_device_name, position, StartDateRank, backup_finish_date)
		--AS
		--	(SELECT CASE	WHEN device_type = 2 THEN 'DISK = ''' + mediafamily.physical_device_name + ''''
		--					WHEN device_type = 5 THEN 'TAPE = ''' + mediafamily.physical_device_name + ''''
		--					WHEN device_type = 9 THEN 'URL = ''' + mediafamily.physical_device_name + ''''
		--					WHEN device_type = 102 THEN  mediafamily.logical_device_name
		--					ELSE '***UNSUPPORTED DEVICE***'
		--			END, 
		--	position, 
		--	RANK() OVER (ORDER BY backup_finish_date ASC) AS StartDateRank, 
		--	backup_finish_date
		--	FROM msdb.dbo.backupset backupset
		--	INNER JOIN msdb.dbo.backupmediafamily mediafamily ON backupset.media_set_id = mediafamily.media_set_id
		--	WHERE backupset.database_name = @DatabaseName
		--	AND backupset.backup_finish_date > @RestoreToDate
		--	AND backupset.type = 'L'
  --          AND is_copy_only IN (0,@IncludeCopyOnly))

		--INSERT INTO #BackupCommands (backup_finish_date, DBName, command, BackupType, AlterCommand)
		--SELECT DISTINCT  backup_finish_date, @DatabaseName AS DBName,
		--				'RESTORE DATABASE ' + COALESCE(QUOTENAME(@RestoreAsName), QUOTENAME(@DatabaseName)) + ' FROM ' + STUFF ((SELECT ',' + physical_device_name
		--FROM BackupFilesCTE
		--WHERE StartDateRank = 1
		--FOR XML PATH('')),1,1,'') + ' WITH NORECOVERY, FILE = ' + CAST(position AS VARCHAR)  + ', STOPAT = ''' + CAST(@RestoreToDate AS VARCHAR) + '''' AS Command, 'LOG',0
		--FROM BackupFilesCTE
		--WHERE StartDateRank = 1
	END

	INSERT INTO #BackupCommandsFinal (backup_finish_date, DBName, command, BackupType, AlterCommand, takenOnServer)
	SELECT backup_finish_date, DBName, command, BackupType, AlterCommand, takenOnServer FROM #BackupCommands;

	TRUNCATE TABLE #BackupCommands

	IF (CURSOR_STATUS('local','ReplicaCur') != -3)
	BEGIN
		CLOSE ReplicaCur
		DEALLOCATE ReplicaCur
	END

	FETCH NEXT FROM DatabaseCur INTO @DatabaseName, @RestoreAsName
END


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

SELECT backup_finish_date, DBName, command, BackupType, takenOnServer
FROM #BackupCommandsFinal
ORDER BY DBName,backup_finish_date

--check for unsupported backup device and raise alert
IF EXISTS (SELECT command FROM #BackupCommandsFinal WHERE command LIKE '%***UNSUPPORTED DEVICE***%')
RAISERROR (N'One or more backups were taken to an unsupported device, possibly by a third party backup tool' , 15, 1)

END




