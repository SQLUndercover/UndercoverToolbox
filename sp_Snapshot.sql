/******************************************************************

Author: David Fowler
Revision date: 26 January 2024
Version: 2

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

CREATE OR ALTER PROC sp_snapshot (
	@DatabaseList NVARCHAR(4000)
	,@Suffix NVARCHAR(100) = 'snapshot'
	,@FilePath NVARCHAR(255) = ''
	,@Timestamp BIT = 0
	,@DateFormat INT = 126
	,@ListOnly BIT = 0
	)
AS
BEGIN
	SET NOCOUNT ON

	IF OBJECT_ID('tempdb..#DatabaseList') IS NOT NULL
		DROP TABLE #DatabaseList

	CREATE TABLE #DatabaseList (name NVARCHAR(4000))

	IF OBJECT_ID('tempdb..#DatabasesFinal') IS NOT NULL
		DROP TABLE #DatabasesFinal

	IF @Timestamp = 1
	BEGIN
		SET @Suffix += '_' + CONVERT(VARCHAR, GETDATE(), @DateFormat)
	END

	--we need to strip out certain characters from the file name that tend to occur in dates6
	SET @Suffix = REPLACE(@Suffix, ':', '')
	SET @Suffix = REPLACE(@Suffix, '\', '')
	SET @Suffix = REPLACE(@Suffix, '/', '')

	--select the database list into a temp table so that we can work with it
	INSERT INTO #DatabaseList
	SELECT value
	FROM STRING_SPLIT(@DatabaseList, ',')

	--get list of databases, including those covered by any wildcards
	SELECT QUOTENAME(name) AS name
	INTO #DatabasesFinal
	FROM sys.databases databases
	WHERE EXISTS (
			SELECT name
			FROM #DatabaseList
			WHERE databases.name LIKE #DatabaseList.name
			)

	IF @ListOnly = 1 --if @listonly set then only print the affected databases
		SELECT name
		FROM #DatabasesFinal
	ELSE
	BEGIN
		DECLARE @Databases VARCHAR(128)

		------------------------------------------------------------------------------------------------------
		--Loop through each database creating snapshots
		DECLARE databases_curr CURSOR
		FOR
		SELECT name
		FROM #DatabasesFinal

		OPEN databases_curr

		FETCH NEXT
		FROM databases_curr
		INTO @Databases

		WHILE @@FETCH_STATUS = 0
		BEGIN
			--create snapshots
			DECLARE @SQL VARCHAR(MAX)

			SET @SQL = 'USE ' + @Databases + 'DECLARE @DatabaseName VARCHAR(128)
				DECLARE @SnapshotName VARCHAR(128)
				SET @DatabaseName = DB_NAME()
				SET @SnapshotName = DB_NAME() + ''_' + @Suffix + 
				''' 
 
				--table variable to hold file list
				DECLARE @DatabaseFiles TABLE (id INT identity(1,1),name VARCHAR(128), physical_name VARCHAR(400), ss_file_name VARCHAR(4000)) 
 
				--populate table variable with file information
				INSERT INTO @DatabaseFiles (name, physical_name, ss_file_name)
				SELECT name, physical_name, REVERSE(SUBSTRING(REVERSE(Physical_name),CHARINDEX(''\'', REVERSE(physical_name),0),LEN(physical_name)))
				FROM sys.master_files
				WHERE type != 1 AND database_id = DB_ID()
 
				--begin building snapshot script
				DECLARE @SnapshotScript VARCHAR(1000)
				SET @SnapshotScript = ''CREATE DATABASE '' + QUOTENAME(@SnapshotName) + '' ON '' 
 
				--loop through datafile table variable
				DECLARE @LoopCounter INT = 0 
 
				DECLARE @FileCount INT
				SELECT @FileCount = COUNT(*)
				FROM @DatabaseFiles 
 
				WHILE @LoopCounter < @FileCount
				BEGIN
					SET @LoopCounter = @LoopCounter + 1

					IF ''' + @FilePath + 
				''' = ''''
					BEGIN
						SELECT @SnapshotScript = @SnapshotScript + ''(NAME = '' + QUOTENAME(name) + '', FILENAME = '''''' + ss_file_name + @SnapshotName + ''.ss''''),''
						FROM @DatabaseFiles
						WHERE id = @LoopCounter
					END 
					ELSE
					BEGIN
						SELECT @SnapshotScript = @SnapshotScript + ''(NAME = '' + QUOTENAME(name) + '', FILENAME = ''''' + @FilePath + ''' + @SnapshotName + ''.ss''''),''
						FROM @DatabaseFiles
						WHERE id = @LoopCounter
					END
				END 
 
				--loop will have added an unwanted comma at the end of the script, delete this comma
				SET @SnapshotScript = LEFT(@snapshotscript, LEN(@snapshotscript) -1) 
 
				--add AS SNAPSHOT to script
				SET @SnapshotScript = @SnapshotScript + '' AS SNAPSHOT OF ['' + @DatabaseName + '']'' 
 
				--Generate the snapshot
				PRINT ''Creating Snapshot for ' + @Databases + '''
				--PRINT @SnapshotScript
				EXEC (@SnapshotScript)'

			EXEC (@SQL)

			FETCH NEXT
			FROM databases_curr
			INTO @Databases
		END

		CLOSE databases_curr

		DEALLOCATE databases_curr
	END
END