SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @ModuleConfig VARCHAR(20) = 'Default'; -- Append to the Default ModuleConfig or specify a new ModuleConfig i.e 'Catalogue'

--Frequency ,Start and End times only apply if the @ModuleConfig does not exist as we do not want to update your existing schedules.
DECLARE @ReportFrequencyMins SMALLINT = 1440;  --Maximum supported value is 1440 (once a day)
DECLARE @ReportStartTime TIME(0) = '09:00';
DECLARE @ReportEndTime TIME(0) = '18:00';

--Enable or Disable the module following installation
DECLARE @EnableModule BIT = 1;



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[CatalogueDroppedDatabasesReport]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Inspector].[CatalogueDroppedDatabasesReport] AS';
END

EXEC dbo.sp_executesql N'
ALTER PROCEDURE [Inspector].[CatalogueDroppedDatabasesReport]
(
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
--Revision date: 03/01/2020
BEGIN

DECLARE @HtmlTableHead VARCHAR(2000);
DECLARE @LastestExecution DATETIME
DECLARE @Frequency INT = (SELECT [Frequency] FROM [Inspector].[ModuleConfig] WHERE ModuleConfig_Desc = @ModuleConfig);

SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

--Set columns names for the Html table
SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
	@Servername,
	@Modulename,
	@ServerSpecific,
	''Databases dropped in the last ''+CAST(@Frequency AS VARCHAR(10))+'' mins'',
	@TableHeaderColour,
	''Server name,Database name,AG name,File path,DaysSeenByCatalogue,LastSeenByCatalogue''
	)
);


EXEC sp_executesql N''SELECT @LastestExecution = MAX(ExecutionDate) FROM [Catalogue].[ExecutionLog];'',
N''@LastestExecution DATETIME OUTPUT'',
@LastestExecution = @LastestExecution OUTPUT;

EXEC sp_executesql 
N''
SET @HtmlOutput = (
SELECT 
CASE 
	WHEN @WarningLevel = 1 THEN @WarningHighlight
	WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
	WHEN @WarningLevel = 3 THEN @InfoHighlight
END AS [@bgcolor], 
CatalogueDatabases.ServerName AS ''''td'''','''''''', +
CatalogueDatabases.DBName AS ''''td'''','''''''', +
ISNULL(AGName,N''''Not in an AG'''') AS ''''td'''','''''''', +
CatalogueDatabases.FilePaths AS ''''td'''','''''''', +
DATEDIFF(DAY,FirstRecorded,LastRecorded) AS ''''td'''','''''''', +
CONVERT(VARCHAR(17),CatalogueDatabases.LastRecorded,113) AS ''''td'''',''''''''
FROM [Catalogue].[Databases] CatalogueDatabases
INNER JOIN [Inspector].[CurrentServers] InspectorServers ON CatalogueDatabases.ServerName = InspectorServers.Servername 
WHERE CatalogueDatabases.ServerName = @Servername
AND [CatalogueDatabases].[LastRecorded] >= DATEADD(MINUTE,-@Frequency,GETDATE())
AND [CatalogueDatabases].[LastRecorded] < @LastestExecution
FOR XML PATH(''''tr''''),ELEMENTS);'',
N''@Servername NVARCHAR(128), 
@LastestExecution DATETIME,
@Frequency INT,
@WarningLevel TINYINT,
@WarningHighlight VARCHAR(7),
@AdvisoryHighlight VARCHAR(7),
@InfoHighlight VARCHAR(7),
@HtmlOutput VARCHAR(MAX) OUTPUT'',
@Servername = @Servername, 
@LastestExecution = @LastestExecution, 
@Frequency = @Frequency,
@WarningLevel = @WarningLevel,
@WarningHighlight = @WarningHighlight,
@AdvisoryHighlight = @AdvisoryHighlight,
@InfoHighlight = @InfoHighlight,
@HtmlOutput = @HtmlOutput OUTPUT;


IF (@HtmlOutput IS NOT NULL)
BEGIN 
SET @HtmlOutput = 
	@HtmlTableHead
	+ @HtmlOutput
	+ @TableTail 
	+''<p><BR><p>''
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
	@CollectionOutOfDate AS ''@CollectionOutOfDate'',
	@PSCollection AS ''@PSCollection''
END 

END';

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[CatalogueDroppedTablesReport]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Inspector].[CatalogueDroppedTablesReport] AS'; 
END


EXEC dbo.sp_executesql N'
ALTER PROCEDURE [Inspector].[CatalogueDroppedTablesReport]
(
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
--Revision date: 03/01/2020
BEGIN

DECLARE @HtmlTableHead VARCHAR(2000);
DECLARE @LastestExecution DATETIME
DECLARE @Frequency INT = (SELECT [Frequency] FROM [Inspector].[ModuleConfig] WHERE ModuleConfig_Desc = @ModuleConfig);

SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

--Set columns names for the Html table
SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
	@Servername,
	@Modulename,
	@ServerSpecific,
	''Tables dropped in the last ''+CAST(@Frequency AS VARCHAR(10))+'' mins'',
	@TableHeaderColour,
	''Server name,Database name,Schema name,Table name,LastSeenByCatalogue''
	)
);

EXEC sp_executesql N''SELECT @LastestExecution = MAX(ExecutionDate) FROM [Catalogue].[ExecutionLog];'',
N''@LastestExecution DATETIME OUTPUT'',@LastestExecution = @LastestExecution OUTPUT;

EXEC sp_executesql 
N''
SET @HtmlOutput = (
SELECT 
CASE 
	WHEN @WarningLevel = 1 THEN @WarningHighlight
	WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
	WHEN @WarningLevel = 3 THEN @InfoHighlight
END AS [@bgcolor],
CatalogueTables.ServerName AS ''''td'''','''''''', +
CatalogueTables.DatabaseName AS ''''td'''','''''''', +
CatalogueTables.SchemaName AS ''''td'''','''''''', +
CatalogueTables.TableName AS ''''td'''','''''''', +
CONVERT(VARCHAR(17),CatalogueTables.LastRecorded,113) AS ''''td'''','''''''' 
FROM [Inspector].[CurrentServers] InspectorServers
INNER JOIN [Catalogue].[Tables] CatalogueTables ON CatalogueTables.ServerName = InspectorServers.Servername 
WHERE CatalogueTables.ServerName = @Servername
AND [CatalogueTables].[LastRecorded] >= DATEADD(MINUTE,-@Frequency,GETDATE())
AND [CatalogueTables].[LastRecorded] < @LastestExecution
AND [DatabaseName] != ''''tempdb''''
AND NOT EXISTS (SELECT 1 FROM [Catalogue].[Databases] CatalogueDatabases 
				WHERE CatalogueDatabases.ServerName = InspectorServers.Servername 
				AND  CatalogueDatabases.DBName= CatalogueTables.DatabaseName 
				AND  [CatalogueDatabases].[LastRecorded] < @LastestExecution)
FOR XML PATH(''''tr''''),ELEMENTS);'',
N''@Servername NVARCHAR(128), 
@LastestExecution DATETIME,
@Frequency INT,
@WarningLevel TINYINT,
@WarningHighlight VARCHAR(7),
@AdvisoryHighlight VARCHAR(7),
@InfoHighlight VARCHAR(7),
@HtmlOutput VARCHAR(MAX) OUTPUT'',
@Servername = @Servername, 
@LastestExecution = @LastestExecution, 
@Frequency = @Frequency,
@WarningLevel = @WarningLevel,
@WarningHighlight = @WarningHighlight,
@AdvisoryHighlight = @AdvisoryHighlight,
@InfoHighlight = @InfoHighlight,
@HtmlOutput = @HtmlOutput OUTPUT;

IF (@HtmlOutput IS NOT NULL)
BEGIN 
SET @HtmlOutput = 
	@HtmlTableHead
	+ @HtmlOutput
	+ @TableTail 
	+''<p><BR><p>''
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
	@CollectionOutOfDate AS ''@CollectionOutOfDate'',
	@PSCollection AS ''@PSCollection''
END 

END';


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[CatalogueMissingLoginsReport]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Inspector].[CatalogueMissingLoginsReport] AS';
END


EXEC dbo.sp_executesql N'
ALTER PROCEDURE [Inspector].[CatalogueMissingLoginsReport]
(
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
--Revision date: 03/01/2020
BEGIN
SET NOCOUNT ON;

DECLARE @HtmlTableHead VARCHAR(2000);
DECLARE @LastestExecution DATETIME
DECLARE @Frequency INT = (SELECT [Frequency] FROM [Inspector].[ModuleConfig] WHERE ModuleConfig_Desc = @ModuleConfig);

SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

--Set columns names for the Html table
SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
	@Servername,
	@Modulename,
	@ServerSpecific,
	''Missing logins in the last ''+CAST(@Frequency AS VARCHAR(10))+'' mins'',
	@TableHeaderColour,
	''Server name,Login name,CreateCommand''
	)
);


IF OBJECT_ID(''tempdb.dbo.#ServerLogins'') IS NOT NULL
DROP TABLE #ServerLogins;

CREATE TABLE #ServerLogins (
AGName NVARCHAR(128),
LoginName NVARCHAR(128),
ServerName NVARCHAR(128)
);


EXEC sp_executesql 
N''INSERT INTO #ServerLogins (AGName,LoginName,ServerName)
SELECT DISTINCT AGs.AGName, Logins.LoginName, AGs2.ServerName
FROM (SELECT DISTINCT AGName FROM Catalogue.AvailabilityGroups WHERE ServerName = @Servername) AGList
INNER JOIN Catalogue.AvailabilityGroups AGs ON AGList.AGName = AGs.AGName
INNER JOIN Catalogue.Logins Logins ON AGs.ServerName = Logins.ServerName
INNER JOIN Catalogue.AvailabilityGroups AGs2 ON AGs.AGName = AGs2.AGName
WHERE NOT EXISTS (SELECT 1
					FROM Catalogue.AvailabilityGroups AGs3
					JOIN Catalogue.Logins Logins3 ON AGs3.ServerName = Logins3.ServerName
					WHERE AGs3.AGName = AGs.AGName
					AND AGs3.ServerName = AGs2.ServerName
					AND Logins3.LoginName = Logins.LoginName)
AND Logins.LoginName NOT IN (SELECT [LoginName] FROM [Inspector].[CatalogueSIDExclusions] WHERE [AGs].[AGName] = [CatalogueSIDExclusions].[AGName])
AND Logins.LoginName != ''''sa''''
AND AGs.LastRecorded >= DATEADD(MINUTE,-@Frequency,GETDATE())
AND Logins.LastRecorded >= DATEADD(MINUTE,-@Frequency,GETDATE())
AND AGs2.LastRecorded >= DATEADD(MINUTE,-@Frequency,GETDATE())
AND EXISTS (SELECT 1 FROM [Catalogue].[ExecutionLog] WHERE [ExecutionDate] >= DATEADD(MINUTE,-@Frequency,GETDATE()))

SET @HtmlOutput = (
SELECT 
CASE 
	WHEN @WarningLevel = 1 THEN @WarningHighlight
	WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
	WHEN @WarningLevel = 3 THEN @InfoHighlight
END AS [@bgcolor], 
ServerName AS ''''td'''','''''''', + 
LoginName AS ''''td'''','''''''', + 
CreateCommand AS ''''td'''',''''''''
FROM 
(
	SELECT DISTINCT 
	#ServerLogins.ServerName, 
	Logins.LoginName,
	CASE 
		WHEN Logins.LoginName LIKE ''''%\%'''' THEN ''''CREATE LOGIN '''' + QUOTENAME(Logins.LoginName) + '''' FROM WINDOWS''''
		ELSE ''''CREATE LOGIN '''' + QUOTENAME(Logins.LoginName) + '''' WITH PASSWORD = 0x'''' + CONVERT(VARCHAR(MAX), Logins.PasswordHash, 2) + '''' HASHED, SID = 0x'''' + CONVERT(VARCHAR(MAX), Logins.SID, 2) 
	END AS CreateCommand
	FROM Catalogue.AvailabilityGroups AGs
	JOIN Catalogue.Logins Logins ON AGs.ServerName = Logins.ServerName
	JOIN #ServerLogins ON AGs.AGName = #ServerLogins.AGName AND Logins.LoginName = #ServerLogins.LoginName
	JOIN Catalogue.Users Users ON Users.MappedLoginName = #ServerLogins.LoginName
	JOIN Catalogue.Databases Databases ON Users.DBName = Databases.DBName 
													AND AGs.AGName = Databases.AGName
	WHERE AGs.Role = ''''PRIMARY''''
	AND #ServerLogins.ServerName = @Servername
	AND AGs.LastRecorded >= DATEADD(MINUTE,-@Frequency,GETDATE())
	AND Logins.LastRecorded >= DATEADD(MINUTE,-@Frequency,GETDATE())
	AND Users.LastRecorded >= DATEADD(MINUTE,-@Frequency,GETDATE())
	AND Databases.LastRecorded >= DATEADD(MINUTE,-@Frequency,GETDATE())
) AS MissingLoginInfo
FOR XML PATH(''''tr''''),ELEMENTS);'',
N''@Servername NVARCHAR(128), 
@LastestExecution DATETIME,
@Frequency INT,
@WarningLevel TINYINT,
@WarningHighlight VARCHAR(7),
@AdvisoryHighlight VARCHAR(7),
@InfoHighlight VARCHAR(7),
@HtmlOutput VARCHAR(MAX) OUTPUT'',
@Servername = @Servername, 
@LastestExecution = @LastestExecution, 
@Frequency = @Frequency,
@WarningLevel = @WarningLevel,
@WarningHighlight = @WarningHighlight,
@AdvisoryHighlight = @AdvisoryHighlight,
@InfoHighlight = @InfoHighlight,
@HtmlOutput = @HtmlOutput OUTPUT;


IF (@HtmlOutput IS NOT NULL)
BEGIN 
SET @HtmlOutput = 
	@HtmlTableHead
	+ @HtmlOutput
	+ @TableTail 
	+''<p><BR><p>''
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
	@CollectionOutOfDate AS ''@CollectionOutOfDate'',
	@PSCollection AS ''@PSCollection''
END 

END';



IF NOT EXISTS(SELECT 1 FROM [Inspector].[ModuleConfig] WHERE [ModuleConfig_Desc] = @ModuleConfig)
BEGIN 
	INSERT INTO [Inspector].[ModuleConfig] ([ModuleConfig_Desc], [IsActive], [Frequency], [StartTime], [EndTime], [LastRunDateTime], [ReportWarningsOnly], [NoClutter], [ShowDisabledModules])
	VALUES(@ModuleConfig, @EnableModule, @ReportFrequencyMins, @ReportStartTime, @ReportEndTime, NULL, 0, 0, 0);
END


IF NOT EXISTS(SELECT 1 FROM [Inspector].[Modules] WHERE [Modulename] = 'CatalogueDroppedDatabases' AND [ModuleConfig_Desc] = @ModuleConfig)
BEGIN 
	INSERT INTO [Inspector].[Modules] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [WarningLevel], [ServerSpecific], [Debug], [IsActive], [HeaderText], [Frequency], [StartTime], [EndTime])
	VALUES(@ModuleConfig,'CatalogueDroppedDatabases',NULL,'CatalogueDroppedDatabasesReport',1,2,1,0,@EnableModule,NULL,@ReportFrequencyMins,@ReportStartTime,@ReportEndTime);
END

IF NOT EXISTS(SELECT 1 FROM [Inspector].[Modules] WHERE [Modulename] = 'CatalogueDroppedTables' AND [ModuleConfig_Desc] = @ModuleConfig)
BEGIN 
	INSERT INTO [Inspector].[Modules] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [WarningLevel], [ServerSpecific], [Debug], [IsActive], [HeaderText], [Frequency], [StartTime], [EndTime])
	VALUES(@ModuleConfig,'CatalogueDroppedTables',NULL,'CatalogueDroppedTablesReport',1,2,1,0,@EnableModule,NULL,@ReportFrequencyMins,@ReportStartTime,@ReportEndTime);
END

IF NOT EXISTS(SELECT 1 FROM [Inspector].[Modules] WHERE [Modulename] = 'CatalogueMissingLogins' AND [ModuleConfig_Desc] = @ModuleConfig)
BEGIN 
	INSERT INTO [Inspector].[Modules] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [WarningLevel], [ServerSpecific], [Debug], [IsActive], [HeaderText], [Frequency], [StartTime], [EndTime])
	VALUES(@ModuleConfig,'CatalogueMissingLogins',NULL,'CatalogueMissingLoginsReport',1,2,1,0,@EnableModule,NULL,@ReportFrequencyMins,@ReportStartTime,@ReportEndTime);
END
