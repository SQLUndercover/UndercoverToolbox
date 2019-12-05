IF EXISTS (SELECT * FROM sys.views WHERE [schema_id] = SCHEMA_ID(N'Inspector') AND [name]= N'MultiWarningModules')
BEGIN
	DROP VIEW [Inspector].[MultiWarningModules];			
END

IF OBJECT_ID('Inspector.MultiWarningModules',N'U') IS NULL 
BEGIN  
	CREATE TABLE [Inspector].[MultiWarningModules] (
	[Modulename] VARCHAR(50) NULL
	);
END

IF NOT EXISTS(SELECT 1 FROM [Inspector].[MultiWarningModules] WHERE [Modulename] IN ('DriveSpace','DatabaseGrowths','DatabaseStates'))
BEGIN 
	EXEC sp_executesql N'INSERT INTO [Inspector].[MultiWarningModules] ([Modulename])
	VALUES(''DriveSpace''),(''DatabaseGrowths''),(''DatabaseStates'');';
END