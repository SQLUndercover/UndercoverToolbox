SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

/*********************************************
Description: 

Author: Adrian Buckman
Revision date: 14/05/2020

© www.sqlundercover.com 

MIT License
------------
 
Copyright 2020 Sql Undercover
 
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


DECLARE @ModuleConfig VARCHAR(20) = 'Default'; -- Append to the Default ModuleConfig or specify a new ModuleConfig i.e 'BlitzWaits'

--Frequency ,Start and End times only apply if the @ModuleConfig does not exist as we do not want to update your existing schedules.
DECLARE @ReportFrequencyMins SMALLINT = 1440;  --Maximum supported value is 1440 (once a day)
DECLARE @ReportStartTime TIME(0) = '09:00';
DECLARE @ReportEndTime TIME(0) = '18:00';
DECLARE @MonitorHourStart INT = 0 -- 0 to 23
DECLARE @MonitorHourEnd INT = 23 -- 0 to 23

--Enable or Disable the module following installation
DECLARE @EnableModule BIT = 1;



DECLARE @Revisiondate DATE = '20200514';
DECLARE @InspectorBuild DECIMAL(4,2) = (SELECT TRY_CAST([Value] AS DECIMAL(4,2)) FROM [Inspector].[Settings] WHERE [Description] = 'InspectorBuild');

--Ensure that Blitz tables exist
IF (OBJECT_ID(N'dbo.BlitzFirst_FileStats') IS NULL)
BEGIN 
	RAISERROR('BlitzFirst_FileStats Table not present in this database, please double check the database name is correct - the Inspector must be installed in the same database where your Blitz collection data is stored',11,0);
	RETURN;
END		

IF ((@MonitorHourStart NOT BETWEEN 0 AND 23) OR (@MonitorHourEnd NOT BETWEEN 0 AND 23))
BEGIN 
	RAISERROR('@MonitorHourStart and @MonitorHourEnd must be between 0 and 23',11,0);
	RETURN;
END

--Ensure that the Inspector schema exists
IF SCHEMA_ID(N'Inspector') IS NOT NULL
BEGIN 

	IF OBJECT_ID('Inspector.MonitorHours',N'U') IS NULL 
	BEGIN 
		CREATE TABLE [Inspector].[MonitorHours](
		[Servername] [nvarchar](128) NULL,
		[Modulename] VARCHAR(50) NULL,
		[MonitorHourStart] INT NOT NULL,
		[MonitorHourEnd] INT NOT NULL
		);
	
		EXEC sp_executesql N'CREATE UNIQUE CLUSTERED INDEX [CIX_Servername_Modulename] ON [Inspector].[MonitorHours] ([Servername],[Modulename]);';
	END
	
	
	
	EXEC sp_executesql N'
	IF NOT EXISTS(SELECT 1 FROM [Inspector].[MonitorHours] WHERE Servername = @@SERVERNAME AND Modulename = ''BlitzFileStats'') 
	BEGIN 
		INSERT INTO [Inspector].[MonitorHours] ([Servername],[Modulename],[MonitorHourStart],[MonitorHourEnd])
		VALUES(@@SERVERNAME,''BlitzFileStats'',@MonitorHourStart,@MonitorHourEnd);
	END ',
	N'@MonitorHourStart INT, @MonitorHourEnd INT',
	@MonitorHourStart = @MonitorHourStart,
	@MonitorHourEnd = @MonitorHourEnd;
	
	IF OBJECT_ID('Inspector.BlitzFileStatsConfig',N'U') IS NULL 
	BEGIN 
		CREATE TABLE [Inspector].[BlitzFileStatsConfig](
		[Servername] [nvarchar](128) NOT NULL,
		[io_stall_read_ms_threshold] INT NOT NULL,
		[io_stall_write_ms_threshold] INT NOT NULL
		);

		EXEC sp_executesql N'CREATE UNIQUE CLUSTERED INDEX [CIX_Servername] ON [Inspector].[BlitzFileStatsConfig] ([Servername]);';
	END

	EXEC sp_executesql N'
	IF NOT EXISTS(SELECT 1 FROM [Inspector].[BlitzFileStatsConfig] WHERE Servername = @@SERVERNAME) 
	BEGIN 
		INSERT INTO [Inspector].[BlitzFileStatsConfig] ([Servername],[io_stall_read_ms_threshold],[io_stall_write_ms_threshold])
		VALUES(@@SERVERNAME,200,200);
	END ';
	
	IF OBJECT_ID('Inspector.GetMonitorHours') IS NULL
	BEGIN 
		EXEC sp_executesql N'CREATE PROCEDURE [Inspector].[GetMonitorHours] AS;';
	END 
	
	EXEC sp_executesql N'ALTER PROCEDURE [Inspector].[GetMonitorHours] (
	@Servername NVARCHAR(128),
	@Modulename VARCHAR(50),
	@MonitorHourStart INT OUTPUT,
	@MonitorHourEnd INT OUTPUT	
	)
	AS 
	BEGIN 
		/* Revision date: 01/05/2020 */
	
		SELECT 
		@MonitorHourStart = [MonitorHourStart],
		@MonitorHourEnd = [MonitorHourEnd]
		FROM [Inspector].[MonitorHours] 
		WHERE [Servername] = @Servername 
		AND [Modulename] = @Modulename;
	
	END';
	
	
	IF OBJECT_ID('Inspector.GetModuleConfigFrequency') IS NULL
	BEGIN 
		EXEC sp_executesql N'CREATE PROCEDURE [Inspector].[GetModuleConfigFrequency] AS;';
	END 
	
	EXEC sp_executesql N'ALTER PROCEDURE [Inspector].[GetModuleConfigFrequency] (
	@ModuleConfig VARCHAR(20),
	@Frequency INT OUTPUT
	)
	AS 
	BEGIN 
		/* Revision date: 01/05/2020 */
	
		SELECT 
		@Frequency = [Frequency] 
		FROM [Inspector].[ModuleConfig]
		WHERE ModuleConfig_Desc = @ModuleConfig;
	
	END';
	


IF OBJECT_ID('Inspector.BlitzFileStatsReport',N'P') IS NULL 
BEGIN 
	EXEC('CREATE PROCEDURE [Inspector].[BlitzFileStatsReport] AS');
END 

IF OBJECT_ID('Inspector.BlitzFileStatsReport',N'P') IS NOT NULL
BEGIN 
EXEC('ALTER PROCEDURE [Inspector].[BlitzFileStatsReport] (	
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
/* Revision date: 11/05/2020 */	
	
DECLARE @Frequency INT
DECLARE @MonitorHourStart INT;
DECLARE @MonitorHourEnd INT;
DECLARE @io_stall_read_ms_threshold INT;
DECLARE @io_stall_write_ms_threshold INT;
DECLARE @HtmlTableHead VARCHAR(4000);
DECLARE @Columnnames VARCHAR(2000);
DECLARE @SQLtext NVARCHAR(4000);


EXEC [Inspector].[GetMonitorHours] 
	@Servername = @Servername,
	@Modulename = @Modulename, 
	@MonitorHourStart  = @MonitorHourStart OUTPUT,
	@MonitorHourEnd = @MonitorHourEnd OUTPUT;


EXEC [Inspector].[GetModuleConfigFrequency] 
	@ModuleConfig = @ModuleConfig,
	@Frequency = @Frequency OUTPUT;


SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

SET @io_stall_read_ms_threshold = (SELECT [io_stall_read_ms_threshold] FROM [Inspector].[BlitzFileStatsConfig] WHERE [Servername] = @Servername);
SET @io_stall_write_ms_threshold = (SELECT [io_stall_write_ms_threshold] FROM [Inspector].[BlitzFileStatsConfig] WHERE [Servername] = @Servername);

--Set defaults if NULL
IF @MonitorHourStart IS NULL BEGIN SET @MonitorHourStart = 0 END;
IF @MonitorHourEnd IS NULL BEGIN SET @MonitorHourEnd = 23 END;
IF @io_stall_read_ms_threshold IS NULL BEGIN SET @io_stall_read_ms_threshold = 200 END;
IF @io_stall_write_ms_threshold IS NULL BEGIN SET @io_stall_write_ms_threshold = 200 END;

SELECT 
		CASE 
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
	   [ServerName],
       CONVERT(VARCHAR(17),[CheckDate],113) AS CheckDate,
	   SUBSTRING(PhysicalName,1,LEN(PhysicalName)-CHARINDEX(''\'',REVERSE(PhysicalName))+1) AS Drive,
       AVG([io_stall_read_ms_average]) AS [io_stall_read_ms_average],
       AVG([io_stall_write_ms_average]) AS [io_stall_write_ms_average],
	   @io_stall_read_ms_threshold AS ReadThreshold,
	   @io_stall_write_ms_threshold AS WriteThreshold
  INTO #InspectorModuleReport
  FROM [dbo].[BlitzFirst_FileStats_Deltas]
  WHERE ServerName = @Servername
  AND CheckDate >= DATEADD(MINUTE,-@Frequency,SYSDATETIMEOFFSET())
  AND DATEPART(HOUR,[CheckDate]) BETWEEN @MonitorHourStart AND @MonitorHourEnd
  AND (([io_stall_read_ms_average] > @io_stall_read_ms_threshold) OR ([io_stall_write_ms_average] > @io_stall_write_ms_threshold))
GROUP BY 
[ServerName],
[CheckDate],
SUBSTRING(PhysicalName,1,LEN(PhysicalName)-CHARINDEX(''\'',REVERSE(PhysicalName))+1);


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
''IO Read/Write stalls exceeding your thresholds for the last ''+CAST(@Frequency AS VARCHAR(6))+ '' minutes between the hours of ''+CAST(@MonitorHourStart AS VARCHAR(6))+'' and ''+CAST(@MonitorHourEnd AS VARCHAR(6)), --/**  OPTIONAL  **/ Title for the HTML table, you can use a string here instead such as ''My table title here'' if you want to
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
[CheckDate] ASC,
[Drive] ASC
FOR XML PATH(''''tr''''),Elements);''
/**  OPTIONAL  **/ --Add an ORDER BY if required

EXEC sp_executesql @SQLtext,N''@HtmlOutput VARCHAR(MAX) OUTPUT'',@HtmlOutput = @HtmlOutput OUTPUT;

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
	@Frequency AS ''@Frequency'',
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
	@PSCollection AS ''@PSCollection'',
	@io_stall_read_ms_threshold AS ''@io_stall_read_ms_threshold'',
	@io_stall_write_ms_threshold AS ''@io_stall_write_ms_threshold'',
	@MonitorHourStart AS ''@MonitorHourStart'',
	@MonitorHourEnd AS ''@MonitorHourEnd'';
END 

END');
END

IF NOT EXISTS(SELECT 1 FROM [Inspector].[ModuleConfig] WHERE [ModuleConfig_Desc] = @ModuleConfig)
BEGIN 
	INSERT INTO [Inspector].[ModuleConfig] ([ModuleConfig_Desc], [IsActive], [Frequency], [StartTime], [EndTime], [LastRunDateTime], [ReportWarningsOnly], [NoClutter], [ShowDisabledModules])
	VALUES(@ModuleConfig, @EnableModule, @ReportFrequencyMins, @ReportStartTime, @ReportEndTime, NULL, 0, 0, 0);
END

--No need to update this one as the schedule information here is not used as its a Report only module, the row just needs to exist.
IF NOT EXISTS(SELECT 1 FROM [Inspector].[Modules] WHERE [Modulename] = 'BlitzFileStats' AND [ModuleConfig_Desc] = @ModuleConfig)
BEGIN 
	INSERT INTO [Inspector].[Modules] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [WarningLevel], [ServerSpecific], [Debug], [IsActive], [HeaderText], [Frequency], [StartTime], [EndTime])
	VALUES(@ModuleConfig,'BlitzFileStats',NULL,'BlitzFileStatsReport',20,2,1,0,@EnableModule,'Read/Write IO Stalls breached your threshold',@ReportFrequencyMins,@ReportStartTime,@ReportEndTime);
END


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID(N'Inspector.InspectorUpgradeHistory') AND name = 'RevisionDate')
BEGIN 
	ALTER TABLE [Inspector].[InspectorUpgradeHistory] ADD [RevisionDate] DATE NULL;
END

EXEC sp_executesql N'
INSERT INTO [Inspector].[InspectorUpgradeHistory] ([Log_Date], [PreserveData], [CurrentBuild], [TargetBuild], [SetupCommand], [RevisionDate])
VALUES(GETDATE(),1,@InspectorBuild,@InspectorBuild,''Inspector_BlitzFileStats_CustomModule.sql'',@Revisiondate);',
N'@InspectorBuild DECIMAL(4,2),
@Revisiondate DATE',
@InspectorBuild = @InspectorBuild,
@Revisiondate = @Revisiondate;


END
ELSE 
BEGIN 
	RAISERROR('Inspector schema not found, ensure that the Inspector is installed then try running this script again',11,0);
END
GO