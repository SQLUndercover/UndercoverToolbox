/******************************************************************

Author: David Fowler
Revision date: 19 September 2017
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
 
CREATE PROCEDURE sp_Snapshot
(@DatabaseList NVARCHAR(4000),
@ListOnly BIT = 0)
 
AS
 
BEGIN
 
SET NOCOUNT ON
 
IF OBJECT_ID('tempdb..#DatabaseList') IS NOT NULL
    DROP TABLE #DatabaseList
 
CREATE TABLE #DatabaseList (name NVARCHAR(4000))
 
IF OBJECT_ID('tempdb..#DatabasesFinal') IS NOT NULL
    DROP TABLE #DatabasesFinal
 
--set compatibility mode
DECLARE @compatibility BIT
 
--set compatibility to 1 if server version includes STRING_SPLIT
SELECT  @compatibility = CASE
            WHEN SERVERPROPERTY ('productversion') >= '13.0.4001.0' AND Compatibility_Level >= 130 THEN 1
            ELSE 0
        END
FROM sys.databases
WHERE name = DB_NAME()
 
--select the database list into a temp table so that we can work with it
IF @compatibility = 1 --if compatibility = 1 then use STRING_SPLIT otherwise use fn_SplitString
    INSERT INTO #DatabaseList
    SELECT value
    FROM STRING_SPLIT(@DatabaseList,',')
ELSE
    INSERT INTO #DatabaseList
    SELECT StringElement AS name
    FROM master..fn_SplitString(@DatabaseList,',')
 
--get list of databases, including those covered by any wildcards
SELECT QUOTENAME(name) AS name
INTO #DatabasesFinal
FROM sys.databases databases
WHERE EXISTS
        (SELECT name
        FROM #DatabaseList
        WHERE databases.name LIKE #DatabaseList.name)   
 
IF @ListOnly = 1 --if @listonly set then only print the affected databases
SELECT name
FROM #DatabasesFinal
ELSE
BEGIN
 
    DECLARE @Databases VARCHAR(128)
 
    ------------------------------------------------------------------------------------------------------
    --Loop through each database creating snapshots
 
    DECLARE databases_curr CURSOR
    FOR SELECT name
        FROM #DatabasesFinal
 
    OPEN databases_curr
 
    FETCH NEXT FROM databases_curr
    INTO @Databases
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
 
        --create snapshots
 
        EXEC ('USE ' + @Databases +
            'DECLARE @DatabaseName VARCHAR(128)
            DECLARE @SnapshotName VARCHAR(128)
            SET @DatabaseName = DB_NAME()
            SET @SnapshotName = DB_NAME() + ''_snapshot'' 
 
            --table variable to hold file list
            DECLARE @DatabaseFiles TABLE (id INT identity(1,1),name VARCHAR(128), physical_name VARCHAR(400)) 
 
            --populate table variable with file information
            INSERT INTO @DatabaseFiles (name, physical_name)
            SELECT name, physical_name
            FROM sys.database_files
            WHERE type != 1 
 
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
            SELECT @SnapshotScript = @SnapshotScript + ''(NAME = '' + QUOTENAME(name) + '', FILENAME = '''''' + physical_name + ''.ss''''),''
            FROM @DatabaseFiles
            WHERE id = @LoopCounter
            END 
 
            --loop will have added an unwanted comma at the end of the script, delete this comma
            SET @SnapshotScript = LEFT(@snapshotscript, LEN(@snapshotscript) -1) 
 
            --add AS SNAPSHOT to script
            SET @SnapshotScript = @SnapshotScript + '' AS SNAPSHOT OF ['' + @DatabaseName + '']'' 
 
            --Generate the snapshot
            PRINT ''Creating Snapshot for ' + @Databases + '''
            EXEC (@SnapshotScript)')
 
        FETCH NEXT FROM databases_curr
        INTO @Databases
    END
 
    CLOSE databases_curr
    DEALLOCATE databases_curr
END
END