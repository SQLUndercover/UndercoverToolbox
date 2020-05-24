/*********************************************
Description: BlitzWaits Custom module for the Inspector
			 This Module will install as DISABLED so that you can set your schedule for BlitzWaits in Inspector.ModuleConfig
			 Report on waits collected by sp_BlitzFirst
			 To highlight certain wait types "Watched wait types" insert the wait type name into [Inspector].[BlitzWait_WatchedWaitTypes] and set a WarningLevel 1,2 or 3
			 which will use the built in highlighting colour system, Default: 1 = Red, 2 = Yellow , 3 = White. Highlighted waits will also show Warnings/Advisory text in the
			 Report headers.
			 Use the settings 'BlitzWaitsTopXRows' and 'BlitzWaitsHourlyBucketSize' to control how many rows are return and the rollup of data - going too granular
			 i.e BlitzWaitsTopXRows = 5 and BlitzWaitsHourlyBucketSize = 1 will show you the TOP 5 waits per hour , if your report is set to a frequency of 1440 that will be 120 rows! so 
			 it is up to you how much you want to see.

Author: Adrian Buckman
Revision date: 24/05/2020
Credit: Brent Ozar unlimited and its contributors, part of the code used in [Inspector].[BlitzWaitsReport] is a revision of the view [dbo].[BlitzFirst_WaitStats_Deltas].

© www.sqlundercover.com 

MIT License
------------
 
Copyright 2019 Sql Undercover
 
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
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;


--These Parameters control the report size TOP X wait stats and the size of the buckets for summing of waits deltas. Can be changed in the Settings table at any time
DECLARE @BlitzWaitsTopXRows TINYINT = 3;
DECLARE @BlitzWaitsHourlyBucketSize TINYINT = 2;

--Alternating bucket colours specify a html color as hex, can be changed later in the settings table
DECLARE @BlitzWaitsBucketColourOdd VARCHAR(7) = '#E6F5FF'
DECLARE @BlitzWaitsBucketColourEven VARCHAR(7) = '#CCEBFF'

--Set the ModuleConfig to use, specify an existing one or a new one to if you want this to report independently
DECLARE @ModuleConfig VARCHAR(20) = 'Default'; -- Append to the Default ModuleConfig or specify a new ModuleConfig i.e 'BlitzWaits'

--Frequency ,Start and End times only apply if the @ModuleConfig does not exist as we do not want to update your existing schedules.
DECLARE @ReportFrequencyMins SMALLINT = 1440;  --Maximum supported value is 1440 (once a day)
DECLARE @ReportStartTime TIME(0) = '09:00';
DECLARE @ReportEndTime TIME(0) = '18:00';

--Enable or Disable the module following installation
DECLARE @EnableModule BIT = 1;

--see waits from your watched list IF the threshold was breached (this will increase rows returned in the bucket if breaches are present), can be changed in the Settings table at any time
DECLARE @BlitzWaitsAlwaysShowBreached BIT = 1;


/*
Poison waits included:
CMEMTHREAD 
IO_QUEUE_LIMIT 
IO_RETRY 
LOG_RATE_GOVERNOR 
POOL_LOG_RATE_GOVERNOR 
PREEMPTIVE_DEBUG 
RESMGR_THROTTLED 
RESOURCE_SEMAPHORE 
RESOURCE_SEMAPHORE_QUERY_COMPILE 
THREADPOOL
*/



DECLARE @Revisiondate DATE = '20200524';
DECLARE @InspectorBuild DECIMAL(4,2) = (SELECT TRY_CAST([Value] AS DECIMAL(4,2)) FROM [Inspector].[Settings] WHERE [Description] = 'InspectorBuild');


--Ensure that Blitz tables exist
IF (OBJECT_ID(N'dbo.BlitzFirst_WaitStats') IS NULL OR OBJECT_ID(N'dbo.BlitzFirst_WaitStats_Categories') IS NULL)
BEGIN 
	RAISERROR('BlitzFirst_WaitStats and BlitzFirst_WaitStats_Categories Tables not present in this database, please double check the database name is correct - the Inspector must be installed in the same database where your Blitz collection data is stored',11,0);
	RETURN;
END		

--Ensure that the Inspector schema exists
IF SCHEMA_ID(N'Inspector') IS NOT NULL
BEGIN 

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[BlitzWaits_WatchedWaitTypes]') AND type in (N'U'))
BEGIN
	CREATE TABLE [Inspector].[BlitzWaits_WatchedWaitTypes](
		[Servername] [NVARCHAR](128) NOT NULL,
		[Wait_type] [NVARCHAR](60) NOT NULL,
		[WarningLevel] [TINYINT] NOT NULL,
		[IsActive] BIT NOT NULL,
		[Threshold] DECIMAL(8,2) NULL,
	    [ThresholdDirection] CHAR(1)
	);
END

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[Inspector].[CheckBlitzWaitWarningLevel]') AND parent_object_id = OBJECT_ID(N'[Inspector].[BlitzWaits_WatchedWaitTypes]'))
BEGIN
	ALTER TABLE [Inspector].[BlitzWaits_WatchedWaitTypes] WITH CHECK ADD CONSTRAINT [CheckBlitzWaitWarningLevel] CHECK  (([WarningLevel]<(4)));
END

IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[Inspector].[CheckBlitzThresholdDirection]') AND parent_object_id = OBJECT_ID(N'[Inspector].[BlitzWaits_WatchedWaitTypes]'))
BEGIN
	ALTER TABLE [Inspector].[BlitzWaits_WatchedWaitTypes] WITH CHECK ADD CONSTRAINT [CheckBlitzThresholdDirection] CHECK  (([ThresholdDirection] IN ('<','>') OR [ThresholdDirection] IS NULL));
END

 
INSERT INTO [Inspector].[BlitzWaits_WatchedWaitTypes] ([Servername],[Wait_type],[WarningLevel],[IsActive],[Threshold],[ThresholdDirection])
SELECT 
[Servername],
[Waits].[WaitType],
1 AS [WarningLevel],
1 AS [IsActive],
10.00 AS [Threshold],
'>' AS [ThresholdDirection]
FROM [Inspector].[CurrentServers]
CROSS APPLY (
			VALUES
			('CMEMTHREAD'),
			('IO_QUEUE_LIMIT'),
			('IO_RETRY'),
			('LOG_RATE_GOVERNOR'),
			('POOL_LOG_RATE_GOVERNOR'),
			('PREEMPTIVE_DEBUG'),
			('RESMGR_THROTTLED'),
			('RESOURCE_SEMAPHORE'),
			('RESOURCE_SEMAPHORE_QUERY_COMPILE'), 
			('THREADPOOL')) AS Waits (WaitType)
WHERE NOT EXISTS (SELECT 1 FROM [Inspector].[BlitzWaits_WatchedWaitTypes] WatchedWaits WHERE [WatchedWaits].[Servername] = [CurrentServers].[Servername] AND [WatchedWaits].[Wait_type] = [Waits].[WaitType]);


IF OBJECT_ID('Inspector.MonitorHours',N'U') IS NULL 
BEGIN 
	CREATE TABLE [Inspector].[MonitorHours](
	[Servername] NVARCHAR(128) NULL,
	[Modulename] VARCHAR(50) NULL,
	[MonitorHourStart] INT NOT NULL,
	[MonitorHourEnd] INT NOT NULL
	);

	EXEC sp_executesql N'CREATE UNIQUE CLUSTERED INDEX [CIX_Servername_Modulename] ON [Inspector].[MonitorHours] ([Servername],[Modulename]);';
END


EXEC sp_executesql N'
IF NOT EXISTS(SELECT 1 FROM [Inspector].[MonitorHours] WHERE Servername = @@SERVERNAME AND Modulename = ''BlitzWaits'') 
BEGIN 
	INSERT INTO [Inspector].[MonitorHours] ([Servername],[Modulename],[MonitorHourStart],[MonitorHourEnd])
	VALUES(@@SERVERNAME,''BlitzWaits'',0,23);
END';

IF NOT EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'BlitzWaitsTopXRows')
BEGIN 
	INSERT INTO [Inspector].[Settings] ([Description],[Value])
	VALUES('BlitzWaitsTopXRows',@BlitzWaitsTopXRows);
END
ELSE 
BEGIN 
	UPDATE [Inspector].[Settings]
	SET [Value] = @BlitzWaitsTopXRows
	WHERE [Description] = 'BlitzWaitsTopXRows';
END 

IF NOT EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'BlitzWaitsHourlyBucketSize')
BEGIN 
	INSERT INTO [Inspector].[Settings] ([Description],[Value])
	VALUES('BlitzWaitsHourlyBucketSize',@BlitzWaitsHourlyBucketSize);
END
ELSE 
BEGIN 
	UPDATE [Inspector].[Settings]
	SET [Value] = @BlitzWaitsHourlyBucketSize
	WHERE [Description] = 'BlitzWaitsHourlyBucketSize';
END 


IF NOT EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'BlitzWaitsAlwaysShowBreached')
BEGIN 
	INSERT INTO [Inspector].[Settings] ([Description],[Value])
	VALUES('BlitzWaitsAlwaysShowBreached',@BlitzWaitsAlwaysShowBreached);
END


IF NOT EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'BlitzWaitsBucketColourOdd')
BEGIN 
	INSERT INTO [Inspector].[Settings] ([Description],[Value])
	VALUES('BlitzWaitsBucketColourOdd',@BlitzWaitsBucketColourOdd);
END

IF NOT EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'BlitzWaitsBucketColourEven')
BEGIN 
	INSERT INTO [Inspector].[Settings] ([Description],[Value])
	VALUES('BlitzWaitsBucketColourEven',@BlitzWaitsBucketColourEven);
END


IF OBJECT_ID('Inspector.BlitzWaitsReport',N'P') IS NULL 
BEGIN 
	EXEC('CREATE PROCEDURE [Inspector].[BlitzWaitsReport] AS');
END 

IF OBJECT_ID('Inspector.BlitzWaitsReport',N'P') IS NOT NULL
BEGIN 
	EXEC ('
ALTER PROCEDURE [Inspector].[BlitzWaitsReport] (
@Servername NVARCHAR(128),
@Modulename VARCHAR(50),
@TableHeaderColour VARCHAR(7) = ''#E6E6FA'',
@WarningHighlight VARCHAR(7),
@AdvisoryHighlight VARCHAR(7),
@InfoHighlight VARCHAR(7),
@ModuleConfig VARCHAR(20),
@WarningLevel TINYINT,
@ServerSpecific BIT,
@NoClutter BIT,
@TableTail VARCHAR(256),
@HtmlOutput VARCHAR(MAX) OUTPUT,
@CollectionOutOfDate BIT OUTPUT,
@PSCollection BIT,
@Debug BIT = 0
)
AS
BEGIN
--Revision date: 24/05/2020
/*
Explanation of the logic used here:
DATEADD(HOUR,(DATEPART(HOUR,CheckDate)%@HourlyBucketSize)/-1,DATEADD(HOUR, DATEDIFF(HOUR, 0, CheckDate), 0))

Round the CheckDate down to the Hour it occured within then use Mod to work out the required offset to satisfy the bucket size , then multiply by -1 to turn negative.

DATEADD(HOUR,(DATEPART(HOUR,CheckDate)%@HourlyBucketSize)/-1,DATEADD(HOUR, DATEDIFF(HOUR, 0, CheckDate), 0))
*/


	DECLARE @HtmlTableHead VARCHAR(4000);
	DECLARE @Columnnames VARCHAR(2000);
	DECLARE @SQLtext NVARCHAR(4000);
	DECLARE @MonitorHourStart INT;
	DECLARE @MonitorHourEnd INT;
	DECLARE @Frequency INT;
	DECLARE @Top INT = (SELECT ISNULL(TRY_CAST([Value] AS INT),3) FROM [Inspector].[Settings] WHERE [Description] = ''BlitzWaitsTopXRows''); 
	DECLARE @HourlyBucketSize INT = (SELECT ISNULL(TRY_CAST([Value] AS INT),3) FROM [Inspector].[Settings] WHERE [Description] = ''BlitzWaitsHourlyBucketSize''); 
	DECLARE @AlwaysShowBreached BIT = (SELECT ISNULL(TRY_CAST([Value] AS BIT),0) FROM [Inspector].[Settings] WHERE [Description] = ''BlitzWaitsAlwaysShowBreached'');
	DECLARE @BlitzWaitsBucketColourOdd VARCHAR(7) = (SELECT ISNULL(TRY_CAST([Value] AS VARCHAR(7)),''#FFFFFF'') FROM [Inspector].[Settings] WHERE [Description] = ''BlitzWaitsBucketColourOdd'');
	DECLARE @BlitzWaitsBucketColourEven VARCHAR(7) = (SELECT ISNULL(TRY_CAST([Value] AS VARCHAR(7)),''#FFFFFF'') FROM [Inspector].[Settings] WHERE [Description] = ''BlitzWaitsBucketColourEven'');
	DECLARE @CheckDate DATETIMEOFFSET(7);

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	EXEC [Inspector].[GetMonitorHours] 
		@Servername = @Servername,
		@Modulename = @Modulename, 
		@MonitorHourStart  = @MonitorHourStart OUTPUT,
		@MonitorHourEnd = @MonitorHourEnd OUTPUT;

	EXEC [Inspector].[GetModuleConfigFrequency] 
		@ModuleConfig = @ModuleConfig,
		@Frequency = @Frequency OUTPUT;

	SET @CheckDate = DATEADD(MINUTE,-@Frequency,SYSDATETIMEOFFSET());

	IF (@Top IS NULL) BEGIN SET @Top = 3 END;
	IF (@HourlyBucketSize IS NULL) BEGIN SET @HourlyBucketSize = 1 END;
	IF ((@HourlyBucketSize*60) > @Frequency) BEGIN SET @HourlyBucketSize = @Frequency/60 END
	IF (@AlwaysShowBreached IS NULL) BEGIN SET @AlwaysShowBreached = 0 END
	IF (@BlitzWaitsBucketColourOdd IS NULL) BEGIN SET @BlitzWaitsBucketColourOdd = ''#bffffc'' END
	IF (@BlitzWaitsBucketColourEven IS NULL) BEGIN SET @BlitzWaitsBucketColourEven = ''#bfe8ff'' END
	IF @MonitorHourStart IS NULL BEGIN SET @MonitorHourStart = 0 END;
	IF @MonitorHourEnd IS NULL BEGIN SET @MonitorHourEnd = 23 END;


/********************************************************/
	--Your query MUST have a case statement that determines which colour to highlight rows
	--Your query MUST use an INTO clause to populate the temp table so that the column names can be determined for the report
	--@bgcolor is used the for table highlighting , Warning,Advisory and Info highlighting colours are determined from 
	--the ModuleWarningLevel table and your Case expression And/or Where clause will determine which rows get the highlight
	--Look for /**  OPTIONAL  **/ headings throughout the query as you may want to change defaults.
	--query example:

/**  REQUIRED  **/ --Add your query below

--for collected data reference an Inspector table
IF OBJECT_ID(''tempdb.dbo.#Deltas'') IS NOT NULL 
DROP TABLE #Deltas;


CREATE TABLE #Deltas ( 
[ServerName] NVARCHAR(128) COLLATE DATABASE_DEFAULT NOT NULL,
[CheckDate] DATETIMEOFFSET(7) NOT NULL,
[wait_type] NVARCHAR(60) COLLATE DATABASE_DEFAULT NOT NULL,
[WaitCategory] NVARCHAR(128) COLLATE DATABASE_DEFAULT NOT NULL,
[Ignorable] BIT NOT NULL,
[ElapsedSeconds] INT NULL,
[wait_time_ms_delta] BIGINT NOT NULL,
[wait_time_minutes_delta] BIGINT NOT NULL,
[wait_time_minutes_per_minute] BIGINT NOT NULL,
[signal_wait_time_ms_delta] BIGINT NOT NULL,
[waiting_tasks_count_delta] BIGINT NOT NULL,
[CheckDateBucket] DATETIMEOFFSET(7) NOT NULL
);

IF OBJECT_ID(''tempdb.dbo.#RowDates'') IS NOT NULL 
DROP TABLE #RowDates;

CREATE TABLE #RowDates (
[ID] BIGINT NOT NULL,
[CheckDate] DATETIMEOFFSET(7) NOT NULL,
[CheckDateBucket] DATETIMEOFFSET(7) NOT NULL
);


INSERT INTO #RowDates ([ID], [CheckDate], [CheckDateBucket])
SELECT 
	ROW_NUMBER() OVER (ORDER BY [ServerName], [CheckDate]) ID,
	[CheckDate],
	DATEADD(HOUR,(DATEPART(HOUR,CheckDate)%@HourlyBucketSize)/-1,DATEADD(HOUR, DATEDIFF(HOUR, 0, CheckDate), 0)) AS CheckDateBucket
FROM [dbo].[BlitzFirst_WaitStats]
WHERE CheckDate >= @CheckDate
AND ServerName = @Servername
GROUP BY [ServerName], [CheckDate];

WITH CheckDates as
(
        SELECT ThisDate.CheckDate,
               LastDate.CheckDate as PreviousCheckDate,
			   ThisDate.CheckDateBucket
        FROM #RowDates ThisDate
        JOIN #RowDates LastDate
        ON ThisDate.ID = LastDate.ID + 1
),
Deltas as (
	SELECT w.ServerName, w.CheckDate, w.wait_type, COALESCE(wc.WaitCategory, ''Other'') AS WaitCategory, COALESCE(wc.Ignorable,0) AS Ignorable
	, DATEDIFF(ss, wPrior.CheckDate, w.CheckDate) AS ElapsedSeconds
	, (w.wait_time_ms - wPrior.wait_time_ms) AS wait_time_ms_delta
	, (w.wait_time_ms - wPrior.wait_time_ms) / 60000.0 AS wait_time_minutes_delta
	, (w.wait_time_ms - wPrior.wait_time_ms) / 1000.0 / DATEDIFF(ss, wPrior.CheckDate, w.CheckDate) AS wait_time_minutes_per_minute
	, (w.signal_wait_time_ms - wPrior.signal_wait_time_ms) AS signal_wait_time_ms_delta
	, (w.waiting_tasks_count - wPrior.waiting_tasks_count) AS waiting_tasks_count_delta
	,Dates.CheckDateBucket
	FROM [dbo].[BlitzFirst_WaitStats] w
	INNER JOIN CheckDates Dates
	ON Dates.CheckDate = w.CheckDate
	INNER JOIN [dbo].[BlitzFirst_WaitStats] wPrior ON w.ServerName = wPrior.ServerName AND w.wait_type = wPrior.wait_type AND Dates.PreviousCheckDate = wPrior.CheckDate
	LEFT OUTER JOIN [dbo].[BlitzFirst_WaitStats_Categories] wc ON w.wait_type = wc.WaitType
	WHERE DATEDIFF(MI, wPrior.CheckDate, w.CheckDate) BETWEEN 1 AND 60
	AND [w].[wait_time_ms] >= [wPrior].[wait_time_ms]
	AND w.ServerName = @Servername
)
INSERT INTO #Deltas (
	[ServerName],
	[CheckDate],
	[wait_type],
	[WaitCategory],
	[Ignorable],
	[ElapsedSeconds],
	[wait_time_ms_delta],
	[wait_time_minutes_delta],
	[wait_time_minutes_per_minute],
	[signal_wait_time_ms_delta],
	[waiting_tasks_count_delta],
	[CheckDateBucket]
)
SELECT 
	[ServerName],
	[CheckDate],
	[wait_type],
	[WaitCategory],
	[Ignorable],
	[ElapsedSeconds],
	[wait_time_ms_delta],
	[wait_time_minutes_delta],
	[wait_time_minutes_per_minute],
	[signal_wait_time_ms_delta],
	[waiting_tasks_count_delta],
	[CheckDateBucket]
FROM Deltas;

WITH Buckets as (
	SELECT 
	ServerName,
	wait_type,
	CheckDateBucket,
	DENSE_RANK() OVER(ORDER BY CheckDateBucket ASC) AS BucketNumber,
	SUM(wait_time_ms_delta) AS wait_time_ms_delta,
	SUM(wait_time_minutes_delta) AS wait_time_minutes_delta,
	SUM(wait_time_minutes_per_minute) AS wait_time_minutes_per_minute,
	SUM(signal_wait_time_ms_delta) AS signal_wait_time_ms_delta,
	SUM(waiting_tasks_count_delta) AS waiting_tasks_count_delta
	FROM #Deltas
	WHERE DATEPART(HOUR,[CheckDate]) BETWEEN @MonitorHourStart AND @MonitorHourEnd
	GROUP BY 
	ServerName,
	wait_type,
	CheckDateBucket
)
SELECT 
CASE WHEN [@bgcolor] = ''#FFFFFF'' THEN CASE
											WHEN [BucketNumber]%2 = 0 THEN @BlitzWaitsBucketColourEven
											WHEN [BucketNumber]%2 != 0 THEN @BlitzWaitsBucketColourOdd
											ELSE ''#FFFFFF''
										END
	ELSE [@bgcolor]
END AS [@bgcolor],
[ServerName],
[Watched],
[HourlyBucket],
[wait_type],
[wait_time_ms_delta],
[wait_time_minutes_delta],
[wait_time_minutes_per_minute],
[signal_wait_time_ms_delta],
[waiting_tasks_count_delta],
[wait_time_ms_per_wait],
[Threshold],
[ThresholdType]
INTO #InspectorModuleReport
FROM
(
	SELECT
	CASE 
		WHEN [BlitzWaits_WatchedWaitTypes].[WarningLevel] = 1 AND [IsActive] = 1 THEN @WarningHighlight
		WHEN [BlitzWaits_WatchedWaitTypes].[WarningLevel] = 2 AND [IsActive] = 1 THEN @AdvisoryHighlight
		WHEN [BlitzWaits_WatchedWaitTypes].[WarningLevel] = 3 AND [IsActive] = 1 THEN @InfoHighlight
		ELSE ''#FFFFFF''
	END AS [@bgcolor],
	[BucketWaits].[ServerName],
	ISNULL([BlitzWaits_WatchedWaitTypes].[IsActive],0) AS Watched,
	CONVERT(VARCHAR(17),[HourlyBucket],113) AS [HourlyBucket],
	[BucketWaits].[wait_type],
	[wait_time_ms_delta],
	CAST([wait_time_minutes_delta] AS DECIMAL(8,2)) AS [wait_time_minutes_delta],
	CAST([wait_time_minutes_per_minute] AS DECIMAL(8,2)) AS [wait_time_minutes_per_minute],
	[signal_wait_time_ms_delta],
	[waiting_tasks_count_delta],
	CAST([wait_time_ms_per_wait] AS DECIMAL(8,2)) AS [wait_time_ms_per_wait],
	ISNULL([BlitzWaits_WatchedWaitTypes].Threshold,0) AS Threshold,
	CASE 
		WHEN [IsActive] = 0 THEN ''None''
		WHEN [ThresholdDirection] = ''<'' THEN ''Less Than''
		WHEN [ThresholdDirection] = ''>'' THEN ''More Than''
		ELSE ''None''
	END AS ThresholdType,
	BucketNumber
	FROM 
	(
		SELECT 
		TopBucketWaits.ServerName, 
		TopBucketWaits.CheckDateBucket AS HourlyBucket,
		TopBucketWaits.wait_type, 
		TopBucketWaits.wait_time_ms_delta,
		TopBucketWaits.wait_time_minutes_delta,
		TopBucketWaits.wait_time_minutes_per_minute,
		TopBucketWaits.signal_wait_time_ms_delta,
		TopBucketWaits.waiting_tasks_count_delta,
		TopBucketWaits.wait_time_ms_per_wait,
		BucketNumber
		FROM (SELECT DISTINCT [CheckDateBucket] FROM #RowDates) AS RowDates
		CROSS APPLY (SELECT TOP (@Top) 
					 ServerName,
					 CheckDateBucket,
					 wait_type,
					 wait_time_ms_delta,
					 wait_time_minutes_delta,
					 wait_time_minutes_per_minute,
					 signal_wait_time_ms_delta,
					 waiting_tasks_count_delta,
					 ISNULL((CAST([wait_time_ms_delta] AS MONEY)/NULLIF(CAST([waiting_tasks_count_delta] AS MONEY),0)),0) AS wait_time_ms_per_wait,
					 BucketNumber
					 FROM Buckets
					 WHERE RowDates.CheckDateBucket = Buckets.CheckDateBucket
					 ORDER BY wait_time_ms_delta DESC
					 ) AS TopBucketWaits
	) BucketWaits
	LEFT JOIN [Inspector].[BlitzWaits_WatchedWaitTypes] ON BucketWaits.[wait_type] = [BlitzWaits_WatchedWaitTypes].[Wait_type] AND BucketWaits.ServerName = [BlitzWaits_WatchedWaitTypes].[Servername]
	UNION --Show watched wait types even if they are not in the Top X waits if @AlwaysShowBreached = 1
	SELECT 
	CASE 
		WHEN [BlitzWaits_WatchedWaitTypes].[WarningLevel] = 1 AND [IsActive] = 1 THEN @WarningHighlight
		WHEN [BlitzWaits_WatchedWaitTypes].[WarningLevel] = 2 AND [IsActive] = 1 THEN @AdvisoryHighlight
		WHEN [BlitzWaits_WatchedWaitTypes].[WarningLevel] = 3 AND [IsActive] = 1 THEN @InfoHighlight
		ELSE ''#FFFFFF''
	END AS [@bgcolor],
	BucketWaits.ServerName, 
	ISNULL([BlitzWaits_WatchedWaitTypes].[IsActive],0) AS Watched,
	CONVERT(VARCHAR(17),CheckDateBucket,113) AS HourlyBucket,
	BucketWaits.wait_type, 
	wait_time_ms_delta,
	wait_time_minutes_delta,
	wait_time_minutes_per_minute,
	signal_wait_time_ms_delta,
	waiting_tasks_count_delta,
	CAST(ISNULL((CAST([wait_time_ms_delta] AS MONEY)/NULLIF(CAST([waiting_tasks_count_delta] AS MONEY),0)),0) AS DECIMAL(8,2)) AS wait_time_ms_per_wait,
	ISNULL([BlitzWaits_WatchedWaitTypes].Threshold,0) AS Threshold,
	CASE 
		WHEN [IsActive] = 0 THEN ''None''
		WHEN [ThresholdDirection] = ''<'' THEN ''Less Than''
		WHEN [ThresholdDirection] = ''>'' THEN ''More Than''
		ELSE ''None''
	END AS ThresholdType,
	BucketNumber
	FROM Buckets BucketWaits
	LEFT JOIN [Inspector].[BlitzWaits_WatchedWaitTypes] ON BucketWaits.[wait_type] = [BlitzWaits_WatchedWaitTypes].[Wait_type] AND BucketWaits.ServerName = [BlitzWaits_WatchedWaitTypes].[Servername]
	WHERE (@AlwaysShowBreached = 1 AND [IsActive] = 1)
	AND ((ThresholdDirection = ''>'' AND ISNULL((CAST([wait_time_ms_delta] AS MONEY)/NULLIF(CAST([waiting_tasks_count_delta] AS MONEY),0)),0) > Threshold)
	OR (ThresholdDirection = ''<'' AND ISNULL((CAST([wait_time_ms_delta] AS MONEY)/NULLIF(CAST([waiting_tasks_count_delta] AS MONEY),0)),0) < Threshold))
) AS FinalWaits
--Purpose of final waits being derived is to get the bucket colouring consistent with the union

/********************************************************/
	
	--No change required here , this part grabs the column names from the temp table created above
	SET @Columnnames = (
	SELECT 
	STUFF(Columnnames,1,1,'''') 
	FROM
	(
		SELECT '',''+name
		FROM tempdb.sys.all_columns
		WHERE [object_id] = OBJECT_ID(N''tempdb.dbo.#InspectorModuleReport'')
		AND name != N''@bgcolor''
		ORDER BY column_id ASC
		FOR XML PATH('''')
	) as g (Columnnames)
	);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
	@Servername,
	@Modulename,
	@ServerSpecific,
	''Top ''+CAST(@Top AS VARCHAR(6))+'' wait stats grouped by ''+CAST(@HourlyBucketSize AS VARCHAR(6))+'' hourly buckets for the last ''+CAST(@Frequency AS VARCHAR(6)) 
	+''mins between the hours of ''
	+CAST(@MonitorHourStart AS VARCHAR(10))
	+'' and ''
	+CAST(@MonitorHourEnd AS VARCHAR(10)), --/**  OPTIONAL  **/ Title for the HTML table, you can use a string here instead such as ''My table title here'' if you want to
	@TableHeaderColour,
	@Columnnames)
	);


	SET @SQLtext = N''
	SELECT @HtmlOutput =
	(SELECT ''
	+''[@bgcolor],''
	+REPLACE(@Columnnames,'','','' AS ''''td'''','''''''',+ '') + '' AS ''''td'''','''''''''' 
	+'' FROM #InspectorModuleReport
	ORDER BY 
	HourlyBucket ASC,
	--Watched ASC,
	wait_time_ms_delta DESC
	FOR XML PATH(''''tr''''),Elements);''
	/**  OPTIONAL  **/ --Add an ORDER BY if required

	EXEC sp_executesql @SQLtext,N''@HtmlOutput VARCHAR(MAX) OUTPUT'',@HtmlOutput = @HtmlOutput OUTPUT;


	--/**  OPTIONAL  **/ --If in the above query you populate the table with something like ''No issues present'' then you probably do not want that to 
	--show when @Noclutter mode is on
	IF (@NoClutter = 1)
	BEGIN 
		IF(@HtmlOutput LIKE ''%<Your No issues present text here>%'')
		BEGIN
			SET @HtmlOutput = NULL;
		END
	END

	--No Change needed here, this part will put all the report pieces together.
	--If there is data for the HTML table then build the HTML table
	IF (@HtmlOutput IS NOT NULL)
	BEGIN 
		SET @HtmlOutput = 
			@HtmlTableHead
			+ @HtmlOutput
			+ @TableTail
			+''<p><BR><p>'';
	END


IF (@Debug = 1)
BEGIN 
	SELECT 
	OBJECT_NAME(@@PROCID) AS ''Procname'',
	@Servername AS ''@Servername'',
	@Modulename AS ''@Modulename'',
	@TableHeaderColour AS ''@TableHeaderColour'',
	@WarningHighlight AS ''@WarningHighlight'',
	@AdvisoryHighlight AS ''@AdvisoryHighlight'',
	@InfoHighlight AS ''@InfoHighlight'',
	@ModuleConfig AS ''@ModuleConfig'',
	@WarningLevel AS ''@WarningLevel'',
	@NoClutter AS ''@NoClutter'',
	@TableTail AS ''@TableTail'',
	@HtmlOutput AS ''@HtmlOutput'',
	@HtmlTableHead AS ''@HtmlTableHead'',
	@SQLtext AS ''@SQLtext'',
	@CollectionOutOfDate AS ''@CollectionOutOfDate'',
	@PSCollection AS ''@PSCollection''
END 

END
');

END

IF NOT EXISTS(SELECT 1 FROM [Inspector].[ModuleConfig] WHERE [ModuleConfig_Desc] = @ModuleConfig)
BEGIN 
	INSERT INTO [Inspector].[ModuleConfig] ([ModuleConfig_Desc], [IsActive], [Frequency], [StartTime], [EndTime], [LastRunDateTime], [ReportWarningsOnly], [NoClutter], [ShowDisabledModules])
	VALUES(@ModuleConfig, @EnableModule, @ReportFrequencyMins, @ReportStartTime, @ReportEndTime, NULL, 0, 0, 0);
END

--No need to update this one as the schedule information here is not used as its a Report only module, the row just needs to exist.
IF NOT EXISTS(SELECT 1 FROM [Inspector].[Modules] WHERE [Modulename] = 'BlitzWaits' AND [ModuleConfig_Desc] = @ModuleConfig)
BEGIN 
	INSERT INTO [Inspector].[Modules] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [WarningLevel], [ServerSpecific], [Debug], [IsActive], [HeaderText], [Frequency], [StartTime], [EndTime])
	VALUES(@ModuleConfig,'BlitzWaits',NULL,'BlitzWaitsReport',1,2,1,0,@EnableModule,'Top wait stats with wait types from your watched list present',@ReportFrequencyMins,@ReportStartTime,@ReportEndTime);
END


IF NOT EXISTS(SELECT 1 FROM [Inspector].[MultiWarningModules] WHERE [Modulename] = 'BlitzWaits')
BEGIN 
	INSERT INTO [Inspector].[MultiWarningModules] ([Modulename])
	VALUES('BlitzWaits');
END


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID(N'Inspector.InspectorUpgradeHistory') AND name = 'RevisionDate')
BEGIN 
	ALTER TABLE [Inspector].[InspectorUpgradeHistory] ADD RevisionDate DATE NULL;
END

EXEC sp_executesql N'
INSERT INTO [Inspector].[InspectorUpgradeHistory] ([Log_Date], [PreserveData], [CurrentBuild], [TargetBuild], [SetupCommand], [RevisionDate])
VALUES(GETDATE(),1,@InspectorBuild,@InspectorBuild,''Inspector_BlitzWaits_CustomModule.sql'',@Revisiondate);',
N'@InspectorBuild DECIMAL(4,2),
@Revisiondate DATE',
@InspectorBuild = @InspectorBuild,
@Revisiondate = @Revisiondate;


PRINT '
Thank you for installing the BlitzWaits Module for Inspector V2.

/** CHECK SETTINGS **/
Check the following settings in [Inspector].[Settings]

	SELECT [Description],[Value]
	FROM [Inspector].[Settings] 
	WHERE [Description] IN (''BlitzWaitsTopXRows'',''BlitzWaitsHourlyBucketSize'',''BlitzWaitsAlwaysShowBreached'');

BlitzWaitsTopXRows is set to 3 by default ,this will show the top 3 wait types with the highest wait delta sum for the period
BlitzWaitsHourlyBucketSize is set to 2 by default ,this will bucket the waits in the 2 hour buckets
BlitzWaitsAlwaysShowBreached is set to 0 by default, set to 1 to always see waits from your watched list IF the threshold was breached (this will increase rows returned in the bucket if breaches are present)

You should change these accordingly as these have a huge impact on the amount of data displayed within the report i.e the higher the BlitzWaitsTopXRows value and the lower
the BlitzWaitsHourlyBucketSize value the more rows you will see on the report.

/** CHECK SCHEDULE **/
To Check the current schedule set for the BlitzWaits module (Disabled at installation) run the following command: 

	SELECT * 
	FROM [Inspector].[ModuleConfig] 
	WHERE [ModuleConfig_Desc] = '''+@ModuleConfig+''';

Update IsActive = 1 to enable and set the StartTime, EndTime and Frequency of the report accordingly

/** Want to highlight specific waits? **/
If you want to highlight specific wait types insert into the table [Inspector].[BlitzWaits_WatchedWaitTypes] along with the warning level:
1 = Warning , default colour is Red
2 - Advisory, default colour is Yellow
3 - Info, default colour is White

Highlighted waits will hightlight the correspinding row in the html table within the report ad in addition will show an entry in the report header for visibility with a hyperlink to the table.
';


--SELECT [Description],[Value]
--FROM [Inspector].[Settings] 
--WHERE [Description] IN ('BlitzWaitsTopXRows','BlitzWaitsHourlyBucketSize','BlitzWaitsAlwaysShowBreached');

--SELECT * 
--FROM [Inspector].[ModuleConfig] 
--WHERE [ModuleConfig_Desc] = @ModuleConfig;

END
ELSE 
BEGIN 
	RAISERROR('Inspector schema not found, ensure that the Inspector is installed then try running this script again',11,0);
END