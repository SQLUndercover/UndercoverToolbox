/******************************************************************

Author: David Fowler
Revision date: 14/08/2023
Version: 1

Audit restores from snapshot

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

CREATE TABLE SnapshotRestoreHistory
(LogDate DATETIME,
ProcessInfo VARCHAR(10),
[Text] VARCHAR(500) NOT NULL)
GO


CREATE PROC PopulateSnapshotRestoreHistory

AS

BEGIN
	--create temp holding table for log entries
	IF OBJECT_ID('tempdb.dbo.#SnapshotLogs') IS NOT NULL
	DROP TABLE #SnapshotLogs

	CREATE TABLE #SnapshotLogs
	(LogDate DATETIME,
	ProcessInfo VARCHAR(10),
	[Text] VARCHAR(500) NOT NULL)


	--temp table to be userd by Log sursor
	IF OBJECT_ID('tempdb.dbo.#LogFiles') IS NOT NULL
	DROP TABLE #LogFiles

	CREATE TABLE #LogFiles (LogNumber INT, StartDate DATETIME, SizeInBytes INT)

	INSERT INTO #LogFiles
	EXEC xp_enumerrorlogs 

	DECLARE @LogNumber INT
	DECLARE LogCur CURSOR LOCAL FAST_FORWARD FOR
	SELECT LogNumber
	FROM #LogFiles

	OPEN LogCur

	FETCH NEXT FROM LogCur INTO @LogNumber

	WHILE @@FETCH_STATUS = 0

	BEGIN
		--get entries from log file
		INSERT INTO #SnapshotLogs
		EXEC [sys].[sp_readerrorlog] @LogNumber,1,'Reverting database'

		--merge log entries in to history table
		MERGE SnapshotRestoreHistory AS Target
		USING #SnapshotLogs
		ON Target.LogDate = #SnapshotLogs.LogDate
			AND Target.[Text] = #SnapshotLogs.[Text]
		WHEN NOT MATCHED BY Target THEN
		INSERT (LogDate,ProcessInfo,[Text])
		VALUES (#SnapshotLogs.LogDate,#SnapshotLogs.ProcessInfo,#SnapshotLogs.[Text]);

		FETCH NEXT FROM LogCur INTO @LogNumber
	END 

	CLOSE LogCur

	DEALLOCATE LogCur

END