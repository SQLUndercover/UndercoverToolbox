/******************************************************************

Author: David Fowler
Revision date: 12 June 2019
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
 

CREATE PROCEDURE sp_AGFailover 
	@AvailabilityGroup VARCHAR(1000) = NULL, --will take a comma delimited list of AG names, leaving as NULL will failover all AGs
	@WaitForHealthy INT = 1, --wait for AG to report as healthy before moving on to the next
	@WhatIf INT = 0		--when set to 1, the proc will report which AGs would be failed over with the current parameter settings but no failover will actually take place
AS

BEGIN
	DECLARE @FailoverSTMT NVARCHAR(300)
	DECLARE @GroupID UNIQUEIDENTIFIER
	DECLARE @AGName SYSNAME
	DECLARE @InfoMsg VARCHAR(500)

	--set compatibility mode
	DECLARE @compatibility BIT

	--set compatibility to 1 if server version includes STRING_SPLIT
	SELECT	@compatibility = CASE
				WHEN SERVERPROPERTY ('productversion') >= '13.0.4001.0' AND Compatibility_Level >= 130 THEN 1
				ELSE 0
			END
	FROM sys.databases
	WHERE name = DB_NAME()


	--create temp table to hold a list of availability groups
	IF OBJECT_ID('tempdb.dbo.#AGList') IS NOT NULL
	DROP TABLE #AGList

	CREATE TABLE #AGList
	(AGName SYSNAME)

	--use fn_StringSplit to populate #AGList
	IF @AvailabilityGroup IS NOT NULL
	BEGIN
		--if compatibility mode = 1 then it's safe to use STRING_SPLIT, otherwise use fn_SplitString
		IF (@Compatibility = 1)
		BEGIN 			
			INSERT INTO #AGList
			SELECT value
			FROM STRING_SPLIT(@AvailabilityGroup,',')
		END
		ELSE
		BEGIN
			INSERT INTO #AGList
			SELECT StringElement
			FROM master.dbo.fn_SplitString(@AvailabilityGroup,',')
		END
	END
	ELSE
	BEGIN --if @AvailabilityGroup is null then populate #AGList with all availability groups
		INSERT INTO #AGList
		SELECT name
		FROM sys.availability_groups
	END


	DECLARE AGsCur CURSOR LOCAL FAST_FORWARD
	FOR
		SELECT N'ALTER AVAILABILITY GROUP ' + QUOTENAME(name) + N' FAILOVER;' AS FailoverSTMT, 
			group_id,
			name
		FROM sys.availability_groups
		WHERE name IN (SELECT AGName FROM #AGList)

	OPEN AGsCur

	FETCH NEXT FROM AGsCur INTO @FailoverSTMT, @GroupID, @AGName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @InfoMsg = 'Failing Over ' + @AGName
		RAISERROR (@InfoMsg,0,1)
	
		IF @WhatIf = 0
		BEGIN
			EXEC sp_executesql @FailoverSTMT

			--check AG health, loop until it reports healthy
			RAISERROR ('Waiting For AG To Report Healthy...',0,1)
			WHILE (((SELECT synchronization_health_desc FROM sys.dm_hadr_availability_group_states WHERE group_id = @GroupID) != 'HEALTHY') AND (@WaitForHealthy = 1))
			BEGIN
				WAITFOR DELAY '00:00:01'
			END
		END
		ELSE
		RAISERROR ('WhatIf = 1, no changes have been made',0,1)

		FETCH NEXT FROM AGsCur INTO @FailoverSTMT, @GroupID, @AGName
	END

	CLOSE AGsCur

	DEALLOCATE AGsCur

END