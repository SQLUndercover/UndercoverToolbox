SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET CONCAT_NULL_YIELDS_NULL ON;
GO

DECLARE @DBname NVARCHAR(128) = DB_NAME();

RAISERROR('/******************************************',0,0,@DBname) WITH NOWAIT;

--Check for the Inspector Schema in the reporting database and create the schema if it does not exist
IF SCHEMA_ID('Inspector') IS NULL
BEGIN
	RAISERROR('Creating Inspector Schema in database: %s',0,0,@DBname) WITH NOWAIT;
	EXEC sp_executesql N'CREATE SCHEMA [Inspector]'
END
GO

DECLARE @DBname NVARCHAR(128) = DB_NAME();
RAISERROR('Creating Inspector setup stored procedure in database: %s',0,0,@DBname) WITH NOWAIT;

RAISERROR('******************************************/',0,0,@DBname) WITH NOWAIT;

IF OBJECT_ID('Inspector.InspectorSetup') IS NOT NULL 
DROP PROCEDURE [Inspector].[InspectorSetup];
GO

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
 

Author: Adrian Buckman
Created Date: 15/07/2017

Revision date: 08/07/2021
Version: 2.6

Description: SQLUndercover Inspector setup script Case sensitive compatible.
			 Creates [Inspector].[InspectorSetup] stored procedure.

URL: https://github.com/SQLUndercover/UndercoverToolbox/blob/master/SQLUndercoverInspector/SQLUndercoverinspectorV2.sql
User guide: https://sqlundercover.com/inspectoruserguide/

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

*/

CREATE PROCEDURE [Inspector].[InspectorSetup]
(
@Databasename NVARCHAR(128) = NULL,	--Name of the Logging Database
@DataDrive VARCHAR(50) = NULL,	--List Data Drives here (Comma delimited e.g 'P,Q,R,S')
@LogDrive VARCHAR(50)= NULL, 	--List Log Drives here (Comma delimited e.g 'T,U,V,W')
@StackNameForEmailSubject VARCHAR(255) = 'SQLUndercover',	  --Specify the name for this stack that you want to show in the email subject
@EmailRecipientList VARCHAR(1000) = NULL,	  -- This will populate the EmailRecipients table for 'DBA'
@BackupsPath VARCHAR(255) = NULL,	  -- Backup Drive and path
@LinkedServername NVARCHAR(128) = N'DEPRECATED', -- No longer in use, left here so we didnt break the auto update feature without the need of replacing the file.
@DriveSpaceHistoryRetentionInDays INT = 90, -- Days to retain drive space information
@DaysUntilDriveFullThreshold	  TINYINT = 56, -- Estimated days until drive is full - Specify the threshold for when you will start to receive alerts (Red highlight and Alert header entry)
@FreeSpaceRemainingPercent		  TINYINT = 10,-- Specify the percentage of drive space remaining where you want to start seeing a yellow highlight against the drive
@DriveLetterExcludes			  VARCHAR(10) = NULL, -- Exclude Drive letters from showing Yellow Advisory warnings when @FreeSpaceRemainingPercent has been reached/exceeded e.g C,D (Comma Delimited)
@DatabaseGrowthsAllowedPerDay	  TINYINT = 1,  -- Total Database Growths acceptable for a 24hour period If exceeded a Yellow Advisory condition will be shown
@MAXDatabaseGrowthsAllowedPerDay  TINYINT = 10, -- MAX Database Growths for a 24 hour period If equal or exceeded a Red Warning condition will be shown
@AgentJobOwnerExclusions VARCHAR(255) = 'sa',  --Exclude agent jobs with these owners (Comma delimited)
@FullBackupThreshold TINYINT = 8,		-- X Days older than Getdate()
@DiffBackupThreshold TINYINT = 24,		-- X Hours older than Getdate() 
@LogBackupThreshold  TINYINT = 20,		-- X Minutes older than Getdate()
@DatabaseOwnerExclusions VARCHAR(255) = 'sa',  --Exclude databases with these owners (Comma delimited)
@LongRunningTransactionThreshold INT = 300,	-- Threshold in seconds, display running transactions that exceed this duration during collection
@StartTime TIME(0) = '08:55', --Set the start of the time window you want collections to run for the Default ModuleConfig
@EndTime TIME(0) = '17:30', --Set the end of the time window you want collections to run for the Default ModuleConfig
@InitialSetup BIT = 0,	 --Set to 1 for intial setup, 0 to Upgrade or re deploy to preserve previously logged data and settings config.
@EnableAgentJob BIT = 1,
@Help BIT = 0 --Show example Setup command
)
AS
BEGIN 
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET CONCAT_NULL_YIELDS_NULL ON;

DECLARE @Revisiondate DATE = '20210708';
DECLARE @Build VARCHAR(6) ='2.6'

DECLARE @JobID UNIQUEIDENTIFIER;
DECLARE @JobsWithoutSchedules VARCHAR(1000);
--Allowing NULL values but only when @Help = 1 otherwise raise an error stating that values need to be specified.
IF ((@Databasename IS NULL OR @DataDrive IS NULL OR @LogDrive IS NULL) AND @Help = 0)
BEGIN 
	RAISERROR('@Databasename, @DataDrive, @LogDrive, @BackupsPath cannot be NULL when @Help = 0 is specified',11,0) WITH NOWAIT;
	RETURN;
END

IF (DB_ID(@Databasename) IS NULL AND @Help = 0)
BEGIN 
	RAISERROR('Please enter a valid database name',11,0) WITH NOWAIT;
	RETURN;
END

IF @Help = 1
BEGIN 
PRINT '

--Inspector V'+@Build+'
--Revision date: '+CONVERT(VARCHAR(17),@Revisiondate,113)+'

--You specified @Help = 1 - No setup has been carried out , here is an example command:

EXEC [Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = '''+DB_NAME()+''',	
@DataDrive = '''+ISNULL(@DataDrive,'S,T')+''',	
@LogDrive = '''+ISNULL(@LogDrive,'U,V')+''',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = ''F:\Backups\'',
@StackNameForEmailSubject = ''SQLUndercover'',	
@EmailRecipientList = NULL,	  
@DriveSpaceHistoryRetentionInDays = 90, 
@DaysUntilDriveFullThreshold = 56, 
@FreeSpaceRemainingPercent = 10,
@DriveLetterExcludes = NULL, 
@DatabaseGrowthsAllowedPerDay = 1,  
@MAXDatabaseGrowthsAllowedPerDay = 10, 
@AgentJobOwnerExclusions = ''sa'', 
@FullBackupThreshold = 8,		
@DiffBackupThreshold = 24,		
@LogBackupThreshold = 20,		
@DatabaseOwnerExclusions = ''sa'',  
@StartTime = ''08:55'',
@EndTime = ''17:30'',
@LongRunningTransactionThreshold = 300,	
@InitialSetup = 0,
@EnableAgentJob = 1,
@Help = 0; 
'
RETURN;
END

IF @InitialSetup IS NULL 
BEGIN 
	RAISERROR('@InitialSetup cannot be NULL , please specify 0 or 1',11,0) WITH NOWAIT;
	RETURN;
END 

DECLARE @Compatibility BIT
--SET compatibility to 1 if server version includes STRING_SPLIT
SELECT	@Compatibility = CASE
			WHEN SERVERPROPERTY ('productversion') >= '13.0.4001.0' AND compatibility_level >= 130 THEN 1
			ELSE 0
		END
FROM sys.databases
WHERE name = DB_NAME()


IF OBJECT_ID('master.dbo.fn_SplitString') IS NULL 
BEGIN 
	RAISERROR('Creating fn_SplitString',0,0) WITH NOWAIT;
EXEC ('
USE [master];

EXEC sp_executesql N''
/******************************************************************

Author: David Fowler
Revision date: 01/06/2017
Version: 1

Table valued function that breaks a delimited string into a table of discrete values
URL: //sqlundercover.com/2017/06/01/undercover-toolbox-fn_splitstring-its-like-string_split-but-for-luddites-or-those-who-havent-moved-to-sql-2016-yet/

© www.sqlundercover.com 


This script is for personal, educational, and internal 
corporate purposes, provided that this header is preserved. Redistribution or sale 
of this script,in whole or in part, is prohibited without the author''''s express 
written consent. 

The software is provided "as is", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. in no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in the
software.

******************************************************************/

CREATE FUNCTION fn_SplitString(@DelimitedString VARCHAR(MAX), @Delimiter CHAR(1) = '''','''')
RETURNS @SplitStrings TABLE (StringElement VARCHAR(255))
 
AS
 
BEGIN
 
WITH Split(XMLSplit)
AS
(SELECT CAST(''''<element>'''' + REPLACE(@DelimitedString,@Delimiter,''''</element><element>'''') + ''''</element>'''' AS XML))
INSERT INTO @SplitStrings
SELECT p.value(''''.'''', ''''VARCHAR(255)'''')
FROM Split
CROSS APPLY XMLSplit.nodes(''''/element'''') t(p)
 
RETURN
 
END'';
');

END 


IF @Compatibility = 1 OR (@Compatibility = 0 AND OBJECT_ID('master.dbo.fn_SplitString') IS NOT NULL) 
BEGIN

IF (@DataDrive IS NOT NULL AND @LogDrive IS NOT NULL) 
	BEGIN
	SET  @DataDrive = REPLACE(@DataDrive,' ','')
	SET  @LogDrive  = REPLACE(@LogDrive,' ','')

		IF DB_NAME() = @Databasename
		BEGIN

			SET NOCOUNT ON;

			DECLARE @SQLStatement NVARCHAR(MAX) 
			DECLARE @DatabaseFileSizesResult INT
			DECLARE @CurrentBuild VARCHAR(6)
			 			
			IF RIGHT(@BackupsPath,1) != '\' BEGIN SET @BackupsPath = @BackupsPath +'\' END

			IF OBJECT_ID('Inspector.Settings') IS NOT NULL
			BEGIN
				SELECT @CurrentBuild = (SELECT NULLIF([Value],'') FROM [Inspector].[Settings] WHERE [Description] = 'InspectorBuild')
			END
			
			IF @CurrentBuild IS NOT NULL
			BEGIN 
				IF (@Build < @CurrentBuild)
				BEGIN 
					RAISERROR('Current build: %s , is greater than the build you are trying to install (%s)',11,0,@CurrentBuild,@Build) WITH NOWAIT;
					RETURN;
				END 
				ELSE
				BEGIN
					RAISERROR('Current build: %s , Target build: %s',0,0,@CurrentBuild,@Build) WITH NOWAIT;
				END
			END
			ELSE 
			BEGIN
				RAISERROR('No Inspector build detected, Target build: %s',0,0,@Build) WITH NOWAIT;
			END

			--Validate installation mode, if the Inspector schema does not exist or no config exists in the Settings table
			--then set @InitialSetup = 1 so that a fresh install is conducted.

			--IF Inspector schema does not exist and @IntialSetup is not set to 1 then switch to a 1 for a fresh install
			IF SCHEMA_ID('Inspector') IS NULL 
			BEGIN 
				IF @InitialSetup = 0
				BEGIN
					RAISERROR('Setting @InitialSetup to 1 as the Inspector schema does not exist',0,0) WITH NOWAIT;
					SET @InitialSetup = 1
				END 
			END
			ELSE --IF Schema exists
			BEGIN --IF Settings table does not exist and @IntialSetup is not set to 1 then switch to a 1 for a fresh install
				IF NOT EXISTS (SELECT [name] FROM sys.tables WHERE [schema_id] = SCHEMA_ID('Inspector') AND [name] = 'Settings') 
				BEGIN
					IF @InitialSetup = 0
					BEGIN
						RAISERROR('Setting @InitialSetup to 1 as the Inspector.Settings table does not exist',0,0) WITH NOWAIT;
						SET @InitialSetup = 1
					END 
				END
				ELSE	--IF settings table exists
				BEGIN	--IF no data exists in the Settings table and @IntialSetup is not set to 1 then switch to a 1 for a fresh install
					IF NOT EXISTS (SELECT [Value] FROM [Inspector].[Settings]) AND @InitialSetup = 0
					BEGIN
						RAISERROR('Setting @InitialSetup to 1 as there is no config in [Inspector].[Settings]',0,0) WITH NOWAIT;
						SET @InitialSetup = 1 
					END
				END

			END	

			IF (@BackupsPath IS NULL AND @InitialSetup = 1)
			BEGIN 
				RAISERROR('@BackupsPath is NULL, if you plan on using the BackupSpaceCheck module be sure to insert the backup path into [Inspector].[Settings]',0,0) WITH NOWAIT;
			END

			--Check for the Inspector Schema in the reporting database and create the schema if it does not exist
			IF SCHEMA_ID('Inspector') IS NULL
			BEGIN
			EXEC sp_executesql N'CREATE SCHEMA [Inspector]'
			END


			--Create Inspector Upgrade table if not exists (do not drop)
			IF OBJECT_ID('Inspector.InspectorUpgradeHistory') IS NULL 
			CREATE TABLE [Inspector].[InspectorUpgradeHistory](
			Log_Date DATETIME,
			PreserveData BIT NULL,
			CurrentBuild DECIMAL(4,2) NULL,
			TargetBuild DECIMAL(4,2) NULL,
			SetupCommand VARCHAR(1000) NULL,
			RevisionDate DATE NULL
			);

			ALTER TABLE [Inspector].[InspectorUpgradeHistory] ALTER COLUMN [CurrentBuild] DECIMAL(4,2) NULL;
			ALTER TABLE [Inspector].[InspectorUpgradeHistory] ALTER COLUMN [TargetBuild] DECIMAL(4,2) NULL;

			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID(N'Inspector.InspectorUpgradeHistory') AND name = 'RevisionDate')
			BEGIN 
				ALTER TABLE [Inspector].[InspectorUpgradeHistory] ADD [RevisionDate] DATE NULL;
			END

			
			IF OBJECT_ID('Inspector.ReportData') IS NULL 
			CREATE TABLE [Inspector].[ReportData](
				[ID] INT IDENTITY(1,1),
				[ReportDate] DATETIME NOT NULL,
				[ModuleConfig] VARCHAR(20),
				[ReportData] VARCHAR(MAX) NULL,
				[Summary] XML NULL,
				[Importance] VARCHAR(6) NULL,
				[EmailGroup] VARCHAR(50) NULL,
				[ReportWarningsOnly] TINYINT NULL
			);

			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Summary' AND [object_id] = OBJECT_ID(N'Inspector.ReportData'))
			BEGIN
				--New column for 1.2 for Inspector.ReportData
				ALTER TABLE [Inspector].[ReportData] ADD [Summary] VARCHAR(60) NULL;
			END

			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ReportWarningsOnly' AND [object_id] = OBJECT_ID(N'Inspector.ReportData'))
			BEGIN
				ALTER TABLE [Inspector].[ReportData] ADD [ReportWarningsOnly] TINYINT NULL;
			END

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.ReportData') AND name='IX_ReportDate')
			BEGIN
				CREATE NONCLUSTERED INDEX [IX_ReportDate] ON [Inspector].[ReportData]
				(ReportDate ASC);
			END

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.ReportData') AND name='CIX_ReportData_ID')
			BEGIN
				CREATE CLUSTERED INDEX [CIX_ReportData_ID] ON [Inspector].[ReportData]
				(ID ASC);
			END

			--Inspector V2.00 change to XML
			IF NOT EXISTS (SELECT 1 
							FROM sys.tables 
							INNER JOIN sys.columns ON tables.object_id = columns.object_id 
							INNER JOIN sys.types ON columns.user_type_id = types.user_type_id
							WHERE tables.name = N'ReportData' 
							AND tables.schema_id = SCHEMA_ID(N'Inspector')
							AND columns.name = N'Summary'
							AND types.name = N'xml')
			BEGIN 
				ALTER TABLE [Inspector].[ReportData] ALTER COLUMN [Summary] XML NULL;
			END

			--New columns for 2.2
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Importance' AND [object_id] = OBJECT_ID(N'Inspector.ReportData'))
			BEGIN
				ALTER TABLE [Inspector].[ReportData] ADD [Importance] VARCHAR(6) NULL;
			END

			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'EmailGroup' AND [object_id] = OBJECT_ID(N'Inspector.ReportData'))
			BEGIN
				ALTER TABLE [Inspector].[ReportData] ADD [EmailGroup] VARCHAR(50) NULL;
			END
			
			IF OBJECT_ID('Inspector.Settings') IS NULL 	
			BEGIN
				CREATE TABLE [Inspector].[Settings] 
				(
				[ID] INT IDENTITY(1,1),
				[Description] VARCHAR(100),
				[Value] VARCHAR(255)
				);
				
				ALTER TABLE [Inspector].[Settings]
				ADD CONSTRAINT UC_Description UNIQUE (Description);
				
				ALTER TABLE [Inspector].[Settings] 
				ADD CONSTRAINT [DF_Settings_Value]  DEFAULT (NULL) FOR [Value];
			END

			IF OBJECT_ID('Inspector.ModuleConfigReportExclusions') IS NULL 
			BEGIN 
				CREATE TABLE [Inspector].[ModuleConfigReportExclusions] (
				Servername NVARCHAR(128) NOT NULL,
				Modulename VARCHAR(50) NOT NULL,
				IsActive BIT NOT NULL
				);
			END
			
			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID('Inspector.ModuleConfigReportExclusions') AND [name] = N'CIX_ModuleConfigReportExclusions_Servername_Modulename')
			BEGIN 
				CREATE UNIQUE CLUSTERED INDEX [CIX_ModuleConfigReportExclusions_Servername_Modulename] ON [Inspector].[ModuleConfigReportExclusions] (
				Servername,
				Modulename
				);
			END

			IF OBJECT_ID('Inspector.Modules') IS NULL
			BEGIN 
				CREATE TABLE [Inspector].[Modules](
					[ID] INT IDENTITY(1,1),
					[ModuleConfig_Desc] [varchar](20) NOT NULL,
					[Modulename] [varchar](50) NOT NULL,
					[CollectionProcedurename] [nvarchar](128) NULL,
					[ReportProcedurename] [nvarchar](128) NULL,
					[ReportOrder] TINYINT NOT NULL,
					[WarningLevel] TINYINT NOT NULL,
					[ServerSpecific] BIT NOT NULL,
					[Debug] BIT NOT NULL,
					[IsActive] BIT NOT NULL,
					[HeaderText] VARCHAR(100) NULL,
					[Frequency] SMALLINT NOT NULL,
					[StartTime] TIME(0) NOT NULL,
					[EndTime] TIME(0) NOT NULL,
					[LastRunDateTime] DATETIME NULL
				);

				IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CheckModuleWarningLevel' AND type = N'C' AND parent_object_id = OBJECT_ID(N'Inspector.Modules'))
				BEGIN 
					EXEC sp_executesql N'ALTER TABLE [Inspector].[Modules] ADD CONSTRAINT [CheckModuleWarningLevel] CHECK ([WarningLevel] < 4);';
				END

				IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'Inspector.CheckModuleCollectionProc') AND parent_object_id = OBJECT_ID(N'Inspector.Modules'))
				BEGIN 
					EXEC sp_executesql N'ALTER TABLE [Inspector].[Modules]  WITH CHECK ADD  CONSTRAINT [CheckModuleCollectionProc] CHECK  (([CollectionProcedurename] IS NULL OR [CollectionProcedurename] LIKE ''%Insert''));';
				END
						
				IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'Inspector.CheckModuleReportProc') AND parent_object_id = OBJECT_ID(N'Inspector.Modules'))
				BEGIN 
					EXEC sp_executesql N'ALTER TABLE [Inspector].[Modules]  WITH CHECK ADD  CONSTRAINT [CheckModuleReportProc] CHECK  (([ReportProcedurename] IS NULL OR [ReportProcedurename] LIKE ''%Report''));';
				END
				

			END


			--If Inspector build is less than V1.2 Column names will be different in the Module table.
			IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name LIKE'Enable%')
			BEGIN
				RAISERROR('Altering column names in table [Inspector].[Modules] as part of the upgrade',0,0) WITH NOWAIT;

				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableADHocDatabaseCreationCheck')
				BEGIN 
					EXEC sp_rename 'Inspector.Modules.EnableADHocDatabaseCreationCheck', 'ADHocDatabaseCreationCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableAGCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableAGCheck', 'AGCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableBackupsCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableBackupsCheck', 'BackupsCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableBackupSizesCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableBackupSizesCheck', 'BackupSizesCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableBackupSpaceCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableBackupSpaceCheck', 'BackupSpaceCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableDatabaseFileCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableDatabaseFileCheck', 'DatabaseFileCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableDatabaseGrowthCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableDatabaseGrowthCheck', 'DatabaseGrowthCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableDatabaseOwnershipCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableDatabaseOwnershipCheck', 'DatabaseOwnershipCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableDatabaseSettings')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableDatabaseSettings', 'DatabaseSettings', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableDatabaseStatesCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableDatabaseStatesCheck', 'DatabaseStatesCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableDriveSpaceCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableDriveSpaceCheck', 'DriveSpaceCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableFailedAgentJobCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableFailedAgentJobCheck', 'FailedAgentJobCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableFailedLoginsCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableFailedLoginsCheck', 'FailedLoginsCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableJobOwnerCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableJobOwnerCheck', 'JobOwnerCheck', 'COLUMN';
				END
				
				IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.Modules') AND name ='EnableTopFiveDatabaseSizeCheck')
				BEGIN
					EXEC sp_rename 'Inspector.Modules.EnableTopFiveDatabaseSizeCheck', 'TopFiveDatabaseSizeCheck', 'COLUMN';
				END
			END
			

			IF OBJECT_ID('Inspector.ModuleWarningLevel') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[ModuleWarningLevel]
				(
				[ModuleConfig_Desc] VARCHAR(20) NOT NULL,
				[Module] VARCHAR(50) NOT NULL,
				[WarningLevel] TINYINT NULL
				);

				ALTER TABLE [Inspector].[ModuleWarningLevel] ADD CONSTRAINT [UC_ModuleConfig_Desc_Module] UNIQUE CLUSTERED 
				(
				[ModuleConfig_Desc] ASC,
				[Module]
				);
			END

			--V2.00
			--If the modules table exists and its the Pre V2.00 version transfer the data to the new version of the table and rename
			IF EXISTS (SELECT 1 FROM sys.tables INNER JOIN sys.columns ON tables.object_id = columns.object_id 
							WHERE tables.name = N'Modules' AND [schema_id] = SCHEMA_ID(N'Inspector')
							AND column_id > 2
							AND columns.system_type_id = (SELECT system_type_id FROM sys.types WHERE name = N'bit')
							AND columns.name LIKE N'%Check')
			BEGIN
				RAISERROR('Working the magic to create the new modules table',0,0) WITH NOWAIT;

				--New columns for V1.3 for Inspector.Modules
				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'UnusedLogshipConfig' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
				BEGIN
					ALTER TABLE [Inspector].[Modules] ADD [UnusedLogshipConfig] BIT NULL;
					EXEC sp_executesql N'UPDATE [Inspector].[Modules] SET [UnusedLogshipConfig] = CASE WHEN ModuleConfig_Desc = ''Default'' THEN 1 ELSE 0 END;';	
				END

				--Create new Modules table as V2 for renaming
				IF NOT EXISTS (SELECT 1 FROM sys.tables INNER JOIN sys.columns ON tables.object_id = columns.object_id 
								WHERE tables.name = N'ModulesV2' AND [schema_id] = SCHEMA_ID(N'Inspector')
								AND columns.name IN (N'Modulename',N'CollectionProcedurename',N'ReportProcedurename',N'ReportOrder'))
				BEGIN
					CREATE TABLE [Inspector].[ModulesV2](
						[ID] INT IDENTITY(1,1),
						[ModuleConfig_Desc] [varchar](20) NOT NULL,
						[Modulename] [varchar](50) NOT NULL,
						[CollectionProcedurename] [nvarchar](128) NULL,
						[ReportProcedurename] [nvarchar](128) NULL,
						[ReportOrder] TINYINT NOT NULL,
						[WarningLevel] TINYINT NOT NULL,
						[ServerSpecific] BIT NOT NULL,
						[Debug] BIT NOT NULL,
						[IsActive] BIT NOT NULL,
						[HeaderText] VARCHAR(100) NULL,
						[Frequency] SMALLINT NOT NULL,
						[StartTime] TIME(0) NOT NULL,
						[EndTime] TIME(0) NOT NULL,
						[LastRunDateTime] DATETIME NULL
					);
				END
				
				RAISERROR('Converting old Modules table format data to the new format',0,0) WITH NOWAIT;

				EXEC sp_executesql N'
				--Transfer UseMedianCalculationForDriveSpaceCalc to the Settings table
				INSERT INTO [Inspector].[Settings] ([Description], [Value])				
				SELECT 
				[ModulesList].[Module],
				CAST([Enabled] AS CHAR(1))
				FROM 
				(
				    SELECT						
				    ISNULL(UseMedianCalculationForDriveSpaceCalc,0) AS UseMedianCalculationForDriveSpaceCalc
				    FROM [Inspector].[Modules]
					WHERE [ModuleConfig_Desc] = ''Default''
				) Modules
				UNPIVOT
				([Enabled] FOR Module IN 
				(UseMedianCalculationForDriveSpaceCalc)
				) AS [ModulesList]
				WHERE NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = ''UseMedianCalculationForDriveSpaceCalc'');	

				--Transfer Module information, only insert one row for Periodicbackupcheck as we only want the BackupsCheck Module for that moduleconfig
				INSERT INTO [Inspector].[ModulesV2] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [IsActive], [Debug], [ServerSpecific], [WarningLevel], [Frequency], [StartTime], [EndTime])
				SELECT DISTINCT
				[ModulesList].[ModuleConfig_Desc],
				[ModulesList].[Module],
				[ModulesList].[Module]+''Insert'',
				[ModulesList].[Module]+''Report'',
				CASE
					WHEN [ModulesList].[Module] = ''ADHocDatabaseCreations'' THEN 15
					WHEN [ModulesList].[Module] = ''AGCheck'' THEN 2
					WHEN [ModulesList].[Module] = ''AGDatabases'' THEN 4
					WHEN [ModulesList].[Module] = ''BackupsCheck'' THEN 5
					WHEN [ModulesList].[Module] = ''BackupSpace'' THEN 19
					WHEN [ModulesList].[Module] = ''BackupSizesByDay'' THEN 14
					WHEN [ModulesList].[Module] = ''BackupSpace'' THEN 6
					WHEN [ModulesList].[Module] = ''DatabaseFiles'' THEN 12
					WHEN [ModulesList].[Module] = ''DatabaseGrowths'' THEN 8
					WHEN [ModulesList].[Module] = ''DatabaseOwnership'' THEN 13
					WHEN [ModulesList].[Module] = ''DatabaseSettings'' THEN 16
					WHEN [ModulesList].[Module] = ''DatabaseStates'' THEN 7
					WHEN [ModulesList].[Module] = ''DriveSpace'' THEN 1
					WHEN [ModulesList].[Module] = ''FailedAgentJobs'' THEN 8
					WHEN [ModulesList].[Module] = ''JobOwner'' THEN 10
					WHEN [ModulesList].[Module] = ''LoginAttempts'' THEN 9
					WHEN [ModulesList].[Module] = ''LongRunningTransactions'' THEN 6
					WHEN [ModulesList].[Module] = ''ServerSettings'' THEN 17
					WHEN [ModulesList].[Module] = ''SuspectPages'' THEN 3
					WHEN [ModulesList].[Module] = ''TopFiveDatabases'' THEN 11
					WHEN [ModulesList].[Module] = ''UnusedLogshipConfig'' THEN 18
				END AS ReportOrder,
				[Enabled],
				0 AS [Debug],
				CASE 
					WHEN [ModulesList].[Module] = ''ADHocDatabaseCreations'' THEN 1
					WHEN [ModulesList].[Module] = ''AGCheck'' THEN 1
					WHEN [ModulesList].[Module] = ''AGDatabases'' THEN 1
					WHEN [ModulesList].[Module] = ''BackupsCheck'' THEN 1
					WHEN [ModulesList].[Module] = ''BackupSpace'' THEN 0
					WHEN [ModulesList].[Module] = ''BackupSizesByDay'' THEN 1
					WHEN [ModulesList].[Module] = ''BackupSpace'' THEN 0
					WHEN [ModulesList].[Module] = ''DatabaseFiles'' THEN 1
					WHEN [ModulesList].[Module] = ''DatabaseGrowths'' THEN 0
					WHEN [ModulesList].[Module] = ''DatabaseOwnership'' THEN 1
					WHEN [ModulesList].[Module] = ''DatabaseSettings'' THEN 1
					WHEN [ModulesList].[Module] = ''DatabaseStates'' THEN 1
					WHEN [ModulesList].[Module] = ''DriveSpace'' THEN 1
					WHEN [ModulesList].[Module] = ''FailedAgentJobs'' THEN 1
					WHEN [ModulesList].[Module] = ''JobOwner'' THEN 1
					WHEN [ModulesList].[Module] = ''LoginAttempts'' THEN 1
					WHEN [ModulesList].[Module] = ''LongRunningTransactions'' THEN 1
					WHEN [ModulesList].[Module] = ''ServerSettings'' THEN 1
					WHEN [ModulesList].[Module] = ''SuspectPages'' THEN 1
					WHEN [ModulesList].[Module] = ''TopFiveDatabases'' THEN 1
					WHEN [ModulesList].[Module] = ''UnusedLogshipConfig'' THEN 1
				END AS [ServerSpecific],
				CASE
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''ADHocDatabaseCreations'' THEN 3
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''AGCheck'' THEN 1
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''AGDatabases'' THEN 2
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''BackupsCheck'' THEN 1
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''BackupSpace'' THEN 1
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''BackupSizesByDay'' THEN 3
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''BackupSpace'' THEN 1
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''DatabaseFiles'' THEN 2
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''DatabaseGrowths'' THEN 2
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''DatabaseOwnership'' THEN 3
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''DatabaseSettings'' THEN 3
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''DatabaseStates'' THEN 2
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''DriveSpace'' THEN 1
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''FailedAgentJobs'' THEN 2
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''JobOwner'' THEN 3
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''LoginAttempts'' THEN 3
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''LongRunningTransactions'' THEN 3
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''ServerSettings'' THEN 2
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''SuspectPages'' THEN 1
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''TopFiveDatabases'' THEN 3
					WHEN [WarningLevel] IS NULL AND [ModulesList].[Module] = ''UnusedLogshipConfig'' THEN 3
					WHEN [WarningLevel] > 3 THEN 3
					ELSE [WarningLevel]
				END AS [WarningLevel],
				1440,
				@StartTime,
				@EndTime
				--HeaderText
				FROM 
				(
				    SELECT	
					ModuleConfig_Desc,						
				    ISNULL(AGCheck,0) AS AGCheck,					
				    ISNULL(BackupsCheck,0) AS BackupsCheck,	
					ISNULL(BackupSpaceCheck,0) AS BackupSpace,
				    ISNULL(BackupSizesCheck,0) AS BackupSizesByDay,			
				    ISNULL(DatabaseGrowthCheck,0) AS DatabaseGrowths,			
				    ISNULL(DatabaseFileCheck,0) AS DatabaseFiles,			
				    ISNULL(DatabaseOwnershipCheck,0) AS DatabaseOwnership,		
				    ISNULL(DatabaseStatesCheck,0) AS DatabaseStates,			
				    ISNULL(DriveSpaceCheck,0) AS DriveSpace,				
				    ISNULL(FailedAgentJobCheck,0) AS FailedAgentJobs,			
				    ISNULL(JobOwnerCheck,0) AS JobOwner,				
				    ISNULL(FailedLoginsCheck,0) AS LoginAttempts,			
				    ISNULL(TopFiveDatabaseSizeCheck,0) AS TopFiveDatabases,		
				    ISNULL(ADHocDatabaseCreationCheck,0) AS ADHocDatabaseCreations,	
				    ISNULL(DatabaseSettings,0) AS DatabaseSettings,
				    ISNULL(ServerSettings,0) AS ServerSettings,
				    ISNULL(SuspectPages,0) AS SuspectPages,
				    ISNULL(AGDatabases,0) AS AGDatabases,
				    ISNULL(LongRunningTransactions,0) AS LongRunningTransactions,
					ISNULL(UnusedLogshipConfig,0) AS UnusedLogshipConfig
				    FROM [Inspector].[Modules]
				) Modules
				UNPIVOT
				([Enabled] FOR Module IN 
				(AGCheck
				,BackupsCheck
				,BackupSpace
				,BackupSizesByDay
				,DatabaseGrowths
				,DatabaseFiles
				,DatabaseOwnership
				,DatabaseStates
				,DriveSpace
				,FailedAgentJobs
				,JobOwner
				,LoginAttempts
				,TopFiveDatabases
				,ADHocDatabaseCreations
				,DatabaseSettings
				,ServerSettings
				,SuspectPages
				,AGDatabases
				,LongRunningTransactions
				,UnusedLogshipConfig
				) ) AS [ModulesList]
				LEFT JOIN [Inspector].[ModuleWarningLevel] ON CAST([ModulesList].[Module] AS VARCHAR(50)) = [ModuleWarningLevel].[Module]
													  AND [ModulesList].[ModuleConfig_Desc] = [ModuleWarningLevel].[ModuleConfig_Desc]
			    WHERE [ModulesList].ModuleConfig_Desc != ''PeriodicBackupCheck''
				OR ([ModulesList].ModuleConfig_Desc = ''PeriodicBackupCheck'' AND [ModulesList].Module = ''BackupsCheck'')
				EXCEPT
				SELECT 
				[ModuleConfig_Desc],
				[Modulename],
				[CollectionProcedurename],
				[ReportProcedurename],
				[ReportOrder],
				[IsActive],
				[Debug],
				[ServerSpecific],
				[WarningLevel],
				1440,
				@StartTime,
				@EndTime
				FROM [Inspector].[ModulesV2];
				
				UPDATE [Inspector].[ModulesV2]
				SET [Frequency] = 120, [StartTime] = DATEADD(HOUR,2,@StartTime), [EndTime] = @EndTime
				WHERE [ModuleConfig_Desc] = ''PeriodicBackupCheck''
				AND Modulename = ''BackupsCheck'';

				INSERT INTO [Inspector].[ModulesV2] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [WarningLevel], [ServerSpecific], [Debug], [IsActive], [HeaderText], [Frequency], [StartTime], [EndTime])
				VALUES(''Default'',''DatacollectionsOverdue'',''DatacollectionsOverdueInsert'',''DatacollectionsOverdueReport'',21,1,1,0,1,NULL,1440,@StartTime,@EndTime);
				',N'@StartTime TIME(0),@EndTime TIME(0)',@StartTime = @StartTime,@EndTime = @EndTime;


					IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('Inspector.CurrentServers') AND name = N'FK_ModuleConfig_Desc')
					BEGIN 
						ALTER TABLE [Inspector].[CurrentServers] DROP CONSTRAINT [FK_ModuleConfig_Desc];
					END
					
					IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('Inspector.EmailConfig') AND name = N'FK_ModuleConfig_Email')
					BEGIN 
						ALTER TABLE [Inspector].[EmailConfig] DROP CONSTRAINT [FK_ModuleConfig_Email];
					END

					IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Inspector].[FK_CatalogueModules_ModuleConfig_Desc]') AND parent_object_id = OBJECT_ID(N'[Inspector].[CatalogueModules]'))
					BEGIN 
						ALTER TABLE [Inspector].[CatalogueModules] DROP CONSTRAINT [FK_CatalogueModules_ModuleConfig_Desc];
					END
					
					DROP TABLE [Inspector].[Modules];

					CREATE TABLE [Inspector].[Modules](
						[ID] [int] IDENTITY(1,1) NOT NULL,
						[ModuleConfig_Desc] [varchar](20) NOT NULL,
						[IsActive] BIT NOT NULL,
						[Frequency] SMALLINT NOT NULL,
						[StartTime] TIME(0) NOT NULL,
						[EndTime] TIME(0) NOT NULL,
						[LastRunDateTime] DATETIME NULL,
						[ReportWarningsOnly] TINYINT NOT NULL,
						[NoClutter] BIT NOT NULL,
						[ShowDisabledModules] BIT NOT NULL
					 CONSTRAINT [PK_ModuleConfig_Desc] PRIMARY KEY CLUSTERED 
					([ModuleConfig_Desc] ASC)
					);

					EXEC sp_executesql N'
					INSERT INTO [Inspector].[Modules] ([ModuleConfig_Desc],[IsActive],[Frequency],[StartTime],[EndTime],[ReportWarningsOnly],[NoClutter],[ShowDisabledModules])
					SELECT 
					[ModuleConfig_Desc],
					1,
					CASE 
						WHEN [ModuleConfig_Desc] = ''PeriodicBackupCheck'' THEN 120
						ELSE 1440
					END,
					CASE 
						WHEN [ModuleConfig_Desc] = ''PeriodicBackupCheck'' THEN ''11:00''
						ELSE ''09:00''
					END,
					''17:30'',
					CASE 
						WHEN [ModuleConfig_Desc] = ''PeriodicBackupCheck'' THEN 1
						ELSE 0
					END,
					CASE 
						WHEN [ModuleConfig_Desc] = ''PeriodicBackupCheck'' THEN 1
						ELSE 0
					END,
					1
					FROM 
					(
						SELECT DISTINCT [ModuleConfig_Desc]
						FROM [Inspector].[ModulesV2]
					) AS DistinctModuleConfig_Desc;';
					

					IF EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Inspector].[FK_ModuleConfig_Desc]') AND parent_object_id = OBJECT_ID(N'[Inspector].[CurrentServers]'))
					BEGIN 
						ALTER TABLE [Inspector].[CurrentServers] DROP CONSTRAINT [FK_ModuleConfig_Desc];
					END
					
					IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Inspector].[FK_ModuleConfig_Desc]') AND parent_object_id = OBJECT_ID(N'[Inspector].[CurrentServers]'))
					BEGIN 
						ALTER TABLE [Inspector].[CurrentServers]  WITH CHECK ADD  CONSTRAINT [FK_ModuleConfig_Desc] FOREIGN KEY([ModuleConfig_Desc])
						REFERENCES [Inspector].[Modules] ([ModuleConfig_Desc]);
					
						ALTER TABLE [Inspector].[CurrentServers] CHECK CONSTRAINT [FK_ModuleConfig_Desc];
					END
					
					
					IF EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Inspector].[FK_ModuleConfig_Email]') AND parent_object_id = OBJECT_ID(N'[Inspector].[EmailConfig]'))
					BEGIN
						ALTER TABLE [Inspector].[EmailConfig] DROP CONSTRAINT [FK_ModuleConfig_Email];
					END
					
					IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Inspector].[FK_ModuleConfig_Email]') AND parent_object_id = OBJECT_ID(N'[Inspector].[EmailConfig]'))
					BEGIN
						ALTER TABLE [Inspector].[EmailConfig]  WITH CHECK ADD  CONSTRAINT [FK_ModuleConfig_Email] FOREIGN KEY([ModuleConfig_Desc])
						REFERENCES [Inspector].[Modules] ([ModuleConfig_Desc]);
					
						ALTER TABLE [Inspector].[EmailConfig] CHECK CONSTRAINT [FK_ModuleConfig_Email];
					END

		
				IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CheckModuleWarningLevel' AND type = N'C' AND parent_object_id = OBJECT_ID(N'Inspector.ModulesV2'))
				BEGIN 
					ALTER TABLE [Inspector].[ModulesV2] ADD CONSTRAINT [CheckModuleWarningLevel] CHECK ([WarningLevel] < 4);
				END

				IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'Inspector.CheckModuleCollectionProc') AND parent_object_id = OBJECT_ID(N'Inspector.ModulesV2'))
				BEGIN 
					EXEC sp_executesql N'ALTER TABLE [Inspector].[ModulesV2]  WITH CHECK ADD  CONSTRAINT [CheckModuleCollectionProc] CHECK  (([CollectionProcedurename] IS NULL OR [CollectionProcedurename] LIKE ''%Insert''));';
				END
						
				IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'Inspector.CheckModuleReportProc') AND parent_object_id = OBJECT_ID(N'Inspector.ModulesV2'))
				BEGIN 
					EXEC sp_executesql N'ALTER TABLE [Inspector].[ModulesV2]  WITH CHECK ADD  CONSTRAINT [CheckModuleReportProc] CHECK  (([ReportProcedurename] IS NULL OR [ReportProcedurename] LIKE ''%Report''));';
				END
			
				--Switch tables.
				EXEC sp_rename 'Inspector.Modules', 'ModuleConfig';
				EXEC sp_rename 'Inspector.ModulesV2', 'Modules';

				--Update Warning levels where the Warning level has been changed from the defaults (Keep user adjusted levels)
				EXEC sp_executesql N'		
				UPDATE [Modules]
				SET [WarningLevel] = [ModuleWarningLevel].[WarningLevel]
				FROM [Inspector].[ModuleWarningLevel]
				INNER JOIN [Inspector].[Modules] ON [ModuleWarningLevel].[ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc] 
												AND [ModuleWarningLevel].[Module] = [Modules].[Modulename]
				WHERE [ModuleWarningLevel].[WarningLevel] IS NOT NULL
				AND [ModuleWarningLevel].[WarningLevel] != [Modules].[WarningLevel]
				AND [ModuleWarningLevel].[WarningLevel] < 4;'			

				
				IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ModuleConfig_Desc' AND referenced_object_id = OBJECT_ID(N'Inspector.ModuleConfig'))
				BEGIN
					ALTER TABLE [Inspector].[CurrentServers]  WITH CHECK ADD  CONSTRAINT [FK_ModuleConfig_Desc] FOREIGN KEY([ModuleConfig_Desc])
					REFERENCES [Inspector].[ModuleConfig] ([ModuleConfig_Desc]);
					
					ALTER TABLE [Inspector].[CurrentServers] CHECK CONSTRAINT [FK_ModuleConfig_Desc];
				END
				
				IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ModuleConfig_Email' AND referenced_object_id = OBJECT_ID(N'Inspector.ModuleConfig'))
				BEGIN
					ALTER TABLE [Inspector].[EmailConfig]  WITH CHECK ADD CONSTRAINT [FK_ModuleConfig_Email] FOREIGN KEY([ModuleConfig_Desc])
					REFERENCES [Inspector].[ModuleConfig] ([ModuleConfig_Desc]);
					
					ALTER TABLE [Inspector].[EmailConfig] CHECK CONSTRAINT [FK_ModuleConfig_Email];
				END
			
				IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ModuleConfig_Modules' AND referenced_object_id = OBJECT_ID(N'Inspector.ModuleConfig'))
				BEGIN
					ALTER TABLE [Inspector].[Modules]  WITH CHECK ADD CONSTRAINT [FK_ModuleConfig_Modules] FOREIGN KEY([ModuleConfig_Desc])
					REFERENCES [Inspector].[ModuleConfig] ([ModuleConfig_Desc]);
					
					ALTER TABLE [Inspector].[Modules] CHECK CONSTRAINT [FK_ModuleConfig_Modules];
				END

				IF OBJECT_ID('Inspector.CatalogueModules') IS NULL
				BEGIN
					CREATE TABLE [Inspector].[CatalogueModules] (
					[ModuleConfig_Desc] VARCHAR(20),
					[Module] VARCHAR(50),
					[Enabled] BIT
					);
				END

				IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Inspector].[FK_CatalogueModules_ModuleConfig_Desc]') AND parent_object_id = OBJECT_ID(N'[Inspector].[CatalogueModules]'))
				BEGIN 
					ALTER TABLE [Inspector].[CatalogueModules]  WITH CHECK ADD  CONSTRAINT [FK_CatalogueModules_ModuleConfig_Desc] FOREIGN KEY([ModuleConfig_Desc])
					REFERENCES [Inspector].[ModuleConfig] ([ModuleConfig_Desc])
					
					ALTER TABLE [Inspector].[CatalogueModules] CHECK CONSTRAINT [FK_CatalogueModules_ModuleConfig_Desc]
				END	
				
				IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[UC_CatalogueModules_ModuleConfig_Module]', 'UQ') AND parent_object_id = OBJECT_ID(N'[Inspector].[CatalogueModules]', 'U'))
				BEGIN
					EXEC sp_executesql N'				
					ALTER TABLE [Inspector].[CatalogueModules] ADD CONSTRAINT [UC_CatalogueModules_ModuleConfig_Module] UNIQUE (ModuleConfig_Desc,Module);';
				END
			
			END
			ELSE --If the old Modules table does not exist then check that the new Version is in place - if not then create
			BEGIN 
				--Create new Modules table
				IF NOT EXISTS (SELECT 1 FROM sys.tables INNER JOIN sys.columns ON tables.object_id = columns.object_id 
								WHERE tables.name = N'Modules' AND [schema_id] = SCHEMA_ID(N'Inspector')
								AND columns.name IN (N'Modulename',N'CollectionProcedurename',N'ReportProcedurename',N'ReportOrder'))
				BEGIN
					CREATE TABLE [Inspector].[Modules](
						[ID] INT IDENTITY(1,1),
						[ModuleConfig_Desc] [varchar](20) NOT NULL,
						[Modulename] [varchar](50) NOT NULL,
						[CollectionProcedurename] [nvarchar](128) NULL,
						[ReportProcedurename] [nvarchar](128) NULL,
						[ReportOrder] TINYINT NOT NULL,
						[WarningLevel] TINYINT NOT NULL,
						[ServerSpecific] BIT NOT NULL,
						[Debug] BIT NOT NULL,
						[IsActive] [bit] NOT NULL,
						[HeaderText] VARCHAR(100) NULL,
						[Frequency] SMALLINT NOT NULL,
						[StartTime] TIME(0) NOT NULL,
						[EndTime] TIME(0) NOT NULL,
						[LastRunDateTime] DATETIME NULL
					);
				END
			
			END 

				IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'ModuleConfig' AND [schema_id] = SCHEMA_ID(N'Inspector'))
				BEGIN 
					CREATE TABLE [Inspector].[ModuleConfig](
						[ID] [int] IDENTITY(1,1) NOT NULL,
						[ModuleConfig_Desc] [varchar](20) NOT NULL,
						[IsActive] BIT NOT NULL,
						[Frequency] SMALLINT NOT NULL,
						[StartTime] TIME(0) NOT NULL,
						[EndTime] TIME(0) NOT NULL,
						[LastRunDateTime] DATETIME NULL,
						[ReportWarningsOnly] TINYINT NOT NULL,
						[NoClutter] BIT NOT NULL,
						[ShowDisabledModules] BIT NOT NULL,
						[RunDay] VARCHAR(70) NULL,
						[EmailGroup] VARCHAR(50) NULL,
						[EmailProfile] NVARCHAR(128) NULL,
						[EmailAsAttachment] BIT NULL
					 CONSTRAINT [PK_ModuleConfig_Desc] PRIMARY KEY CLUSTERED 
					([ModuleConfig_Desc] ASC)
					);

					EXEC sp_executesql N'INSERT INTO [Inspector].[ModuleConfig] ([ModuleConfig_Desc],[IsActive],[Frequency],[StartTime],[EndTime],[ReportWarningsOnly],[NoClutter],[ShowDisabledModules],[RunDay])
					VALUES (''Default'',1,1440,''09:00'',''17:30'',0,0,1,''Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday''),(''PeriodicBackupCheck'',1,120,''11:00'',''17:30'',1,1,1,''Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday'');';
				END

				--Add new RunDay column for Specific weekday schedules
				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID('Inspector.ModuleConfig') AND [name] = 'RunDay')
				BEGIN 
					ALTER TABLE [Inspector].[ModuleConfig] ADD [RunDay] VARCHAR(70) NULL;
				END 

				--Update RunDay column if it is NULL , its the same behaviour as the update but it just shows users the supported format
				EXEC sp_executesql N'
				UPDATE [Inspector].[ModuleConfig]
				SET [RunDay] = ''Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday''
				WHERE [RunDay] IS NULL;';

				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID('Inspector.ModuleConfig') AND [name] = 'EmailGroup')
				BEGIN 
					EXEC sp_executesql N'ALTER TABLE [Inspector].[ModuleConfig] ADD [EmailGroup] VARCHAR(50) NULL;';
				END

				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID('Inspector.ModuleConfig') AND [name] = 'EmailProfile')
				BEGIN 
					EXEC sp_executesql N'ALTER TABLE [Inspector].[ModuleConfig] ADD [EmailProfile] VARCHAR(128) NULL;';
				END

				IF NOT EXISTS (SELECT 1
								FROM sys.tables 
								INNER JOIN sys.columns ON tables.object_id = columns.object_id 
								INNER JOIN sys.types ON columns.user_type_id = types.user_type_id
								WHERE tables.name = N'ModuleConfig' 
								AND tables.schema_id = SCHEMA_ID(N'Inspector')
								AND columns.name = N'ReportWarningsOnly'
								AND types.name = N'tinyint')
				BEGIN 
					ALTER TABLE [Inspector].[ModuleConfig] ALTER COLUMN [ReportWarningsOnly] TINYINT NOT NULL;
				END

				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID('Inspector.ModuleConfig') AND [name] = 'EmailAsAttachment')
				BEGIN 
					EXEC sp_executesql N'ALTER TABLE [Inspector].[ModuleConfig] ADD [EmailAsAttachment] BIT NULL;';
				END

				EXEC sp_executesql N'
				UPDATE [Inspector].[ModuleConfig]
				SET [EmailAsAttachment] = 0
				WHERE [EmailAsAttachment] IS NULL;';

				IF OBJECT_ID('Inspector.CatalogueModules') IS NULL
				BEGIN
					CREATE TABLE [Inspector].[CatalogueModules] (
					[ModuleConfig_Desc] VARCHAR(20),
					[Module] VARCHAR(50),
					[Enabled] BIT
					);
					
					IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[UC_CatalogueModules_ModuleConfig_Module]', 'UQ') AND parent_object_id = OBJECT_ID(N'[Inspector].[CatalogueModules]', 'U'))
					BEGIN
						EXEC sp_executesql N'				
						ALTER TABLE [Inspector].[CatalogueModules] ADD CONSTRAINT [UC_CatalogueModules_ModuleConfig_Module] UNIQUE (ModuleConfig_Desc,Module);';
					END

					EXEC sp_executesql N'
					--One off population
					INSERT INTO [Inspector].[CatalogueModules] ([ModuleConfig_Desc],[Module],[Enabled])
					SELECT 
					[ModuleConfig].[ModuleConfig_Desc],
					[CatalogueModulesList].[Module],
					CASE WHEN [ModuleConfig_Desc] = ''Default'' THEN 1 ELSE 0 END AS [Enabled]
					FROM [Inspector].[ModuleConfig]
					CROSS JOIN (SELECT [Module] FROM (VALUES(''CatalogueMissingLogins''),(''CatalogueDroppedTables''),(''CatalogueDroppedDatabases'')) ModuleList(Module)) AS CatalogueModulesList
					WHERE NOT EXISTS (SELECT 1 FROM [Inspector].[CatalogueModules] WHERE [ModuleConfig_Desc] = [ModuleConfig].[ModuleConfig_Desc] AND [Module] = [CatalogueModulesList].[Module])';
				END
				ELSE 
				BEGIN 
					EXEC sp_executesql N'
					--Added this block for future Catalogue module additions
					INSERT INTO [Inspector].[CatalogueModules] ([ModuleConfig_Desc],[Module],[Enabled])
					SELECT 
					[ModuleConfig].[ModuleConfig_Desc],
					[CatalogueModulesList].[Module],
					CASE WHEN [ModuleConfig_Desc] = ''Default'' THEN 1 ELSE 0 END AS [Enabled]
					FROM [Inspector].[ModuleConfig]
					CROSS JOIN (SELECT [Module] FROM (VALUES(''CatalogueMissingLogins''),(''CatalogueDroppedTables''),(''CatalogueDroppedDatabases'')) ModuleList(Module)) AS CatalogueModulesList
					WHERE NOT EXISTS (SELECT 1 FROM [Inspector].[CatalogueModules] WHERE [ModuleConfig_Desc] = [ModuleConfig].[ModuleConfig_Desc] AND [Module] = [CatalogueModulesList].[Module])';
				END 
					

			--Recreate the foreign keys
			IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CatalogueModules_ModuleConfig_Desc' AND referenced_object_id = OBJECT_ID(N'Inspector.ModuleConfig'))
			BEGIN
				EXEC sp_executesql N'
				ALTER TABLE [Inspector].[CatalogueModules]  WITH CHECK ADD  CONSTRAINT [FK_CatalogueModules_ModuleConfig_Desc] FOREIGN KEY([ModuleConfig_Desc])
				REFERENCES [Inspector].[ModuleConfig] ([ModuleConfig_Desc]);
			
				ALTER TABLE [Inspector].[CatalogueModules] CHECK CONSTRAINT [FK_CatalogueModules_ModuleConfig_Desc];';
			END

			IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ModuleConfig_Modules' AND referenced_object_id = OBJECT_ID(N'Inspector.ModuleConfig'))
			BEGIN
				ALTER TABLE [Inspector].[Modules]  WITH CHECK ADD CONSTRAINT [FK_ModuleConfig_Modules] FOREIGN KEY([ModuleConfig_Desc])
				REFERENCES [Inspector].[ModuleConfig] ([ModuleConfig_Desc]);
				
				ALTER TABLE [Inspector].[Modules] CHECK CONSTRAINT [FK_ModuleConfig_Modules];
			END

			IF OBJECT_ID('Inspector.ADHocDatabaseCreations') IS NULL
			BEGIN 
				CREATE TABLE [Inspector].[ADHocDatabaseCreations] (
				[Servername] NVARCHAR(128) NOT NULL,
				[Log_Date] DATETIME NULL,
				[Databasename] NVARCHAR(128) NOT NULL,
				[Create_Date] DATETIME NULL
				);
			END

			
			IF OBJECT_ID('Inspector.ADHocDatabaseSupression') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[ADHocDatabaseSupression] (
				[Servername] NVARCHAR(128),
				[Log_Date] DATETIME,
				[Databasename] NVARCHAR(128),
				[Suppress] BIT
				);
			END
			
			
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

			IF NOT EXISTS(SELECT 1 FROM [Inspector].[MultiWarningModules] WHERE [Modulename] IN ('DriveSpace','DatabaseGrowths','DatabaseStates','ServerSettings'))
			BEGIN 
				EXEC sp_executesql N'INSERT INTO [Inspector].[MultiWarningModules] ([Modulename])
				VALUES(''DriveSpace''),(''DatabaseGrowths''),(''DatabaseStates''),(''ServerSettings'');';
			END


			IF OBJECT_ID('Inspector.AGCheck') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[AGCheck](
				[Servername] NVARCHAR(128) NOT NULL,
				[Log_Date] DATETIME NOT NULL,
				[AGname] NVARCHAR(128) NULL,
				[State] VARCHAR(50) NULL,
				[ReplicaServername] NVARCHAR(256) NULL,
				[Suspended] BIT NULL,
				[SuspendReason] VARCHAR(50) NULL,
				[FailoverReady] BIT NULL
				); 
			END

			IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.AGCheck') AND [name] = 'FailoverReady')
			BEGIN 
				ALTER TABLE [Inspector].[AGCheck] ADD [FailoverReady] BIT;
			END
			 
			IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.AGCheck') AND [name] = 'ReplicaRole')
			BEGIN 
				ALTER TABLE [Inspector].[AGCheck] ADD [ReplicaRole] NVARCHAR(60) NULL;
			END


			IF OBJECT_ID('Inspector.AGCheckConfig') IS NULL
			BEGIN
			CREATE TABLE [Inspector].[AGCheckConfig] (
			[AGname] NVARCHAR(128) NOT NULL,
			[AGReplicaCount] TINYINT NOT NULL,
			[FailoverReadyNodeCount] TINYINT NOT NULL,
			[FailoverReadyNodePercentCount] AS CASE 
													WHEN [FailoverReadyNodeCount] > 10 
													THEN CASE
															WHEN CAST(ROUND([AGReplicaCount] * (CAST(FailoverReadyNodeCount AS DECIMAL(4,2))/100),0) AS TINYINT) < 1 THEN 1 
															ELSE CAST(ROUND([AGReplicaCount] * (CAST(FailoverReadyNodeCount AS DECIMAL(4,2))/100),0) AS TINYINT) 
														 END
											   END,
			CONSTRAINT [PK_AGCheckConfig_AGname] PRIMARY KEY CLUSTERED (AGname)
			);
			END


			SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
			--Populate AGCheckConfig
			INSERT INTO [Inspector].[AGCheckConfig] ([AGname],[AGReplicaCount],[FailoverReadyNodeCount])
			SELECT 
			Groups.[name],
			COUNT([name]),
			2
			FROM sys.availability_groups Groups
			INNER JOIN sys.availability_replicas as Replicas ON Groups.group_id = Replicas.group_id
			WHERE NOT EXISTS (SELECT 1 FROM [Inspector].[AGCheckConfig] WHERE [AGname] = Groups.[name] COLLATE DATABASE_DEFAULT)
			GROUP BY Groups.[name];
			'
			EXEC(@SQLStatement);
			

			IF OBJECT_ID('Inspector.DatabaseFiles') IS NULL
			CREATE TABLE [Inspector].[DatabaseFiles]
			(
			[Servername] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Databasename] NVARCHAR(128), 
			[FileType] VARCHAR(8),
			[FilePath] NVARCHAR(260)
			);
			
			
			
			IF OBJECT_ID('Inspector.DatabaseStates') IS NULL
			CREATE TABLE [Inspector].[DatabaseStates]
			(
			[Servername] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[DatabaseState] VARCHAR(40)  NULL,
			[Total] INT,
			[DatabaseNames] VARCHAR(MAX) NULL
			); 
			
			
			IF OBJECT_ID('Inspector.DriveSpace') IS NULL
			CREATE TABLE [Inspector].[DriveSpace] 
			(
			[Servername] NVARCHAR(128),
			[Log_Date] DATETIME,
			[Drive] NVARCHAR(128),
			[Capacity_GB] DECIMAL(10,2),
			[AvailableSpace_GB] DECIMAL(10,2),
			[UsedSpaceGB] DECIMAL(10,2) NULL,
			[PrevUsedSpace_GB] DECIMAL(10,2) NULL,
			[UsedSpaceVarianceGB] AS CAST([UsedSpaceGB]-[PrevUsedSpace_GB] AS DECIMAL(10,2))
			);

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND type = 1)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND name='CIX_Servername_LogDate_Drive')
				BEGIN 
					CREATE CLUSTERED INDEX [CIX_Servername_LogDate_Drive] ON [Inspector].[DriveSpace] ([Servername] ASC,[Log_Date] ASC,[Drive] ASC);
				END
			END

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND name = 'IX_DriveSpace_Servername_Drive_Capacity_GB_Log_Date')
			BEGIN 
				CREATE NONCLUSTERED INDEX [IX_DriveSpace_Servername_Drive_Capacity_GB_Log_Date] ON [Inspector].[DriveSpace]
				(Servername ASC,Drive ASC,Capacity_GB ASC,Log_Date DESC) INCLUDE (AvailableSpace_GB);
			END

			--Increase column length to accomodate shared storage names such as \\ClusterStorage
			IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND [name] = N'Drive' AND max_length != 256)
			BEGIN 
				ALTER TABLE [Inspector].[DriveSpace] ALTER COLUMN [Drive] NVARCHAR(128);
			END

			IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND [name] = N'UsedSpaceGB')
			BEGIN 
				ALTER TABLE [Inspector].[DriveSpace] ADD [UsedSpaceGB] DECIMAL(10,2) NULL;
			END
			
			IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND [name] = N'PrevUsedSpace_GB')
			BEGIN 
				ALTER TABLE [Inspector].[DriveSpace] ADD [PrevUsedSpace_GB] DECIMAL(10,2) NULL;
			END

			IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND [name] = N'UsedSpaceVarianceGB')
			BEGIN 
				EXEC sp_executesql N'ALTER TABLE [Inspector].[DriveSpace] ADD [UsedSpaceVarianceGB] AS CAST([UsedSpaceGB]-[PrevUsedSpace_GB] AS DECIMAL(10,2));';
			END

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND name = 'IX_DriveSpace_Drive_UsedSpaceVarianceGB')
			BEGIN 
				CREATE NONCLUSTERED INDEX [IX_DriveSpace_Drive_UsedSpaceVarianceGB] ON Inspector.DriveSpace ([Drive] ASC,[UsedSpaceVarianceGB] ASC);
			END


			/* One off update of UsedSpaceGB and PrevUsedSpace_GB */
			EXEC sp_executesql N'UPDATE DS
			SET UsedSpaceGB = PrevUsedCalc.UsedSpaceGB,
				PrevUsedSpace_GB = PrevUsedCalc.PrevUsed
			FROM 
			(
				SELECT [Servername]
				      ,[Log_Date]
				      ,[Drive]
					  ,[Capacity_GB]-[AvailableSpace_GB] AS UsedSpaceGB
					  ,LAG([UsedSpaceGB],1,[UsedSpaceGB]) OVER(PARTITION BY [Servername],[Drive] ORDER BY [Log_Date] ASC) AS PrevUsed
				  FROM [Inspector].[DriveSpace]
			) AS PrevUsedCalc 
			INNER JOIN Inspector.DriveSpace DS ON DS.Servername = PrevUsedCalc.Servername
											AND DS.Drive = PrevUsedCalc.Drive
											AND DS.Log_Date = PrevUsedCalc.Log_Date
			WHERE (DS.PrevUsedSpace_GB IS NULL OR DS.UsedSpaceGB IS NULL);';


			IF OBJECT_ID('Inspector.FailedAgentJobs') IS NULL
			CREATE TABLE [Inspector].[FailedAgentJobs]
			(
			[Servername] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Jobname] VARCHAR(128)  NULL,
			[LastStepFailed] TINYINT NULL,
			[LastFailedDate] DATETIME NULL,
			[LastError] VARCHAR(260) NULL
			);
			
			
			IF OBJECT_ID('Inspector.LoginAttempts') IS NULL
			CREATE TABLE [Inspector].[LoginAttempts]
			(
			[Servername] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Username] VARCHAR(50)  NULL,
			[Attempts] INT NULL,
			[LastErrorDate] DATETIME NULL,
			[LastError] VARCHAR(260) NULL
			); 
			
			
			
			IF OBJECT_ID('Inspector.JobOwner') IS NULL
			CREATE TABLE [Inspector].[JobOwner]
			(
			[Servername] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Job_ID]  UNIQUEIDENTIFIER  NULL,
			[Jobname] VARCHAR(100) NOT NULL
			); 
			
			
			
			IF OBJECT_ID('Inspector.TopFiveDatabases') IS NULL
			CREATE TABLE [Inspector].[TopFiveDatabases]
			(
			[Servername] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Databasename] NVARCHAR(128)  NULL,
			[TotalSize_MB] BIGINT
			); 
			
			
			IF OBJECT_ID('Inspector.BackupsCheck') IS NULL
			--New columns for 1.2 [primary_replica],[backup_preference]
			CREATE TABLE [Inspector].[BackupsCheck](
			[Servername] NVARCHAR (128) NOT NULL,
			[Log_Date] [datetime] NOT NULL,
			[Databasename] [nvarchar](128) NULL,
			[AGname] Nvarchar (128) NULL,
			[FULL] [datetime] NULL,
			[DIFF] [datetime] NULL,
			[LOG] [datetime] NULL,
			[IsFullRecovery] [bit] NULL,
			[IsSystemDB] [bit] NULL,
			[primary_replica] [nvarchar](128) NULL,
			[backup_preference] [nvarchar](60) NULL
			);
			
			--New columns for 1.2 [primary_replica],[backup_preference]
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.BackupsCheck') AND name ='primary_replica')
			BEGIN 
				ALTER TABLE [Inspector].[BackupsCheck] ADD [primary_replica] [nvarchar](128) NULL;
			END 	
			
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.BackupsCheck') AND name ='backup_preference')
			BEGIN 
				ALTER TABLE [Inspector].[BackupsCheck] ADD [backup_preference] [nvarchar](60) NULL;
			END 
			
			
			IF OBJECT_ID('Inspector.DatabaseFileSizes') IS NULL
			BEGIN
			--New Column [LastUpdated] for 1.0.1
			CREATE TABLE [Inspector].[DatabaseFileSizes](
			[Servername] NVARCHAR(128)  NOT NULL,
			[Database_id] INT NOT NULL,
			[Database_name] NVARCHAR(128) NULL,
			[OriginalDateLogged] DATETIME NOT NULL,
			[OriginalSize_MB] BIGINT NULL,
			[Type_desc] NVARCHAR(60) NULL,
			[File_id] INT NOT NULL,
			[Filename] NVARCHAR(260) NULL,
			[PostGrowthSize_MB] BIGINT NULL,
			[GrowthRate] INT NULL,
			[Is_percent_growth] BIT NOT NULL,
			[NextGrowth] BIGINT  NULL,
			[LastUpdated] DATETIME NULL	  
			); 
			END

			--Change data type for File_id #205
			IF EXISTS(SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID(N'Inspector.DatabaseFileSizes') AND [name] = N'File_id' AND [user_type_id] = (SELECT user_type_id FROM sys.types WHERE [name] = N'tinyint'))
			BEGIN 
				ALTER TABLE [Inspector].[DatabaseFileSizes] ALTER COLUMN [File_id] INT NOT NULL;	
			END 

			--New Column [LastUpdated] for 1.0.1
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.DatabaseFileSizes') AND name ='LastUpdated')
			BEGIN 
				ALTER TABLE [Inspector].[DatabaseFileSizes] ADD [LastUpdated] DATETIME NULL;
			END 

;
			SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
			--Make a one off update to the Database files to ensure they now show the full path and not just the filename
			UPDATE [DatabaseFileSizes]
			SET [Filename] = [master_files].[physical_name],[LastUpdated] = GETDATE()
			FROM sys.master_files
			INNER JOIN [Inspector].[DatabaseFileSizes] ON [DatabaseFileSizes].[Database_id] = [master_files].[database_id]
														AND [DatabaseFileSizes].[File_id] = [master_files].[file_id]
			WHERE [DatabaseFileSizes].[Servername] = @@SERVERNAME;';

			EXEC(@SQLStatement);


			IF OBJECT_ID('Inspector.DatabaseFileSizeHistory') IS NULL
			BEGIN
			CREATE TABLE [Inspector].DatabaseFileSizeHistory
			(
			[GrowthID] BIGINT IDENTITY(1,1),
			[Servername] NVARCHAR(128)  NOT NULL,
			[Database_id] INT NOT NULL,
			[Database_name] NVARCHAR(128) NOT NULL,
			[Log_Date] DATETIME NOT NULL,
			[Type_Desc] NVARCHAR(60) NOT NULL,
			[File_id] INT NOT NULL,
			[FileName] NVARCHAR(260) NOT NULL,
			[PreGrowthSize_MB] BIGINT NOT NULL,
			[GrowthRate_MB] INT NOT NULL,
			[GrowthIncrements] INT NOT NULL,
			[PostGrowthSize_MB] BIGINT NOT NULL,
			[Drive] NVARCHAR(128)
			);

			END

			--Change data type for File_id #205
			IF EXISTS(SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID(N'Inspector.DatabaseFileSizeHistory') AND [name] = N'File_id' AND [user_type_id] = (SELECT user_type_id FROM sys.types WHERE [name] = N'tinyint'))
			BEGIN 
				ALTER TABLE [Inspector].[DatabaseFileSizeHistory] ALTER COLUMN [File_id] INT NOT NULL;	
			END 


			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.DatabaseFileSizeHistory') AND name='IX_Servername_Includes_Log_Date')
			BEGIN
				CREATE NONCLUSTERED INDEX [IX_Servername_Includes_Log_Date] ON [Inspector].[DatabaseFileSizeHistory]
				([Servername] ASC) INCLUDE ([Log_Date]); 
			END

			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Drive' AND [object_id] = OBJECT_ID(N'Inspector.DatabaseFileSizeHistory'))
			BEGIN
				--New column for 1.4
				ALTER TABLE [Inspector].[DatabaseFileSizeHistory] ADD [Drive] NVARCHAR(128);
			END

			--Increase column length to accomodate shared storage names such as \\ClusterStorage
			IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.DatabaseFileSizeHistory') AND [name] = 'Drive' AND max_length != 256)
			BEGIN 
				ALTER TABLE [Inspector].[DatabaseFileSizeHistory] ALTER COLUMN [Drive] NVARCHAR(128);
			END


			IF OBJECT_ID('Inspector.EmailRecipients') IS NULL		
			CREATE TABLE [Inspector].[EmailRecipients]
			(
			ID INT IDENTITY(1,1),
			Description VARCHAR(50) NOT NULL,
			Recipients VARCHAR(1000) DEFAULT NULL
			CONSTRAINT UC_EmailDescription UNIQUE (Description)
			); 

			--NEw FK for 2.2
			IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ModuleConfig_EmailGroup')
			BEGIN 
				EXEC sp_executesql N'ALTER TABLE [Inspector].[ModuleConfig] WITH CHECK ADD CONSTRAINT [FK_ModuleConfig_EmailGroup] FOREIGN KEY (EmailGroup) REFERENCES [Inspector].[EmailRecipients]([Description]);';
			END
			
			IF OBJECT_ID('Inspector.CurrentServers') IS NULL 
			BEGIN
			CREATE TABLE [Inspector].[CurrentServers]
			(
			[Servername] [Nvarchar](128) NULL,
			[IsActive] BIT,
			[ModuleConfig_Desc] VARCHAR(20),
			TableHeaderColour VARCHAR(7)
			CONSTRAINT UC_Servername UNIQUE (Servername)
			); 
			
			ALTER TABLE Inspector.CurrentServers
			ADD CONSTRAINT FK_ModuleConfig_Desc	FOREIGN KEY (ModuleConfig_Desc) REFERENCES Inspector.ModuleConfig(ModuleConfig_Desc);
			END

			IF OBJECT_ID('Inspector.EmailConfig') IS NULL
			CREATE TABLE [Inspector].[EmailConfig]
			(
			ModuleConfig_Desc VARCHAR(20),
			EmailSubject VARCHAR(100) DEFAULT NULL,
			CONSTRAINT FK_ModuleConfig_Email FOREIGN KEY (ModuleConfig_Desc) REFERENCES Inspector.ModuleConfig(ModuleConfig_Desc)
			);
			

			IF OBJECT_ID('Inspector.ModuleWarnings') IS NULL
			BEGIN
			CREATE TABLE [Inspector].[ModuleWarnings]
			(
			[WarningLevel] TINYINT NULL,
			[WarningDesc] VARCHAR(30),
			[HighlightHtmlColor] VARCHAR(7) NULL,
			[GradientLeftHtmlColor] VARCHAR(7) NULL,
			[GradientRightHtmlColor] VARCHAR(7) NULL
			);
			
			--Insert Module warning level descriptions (new feature for V1.3)
			EXEC sp_executesql N'
			INSERT INTO [Inspector].[ModuleWarnings] ([WarningLevel],[WarningDesc],[HighlightHtmlColor],[GradientLeftHtmlColor],[GradientRightHtmlColor])
			VALUES(NULL,''InspectorDefault'',NULL,NULL,NULL),(1,''Warning'',''#fc5858'',''#000000'',''#fc5858''),(2,''Advisory'',''#FAFCA4'',''#000000'',''#FAFCA4''),(3,''Informational'',''#FEFFFF'',''#000000'',''#FEFFFF'');';

			ALTER TABLE [Inspector].[ModuleWarnings] ADD CONSTRAINT [UC_WarningLevel] UNIQUE CLUSTERED 
			([WarningLevel] ASC);

			END
			ELSE
			BEGIN

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.ModuleWarnings') AND name='UC_WarningLevel')
			BEGIN
				BEGIN TRY
				ALTER TABLE [Inspector].[ModuleWarnings] ADD CONSTRAINT [UC_WarningLevel] UNIQUE CLUSTERED 
				([WarningLevel] ASC);
				END TRY 
				BEGIN CATCH 
					RAISERROR('Unable to create Unique Clustered index [UC_WarningLevel] on [Inspector].[ModuleWarnings]',0,0) 
				END CATCH

			END


			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.ModuleWarnings') AND name='HighlightHtmlColor')
			BEGIN
				ALTER TABLE [Inspector].[ModuleWarnings] ADD [HighlightHtmlColor] VARCHAR(7) NULL;

				EXEC sp_executesql N'
				UPDATE [Inspector].[ModuleWarnings] 
				SET [HighlightHtmlColor] = ''#fc5858''
				WHERE [WarningLevel] = 1;

				UPDATE [Inspector].[ModuleWarnings] 
				SET [HighlightHtmlColor] = ''#FAFCA4''
				WHERE [WarningLevel] = 2;

				UPDATE [Inspector].[ModuleWarnings] 
				SET [HighlightHtmlColor] = ''#FEFFFF''
				WHERE [WarningLevel] = 3;';
			END


			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.ModuleWarnings') AND name='GradientLeftHtmlColor')
			BEGIN
			ALTER TABLE [Inspector].[ModuleWarnings] ADD [GradientLeftHtmlColor] VARCHAR(7) NULL;

			EXEC sp_executesql N'
			UPDATE [Inspector].[ModuleWarnings] 
			SET [GradientLeftHtmlColor] = ''#000000''
			WHERE [WarningLevel] = 1;

			UPDATE [Inspector].[ModuleWarnings] 
			SET [GradientLeftHtmlColor] = ''#000000''
			WHERE [WarningLevel] = 2;

			UPDATE [Inspector].[ModuleWarnings] 
			SET [GradientLeftHtmlColor] = ''#000000''
			WHERE [WarningLevel] = 3;';

			END


			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.ModuleWarnings') AND name='GradientRightHtmlColor')
			BEGIN
			ALTER TABLE [Inspector].[ModuleWarnings] ADD [GradientRightHtmlColor] VARCHAR(7) NULL;

			EXEC sp_executesql N'
			UPDATE [Inspector].[ModuleWarnings] 
			SET [GradientRightHtmlColor] = ''#fc5858''
			WHERE [WarningLevel] = 1;

			UPDATE [Inspector].[ModuleWarnings] 
			SET [GradientRightHtmlColor] = ''#FAFCA4''
			WHERE [WarningLevel] = 2;

			UPDATE [Inspector].[ModuleWarnings] 
			SET [GradientRightHtmlColor] = ''#FEFFFF''
			WHERE [WarningLevel] = 3;';

			END

			END

			IF OBJECT_ID('Inspector.DatabaseOwnership') IS NULL
			CREATE TABLE [Inspector].[DatabaseOwnership]
			 (
			[Servername] [nvarchar](128) NOT NULL,
			[Log_Date] DATETIME NULL,
			[AGname] [nvarchar](128) NULL,
			[Database_name] [nvarchar](128) NOT NULL,
			[Owner] [nvarchar](100) NULL
			);
			
			
			IF OBJECT_ID('Inspector.BackupSizesByDay') IS NULL
			CREATE TABLE [Inspector].[BackupSizesByDay]
			(
			[Servername] [nvarchar](128) NOT NULL,
			[Log_Date] DATETIME NULL,
			[DayOfWeek] [VARCHAR](10) NULL,
			[CastedDate] [DATE] NULL,
			[TotalSizeInBytes] [BIGINT] NULL
			);
			
			IF OBJECT_ID('Inspector.DatabaseSettings') IS NULL
			CREATE TABLE [Inspector].[DatabaseSettings](
			[Servername] [nvarchar](128) NULL,
			[Log_Date] [datetime] NULL,
			[Setting] [varchar](50) NULL,
			[Description] [varchar](100) NULL,
			[Total] [int] NULL
			);
			
			IF OBJECT_ID('Inspector.ServerSettings') IS NULL
			CREATE TABLE [Inspector].[ServerSettings](
			[Servername] NVARCHAR(128) NULL,
			[Log_Date] DATETIME NULL,
			[configuration_id] INT NULL,
			[Setting] NVARCHAR(128) NULL,
			[value_in_use] INT NULL,
			[LastUpdated] DATETIME NOT NULL
			);

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.ServerSettings') AND [name] = N'CIX_Servername_Setting') 
			BEGIN 
				EXEC sp_executesql N'CREATE CLUSTERED INDEX [CIX_Servername_Setting] ON [Inspector].[ServerSettings] ([Servername],[Setting]);';
			END

			IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.ServerSettings') AND [name] = N'LastUpdated') 
			BEGIN 
				ALTER TABLE [Inspector].[ServerSettings] ADD [LastUpdated] DATETIME NULL;
			END

			EXEC sp_executesql N'
			UPDATE [Inspector].[ServerSettings] 
			SET [LastUpdated] = [Log_Date]
			WHERE [LastUpdated] IS NULL;';

			IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.ServerSettings') AND [name] = N'LastUpdated' AND is_nullable = 1)
			BEGIN
				ALTER TABLE [Inspector].[ServerSettings] ALTER COLUMN [LastUpdated] DATETIME NOT NULL;
			END

			/* On off population with IsActtive = 0*/
			EXEC sp_executesql N'
			INSERT INTO [Inspector].[ServerSettings] ([Servername], [Log_Date], [configuration_id], [Setting], [value_in_use], [LastUpdated])
			SELECT 
				@@SERVERNAME,
				GETDATE(),
				[configuration_id],
				[name],
				CAST([value_in_use] AS INT),
				GETDATE()
			FROM sys.configurations conf
			WHERE NOT EXISTS(SELECT 1 FROM [Inspector].[ServerSettings] ssc WHERE [conf].[name] = [ssc].[Setting] AND [ssc].[Servername] = @@SERVERNAME);';


			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[ServerSettingsConfig]') AND type in (N'U'))
			BEGIN
				CREATE TABLE [Inspector].[ServerSettingsConfig] (
				[Servername] NVARCHAR(128), 
				[Setting] NVARCHAR(128), 
				[value_in_use] INT, 
				[IsActive] BIT
				);
			END

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.ServerSettingsConfig') AND [name] = N'CIX_Servername_IsActive_Setting') 
			BEGIN 
				EXEC sp_executesql N'CREATE CLUSTERED INDEX [CIX_Servername_IsActive_Setting] ON [Inspector].[ServerSettingsConfig] ([Servername],[IsActive],[Setting]);';
			END

			/* On off population with IsActtive = 0*/
			EXEC sp_executesql N'
			INSERT INTO [Inspector].[ServerSettingsConfig] ([Servername],[Setting],[value_in_use],[IsActive])
			SELECT 
				@@SERVERNAME,
				[name],
				CAST([value_in_use] AS INT),
				0
			FROM sys.configurations conf
			WHERE NOT EXISTS(SELECT 1 FROM [Inspector].[ServerSettingsConfig] ssc WHERE [conf].[name] = [ssc].[Setting] AND [ssc].[Servername] = @@SERVERNAME);';

			IF NOT EXISTS(SELECT 1 FROM [Inspector].[MultiWarningModules]  WHERE [Modulename] = 'ServerSettings')
			BEGIN 
				INSERT INTO [Inspector].[MultiWarningModules] ([Modulename])
				VALUES('ServerSettings');
			END 

			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[ServerSettingsAudit]') AND type in (N'U'))
			BEGIN
			CREATE TABLE [Inspector].[ServerSettingsAudit](
				[ID] INT IDENTITY(1,1),
				[Servername] NVARCHAR(128) NULL,
				[Log_Date] DATETIME NULL,
				[configuration_id] INT NULL,
				[Setting] NVARCHAR(128) NULL,
				[old_value_in_use] INT NULL,
				[value_in_use] INT NULL,
				[AuditDate] DATETIME NULL,
				[PrevLastUpdated] DATETIME NOT NULL,
				[config_value_in_use] INT
			);
			END

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.ServerSettingsAudit') AND [name] = N'CIX_Servername_Setting_AuditDate') 
			BEGIN 
				EXEC sp_executesql N'CREATE CLUSTERED INDEX [CIX_Servername_Setting_AuditDate] ON [Inspector].[ServerSettingsAudit] ([Servername],[Setting],[AuditDate]);';
			END

			IF OBJECT_ID('Inspector.ServerInfo') IS NULL
			BEGIN 
				CREATE TABLE [Inspector].[ServerInfo] (
				Servername NVARCHAR(128),
				Log_Date DATETIME,
				cpu_count INT,
				hyperthread_count INT,
				physical_memory_gb INT,
				scheduler_count INT,
				affinity_type_desc NVARCHAR(10),
				machine_type NVARCHAR(10)
				);
			END

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.ServerInfo') AND [name] = N'CIX_ServerInfo_Servername_Log_Date') 
			BEGIN 
				EXEC sp_executesql N'CREATE UNIQUE CLUSTERED INDEX [CIX_ServerInfo_Servername_Log_Date] ON [Inspector].[ServerInfo] ([Servername],[Log_Date]);';
			END

IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[Inspector].[ServerSettingsChangeAudit]'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE TRIGGER [Inspector].[ServerSettingsChangeAudit] ON [Inspector].[ServerSettings]
AFTER UPDATE 
AS 
BEGIN 
	SET NOCOUNT ON;

	INSERT INTO [Inspector].[ServerSettingsAudit] ([Servername],[Log_Date],[configuration_id],[Setting],[old_value_in_use],[value_in_use],[AuditDate],[PrevLastUpdated],[config_value_in_use])
	SELECT 
		i.[Servername],
		i.[Log_Date],
		i.[configuration_id],
		i.[Setting],
		d.[value_in_use],
		i.[value_in_use],
		i.[LastUpdated],
		d.[LastUpdated],
		(SELECT value_in_use FROM [Inspector].[ServerSettingsConfig] ssc WHERE i.[Servername] = ssc.[Servername] AND i.[Setting] = ssc.[Setting] AND ssc.[IsActive] = 1)
	FROM inserted i 
	INNER JOIN deleted d ON i.[Servername] = d.[Servername]
							AND i.[Setting] = d.[Setting]

	AND i.value_in_use != d.value_in_use;
END 
';
END;

			IF OBJECT_ID('Inspector.InstanceStart') IS NULL
			CREATE TABLE [Inspector].[InstanceStart](
			Servername NVARCHAR(128),
			Log_Date DATETIME,
			InstanceStart DATETIME
			);


			IF OBJECT_ID('Inspector.SuspectPages') IS NULL
			CREATE TABLE [Inspector].[SuspectPages](
			[Servername] NVARCHAR(128),
			[Log_Date] DATETIME,
			[Databasename] NVARCHAR(128),
			[file_id] INT,
			[page_id] BIGINT,	
			[event_type] INT,
			[error_count] INT,
			[last_update_date] DATETIME
			);
			
			IF OBJECT_ID('Inspector.AGDatabases') IS NULL
			CREATE TABLE [Inspector].[AGDatabases](
			[ID] INT IDENTITY(1,1),
			[Servername] NVARCHAR(128) NULL,
			[Log_Date] DATETIME NULL,
			[LastUpdated] DATETIME NULL,
			[Databasename] NVARCHAR(128) NULL,
			[Is_AG] BIT NULL,
			[Is_AGJoined] BIT NULL
			);

			IF OBJECT_ID('Inspector.InstanceVersion') IS NULL
			CREATE TABLE [Inspector].[InstanceVersion](
			Servername NVARCHAR(128),
			PhysicalServername NVARCHAR(128),
			Log_Date DATETIME,
			VersionInfo NVARCHAR(128)
			);
			
			IF OBJECT_ID('Inspector.LongRunningTransactions') IS NULL
			CREATE TABLE [Inspector].[LongRunningTransactions](
			[Servername] NVARCHAR(128) NULL,
			[Log_Date] DATETIME NULL,
			[session_id] INT NULL,
			[transaction_begin_time] DATETIME NULL,
			[Duration_DDHHMMSS] VARCHAR(20) NULL,
			[TransactionState] VARCHAR(20) NULL,
			[SessionState] NVARCHAR(20) NULL,
			[login_name] NVARCHAR(128) NULL,
			[host_name] NVARCHAR(128) NULL,
			[program_name] NVARCHAR(128) NULL,
			[Databasename] NVARCHAR(128) NULL,
			[Querytext] NVARCHAR(MAX) NULL
			);

			IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.LongRunningTransactions') AND name = 'Querytext')
			BEGIN 
				ALTER TABLE [Inspector].[LongRunningTransactions] ADD [Querytext] NVARCHAR(MAX) NULL;
			END

			IF OBJECT_ID('Inspector.LongRunningTransactionsHistory') IS NULL
			BEGIN 
				CREATE TABLE [Inspector].[LongRunningTransactionsHistory](
				[ID] INT IDENTITY(1,1),
				[Servername] NVARCHAR(128) NULL,
				[Log_Date] DATETIME NULL,
				[session_id] INT NULL,
				[transaction_begin_time] DATETIME NULL,
				[Duration_DDHHMMSS] VARCHAR(20) NULL,
				[TransactionState] VARCHAR(20) NULL,
				[SessionState] NVARCHAR(20) NULL,
				[login_name] NVARCHAR(128) NULL,
				[host_name] NVARCHAR(128) NULL,
				[program_name] NVARCHAR(128) NULL,
				[Databasename] NVARCHAR(128) NULL,
				[Querytext] NVARCHAR(MAX) NULL
				);

				EXEC sp_executesql N'CREATE UNIQUE CLUSTERED INDEX [CIX_ID] ON [Inspector].[LongRunningTransactionsHistory] ([ID] ASC);';
				EXEC sp_executesql N'CREATE NONCLUSTERED INDEX [CIX_Log_Date_Servername] ON [Inspector].[LongRunningTransactionsHistory] ([Log_Date] ASC,[Servername] ASC);';
			END

			IF NOT EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'LongRunningTransactionsHistoryRetentionDays')
			BEGIN 
				INSERT INTO [Inspector].[Settings] ([Description], [Value])
				VALUES('LongRunningTransactionsHistoryRetentionDays','7');
			END 

			IF OBJECT_ID('Inspector.InstanceVersionHistory') IS NULL
			CREATE TABLE [Inspector].[InstanceVersionHistory](
			[Servername] NVARCHAR(128) NOT NULL,
			[Log_Date] DATETIME NOT NULL,
			[CollectionDatetime] DATETIME NOT NULL,
			[VersionNo] NVARCHAR(128) NULL,
			[Edition] NVARCHAR(128) NULL
			);

			--Extend the length of the VersionNo column to NVARCHAR(128) to accomodate additionally logged information #93
			IF (SELECT max_length FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.InstanceVersionHistory') AND name = 'VersionNo') < 256
			BEGIN 
				ALTER TABLE [Inspector].[InstanceVersionHistory] ALTER COLUMN [VersionNo] NVARCHAR(128);
			END

			IF OBJECT_ID('Inspector.UnusedLogshipConfig') IS NULL
			CREATE TABLE [Inspector].[UnusedLogshipConfig] (
			Servername NVARCHAR(128),
			Log_Date DATETIME,
			Databasename NVARCHAR(128),
			Databasestate NVARCHAR(128)
			);

			IF OBJECT_ID('Inspector.ExecutionLog') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[ExecutionLog](
				[ID] INT IDENTITY(1,1),
				[ExecutionDate] DATETIME NOT NULL,
				[Servername] NVARCHAR(128) NOT NULL,
				[ModuleConfig_Desc] VARCHAR(20) NOT NULL,
				[Procname] NVARCHAR(128) NOT NULL,
				[Frequency] SMALLINT NULL,
				[Duration] MONEY,
				[PSCollection] BIT NOT NULL,
				[ErrorMessage] NVARCHAR(128) NULL
				); 

				CREATE CLUSTERED INDEX [CIX_ExecutionLog_ID] ON [Inspector].[ExecutionLog]
				([ID] ASC);
			END

			IF NOT EXISTS(SELECT 1 
							FROM sys.tables 
							INNER JOIN sys.columns ON tables.object_id = columns.object_id 
							WHERE tables.schema_id = SCHEMA_ID(N'Inspector')
							AND tables.name = N'ExecutionLog'
							AND columns.name = N'Frequency')
			BEGIN 
				ALTER TABLE [Inspector].[ExecutionLog] ADD [Frequency] SMALLINT NULL;
			END

			IF NOT EXISTS(SELECT 1 
							FROM sys.tables 
							INNER JOIN sys.columns ON tables.object_id = columns.object_id 
							WHERE tables.schema_id = SCHEMA_ID(N'Inspector')
							AND tables.name = N'ExecutionLog'
							AND columns.name = N'ErrorMessage')
			BEGIN 
				ALTER TABLE [Inspector].[ExecutionLog] ADD [ErrorMessage] NVARCHAR(128) NULL;
			END

			IF OBJECT_ID('Inspector.CatalogueSIDExclusions') IS NULL
			BEGIN 
				CREATE TABLE [Inspector].[CatalogueSIDExclusions] (
				AGName NVARCHAR(128),
				LoginName NVARCHAR(128)
				);
			END


			IF OBJECT_ID('Inspector.BackupsCheckExcludes') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[BackupsCheckExcludes] (
				Servername NVARCHAR(128) NOT NULL,
				Databasename NVARCHAR(128) NOT NULL,
				SuppressUntil DATETIME NULL
				);

				CREATE CLUSTERED INDEX [CIX_Servername_Databasename] ON [Inspector].[BackupsCheckExcludes]
				([Servername] ASC,[Databasename] ASC);
			END
			
			
			IF OBJECT_ID('Inspector.AGPrimaryHistory') IS NULL
			BEGIN			
				CREATE TABLE [Inspector].[AGPrimaryHistory](
				[Log_Date] DATETIME NULL,
				[CollectionDateTime] DATETIME NULL,
				[Servername] NVARCHAR(128) NULL,
				[AGname] NVARCHAR(128) NULL
				);		
			END
			
			IF OBJECT_ID('Inspector.DriveSpaceCalc') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[DriveSpaceCalc] (
				[Servername] NVARCHAR(128) NOT NULL,
				[Drive] NVARCHAR(128) NOT NULL,
				[MedianCalc] BIT NOT NULL
				);
			END

			IF OBJECT_ID('Inspector.BackupSpace') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[BackupSpace](
				[Servername] [nvarchar](128) NOT NULL,
				[Log_Date] [datetime] NULL,
				[DayOfWeek] [varchar](10) NULL,
				[CastedDate] [date] NULL,
				[BackupPath] [varchar](256) NULL,
				[TotalSizeInBytes] [bigint] NULL
				);
			END

			IF OBJECT_ID('Inspector.DefaultHeaderText') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[DefaultHeaderText](
					[Modulename] [varchar](128) NOT NULL,
					[HeaderText] [varchar](100) NOT NULL
				);

				--Populate the default text
				EXEC sp_executesql N'
				IF NOT EXISTS (SELECT 1 FROM [Inspector].[DefaultHeaderText]) 
				BEGIN 
					INSERT INTO [Inspector].[DefaultHeaderText] ([Modulename], [HeaderText])
					VALUES(''ADHocDatabaseCreations'',''Potential ADhoc database creations''),
					(''AGCheck'',''AG Warnings''),
					(''AGDatabases'',''Databases not joined to an Availability group''),
					(''BackupsCheck '',''Database Backup issues''),
					(''BackupSpace'',''Backup space issues''),
					(''CatalogueDroppedDatabases'',''Dropped databases''),
					(''CatalogueDroppedTables'',''Dropped tables''),
					(''CatalogueMissingLogins'',''Missing Logins''),
					(''DatabaseFiles'',''Database files on incorrect drives''),
					(''DatabaseGrowths'',''Database Growths in the last 24 hours exceeding thresholds''),
					(''DatabaseOwnership'',''Database ownerships not set to your preferred owner''),
					(''DatabaseSettings'',''Database Auto Close or Auto Shrink settings enabled or Auto Update Stats Disabled''),
					(''DatabaseStates'',''Database state warnings''),
					(''DriveSpace'',''Drive space thresholds breached''),
					(''FailedAgentJobs'',''Failed agent jobs''),
					(''LoginAttempts'',''Failed logins''),
					(''JobOwner'',''Agent jobs not set to your preferred owner''),
					(''LongRunningTransactions'',''Long running transactions exceeding your threshold''),
					(''ServerSettings'',''Server settings changed or differ from your config values''),
					(''SuspectPages'',''Suspect database pages found''),
					(''UnusedLogshipConfig'',''Unused log shipping config found''),
					(''DatacollectionsOverdue'',''Data collection duration exceeded module schedules'');
				END';
				
				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'CIX_DefaultHeaderText_Modulename' AND [object_id] = OBJECT_ID(N'Inspector.DefaultHeaderText'))
				BEGIN 
					EXEC sp_executesql N'CREATE UNIQUE CLUSTERED INDEX [CIX_DefaultHeaderText_Modulename] ON [Inspector].[DefaultHeaderText]
					([Modulename] ASC);';
				END
			END

 
			EXEC sp_executesql N'
			UPDATE [Inspector].[DefaultHeaderText]
			SET [HeaderText] = ''Server settings changed or differ from your config values''
			WHERE [Modulename] = ''ServerSettings''
			AND [HeaderText] = ''Cost Threshold for parallelism, MAXDOP or Max Server memory set to default values'';';
 
 			EXEC sp_executesql N'
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[DefaultHeaderText] WHERE [Modulename] = ''DriveSpace'') 
			BEGIN 
				INSERT INTO [Inspector].[DefaultHeaderText]([Modulename], [HeaderText])
				VALUES(''DriveSpace'',''Drive space thresholds breached'');
			END';

			IF OBJECT_ID('Inspector.DatacollectionsOverdue') IS NULL 
			BEGIN
				CREATE TABLE [Inspector].[DatacollectionsOverdue] (
				[ExecutionLogID] INT,
				[Servername] NVARCHAR(128), 
				[Log_Date] DATETIME,
				[ModuleConfig_Desc] VARCHAR(20), 
				[Procname] NVARCHAR(128), 
				[DurationInSeconds] INT, 
				[ExecutionDate] DATETIME, 
				[PreviousRunDateTime] DATETIME, 
				[RunNumber] INT, 
				[FrequencyInSeconds] INT, 
				[Variance] INT,
				[PSCollection] BIT
				);
			END


			IF NOT EXISTS (SELECT * FROM sys.tables WHERE [name] = N'ReportsDueCache' AND [schema_id] = SCHEMA_ID(N'Inspector'))
			BEGIN 
				CREATE TABLE [Inspector].[ReportsDueCache] (
				[ID] UNIQUEIDENTIFIER NOT NULL,
				[ModuleConfig_Desc] VARCHAR(20) NOT NULL,
				[CurrentScheduleStart] DATETIME NOT NULL,
				[ReportWarningsOnly] TINYINT NOT NULL,
				[NoClutter] BIT NOT NULL,
				[Frequency] SMALLINT NOT NULL,
				[EmailGroup] VARCHAR(50) NULL,
				[EmailProfile] VARCHAR(128) NULL,
				[EmailAsAttachment] BIT NULL
				);
			END
			
			IF NOT EXISTS (SELECT 1 FROM sys.tables INNER JOIN sys.indexes ON indexes.[object_id] = tables .[object_id] WHERE tables.[name] = N'ReportsDueCache' AND indexes.[name] = N'CIX_ID' AND SCHEMA_NAME(tables.[schema_id]) = N'Inspector')
			BEGIN 
				CREATE CLUSTERED INDEX [CIX_ID] ON [Inspector].[ReportsDueCache] (ID ASC);
			END

			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'EmailAsAttachment' AND [object_id] = OBJECT_ID(N'Inspector.ReportsDueCache'))
			BEGIN
				ALTER TABLE [Inspector].[ReportsDueCache] ADD [EmailAsAttachment] BIT NULL;
			END

			IF NOT EXISTS (SELECT * FROM sys.tables WHERE [name] = N'ExecutionLogLastTruncate' AND [schema_id] = SCHEMA_ID(N'Inspector'))
			BEGIN
				CREATE TABLE [Inspector].[ExecutionLogLastTruncate] (
				LastTruncate DATE NOT NULL
				);
			END

			IF NOT EXISTS (SELECT 1 FROM [Inspector].[ExecutionLogLastTruncate])
			BEGIN 
				EXEC sp_executesql N'INSERT INTO [Inspector].[ExecutionLogLastTruncate] (LastTruncate)
				VALUES(CAST(GETDATE() AS DATE));';
			END


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


			IF OBJECT_ID('Inspector.ServerSettingThresholds',N'U') IS NULL 
			BEGIN 
				CREATE TABLE [Inspector].[ServerSettingThresholds] (
				ID INT IDENTITY(1,1),
				Servername NVARCHAR(128) NOT NULL,
				Modulename VARCHAR(50) NOT NULL,
				ThresholdName VARCHAR(100) NOT NULL,
				ThresholdInt INT NULL,
				ThresholdString VARCHAR(255) NULL,
				IsActive BIT NOT NULL
				);

				EXEC sp_executesql N'CREATE UNIQUE CLUSTERED INDEX [ServerSettingThresholds_Servername_Modulename] ON [Inspector].[ServerSettingThresholds] ([Servername],[Modulename],[ThresholdName]);';
			END

			IF OBJECT_ID('Inspector.DriveSpaceThresholds',N'U') IS NULL 
			BEGIN 
				CREATE TABLE [Inspector].[DriveSpaceThresholds](
					[Servername] NVARCHAR(128) NULL,
					[Drive] NVARCHAR(128) NULL,
					[FreeSpaceRemainingPercent] DECIMAL(5,2) NULL,
					[MinAvailableSpace_GB] INT NULL,
					[DaysUntilDriveFull] INT NULL
				);
				
				EXEC sp_executesql N'CREATE UNIQUE CLUSTERED INDEX [DriveSpaceThresholds_Servername_Drive] ON [Inspector].[DriveSpaceThresholds] ([Servername],[Drive]);';
			END

			IF OBJECT_ID('Inspector.TempDB',N'U') IS NULL 
			BEGIN
				CREATE TABLE [Inspector].[TempDB] (
					Servername NVARCHAR(128) NOT NULL,
					Log_Date DATETIME NOT NULL,
					DatabaseFilename NVARCHAR(256) NOT NULL,
					Reserved_MB DECIMAL(18,2) NOT NULL,
					Unallocated_MB DECIMAL(18,2) NOT NULL,
					Internal_object_reserved_MB DECIMAL(18,2) NOT NULL,
					User_object_reserved_MB DECIMAL(18,2) NOT NULL,
					Version_store_reserved_MB DECIMAL(18,2) NOT NULL,
					UsedPct DECIMAL(10,2) NOT NULL,
					OldestTransactionSessionId INT NULL,
					OldestTransactionDurationMins DECIMAL(18,2) NULL,
					TransactionStartTime DATETIME NULL,
					DateHour AS DATEPART(HOUR,Log_Date)
				);

				EXEC sp_executesql N'CREATE CLUSTERED INDEX [CIX_TempDB_Servername_Log_Date] ON [Inspector].[TempDB] ([Servername] ASC,[Log_Date] ASC,[DateHour] ASC);';
			END

			IF NOT EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'TempDBDataRetentionDays')
			BEGIN 
				INSERT INTO [Inspector].[Settings] ([Description], [Value])
				VALUES('TempDBDataRetentionDays','7');
			END 
			
			IF NOT EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'TempDBPercentUsed')
			BEGIN 
				INSERT INTO [Inspector].[Settings] ([Description], [Value])
				VALUES('TempDBPercentUsed','75');
			END 
			
			IF NOT EXISTS(SELECT 1 FROM [Inspector].[Modules] WHERE [Modulename] = 'TempDB')
			BEGIN 
				INSERT INTO [Inspector].[Modules] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [WarningLevel], [ServerSpecific], [Debug], [IsActive], [HeaderText], [Frequency], [StartTime], [EndTime], [LastRunDateTime])
				VALUES('Default','TempDB','TempDBInsert','TempDBReport',22,2,1,0,1,NULL,5,@StartTime,@EndTime,NULL);
			END 
			
			IF NOT EXISTS(SELECT 1 FROM [Inspector].[DefaultHeaderText] WHERE [Modulename] = 'TempDB')
			BEGIN 
				INSERT INTO [Inspector].[DefaultHeaderText] ([Modulename], [HeaderText])
				VALUES('TempDB','TempDB file usage higher than your threshold');
			END


		    IF OBJECT_ID('Inspector.PSConfig') IS NULL 
			BEGIN
				CREATE TABLE [Inspector].[PSConfig](
					[Servername] NVARCHAR(128) NOT NULL,
					[ModuleConfig_Desc] VARCHAR(20) NOT NULL,
					[Modulename] VARCHAR(50) NOT NULL,
					[Procedurename] NVARCHAR(128) NULL,
					[Tablename] NVARCHAR(128) NULL,
					[StageTablename] NVARCHAR(256) NULL,
					[StageProcname] NVARCHAR(256) NULL,
					[TableAction] VARCHAR(3) NOT NULL,
					[TableAction_Desc] AS CAST(REPLACE(REPLACE(REPLACE([TableAction],'1','Delete All'),'2','Delete with retention'),'3','Stage/Merge') AS VARCHAR(50)),
					[InsertAction] VARCHAR(3) NOT NULL,
					[InsertAction_Desc] AS CAST(REPLACE(REPLACE(REPLACE([InsertAction],'1','All data'),'2','Todays data only'),'3','Frequency based') AS VARCHAR(50)),
					[RetentionInDays] VARCHAR(7) NULL,
					[IsActive] BIT NOT NULL
				);
			END

			--V2.1 Change computed column definition
			IF NOT EXISTS (SELECT * FROM sys.computed_columns WHERE [object_id] = OBJECT_ID('Inspector.PSConfig') AND [name] = N'InsertAction_Desc' AND [definition] LIKE '%Frequency based%')
			BEGIN 
				ALTER TABLE [Inspector].[PSConfig] DROP COLUMN [InsertAction_Desc];
			END 
			
			IF NOT EXISTS (SELECT * FROM sys.computed_columns WHERE [object_id] = OBJECT_ID('Inspector.PSConfig') AND [name] = N'InsertAction_Desc')
			BEGIN 
				ALTER TABLE [Inspector].[PSConfig] ADD [InsertAction_Desc] AS CAST(REPLACE(REPLACE(REPLACE([InsertAction],'1','All data'),'2','Todays data only'),'3','Frequency based') AS VARCHAR(50));
			END 

			--Insert new settings for V1.2
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'LongRunningTransactionThreshold')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value]) 
				VALUES ('LongRunningTransactionThreshold',CAST(@LongRunningTransactionThreshold AS VARCHAR(8)));
			END

			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'ReportDataRetention')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value]) 
				VALUES ('ReportDataRetention','30');
			END

			--New setting for V1.4
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'DataDrives')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value]) 
				VALUES ('DataDrives',@DataDrive);
			END

			--New setting for V1.4
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'LogDrives')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value]) 
				VALUES ('LogDrives',@LogDrive);
			END

			--New setting for V1.4
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'InspectorUpgradeFilenameSync')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value]) 
				VALUES ('InspectorUpgradeFilenameSync',1);
			END

			--New Setting for 1.2 - Powershell banner.
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'PSEmailBannerURL')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES ('PSEmailBannerURL','http://bit.ly/PSInspectorEmailBanner');
			END

			--New URL for standard email banner
			IF (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = 'EmailBannerURL') = 'https://i2.wp.com/sqlundercover.files.wordpress.com/2017/11/inspector_whitehandle.png?ssl=1&w=450'
			BEGIN
				UPDATE [Inspector].[Settings] 
				SET [Value] = 'http://bit.ly/InspectorEmailBanner'
				WHERE [Description] = 'EmailBannerURL';
			END
			
			--New Setting for V1.4
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'AGPrimaryHistoryRetentionPeriodInDays')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES ('AGPrimaryHistoryRetentionPeriodInDays','90');
			END
			ELSE 
			BEGIN
				UPDATE [Inspector].[Settings] 
				SET [Value] = '90'
				WHERE [Description] = 'AGPrimaryHistoryRetentionPeriodInDays';
			END	
			
			--New Setting for V2.00
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'ReportDataDetailedSummary')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES ('ReportDataDetailedSummary','1');
			END

			--New setting for V2.01
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'BackupSpaceWeekdayOffset')
			BEGIN 
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES('BackupSpaceWeekdayOffset','1');
			END 

			--New settings for V2.1
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'PSAutoUpdateModules')
			BEGIN 
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES('PSAutoUpdateModules','1');
			END 
			
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'PSAutoUpdateModulesFrequencyMins')
			BEGIN 
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES('PSAutoUpdateModulesFrequencyMins','1440');
			END 

			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'DatabaseGrowthRetentionPeriodInDays')
			BEGIN 
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES('DatabaseGrowthRetentionPeriodInDays',180);
			END 
			
			--Update email banner for V2
			IF (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = 'EmailBannerURL') = 'http://bit.ly/InspectorEmailBanner'
			BEGIN
				UPDATE [Inspector].[Settings] 
				SET [Value] = 'http://bit.ly/InspectorV2'
				WHERE [Description] = 'EmailBannerURL';
			END
			
			--Remove linked server settings #277 V2.6
			IF EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'CentraliseExecutionLog')
			BEGIN 
				DELETE FROM [Inspector].[Settings]
				WHERE [Description] = 'CentraliseExecutionLog';
			END 

			IF EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'LinkedServername')
			BEGIN 
				DELETE FROM [Inspector].[Settings]
				WHERE [Description] = 'LinkedServername';
			END 

			IF (EXISTS(SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'DiffBackupThreshold') AND @CurrentBuild < 2.6)
			BEGIN 
				RAISERROR('Updating your diff threshold from days to hours if required',0,0) WITH NOWAIT;

				UPDATE [Inspector].[Settings]
				SET [Value] = [Value]*24
				WHERE [Description] = 'DiffBackupThreshold'
				AND [Value] IS NOT NULL;

			END
			

--Populate config
IF @InitialSetup = 1 
BEGIN
--Truncate tables - Settings,Modules,EmailConfig,ModuleWarnings,ModuleWarningLevel,EmailRecipients,CatalogueModules
EXEC sp_executesql N'
TRUNCATE TABLE [Inspector].[Settings];
TRUNCATE TABLE [Inspector].[EmailConfig];
TRUNCATE TABLE [Inspector].[ModuleWarnings];
TRUNCATE TABLE [Inspector].[ModuleWarningLevel];
UPDATE [Inspector].[ModuleConfig] SET [EmailGroup] = NULL WHERE [EmailGroup] IS NOT NULL;
UPDATE [Inspector].[ModuleConfig] SET [EmailProfile] = NULL WHERE [EmailProfile] IS NOT NULL;
DELETE FROM [Inspector].[EmailRecipients];
TRUNCATE TABLE [Inspector].[CatalogueModules];
TRUNCATE TABLE [Inspector].[DefaultHeaderText];
TRUNCATE TABLE [Inspector].[ServerSettingThresholds];';

UPDATE [Inspector].[CurrentServers]
SET ModuleConfig_Desc = NULL
WHERE ModuleConfig_Desc IS NOT NULL;

DELETE FROM [Inspector].[Modules];
DBCC CHECKIDENT ('Inspector.Modules', RESEED, 0) WITH NO_INFOMSGS;

DELETE FROM [Inspector].[ModuleConfig];
DBCC CHECKIDENT ('Inspector.ModuleConfig', RESEED, 0) WITH NO_INFOMSGS;
 
--Insert Settings into Inspector Base tables  
EXEC sp_executesql N'
INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES  (''SQLUndercoverInspectorEmailSubject'',@StackNameForEmailSubject),
		(''DriveSpaceRetentionPeriodInDays'',@DriveSpaceHistoryRetentionInDays),
		(''DatabaseGrowthRetentionPeriodInDays'',''180''),
		(''AGPrimaryHistoryRetentionPeriodInDays'',''90''),
		(''FullBackupThreshold'',@FullBackupThreshold),
		(''DiffBackupThreshold'',@DiffBackupThreshold),
		(''LogBackupThreshold'' ,@LogBackupThreshold),
		(''DaysUntilDriveFullThreshold'' ,@DaysUntilDriveFullThreshold),
		(''FreeSpaceRemainingPercent'',@FreeSpaceRemainingPercent),
		(''DatabaseGrowthsAllowedPerDay'',@DatabaseGrowthsAllowedPerDay),
		(''MAXDatabaseGrowthsAllowedPerDay'',@MAXDatabaseGrowthsAllowedPerDay),
		(''LongRunningTransactionThreshold'',@LongRunningTransactionThreshold),
		(''ReportDataRetention'',''30''),
		(''BackupsPath'',@BackupsPath),
		(''EmailBannerURL'',''http://bit.ly/InspectorV2''),
		(''PSEmailBannerURL'',''http://bit.ly/PSInspectorEmailBanner''),
		(''DatabaseOwnerExclusions'',@DatabaseOwnerExclusions),
		(''AgentJobOwnerExclusions'',@AgentJobOwnerExclusions),
		(''InspectorBuild'',@Build),
		(''DriveSpaceDriveLetterExcludes'',@DriveLetterExcludes),
		(''DataDrives'',@DataDrive),
		(''LogDrives'',@LogDrive),
		(''InspectorUpgradeFilenameSync'',''1''),
		(''UseMedianCalculationForDriveSpaceCalc'',''0''),
		(''ReportDataDetailedSummary'',''1''),
		(''CentraliseExecutionLog'',''0''),
		(''BackupSpaceWeekdayOffset'',''1''),
		(''TempDBDataRetentionDays'',''7''),
		(''TempDBPercentUsed'',''75''),
		(''LongRunningTransactionsHistoryRetentionDays'',''7'');
		
IF NOT EXISTS (SELECT 1 FROM [Inspector].[ModuleConfig])
BEGIN 
	INSERT INTO [Inspector].[ModuleConfig] ([ModuleConfig_Desc], [IsActive],[Frequency], [StartTime], [EndTime], [ReportWarningsOnly], [RunDay], [NoClutter],[ShowDisabledModules])
	VALUES(''Default'',1,1440,''09:00'',''17:30'',0,''Monday,Tuesday,Wednesday,Thursday,Friday'',0,1),
	(''PeriodicBackupCheck'',1,120,''11:00'',''17:30'',1,''Monday,Tuesday,Wednesday,Thursday,Friday'',1,1);
END

INSERT INTO [Inspector].[Modules] ([ModuleConfig_Desc], [Modulename], [CollectionProcedurename], [ReportProcedurename], [ReportOrder], [IsActive], [Debug], [ServerSpecific], [WarningLevel], [HeaderText], [Frequency], [StartTime], [EndTime])
VALUES(''Default'',''ADHocDatabaseCreations'',''ADHocDatabaseCreationsInsert'',''ADHocDatabaseCreationsReport'',1,1,0,1,2,NULL,1440,@StartTime,@EndTime),
(''Default'',''AGCheck'',''AGCheckInsert'',''AGCheckReport'',2,1,0,1,1,NULL,1440,@StartTime,@EndTime),
(''Default'',''AGDatabases'',''AGDatabasesInsert'',''AGDatabasesReport'',3,1,0,1,2,NULL,1440,@StartTime,@EndTime),
(''Default'',''BackupsCheck'',''BackupsCheckInsert'',''BackupsCheckReport'',4,1,0,1,1,NULL,1440,@StartTime,@EndTime),
(''Default'',''BackupSizesByDay'',''BackupSizesByDayInsert'',''BackupSizesByDayReport'',5,1,0,1,3,NULL,1440,@StartTime,@EndTime),
(''Default'',''BackupSpace'',''BackupSpaceInsert'',''BackupSpaceReport'',6,1,0,0,1,NULL,1440,@StartTime,@EndTime),
(''Default'',''DatabaseFiles'',''DatabaseFilesInsert'',''DatabaseFilesReport'',7,1,0,1,2,NULL,1440,@StartTime,@EndTime),
(''Default'',''DatabaseGrowths'',''DatabaseGrowthsInsert'',''DatabaseGrowthsReport'',8,1,0,0,2,NULL,1440,@StartTime,@EndTime),
(''Default'',''DatabaseOwnership'',''DatabaseOwnershipInsert'',''DatabaseOwnershipReport'',9,1,0,1,3,NULL,1440,@StartTime,@EndTime),
(''Default'',''DatabaseSettings'',''DatabaseSettingsInsert'',''DatabaseSettingsReport'',10,1,0,1,3,NULL,1440,@StartTime,@EndTime),
(''Default'',''DatabaseStates'',''DatabaseStatesInsert'',''DatabaseStatesReport'',11,1,0,1,2,NULL,1440,@StartTime,@EndTime),
(''Default'',''DriveSpace'',''DriveSpaceInsert'',''DriveSpaceReport'',1,1,0,1,1,NULL,1440,@StartTime,@EndTime),
(''Default'',''FailedAgentJobs'',''FailedAgentJobsInsert'',''FailedAgentJobsReport'',13,1,0,1,2,NULL,1440,@StartTime,@EndTime),
(''Default'',''JobOwner'',''JobOwnerInsert'',''JobOwnerReport'',15,1,0,1,3,NULL,1440,@StartTime,@EndTime),
(''Default'',''LoginAttempts'',''LoginAttemptsInsert'',''LoginAttemptsReport'',14,1,0,1,2,NULL,1440,@StartTime,@EndTime),
(''Default'',''LongRunningTransactions'',''LongRunningTransactionsInsert'',''LongRunningTransactionsReport'',16,1,0,1,3,NULL,1440,@StartTime,@EndTime),
(''Default'',''ServerSettings'',''ServerSettingsInsert'',''ServerSettingsReport'',17,1,0,1,2,NULL,1440,@StartTime,@EndTime),
(''Default'',''SuspectPages'',''SuspectPagesInsert'',''SuspectPagesReport'',1,1,0,1,1,NULL,1440,@StartTime,@EndTime),
(''Default'',''TopFiveDatabases'',''TopFiveDatabasesInsert'',''TopFiveDatabasesReport'',19,1,0,1,3,NULL,1440,@StartTime,@EndTime),
(''Default'',''UnusedLogshipConfig'',''UnusedLogshipConfigInsert'',''UnusedLogshipConfigReport'',20,1,0,1,3,NULL,1440,@StartTime,@EndTime),
(''Default'',''DatacollectionsOverdue'',''DatacollectionsOverdueInsert'',''DatacollectionsOverdueReport'',21,1,0,0,1,NULL,1440,@StartTime,@EndTime),
(''Default'',''TempDB'',''TempDBInsert'',''TempDBReport'',22,2,1,0,1,NULL,5,@StartTime,@EndTime),
(''PeriodicBackupCheck'',''BackupsCheck'',''BackupsCheckInsert'',''BackupsCheckReport'',1,1,0,1,1,NULL,120,DATEADD(HOUR,2,@StartTime),@EndTime);

INSERT INTO [Inspector].[DefaultHeaderText] ([Modulename], [HeaderText])
VALUES(''ADHocDatabaseCreations'',''Potential ADhoc database creations''),
(''AGCheck'',''AG Warnings''),
(''AGDatabases'',''Databases not joined to an Availability group''),
(''BackupsCheck '',''Database Backup issues''),
(''BackupSpace'',''Backup space issues''),
(''CatalogueDroppedDatabases'',''Dropped databases''),
(''CatalogueDroppedTables'',''Dropped tables''),
(''CatalogueMissingLogins'',''Missing Logins''),
(''DatabaseFiles'',''Database files on incorrect drives''),
(''DatabaseGrowths'',''Database Growths in the last 24 hours exceeding thresholds''),
(''DatabaseOwnership'',''Database ownerships not set to your preferred owner''),
(''DatabaseSettings'',''Database Auto Close or Auto Shrink settings enabled or Auto Update Stats Disabled''),
(''DatabaseStates'',''Database state warnings''),
(''FailedAgentJobs'',''Failed agent jobs''),
(''LoginAttempts'',''Failed logins''),
(''JobOwner'',''Agent jobs not set to your preferred owner''),
(''LongRunningTransactions'',''Long running transactions exceeding your threshold''),
(''ServerSettings'',''Cost Threshold for parallelism, MAXDOP or Max Server memory set to default values''),
(''SuspectPages'',''Suspect database pages found''),
(''UnusedLogshipConfig'',''Unused log shipping config found''),
(''TempDB'',''TempDB file usage higher than your threshold'');

INSERT INTO [Inspector].[EmailConfig] (ModuleConfig_Desc,EmailSubject)
VALUES (''Default'',''SQLUndercover Inspector check ''),(''PeriodicBackupCheck'',''SQLUndercover Backups Report'');

INSERT INTO [Inspector].[ModuleWarnings] ([WarningLevel],[WarningDesc])
VALUES(NULL,''InspectorDefault''),(1,''Red''),(2,''Yellow''),(3,''Information (white)'');',
N'@StackNameForEmailSubject VARCHAR(255),
@EmailRecipientList VARCHAR(1000),
@DriveSpaceHistoryRetentionInDays VARCHAR(6),
@FullBackupThreshold VARCHAR(3),
@DiffBackupThreshold VARCHAR(3),
@LogBackupThreshold VARCHAR(6),
@DaysUntilDriveFullThreshold VARCHAR(4),
@FreeSpaceRemainingPercent VARCHAR(3),
@DatabaseGrowthsAllowedPerDay VARCHAR(5),
@MAXDatabaseGrowthsAllowedPerDay VARCHAR(5),
@LongRunningTransactionThreshold VARCHAR(8),
@BackupsPath VARCHAR(255),
@DatabaseOwnerExclusions VARCHAR(255),
@AgentJobOwnerExclusions VARCHAR(255),
@DriveLetterExcludes VARCHAR(10),
@DataDrive VARCHAR(50),
@LogDrive VARCHAR(50),
@Build VARCHAR(6),
@StartTime TIME(0),
@EndTime TIME(0)',
@StackNameForEmailSubject = @StackNameForEmailSubject,
@EmailRecipientList = @EmailRecipientList,
@DriveSpaceHistoryRetentionInDays = @DriveSpaceHistoryRetentionInDays,
@FullBackupThreshold = @FullBackupThreshold,
@DiffBackupThreshold = @DiffBackupThreshold,
@LogBackupThreshold = @LogBackupThreshold,
@DaysUntilDriveFullThreshold = @DaysUntilDriveFullThreshold,
@FreeSpaceRemainingPercent = @FreeSpaceRemainingPercent,
@DatabaseGrowthsAllowedPerDay = @DatabaseGrowthsAllowedPerDay,
@MAXDatabaseGrowthsAllowedPerDay = @MAXDatabaseGrowthsAllowedPerDay,
@LongRunningTransactionThreshold = @LongRunningTransactionThreshold,
@BackupsPath = @BackupsPath,
@DatabaseOwnerExclusions = @DatabaseOwnerExclusions,
@AgentJobOwnerExclusions = @AgentJobOwnerExclusions,
@DriveLetterExcludes = @DriveLetterExcludes,
@DataDrive = @DataDrive,
@LogDrive = @LogDrive,
@Build = @Build,
@StartTime = @StartTime,
@EndTime = @EndTime;



SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 
INSERT INTO [Inspector].[CurrentServers] (Servername,IsActive,ModuleConfig_Desc)
SELECT DISTINCT replica_server_name,0,NULL
FROM sys.dm_hadr_availability_replica_cluster_nodes AGServers
WHERE NOT EXISTS (SELECT Servername FROM [Inspector].[CurrentServers] WHERE Servername COLLATE DATABASE_DEFAULT = AGServers.replica_server_name)
END 
ELSE 
BEGIN 
INSERT INTO [Inspector].[CurrentServers] (Servername,IsActive,ModuleConfig_Desc)
SELECT @@SERVERNAME,1,NULL
WHERE NOT EXISTS (SELECT Servername FROM [Inspector].[CurrentServers] WHERE Servername = @@Servername)
END
'

EXEC(@SQLStatement);


IF @EmailRecipientList IS NULL 
BEGIN
	EXEC sp_executesql N'
	INSERT INTO [Inspector].[EmailRecipients] (Description)
	VALUES (''DBA'');';
END
ELSE 
BEGIN
	EXEC sp_executesql N'
	INSERT INTO [Inspector].[EmailRecipients] (Description,Recipients)
	VALUES (''DBA'',@EmailRecipientList);',N'@EmailRecipientList VARCHAR(1000)',@EmailRecipientList = @EmailRecipientList;
END

END

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[GetIntervals]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	BEGIN
	EXECUTE dbo.sp_executesql @statement = N'CREATE FUNCTION [Inspector].[GetIntervals](@top AS BIGINT) RETURNS TABLE
	AS
	RETURN
	  WITH
	    L0   AS (SELECT c FROM (SELECT 1 UNION ALL SELECT 1) AS D(c)),
	    L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
	    L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
	    L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
	    L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
	    L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
	    Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL))-1 AS RowNum
	        FROM L5)
	  SELECT TOP(@top) RowNum
	  FROM Nums
	  ORDER BY RowNum;
	' 
	END
	
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[GetIntervals]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	BEGIN
	EXECUTE dbo.sp_executesql @statement = N'ALTER FUNCTION [Inspector].[GetIntervals](@top AS BIGINT) RETURNS TABLE
	AS
	RETURN
	  WITH
	    L0   AS (SELECT c FROM (SELECT 1 UNION ALL SELECT 1) AS D(c)),
	    L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
	    L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
	    L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
	    L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
	    L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
	    Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL))-1 AS RowNum
	        FROM L5)
	  SELECT TOP(@top) RowNum
	  FROM Nums
	  ORDER BY RowNum;
	' 
	END

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[GetServerModuleThreshold]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	BEGIN
		EXECUTE dbo.sp_executesql @statement = N'CREATE FUNCTION [Inspector].[GetServerModuleThreshold] (@Servername NVARCHAR(128)) RETURNS VARCHAR(255) AS BEGIN DECLARE @ThresholdValue VARCHAR(20); RETURN @ThresholdValue; END';
	END 

	EXECUTE dbo.sp_executesql @statement = N'ALTER FUNCTION [Inspector].[GetServerModuleThreshold]
	(
	@Servername NVARCHAR(128),
	@ModuleName VARCHAR(100),
	@SettingName VARCHAR(100)
	)
	RETURNS VARCHAR(255)
	AS
	BEGIN
	
		DECLARE @ThresholdValue VARCHAR(255);
	
		SELECT 
		@ThresholdValue = CASE /* If there is an override then use it even if it is a NULL value as this may be intended */
							WHEN [ServerSettingThresholds].[Modulename] IS NOT NULL THEN ISNULL(CAST([ThresholdInt] AS VARCHAR(255)),[ThresholdString])
							ELSE [GlobalSettings].[Value]
						  END
		FROM 
		(
			SELECT 
			[Servername],
			[Description] AS ThresholdName,
			[Value]
			FROM [Inspector].[Settings]
			CROSS JOIN (SELECT [Servername] FROM [Inspector].[CurrentServers] WHERE [IsActive] = 1) ActiveServers
			WHERE [Description] = @SettingName
		) GlobalSettings
		LEFT JOIN (SELECT 
						[Servername],
						[Modulename],
						[ThresholdName],
						[ThresholdInt],
						[ThresholdString] 
					FROM [Inspector].[ServerSettingThresholds] 
					WHERE [IsActive] = 1) [ServerSettingThresholds] ON GlobalSettings.[Servername] = ServerSettingThresholds.[Servername]
														AND GlobalSettings.[ThresholdName] = ServerSettingThresholds.[ThresholdName]
		WHERE (ServerSettingThresholds.[Modulename] = @ModuleName OR ServerSettingThresholds.[Modulename] IS NULL)
		AND GlobalSettings.[Servername] = @Servername;
	
	
		RETURN @ThresholdValue;
	
	END';

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[GetLastCollectionDateTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	BEGIN
	execute dbo.sp_executesql @statement = N'
	CREATE FUNCTION [Inspector].[GetLastCollectionDateTime] 
	(
	@Modulename VARCHAR(50)
	)
	RETURNS DATETIME
	AS 
	--Revision date: 29/03/2021
	BEGIN 
		DECLARE @LastDateTime DATETIME;
	
		/* We are not filtering on ModuleConfig_Desc here because you might be sharing collections */ 
		SET @LastDateTime = (SELECT TOP 1 [LastRunDateTime]
								FROM [Inspector].[Modules] 
								WHERE [Modulename] = @Modulename
								ORDER BY [LastRunDateTime] DESC);
		
		RETURN(ISNULL(@LastDateTime,''19000101''));
	END
	' 
	END;
	
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[GetLastReportDateTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	BEGIN
	execute dbo.sp_executesql @statement = N'
	CREATE FUNCTION [Inspector].[GetLastReportDateTime] 
	(
	@ModuleConfig VARCHAR(20)
	)
	RETURNS DATETIME
	AS 
	--Revision date: 29/03/2021
	BEGIN 
		DECLARE @LastDateTime DATETIME;
	
		SET @LastDateTime = (SELECT [LastRunDateTime]
								FROM [Inspector].[ModuleConfig] 
								WHERE [ModuleConfig_Desc] = @ModuleConfig);
		
		RETURN(ISNULL(@LastDateTime,CAST(CAST(GETDATE() AS DATE) AS DATETIME)));
	END
	' 
	END;

	IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[Inspector].[ExecutionInfo]'))
	EXEC dbo.sp_executesql @statement = N'CREATE VIEW [Inspector].[ExecutionInfo] AS SELECT 1 AS A';
	
	EXEC dbo.sp_executesql @statement = N'ALTER VIEW [Inspector].[ExecutionInfo]
	AS 
	SELECT 
		Procname,
		COUNT(Procname) AS ExecutionCount,
		SUM(Duration) AS TotalDuration_Seconds,
		AVG(Duration) AS AverageDuration_Seconds,
		MAX(Duration) AS MaxDuration_Seconds
	FROM Inspector.ExecutionLog
	WHERE Procname != N''InspectorDataCollection''
	GROUP BY Procname;';

	IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[Inspector].[ModuleSchedulesDue]'))
	BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE VIEW [Inspector].[ModuleSchedulesDue] 
	AS 
	--Revision date: 13/03/2020
	
		SELECT 
		[Schedules].[Modulename],
		[Schedules].[CollectionProcedurename],
		[ModuleConfig_Desc],
		Frequency,
		StartDatetime,
		EndDatetime,
		DATEADD(MINUTE,RowNum,Schedules.StartDatetime) AS CurrentScheduleStart,
		DATEADD(MINUTE,RowNum+1,Schedules.StartDatetime) AS CurrentScheduleEnd,
		LastRunDateTime,
		RowNum%Frequency AS modulo,
		RowNum
		FROM 
		(
			SELECT 
			[ModuleConfig_Desc],
			[Modulename],
			[CollectionProcedurename],
			[Frequency],
			(DATEDIFF(HOUR,CAST(StartTime AS DATETIME),CAST(EndTime AS DATETIME))*60)/Frequency AS TotalRuns,
			DATEADD(MINUTE,DATEPART(MINUTE,StartTime),DATEADD(HOUR,DATEPART(HOUR,StartTime),CAST(CAST(GETDATE() AS DATE) AS DATETIME))) AS StartDatetime,
			DATEADD(MINUTE,DATEPART(MINUTE,EndTime),DATEADD(HOUR,DATEPART(HOUR,EndTime),CAST(CAST(GETDATE() AS DATE) AS DATETIME))) AS EndDatetime,
			LastRunDateTime
			FROM (
				SELECT [ModuleConfig_Desc],[Modulename],CollectionProcedurename,Frequency,StartTime,EndTime,LastRunDateTime
				FROM [Inspector].[Modules] 
				WHERE [IsActive] = 1
				AND CollectionProcedurename IS NOT NULL
			) Modules
			WHERE CAST(GETDATE() AS TIME(0)) >= StartTime AND CAST(GETDATE() AS TIME(0)) <= EndTime
		) AS Schedules
		CROSS APPLY (SELECT RowNum FROM [Inspector].GetIntervals(DATEDIFF(MINUTE,Schedules.StartDatetime,Schedules.EndDatetime))) AS MinuteIntervals
		WHERE 
		--Check the that he time now falls into a scheduled interval
		((GETDATE() >= DATEADD(MINUTE,RowNum,Schedules.StartDatetime) AND GETDATE() <= DATEADD(MINUTE,RowNum+1,Schedules.StartDatetime)))
		----Check that the current interval (if there is one) is exactly divisible by the Frequency
		AND ((RowNum%Frequency = 0)
		--Check if no run has occured (NULL) OR if the last run is before the start time for today
		OR (LastRunDateTime IS NULL OR LastRunDateTime < Schedules.StartDatetime))' 
	END
	ELSE 
	BEGIN 
	EXEC dbo.sp_executesql @statement = N'ALTER VIEW [Inspector].[ModuleSchedulesDue] 
	AS 
	--Revision date: 13/04/2020
	
		SELECT 
		[Schedules].[Modulename],
		[Schedules].[CollectionProcedurename],
		[ModuleConfig_Desc],
		Frequency,
		StartDatetime,
		EndDatetime,
		DATEADD(MINUTE,RowNum,Schedules.StartDatetime) AS CurrentScheduleStart,
		DATEADD(MINUTE,RowNum+1,Schedules.StartDatetime) AS CurrentScheduleEnd,
		LastRunDateTime,
		RowNum%Frequency AS modulo,
		RowNum
		FROM 
		(
			SELECT 
			[ModuleConfig_Desc],
			[Modulename],
			[CollectionProcedurename],
			[Frequency],
			(DATEDIFF(HOUR,CAST(StartTime AS DATETIME),CAST(EndTime AS DATETIME))*60)/Frequency AS TotalRuns,
			DATEADD(MINUTE,DATEPART(MINUTE,StartTime),DATEADD(HOUR,DATEPART(HOUR,StartTime),CAST(CAST(GETDATE() AS DATE) AS DATETIME))) AS StartDatetime,
			DATEADD(MINUTE,DATEPART(MINUTE,EndTime),DATEADD(HOUR,DATEPART(HOUR,EndTime),CAST(CAST(GETDATE() AS DATE) AS DATETIME))) AS EndDatetime,
			LastRunDateTime
			FROM (
				SELECT [ModuleConfig_Desc],[Modulename],CollectionProcedurename,Frequency,StartTime,EndTime,LastRunDateTime
				FROM [Inspector].[Modules] 
				WHERE [IsActive] = 1
				AND CollectionProcedurename IS NOT NULL
			) Modules
			WHERE CAST(GETDATE() AS TIME(0)) >= StartTime AND CAST(GETDATE() AS TIME(0)) <= EndTime
		) AS Schedules
		CROSS APPLY (SELECT RowNum FROM [Inspector].GetIntervals(DATEDIFF(MINUTE,Schedules.StartDatetime,Schedules.EndDatetime))) AS MinuteIntervals
		WHERE 
		--Check the that he time now falls into a scheduled interval
		((GETDATE() >= DATEADD(MINUTE,RowNum,Schedules.StartDatetime) AND GETDATE() <= DATEADD(MINUTE,RowNum+1,Schedules.StartDatetime)))
		----Check that the current interval (if there is one) is exactly divisible by the Frequency
		AND ((RowNum%Frequency = 0)
		--Check if no run has occured (NULL) OR if the last run is before the start time for today
		OR (LastRunDateTime IS NULL OR LastRunDateTime < Schedules.StartDatetime))' 
	END 


	IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[Inspector].[ReportSchedulesDue]'))
	BEGIN
	EXEC dbo.sp_executesql @statement = N'
	CREATE VIEW [Inspector].[ReportSchedulesDue] 
	AS 
	--Revision date: 15/05/2020
	
		SELECT 
		[ModuleConfig_Desc],
		ReportWarningsOnly,
		NoClutter,
		Frequency,
		StartDatetime,
		EndDatetime,
		DATEADD(MINUTE,RowNum,Schedules.StartDatetime) AS CurrentScheduleStart,
		DATEADD(MINUTE,RowNum+1,Schedules.StartDatetime) AS CurrentScheduleEnd,
		LastRunDateTime,
		RowNum%Frequency AS modulo,
		RowNum,
		EmailGroup,
		EmailProfile,
		EmailAsAttachment
		FROM 
		(
			SELECT 
			[ModuleConfig_Desc],
			[Frequency],
			[ReportWarningsOnly],
			[NoClutter],
			(DATEDIFF(HOUR,CAST(StartTime AS DATETIME),CAST(EndTime AS DATETIME))*60)/Frequency AS TotalRuns,
			DATEADD(MINUTE,DATEPART(MINUTE,StartTime),DATEADD(HOUR,DATEPART(HOUR,StartTime),CAST(CAST(GETDATE() AS DATE) AS DATETIME))) AS StartDatetime,
			DATEADD(MINUTE,DATEPART(MINUTE,EndTime),DATEADD(HOUR,DATEPART(HOUR,EndTime),CAST(CAST(GETDATE() AS DATE) AS DATETIME))) AS EndDatetime,
			LastRunDateTime,RunDay,
			ISNULL(EmailGroup,''DBA'') AS EmailGroup,
			EmailProfile,
			EmailAsAttachment
			FROM (
				SELECT [ModuleConfig_Desc],Frequency,StartTime,EndTime,LastRunDateTime,ReportWarningsOnly,NoClutter,RunDay,EmailGroup,EmailProfile,ISNULL(EmailAsAttachment,0) AS EmailAsAttachment
				FROM [Inspector].[ModuleConfig] 
				WHERE [IsActive] = 1
			) Modules
			WHERE CAST(GETDATE() AS TIME(0)) >= StartTime AND CAST(GETDATE() AS TIME(0)) <= EndTime
		) AS Schedules
		CROSS APPLY (SELECT RowNum FROM [Inspector].GetIntervals(DATEDIFF(MINUTE,Schedules.StartDatetime,Schedules.EndDatetime))) AS MinuteIntervals
		WHERE 
		--RunDay (delimited) is like today''s day name or RunDay is not specified (Every day)
		(RunDay LIKE ''%''+CAST(DATENAME(WEEKDAY,GETDATE()) AS VARCHAR(10))+''%'' OR RunDay IS NULL)
		--Check the that the time now falls into a scheduled interval
		AND	((GETDATE() >= DATEADD(MINUTE,RowNum,Schedules.StartDatetime) AND GETDATE() <= DATEADD(MINUTE,RowNum+1,Schedules.StartDatetime)))
		----Check that the current interval (if there is one) is exactly divisible by the Frequency
		AND ((RowNum%Frequency = 0)
		--Check if no run has occured (NULL) OR if the last run is before the start time for today
		OR (LastRunDateTime IS NULL OR LastRunDateTime < Schedules.StartDatetime))' 
	END
	ELSE 
	BEGIN 
	EXEC dbo.sp_executesql @statement = N'
	ALTER VIEW [Inspector].[ReportSchedulesDue] 
	AS 
	--Revision date: 15/05/2020
	
		SELECT 
		[ModuleConfig_Desc],
		ReportWarningsOnly,
		NoClutter,
		Frequency,
		StartDatetime,
		EndDatetime,
		DATEADD(MINUTE,RowNum,Schedules.StartDatetime) AS CurrentScheduleStart,
		DATEADD(MINUTE,RowNum+1,Schedules.StartDatetime) AS CurrentScheduleEnd,
		LastRunDateTime,
		RowNum%Frequency AS modulo,
		RowNum,
		EmailGroup,
		EmailProfile,
		EmailAsAttachment
		FROM 
		(
			SELECT 
			[ModuleConfig_Desc],
			[Frequency],
			[ReportWarningsOnly],
			[NoClutter],
			(DATEDIFF(HOUR,CAST(StartTime AS DATETIME),CAST(EndTime AS DATETIME))*60)/Frequency AS TotalRuns,
			DATEADD(MINUTE,DATEPART(MINUTE,StartTime),DATEADD(HOUR,DATEPART(HOUR,StartTime),CAST(CAST(GETDATE() AS DATE) AS DATETIME))) AS StartDatetime,
			DATEADD(MINUTE,DATEPART(MINUTE,EndTime),DATEADD(HOUR,DATEPART(HOUR,EndTime),CAST(CAST(GETDATE() AS DATE) AS DATETIME))) AS EndDatetime,
			LastRunDateTime,RunDay,
			ISNULL(EmailGroup,''DBA'') AS EmailGroup,
			EmailProfile,
			EmailAsAttachment
			FROM (
				SELECT [ModuleConfig_Desc],Frequency,StartTime,EndTime,LastRunDateTime,ReportWarningsOnly,NoClutter,RunDay,EmailGroup,EmailProfile,ISNULL(EmailAsAttachment,0) AS EmailAsAttachment
				FROM [Inspector].[ModuleConfig] 
				WHERE [IsActive] = 1
			) Modules
			WHERE CAST(GETDATE() AS TIME(0)) >= StartTime AND CAST(GETDATE() AS TIME(0)) <= EndTime
		) AS Schedules
		CROSS APPLY (SELECT RowNum FROM [Inspector].GetIntervals(DATEDIFF(MINUTE,Schedules.StartDatetime,Schedules.EndDatetime))) AS MinuteIntervals
		WHERE 
		--RunDay (delimited) is like today''s day name or RunDay is not specified (Every day)
		(RunDay LIKE ''%''+CAST(DATENAME(WEEKDAY,GETDATE()) AS VARCHAR(10))+''%'' OR RunDay IS NULL)
		--Check the that the time now falls into a scheduled interval
		AND	((GETDATE() >= DATEADD(MINUTE,RowNum,Schedules.StartDatetime) AND GETDATE() <= DATEADD(MINUTE,RowNum+1,Schedules.StartDatetime)))
		----Check that the current interval (if there is one) is exactly divisible by the Frequency
		AND ((RowNum%Frequency = 0)
		--Check if no run has occured (NULL) OR if the last run is before the start time for today
		OR (LastRunDateTime IS NULL OR LastRunDateTime < Schedules.StartDatetime))' 
	
	END


	IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'Inspector.ExecutionLogDetails'))
	BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE VIEW [Inspector].[ExecutionLogDetails]
	AS 
	--Revision date: 31/10/2019
	
	SELECT TOP (2147483647) --Crazy top so that we can retain the Order by clause.
	ID,
	Servername,
	ModuleConfig_Desc,
	Procname,
	Frequency,
	Duration,
	ExecutionDate,
	PreviousRunDateTime,
	Rownum AS RunNumber,
	CASE 
		WHEN Rownum = 1 THEN Frequency 
		ELSE ActualFrequency
	END AS ActualFrequency,
	PSCollection
	FROM 
	(
		SELECT 
		ExecutionLog.ID,
		ExecutionLog.Servername,
		ExecutionLog.ModuleConfig_Desc,
		ExecutionLog.Procname,
		CASE 
			WHEN ExecutionLog.Procname LIKE ''%Report'' THEN (SELECT Frequency FROM Inspector.ModuleConfig WHERE [ModuleConfig_Desc] = ExecutionLog.ModuleConfig_Desc)
			ELSE ExecutionLog.Frequency
		END AS Frequency,
		Duration,
		ExecutionDate,
		LAG(ExecutionDate,1,ExecutionDate) OVER (PARTITION BY ExecutionLog.ModuleConfig_Desc,ExecutionLog.Procname,ExecutionLog.Servername ORDER BY ExecutionLog.ExecutionDate ASC) AS PreviousRunDateTime,
		ROW_NUMBER() OVER (PARTITION BY ExecutionLog.ModuleConfig_Desc,ExecutionLog.Procname,ExecutionLog.Servername ORDER BY ExecutionLog.ExecutionDate ASC) AS Rownum,
		DATEDIFF(MINUTE,LAG(ExecutionDate,1,ExecutionDate) OVER (PARTITION BY ExecutionLog.ModuleConfig_Desc,ExecutionLog.Procname,ExecutionLog.Servername ORDER BY ExecutionLog.ExecutionDate ASC),ExecutionDate) AS ActualFrequency,
		PSCollection
		FROM [Inspector].[Modules] 
		RIGHT JOIN [Inspector].[ExecutionLog] ON Modules.ModuleConfig_Desc = ExecutionLog.ModuleConfig_Desc AND CollectionProcedurename = Procname
	) AS ModuleExecutions
	ORDER BY 
	ModuleConfig_Desc ASC,
	Procname ASC,
	Servername ASC,
	ExecutionDate ASC'
	END 
	ELSE 
	BEGIN 
	EXEC dbo.sp_executesql @statement = N'ALTER VIEW [Inspector].[ExecutionLogDetails]
	AS 
	--Revision date: 31/10/2019
	
	SELECT TOP (2147483647) --Crazy top so that we can retain the Order by clause.
	ID,
	Servername,
	ModuleConfig_Desc,
	Procname,
	Frequency,
	Duration,
	ExecutionDate,
	PreviousRunDateTime,
	Rownum AS RunNumber,
	CASE 
		WHEN Rownum = 1 THEN Frequency 
		ELSE ActualFrequency
	END AS ActualFrequency,
	PSCollection
	FROM 
	(
		SELECT 
		ExecutionLog.ID,
		ExecutionLog.Servername,
		ExecutionLog.ModuleConfig_Desc,
		ExecutionLog.Procname,
		CASE 
			WHEN ExecutionLog.Procname LIKE ''%Report'' THEN (SELECT Frequency FROM Inspector.ModuleConfig WHERE [ModuleConfig_Desc] = ExecutionLog.ModuleConfig_Desc)
			ELSE ExecutionLog.Frequency
		END AS Frequency,
		Duration,
		ExecutionDate,
		LAG(ExecutionDate,1,ExecutionDate) OVER (PARTITION BY ExecutionLog.ModuleConfig_Desc,ExecutionLog.Procname,ExecutionLog.Servername ORDER BY ExecutionLog.ExecutionDate ASC) AS PreviousRunDateTime,
		ROW_NUMBER() OVER (PARTITION BY ExecutionLog.ModuleConfig_Desc,ExecutionLog.Procname,ExecutionLog.Servername ORDER BY ExecutionLog.ExecutionDate ASC) AS Rownum,
		DATEDIFF(MINUTE,LAG(ExecutionDate,1,ExecutionDate) OVER (PARTITION BY ExecutionLog.ModuleConfig_Desc,ExecutionLog.Procname,ExecutionLog.Servername ORDER BY ExecutionLog.ExecutionDate ASC),ExecutionDate) AS ActualFrequency,
		PSCollection
		FROM [Inspector].[Modules] 
		RIGHT JOIN [Inspector].[ExecutionLog] ON Modules.ModuleConfig_Desc = ExecutionLog.ModuleConfig_Desc AND CollectionProcedurename = Procname
	) AS ModuleExecutions
	ORDER BY 
	ModuleConfig_Desc ASC,
	Procname ASC,
	Servername ASC,
	ExecutionDate ASC'
	END


	IF OBJECT_ID('Inspector.PowerBIBackupsview') IS NULL
	BEGIN
	EXEC sp_executesql N'CREATE VIEW [Inspector].[PowerBIBackupsview]
	AS
	--Revision Date: 01/05/2019
	WITH RawData AS 
	(SELECT 
	Log_Date,
	LTRIM(RTRIM(BackupSet.Databasename)) AS Databasename, --Added trim as Leading and trailing spaces can cause misreporting
	[FULL] AS LastFull,
	[DIFF] AS LastDiff,
	[LOG] AS LastLog,
	BackupSet.AGname,
	CASE WHEN BackupSet.AGname = ''Not in an AG'' THEN BackupSet.Servername
	ELSE BackupSet.AGname END AS GroupingMethod,  
	BackupSet.Servername,
	BackupSet.IsFullRecovery,
	BackupSet.IsSystemDB,
	BackupSet.primary_replica,
	BackupSet.backup_preference
	FROM [Inspector].[BackupsCheck] BackupSet
	INNER JOIN [Inspector].[CurrentServers] ON BackupSet.Servername = CurrentServers.Servername
	WHERE CAST(GETDATE() AS DATE) >= CAST(GETDATE() AS DATE)
	AND CurrentServers.IsActive = 1
	AND NOT EXISTS (SELECT 1 
		FROM [Inspector].[BackupsCheckExcludes] 
		WHERE [Servername] = [BackupSet].[Servername] 
		AND [Databasename] = [BackupSet].[Databasename]
		AND ([SuppressUntil] IS NULL OR [SuppressUntil] >= GETDATE())
		)
	),
	Aggregates AS (
	SELECT 
	MAX(Log_Date) AS Log_Date,
	RawData.Databasename,
	MAX(Servername) AS Servername,
	MAX(LastFull) AS LastFull,
	MAX(LastDiff) AS LastDiff,
	MAX(LastLog) AS LastLog,
	AGname,
	GroupingMethod,
	IsFullRecovery,
	IsSystemDB,
	MAX(primary_replica) AS primary_replica,
	UPPER(backup_preference) AS backup_preference
	FROM RawData RawData
	GROUP BY Databasename,AGname,GroupingMethod,IsFullRecovery,IsSystemDB,backup_preference
	),
	Validations AS (
	SELECT 
	Log_Date,
	Databasename,
	Servername,
	LastFull,
	LastDiff,
	LastLog,
	DATEDIFF(DAY,LastFull,Log_Date) AS FullBackupAge,
	DATEDIFF(DAY,LastDiff,Log_Date) AS DiffBackupAge,
	DATEDIFF(MINUTE,LastLog,Log_Date) AS LogBackupAge,
	AGname,
	GroupingMethod,
	IsFullRecovery,
	IsSystemDB,
	primary_replica,
	backup_preference,
	(SELECT ISNULL(CAST([Value] AS INT),8) FROM [Inspector].[Settings] WHERE [Description] = ''FullBackupThreshold'') AS FullBackupThreshold,
	(SELECT ISNULL(CAST([Value] AS INT),365) FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') AS DiffBackupThreshold,
	(SELECT ISNULL(CAST([Value] AS INT),60) FROM [Inspector].[Settings] WHERE [Description] = ''LogBackupThreshold'') AS LogBackupThreshold
	FROM Aggregates
	)
	SELECT 
	Log_Date,
	Databasename,
	Servername,
	NULLIF(LastFull,''19000101 00:00:00'') AS LastFull,
	NULLIF(LastDiff,''19000101 00:00:00'') AS LastDiff,
	NULLIF(LastLog,''19000101 00:00:00'') AS LastLog,
	FullBackupAge,
	DiffBackupAge,
	LogBackupAge,
	REPLACE(AGname,''Not in an AG'',''Non AG'') AS AGname,
	GroupingMethod,
	IsFullRecovery,
	IsSystemDB,
	primary_replica,
	backup_preference,
	FullBackupThreshold,
	DiffBackupThreshold,
	LogBackupThreshold,
	CASE 
		WHEN FullBackupAge > FullBackupThreshold THEN 1 ELSE 0 
	END AS FullBackupBreach,
	CASE 
		WHEN IsSystemDB = 1 THEN 0 
		WHEN IsSystemDB = 0 AND (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') IS NULL THEN 0
		WHEN IsSystemDB = 0 AND (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') IS NOT NULL AND DiffBackupAge > DiffBackupThreshold THEN 1 ELSE 0
	END AS DiffBackupBreach,
	CASE 
		WHEN IsSystemDB = 1 OR IsFullRecovery = 0 THEN 0 
		WHEN (IsSystemDB =  0 AND IsFullRecovery = 1) AND LogBackupAge > LogBackupThreshold THEN 1 ELSE 0 
	END AS LogBackupBreach,
	CASE 
		WHEN IsSystemDB = 1 OR IsFullRecovery = 0 THEN 1 
		WHEN (IsSystemDB =  0 AND IsFullRecovery = 1) AND (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') IS NULL THEN 2
		WHEN (IsSystemDB =  0 AND IsFullRecovery = 1) AND (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') IS NOT NULL THEN 3
	END AS TotalBackupTypes
	FROM Validations;'
	END
	ELSE
	BEGIN 
	EXEC sp_executesql N'ALTER VIEW [Inspector].[PowerBIBackupsview]
	AS
	--Revision Date: 01/05/2019
	WITH RawData AS 
	(SELECT 
	Log_Date,
	LTRIM(RTRIM(BackupSet.Databasename)) AS Databasename, --Added trim as Leading and trailing spaces can cause misreporting
	[FULL] AS LastFull,
	[DIFF] AS LastDiff,
	[LOG] AS LastLog,
	BackupSet.AGname,
	CASE WHEN BackupSet.AGname = ''Not in an AG'' THEN BackupSet.Servername
	ELSE BackupSet.AGname END AS GroupingMethod,  
	BackupSet.Servername,
	BackupSet.IsFullRecovery,
	BackupSet.IsSystemDB,
	BackupSet.primary_replica,
	BackupSet.backup_preference
	FROM [Inspector].[BackupsCheck] BackupSet
	INNER JOIN [Inspector].[CurrentServers] ON BackupSet.Servername = CurrentServers.Servername
	WHERE CAST(GETDATE() AS DATE) >= CAST(GETDATE() AS DATE)
	AND CurrentServers.IsActive = 1
	AND NOT EXISTS (SELECT 1 
		FROM [Inspector].[BackupsCheckExcludes] 
		WHERE [Servername] = [BackupSet].[Servername] 
		AND [Databasename] = [BackupSet].[Databasename]
		AND ([SuppressUntil] IS NULL OR [SuppressUntil] >= GETDATE())
		)
	),
	Aggregates AS (
	SELECT 
	MAX(Log_Date) AS Log_Date,
	RawData.Databasename,
	MAX(Servername) AS Servername,
	MAX(LastFull) AS LastFull,
	MAX(LastDiff) AS LastDiff,
	MAX(LastLog) AS LastLog,
	AGname,
	GroupingMethod,
	IsFullRecovery,
	IsSystemDB,
	MAX(primary_replica) AS primary_replica,
	UPPER(backup_preference) AS backup_preference
	FROM RawData RawData
	GROUP BY Databasename,AGname,GroupingMethod,IsFullRecovery,IsSystemDB,backup_preference
	),
	Validations AS (
	SELECT 
	Log_Date,
	Databasename,
	Servername,
	LastFull,
	LastDiff,
	LastLog,
	DATEDIFF(DAY,LastFull,Log_Date) AS FullBackupAge,
	DATEDIFF(DAY,LastDiff,Log_Date) AS DiffBackupAge,
	DATEDIFF(MINUTE,LastLog,Log_Date) AS LogBackupAge,
	AGname,
	GroupingMethod,
	IsFullRecovery,
	IsSystemDB,
	primary_replica,
	backup_preference,
	(SELECT ISNULL(CAST([Value] AS INT),8) FROM [Inspector].[Settings] WHERE [Description] = ''FullBackupThreshold'') AS FullBackupThreshold,
	(SELECT ISNULL(CAST([Value] AS INT),365) FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') AS DiffBackupThreshold,
	(SELECT ISNULL(CAST([Value] AS INT),60) FROM [Inspector].[Settings] WHERE [Description] = ''LogBackupThreshold'') AS LogBackupThreshold
	FROM Aggregates
	)
	SELECT 
	Log_Date,
	Databasename,
	Servername,
	NULLIF(LastFull,''19000101 00:00:00'') AS LastFull,
	NULLIF(LastDiff,''19000101 00:00:00'') AS LastDiff,
	NULLIF(LastLog,''19000101 00:00:00'') AS LastLog,
	FullBackupAge,
	DiffBackupAge,
	LogBackupAge,
	REPLACE(AGname,''Not in an AG'',''Non AG'') AS AGname,
	GroupingMethod,
	IsFullRecovery,
	IsSystemDB,
	primary_replica,
	backup_preference,
	FullBackupThreshold,
	DiffBackupThreshold,
	LogBackupThreshold,
	CASE 
		WHEN FullBackupAge > FullBackupThreshold THEN 1 ELSE 0 
	END AS FullBackupBreach,
	CASE 
		WHEN IsSystemDB = 1 THEN 0 
		WHEN IsSystemDB = 0 AND (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') IS NULL THEN 0
		WHEN IsSystemDB = 0 AND (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') IS NOT NULL AND DiffBackupAge > DiffBackupThreshold THEN 1 ELSE 0
	END AS DiffBackupBreach,
	CASE 
		WHEN IsSystemDB = 1 OR IsFullRecovery = 0 THEN 0 
		WHEN (IsSystemDB =  0 AND IsFullRecovery = 1) AND LogBackupAge > LogBackupThreshold THEN 1 ELSE 0 
	END AS LogBackupBreach,
	CASE 
		WHEN IsSystemDB = 1 OR IsFullRecovery = 0 THEN 1 
		WHEN (IsSystemDB =  0 AND IsFullRecovery = 1) AND (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') IS NULL THEN 2
		WHEN (IsSystemDB =  0 AND IsFullRecovery = 1) AND (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'') IS NOT NULL THEN 3
	END AS TotalBackupTypes
	FROM Validations;'
	END
			
	
			IF OBJECT_ID('Inspector.DatabaseGrowthInfo') IS NULL
			BEGIN
			EXEC sp_executesql N'
			CREATE VIEW [Inspector].[DatabaseGrowthInfo] 
			AS
			--Revision date 09/04/2019			
			SELECT 
			[GrowthInfo].[Servername],
			[GrowthInfo].[Database_name],
			[GrowthInfo].[Drive],
			[GrowthInfo].[FileName],
			[GrowthInfo].[FirstRecordedGrowth],
			DATEDIFF(DAY,[GrowthInfo].[FirstRecordedGrowth],CAST(GETDATE() AS DATE)) AS FirstRecordedGrowthAge_Days,
			[GrowthInfo].[TotalGrowths],
			[GrowthInfo].[File_id],
			[DatabaseFileSizes].[GrowthRate] AS GrowthRate_MB,
			[GrowthInfo].[TotalGrowth_MB],
			[GrowthInfo].[TotalGrowth_MB]/DATEDIFF(DAY,[GrowthInfo].FirstRecordedGrowth,CAST(GETDATE() AS DATE)) AS AverageDailyGrowth_MB,
			(([GrowthInfo].[TotalGrowth_MB]/DATEDIFF(DAY,[GrowthInfo].FirstRecordedGrowth,CAST(GETDATE() AS DATE)))*365)/12 AS AverageMonthlyGrowth_MB,
			([GrowthInfo].[TotalGrowth_MB]/DATEDIFF(DAY,[GrowthInfo].FirstRecordedGrowth,CAST(GETDATE() AS DATE)))*365 AS AverageYearlyGrowth_MB
			FROM 
			(
				SELECT 
				[Servername],
				[Database_name],
				[Drive],
				[FileName],
				CAST(MIN([Log_Date]) AS DATE) AS FirstRecordedGrowth,
				COUNT([Log_Date]) AS TotalGrowths,
				[File_id],
				SUM([PostGrowthSize_MB]-[PreGrowthSize_MB]) AS TotalGrowth_MB
				FROM [Inspector].[DatabaseFileSizeHistory]
				GROUP BY 
				[Servername],
				[Database_name],
				[Drive],
				[FileName],
				[File_id]
			) GrowthInfo
			INNER JOIN [Inspector].[DatabaseFileSizes] ON [DatabaseFileSizes].[Database_name] = [GrowthInfo].[Database_name] 
			AND  [DatabaseFileSizes].[Servername] =  [GrowthInfo].[Servername] 
			AND [DatabaseFileSizes].[File_id] =  [GrowthInfo].[File_id];';
			END
			ELSE 
			BEGIN 
			EXEC sp_executesql N'
			ALTER VIEW [Inspector].[DatabaseGrowthInfo] 
			AS
			--Revision date 09/04/2019
			SELECT 
			[GrowthInfo].[Servername],
			[GrowthInfo].[Database_name],
			[GrowthInfo].[Drive],
			[GrowthInfo].[FileName],
			[GrowthInfo].[FirstRecordedGrowth],
			DATEDIFF(DAY,[GrowthInfo].[FirstRecordedGrowth],CAST(GETDATE() AS DATE)) AS FirstRecordedGrowthAge_Days,
			[GrowthInfo].[TotalGrowths],
			[GrowthInfo].[File_id],
			[DatabaseFileSizes].[GrowthRate] AS GrowthRate_MB,
			[GrowthInfo].[TotalGrowth_MB],
			[GrowthInfo].[TotalGrowth_MB]/DATEDIFF(DAY,[GrowthInfo].FirstRecordedGrowth,CAST(GETDATE() AS DATE)) AS AverageDailyGrowth_MB,
			(([GrowthInfo].[TotalGrowth_MB]/DATEDIFF(DAY,[GrowthInfo].FirstRecordedGrowth,CAST(GETDATE() AS DATE)))*365)/12 AS AverageMonthlyGrowth_MB,
			([GrowthInfo].[TotalGrowth_MB]/DATEDIFF(DAY,[GrowthInfo].FirstRecordedGrowth,CAST(GETDATE() AS DATE)))*365 AS AverageYearlyGrowth_MB
			FROM 
			(
				SELECT 
				[Servername],
				[Database_name],
				[Drive],
				[FileName],
				CAST(MIN([Log_Date]) AS DATE) AS FirstRecordedGrowth,
				COUNT([Log_Date]) AS TotalGrowths,
				[File_id],
				SUM([PostGrowthSize_MB]-[PreGrowthSize_MB]) AS TotalGrowth_MB
				FROM [Inspector].[DatabaseFileSizeHistory]
				GROUP BY 
				[Servername],
				[Database_name],
				[Drive],
				[FileName],
				[File_id]
			) GrowthInfo
			INNER JOIN [Inspector].[DatabaseFileSizes] ON [DatabaseFileSizes].[Database_name] = [GrowthInfo].[Database_name] 
			AND  [DatabaseFileSizes].[Servername] =  [GrowthInfo].[Servername] 
			AND [DatabaseFileSizes].[File_id] =  [GrowthInfo].[File_id];';
			END 

			IF OBJECT_ID('Inspector.DriveSpaceInfo') IS NULL
			BEGIN
			EXEC sp_executesql N'CREATE VIEW [Inspector].[DriveSpaceInfo]
			AS
			
			/*
			Author: Adrian Buckman
			Created: 23/08/2018
			Revised: 30/06/2021
			Description: Show aggregated space used by drive by server, show Average daily,monthly and yearly usage and MIN/MAX Daily Increment variances.
			*/
			
			SELECT 
			Servername,
			Drive,
			(SELECT TOP (1) Capacity_GB FROM [Inspector].[DriveSpace] LastCapacity WHERE LastCapacity.Servername = DriveInfo.Servername AND LastCapacity.Drive = DriveInfo.Drive) AS Capacity_GB,
			COUNT(*) AS DaysRecorded,
			CAST(AVG(Delta_GB) AS DECIMAL(8,2)) AS AVG_Daily_Growth_GB,
			CAST(((AVG(Delta_GB)*365)/12) AS DECIMAL(8,2)) AS AVG_Monthly_Growth_GB,
			CAST((AVG(Delta_GB)*365) AS DECIMAL(8,2)) AS AVG_Yearly_GB,
			CAST((MIN(Delta_GB)) AS DECIMAL(8,2)) AS MIN_Daily_Increment_GB,
			CAST((MAX(Delta_GB)) AS DECIMAL(8,2)) AS MAX_Daily_Increment_GB
			FROM 
			(SELECT
				Servername,
				Log_Date,
				Drive,
				Capacity_GB,
				AvailableSpace_GB,
				Used_GB,
				CASE WHEN Delta_GB < 0 THEN 0 ELSE Delta_GB END AS Delta_GB
				FROM 
				(
					SELECT 
					Servername,
					Log_Date,
					Drive,
					Capacity_GB,
					AvailableSpace_GB,
					Capacity_GB - AvailableSpace_GB AS Used_GB,
					--LAG(Capacity_GB - AvailableSpace_GB,1,NULL) OVER (PARTITION BY Servername,Drive ORDER BY Servername ASC, Drive ASC, Log_Date ASC) Prev_used_GB,
					Capacity_GB - AvailableSpace_GB - LAG(Capacity_GB - AvailableSpace_GB,1,Capacity_GB - AvailableSpace_GB) OVER (PARTITION BY Servername,Drive ORDER BY Servername ASC, Drive ASC, Log_Date ASC) AS Delta_GB
					FROM [Inspector].[DriveSpace]
				
				) AS Derived
			) AS DriveInfo
			GROUP BY 
			Servername,
			Drive
			';

			END
			ELSE 
			BEGIN
			EXEC sp_executesql N'ALTER VIEW [Inspector].[DriveSpaceInfo]
			AS
			
			/*
			Author: Adrian Buckman
			Created: 23/08/2018
			Revised: 30/06/2021
			Description: Show aggregated space used by drive by server, show Average daily,monthly and yearly usage and MIN/MAX Daily Increment variances.
			*/
			
			SELECT 
			Servername,
			Drive,
			(SELECT TOP (1) Capacity_GB FROM [Inspector].[DriveSpace] LastCapacity WHERE LastCapacity.Servername = DriveInfo.Servername AND LastCapacity.Drive = DriveInfo.Drive) AS Capacity_GB,
			COUNT(*) AS DaysRecorded,
			CAST(AVG(Delta_GB) AS DECIMAL(8,2)) AS AVG_Daily_Growth_GB,
			CAST(((AVG(Delta_GB)*365)/12) AS DECIMAL(8,2)) AS AVG_Monthly_Growth_GB,
			CAST((AVG(Delta_GB)*365) AS DECIMAL(8,2)) AS AVG_Yearly_GB,
			CAST((MIN(Delta_GB)) AS DECIMAL(8,2)) AS MIN_Daily_Increment_GB,
			CAST((MAX(Delta_GB)) AS DECIMAL(8,2)) AS MAX_Daily_Increment_GB
			FROM 
			(SELECT
				Servername,
				Log_Date,
				Drive,
				Capacity_GB,
				AvailableSpace_GB,
				Used_GB,
				CASE WHEN Delta_GB < 0 THEN 0 ELSE Delta_GB END AS Delta_GB
				FROM 
				(
					SELECT 
					Servername,
					Log_Date,
					Drive,
					Capacity_GB,
					AvailableSpace_GB,
					Capacity_GB - AvailableSpace_GB AS Used_GB,
					--LAG(Capacity_GB - AvailableSpace_GB,1,NULL) OVER (PARTITION BY Servername,Drive ORDER BY Servername ASC, Drive ASC, Log_Date ASC) Prev_used_GB,
					Capacity_GB - AvailableSpace_GB - LAG(Capacity_GB - AvailableSpace_GB,1,Capacity_GB - AvailableSpace_GB) OVER (PARTITION BY Servername,Drive ORDER BY Servername ASC, Drive ASC, Log_Date ASC) AS Delta_GB
					FROM [Inspector].[DriveSpace]
				
				) AS Derived
			) AS DriveInfo
			GROUP BY 
			Servername,
			Drive
			';

			END

			--Create Powershell collection objects
			IF OBJECT_ID('Inspector.PSEnabledModules') IS NULL
			BEGIN
			EXEC ('CREATE VIEW [Inspector].[PSEnabledModules]
			AS
			--Revision date: 27/01/2020
			SELECT 
			[ModuleConfig_Desc],
			[Modulename],
			[CollectionProcedurename],
			IsActive AS [Enabled]
			FROM [Inspector].[Modules] 
			WHERE IsActive = 1;');
			END
			ELSE 
			BEGIN
			EXEC ('ALTER VIEW [Inspector].[PSEnabledModules]
			AS
			--Revision date: 27/01/2020
			SELECT 
			[ModuleConfig_Desc],
			[Modulename],
			[CollectionProcedurename],
			IsActive AS [Enabled]
			FROM [Inspector].[Modules] 
			WHERE IsActive = 1;');
			END

			IF OBJECT_ID('Inspector.PSInspectorTables') IS NULL
			BEGIN
			EXEC sp_executesql N'
			CREATE VIEW [Inspector].[PSInspectorTables]
			AS
			--Revision date: 14/10/2019

			SELECT DISTINCT Modulename AS Tablename
			FROM [Inspector].[Modules] 
			INNER JOIN sys.tables on Modules.Modulename = tables.name 
			WHERE tables.schema_id = SCHEMA_ID(N''Inspector'');'
			END
			ELSE 
			BEGIN 
			EXEC sp_executesql N'
			ALTER VIEW [Inspector].[PSInspectorTables]
			AS
			--Revision date: 14/10/2019

			SELECT DISTINCT Modulename AS Tablename
			FROM [Inspector].[Modules] 
			INNER JOIN sys.tables on Modules.Modulename = tables.name 
			WHERE tables.schema_id = SCHEMA_ID(N''Inspector'');'
			END
						
			IF OBJECT_ID('Inspector.PSADHocDatabaseSupressionStage') IS NULL
			CREATE TABLE [Inspector].[PSADHocDatabaseSupressionStage](
			[Servername] [nvarchar](128) NULL,
			[Log_Date] [datetime] NULL,
			[Databasename] [nvarchar](128) NULL,
			[Suppress] [bit] NULL
			);

			IF OBJECT_ID('Inspector.PSAutoUpdate') IS NULL
			CREATE TABLE [Inspector].[PSAutoUpdate](
			[Updatename] [nvarchar](128) NOT NULL,
			[LastUpdated] [datetime] NULL
			);

			IF NOT EXISTS(SELECT 1 FROM [Inspector].[PSAutoUpdate] WHERE [Updatename] = 'PSAutoUpdate')
			BEGIN 
				INSERT INTO [Inspector].[PSAutoUpdate] ([Updatename],[LastUpdated])
				VALUES('PSAutoUpdate',NULL);
			END
			
			IF OBJECT_ID('Inspector.PSAGDatabasesStage') IS NULL
			CREATE TABLE [Inspector].[PSAGDatabasesStage](
			[ID] [int] IDENTITY(1,1) NOT NULL,
			[Servername] [nvarchar](128) NULL,
			[Log_Date] [datetime] NULL,
			[LastUpdated] [datetime] NULL,
			[Databasename] [nvarchar](128) NULL,
			[Is_AG] [bit] NULL,
			[Is_AGJoined] [bit] NULL
			);
			
			IF OBJECT_ID('Inspector.PSDatabaseFileSizesStage') IS NULL
			BEGIN
			CREATE TABLE [Inspector].[PSDatabaseFileSizesStage](
			[Servername] [nvarchar](128) NOT NULL,
			[Database_id] [int] NOT NULL,
			[Database_name] [nvarchar](128) NULL,
			[OriginalDateLogged] [datetime] NOT NULL,
			[OriginalSize_MB] [bigint] NULL,
			[Type_desc] [nvarchar](60) NULL,
			[File_id] [tinyint] NOT NULL,
			[Filename] [nvarchar](260) NULL,
			[PostGrowthSize_MB] [bigint] NULL,
			[GrowthRate] [int] NULL,
			[Is_percent_growth] [bit] NOT NULL,
			[NextGrowth] [bigint] NULL,
			[LastUpdated] [datetime] NULL
			); 
			END

			
			IF OBJECT_ID('Inspector.PSDatabaseFileSizeHistoryStage') IS NULL
			BEGIN
			CREATE TABLE [Inspector].[PSDatabaseFileSizeHistoryStage](
			[GrowthID] [bigint] NOT NULL,
			[Servername] [nvarchar](128) NOT NULL,
			[Database_id] [int] NOT NULL,
			[Database_name] [nvarchar](128) NOT NULL,
			[Log_Date] [datetime] NOT NULL,
			[Type_Desc] [nvarchar](60) NOT NULL,
			[File_id] [tinyint] NOT NULL,
			[FileName] [nvarchar](260) NOT NULL,
			[PreGrowthSize_MB] [bigint] NOT NULL,
			[GrowthRate_MB] [int] NOT NULL,
			[GrowthIncrements] [int] NOT NULL,
			[PostGrowthSize_MB] [bigint] NOT NULL,
			[Drive] [NVARCHAR](128),
			);
			END

			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Drive' AND [object_id] = OBJECT_ID(N'Inspector.PSDatabaseFileSizeHistoryStage'))
			BEGIN
				--New column for 1.4
				ALTER TABLE [Inspector].[PSDatabaseFileSizeHistoryStage] ADD [Drive] NVARCHAR(128);
			END

			--Increase column length to accomodate shared storage names such as \\ClusterStorage
			IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.PSDatabaseFileSizeHistoryStage') AND [name] = 'Drive' AND max_length != 256)
			BEGIN 
				ALTER TABLE [Inspector].[PSDatabaseFileSizeHistoryStage] ALTER COLUMN [Drive] NVARCHAR(128);
			END
			
			IF OBJECT_ID('Inspector.PSADHocDatabaseCreationsStage') IS NULL
			CREATE TABLE [Inspector].[PSADHocDatabaseCreationsStage](
			[Servername] [nvarchar](128) NOT NULL,
			[Log_Date] [datetime] NULL,
			[Databasename] [nvarchar](128) NOT NULL,
			[Create_Date] [datetime] NULL
			); 	
			
			IF OBJECT_ID('Inspector.PSDriveSpaceStage') IS NULL
			CREATE TABLE [Inspector].[PSDriveSpaceStage](
			[Servername] [nvarchar](128) NULL,
			[Log_Date] [datetime] NULL,
			[Drive] [nvarchar](128) NULL,
			[Capacity_GB] [decimal](10, 2) NULL,
			[AvailableSpace_GB] [decimal](10, 2) NULL
			);	 

			--Increase column length to accomodate shared storage names such as \\ClusterStorage
			IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.PSDriveSpaceStage') AND [name] = 'Drive' AND max_length != 256)
			BEGIN 
				ALTER TABLE [Inspector].[PSDriveSpaceStage] ALTER COLUMN [Drive] NVARCHAR(128);
			END

			IF OBJECT_ID('Inspector.PSInstanceVersionHistoryStage') IS NULL
			CREATE TABLE [Inspector].[PSInstanceVersionHistoryStage](
			[Servername] NVARCHAR(128) NOT NULL,
			[Log_Date] DATETIME NOT NULL,
			[CollectionDatetime] DATETIME NOT NULL,
			[VersionNo] NVARCHAR(128) NULL,
			[Edition] NVARCHAR(128) NULL
			);
			
			IF EXISTS (SELECT 1 FROM sys.all_columns WHERE object_id = OBJECT_ID('Inspector.PSInstanceVersionHistoryStage') AND name = 'VersionNo' AND max_length < 256)
			BEGIN 
				ALTER TABLE [Inspector].[PSInstanceVersionHistoryStage] ALTER COLUMN [VersionNo] NVARCHAR(128);
			END
			
			
			IF OBJECT_ID('Inspector.PSAGPrimaryHistoryStage') IS NULL
			BEGIN			
				CREATE TABLE [Inspector].[PSAGPrimaryHistoryStage](
				[Log_Date] DATETIME NULL,
				[CollectionDateTime] DATETIME NULL,
				[Servername] NVARCHAR(128) NULL,
				[AGname] NVARCHAR(128) NULL
				);		
			END			
		

			--Typo Fix 1.0.1
			IF OBJECT_ID('Inspector.LoginAttemptsiInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[LoginAttemptsiInsert];

			--Drop functions for recreation
			IF OBJECT_ID('Inspector.GetNonServerSpecificModules') IS NOT NULL 
			DROP FUNCTION [Inspector].[GetNonServerSpecificModules];

			IF OBJECT_ID('Inspector.GenerateHtmlTableheader') IS NOT NULL
			DROP FUNCTION [Inspector].[GenerateHtmlTableheader];

			IF OBJECT_ID('Inspector.GetWarningLevel') IS NOT NULL
			DROP FUNCTION [Inspector].[GetWarningLevel];
			
			IF OBJECT_ID('Inspector.GetDebugFlag') IS NOT NULL
			DROP FUNCTION [Inspector].[GetDebugFlag];
				
			IF OBJECT_ID('Inspector.GetServerInfo') IS NOT NULL
			DROP FUNCTION [Inspector].[GetServerInfo];

			--Drop Trigger for recreation
			IF OBJECT_ID('Inspector.PSConfigSync') IS NOT NULL 
			DROP TRIGGER [Inspector].[PSConfigSync];


SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
-- =============================================
-- This trigger is used to keep the table PSConfig up to date with the Modules table
-- =============================================
CREATE TRIGGER [Inspector].[PSConfigSync]
   ON [Inspector].[Modules] 
   AFTER DELETE,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	--Revision date: 23/10/2019

	--Inserts into the Modules table are not handled by this trigger , the Procedure [Inspector].[PopulatePSConfig] is responsible
	--for that as there is additional logic that needs to be applied for Inspector default modules.

	DECLARE @DriveSpaceRetentionPeriodInDays VARCHAR(6);

	SET @DriveSpaceRetentionPeriodInDays = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''DriveSpace'', ''DriveSpaceRetentionPeriodInDays'') AS INT), 90));

	--Update IsActive flag
	UPDATE PS
	SET IsActive = inserted.IsActive
	FROM [Inspector].[PSConfig] PS
	INNER JOIN inserted ON PS.ModuleConfig_Desc = inserted.ModuleConfig_Desc AND PS.Modulename = inserted.Modulename
	WHERE inserted.IsActive != PS.IsActive;


	--Add rows when IsActive is set to 1 and rows do not already exist in PSConfig
	INSERT INTO [Inspector].[PSConfig] ([Servername], [ModuleConfig_Desc], [Modulename], [Procedurename], [Tablename], [StageTablename], [StageProcname], [TableAction], [InsertAction], [RetentionInDays],[IsActive])
	SELECT 
	[ActiveServers].
	[Servername],
	inserted.[ModuleConfig_Desc], 
	[Modulename], 
	[CollectionProcedurename], 
	CASE
		WHEN [inserted].[Modulename] = ''DatabaseGrowths''
		THEN ''DatabaseFileSizes,DatabaseFileSizeHistory''
		WHEN [inserted].[Modulename] = ''ADHocDatabaseCreations''
		THEN ''ADHocDatabaseCreations,ADHocDatabaseSupression''
		WHEN [inserted].[Modulename] = ''AGCheck''
		THEN ''AGCheck,AGPrimaryHistory''
		ELSE REPLACE([CollectionProcedurename],''Insert'','''')
	END AS Tablename,
	CASE
		WHEN [inserted].[Modulename] IN (''AGDatabases'',''DriveSpace'')
		THEN ''PS''+[inserted].[Modulename]+''Stage''
		WHEN [inserted].[Modulename] = ''ADHocDatabaseCreations''
		THEN ''PSADHocDatabaseCreationsStage,PSADHocDatabaseSupressionStage''
		WHEN [inserted].[Modulename] = ''DatabaseGrowths''
		THEN ''PSDatabaseFileSizesStage,PSDatabaseFileSizeHistoryStage''
		WHEN [inserted].[Modulename] = ''AGCheck''
		THEN ''N/A,PSAGPrimaryHistoryStage''
		ELSE NULL
	END AS StageTablename,
	CASE
		WHEN [inserted].[Modulename] IN (''AGDatabases'', ''DriveSpace'', ''DatabaseGrowths'', ''ADHocDatabaseCreations'')
		THEN ''PSGet''+[inserted].[Modulename]+''Stage''
		WHEN [inserted].[Modulename] = ''AGCheck''
		THEN ''N/A,PSGetAGPrimaryHistoryStage''
		ELSE NULL
	END AS StageProcname,
	CASE
		WHEN [inserted].[Modulename] IN (''AGDatabases'',''DriveSpace'')
		THEN ''3''
		WHEN [inserted].[Modulename] IN (''ADHocDatabaseCreations'',''DatabaseGrowths'')
		THEN ''3,3''
		WHEN [inserted].[Modulename] = ''AGCheck''
		THEN ''1,3''
		ELSE ''1''
	END AS TableAction, --1 delete, 2 delete with retention, 3 Stage/merge
	CASE
		WHEN [inserted].[Modulename] IN (''AGDatabases'',''BackupSizesByDay'')
		THEN ''1''
		WHEN [inserted].[Modulename] IN (''ADHocDatabaseCreations'',''AGCheck'')
		THEN ''1,1''
		WHEN [inserted].[Modulename] = ''DatabaseGrowths''
		THEN ''1,2''
		ELSE ''2''
	END AS InsertAction, --1 ALL, 2 Todays'''' data only
	CASE 
		WHEN [inserted].[Modulename] = (''DatabaseGrowths'') THEN @DriveSpaceRetentionPeriodInDays+'',''+@DriveSpaceRetentionPeriodInDays
		WHEN [inserted].[Modulename] = (''DriveSpace'') THEN @DriveSpaceRetentionPeriodInDays
		ELSE NULL 
	END AS RetentionInDays,
	1
	FROM inserted 
	INNER JOIN	
	(
		SELECT 
		[Servername], 
		ISNULL([ModuleConfig_Desc], ''Default'') AS [ModuleConfig_Desc]
		FROM [Inspector].[CurrentServers]
		WHERE IsActive = 1
	) AS ActiveServers ON inserted.[ModuleConfig_Desc] = ActiveServers.[ModuleConfig_Desc]
	WHERE inserted.IsActive = 1
	AND NOT EXISTS (SELECT 1 
						FROM [Inspector].[PSConfig] PS 
						WHERE PS.ModuleConfig_Desc = inserted.ModuleConfig_Desc AND PS.Modulename = inserted.Modulename
						);


	--Remove rows that have been deleted from Modules
	DELETE PS
	FROM [Inspector].[PSConfig] PS
	INNER JOIN deleted ON PS.ModuleConfig_Desc = deleted.ModuleConfig_Desc AND PS.Modulename = deleted.Modulename
	WHERE NOT EXISTS (SELECT 1 
						FROM [Inspector].[Modules] DeletedModule 
						WHERE DeletedModule.ModuleConfig_Desc = deleted.ModuleConfig_Desc 
						AND DeletedModule.Modulename = deleted.Modulename
						);

END'

EXEC(@SQLStatement);

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


IF OBJECT_ID('Inspector.ADHocDatabaseCreationsInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[ADHocDatabaseCreationsInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[ADHocDatabaseCreationsInsert]
AS
BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;

DELETE 
FROM [Inspector].[ADHocDatabaseCreations]
WHERE Servername = @Servername;


INSERT INTO [Inspector].[ADHocDatabaseCreations] (Servername,Log_Date,Databasename,Create_Date)
SELECT
@Servername,
GETDATE(),
name,
Create_date
FROM sys.databases
WHERE 
(name LIKE ''[A-Z]%[0-9]%''
OR name LIKE ''%Restored%''
OR name LIKE ''%Copy%'')
AND [state] = 0 
AND [create_date] > DATEADD(DAY,-7,CAST(GETDATE() AS DATE))
AND [source_database_id] IS NULL 
AND name COLLATE DATABASE_DEFAULT NOT IN (SELECT Databasename 
			  FROM [Inspector].[ADHocDatabaseSupression] 
			  WHERE Servername = @Servername AND Suppress = 1)
ORDER BY create_date ASC;


INSERT INTO [Inspector].[ADHocDatabaseSupression] (Servername, Log_Date, Databasename, Suppress)
SELECT
@Servername,
GETDATE(),
Databasename,
0
FROM [Inspector].[ADHocDatabaseCreations] Creations
WHERE Servername = @Servername
AND NOT EXISTS (SELECT Databasename 
			 FROM [Inspector].[ADHocDatabaseSupression] SuppressList
			 WHERE SuppressList.Servername = @Servername AND SuppressList.Databasename = Creations.Databasename);


IF NOT EXISTS (SELECT Servername
			FROM [Inspector].[ADHocDatabaseCreations] 
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO [Inspector].[ADHocDatabaseCreations] (Servername,Log_Date,Databasename,Create_Date)
			VALUES(@Servername,GETDATE(),''No Ad hoc database creations present'',NULL)
			END

END;';


IF OBJECT_ID('Inspector.AGCheckInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[AGCheckInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[AGCheckInsert]
AS
BEGIN

--Revision date: 24/04/2019

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME
DECLARE @PrimaryHistoryRetention INT = (SELECT ISNULL(NULLIF([Value],''''),90) From [Inspector].[Settings] Where Description = ''AGPrimaryHistoryRetentionPeriodInDays'');

INSERT INTO [Inspector].[AGPrimaryHistory] ([Log_Date], [CollectionDateTime], [Servername], [AGname])
--Is this server now a primary since the last Inspector collection
SELECT 
[Log_Date],
GETDATE(),
@Servername,
[AGname]
FROM sys.dm_hadr_availability_group_states States
INNER JOIN sys.availability_groups Groups ON States.group_id = Groups.group_id
INNER JOIN (SELECT [Log_Date],[AGname]
			FROM [Inspector].[AGCheck]
			WHERE [ReplicaServername] = @Servername
			AND [ReplicaRole] = N''SECONDARY''
			) AS SecondaryCheck ON [Groups].[name] = [SecondaryCheck].[AGname] COLLATE DATABASE_DEFAULT
WHERE States.primary_replica = @Servername
AND NOT EXISTS (SELECT 1 
				FROM [Inspector].[AGPrimaryHistory] 
				WHERE [AGPrimaryHistory].[Log_Date] = [SecondaryCheck].[Log_Date]
				AND [AGPrimaryHistory].[AGname] = [SecondaryCheck].[AGname] 
				AND [AGPrimaryHistory].[Servername] = @Servername)

DELETE 
FROM [Inspector].[AGCheck]
WHERE Servername = @Servername;

DELETE 
FROM [Inspector].[AGPrimaryHistory]
WHERE Servername = @Servername
AND [Log_Date] <= DATEADD(DAY,-@PrimaryHistoryRetention,GETDATE());

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 

INSERT INTO [Inspector].[AGCheck] ([Servername], [Log_Date], [AGname], [State], [ReplicaServername], [Suspended], [SuspendReason], [FailoverReady], [ReplicaRole])
SELECT DISTINCT
@Servername,
GETDATE(),
Groups.name AS AGNAME,
States.synchronization_health_desc,
Replicas.replica_server_name,
ReplicaStates.is_suspended,
ISNULL(ReplicaStates.suspend_reason_desc,''N/A'') AS suspend_reason_desc,
FailoverReady.is_failover_ready,
States.role_desc
FROM sys.availability_groups Groups
INNER JOIN sys.dm_hadr_availability_replica_states as States ON States.group_id = Groups.group_id
INNER JOIN sys.availability_replicas as Replicas ON States.replica_id = Replicas.replica_id
INNER JOIN sys.dm_hadr_database_replica_cluster_states FailoverReady ON Replicas.replica_id = FailoverReady.replica_id
INNER JOIN sys.dm_hadr_database_replica_states as ReplicaStates ON Replicas.replica_id = ReplicaStates.replica_id;

--Update AG Replica count if it has changed
UPDATE [AGCheckConfig]
SET [AGReplicaCount] = [ReplicaCount]
FROM
(
	SELECT 
	Groups.[name],
	COUNT([name]) AS ReplicaCount
	FROM sys.availability_groups Groups
	INNER JOIN sys.availability_replicas as Replicas ON Groups.group_id = Replicas.group_id
	GROUP BY Groups.[name]
) AS ReplicaCounts 
INNER JOIN [Inspector].[AGCheckConfig] ON [AGname] = [ReplicaCounts].[name] COLLATE DATABASE_DEFAULT
WHERE [AGCheckConfig].[AGReplicaCount] != ReplicaCount;


--Insert AG Replica counts and base Failover ready node count config count 
INSERT INTO [Inspector].[AGCheckConfig] ([AGname],[AGReplicaCount],[FailoverReadyNodeCount])
SELECT 
Groups.[name],
COUNT([name]),
2
FROM sys.availability_groups Groups
INNER JOIN sys.availability_replicas as Replicas ON Groups.group_id = Replicas.group_id
WHERE NOT EXISTS (SELECT 1 FROM [Inspector].[AGCheckConfig] WHERE [AGname] = Groups.[name] COLLATE DATABASE_DEFAULT)
GROUP BY Groups.[name];

END 
ELSE 
BEGIN

INSERT INTO [Inspector].[AGCheck] ([Servername], [Log_Date], [AGname], [State])
SELECT
@Servername,
GETDATE(),
''HADR IS NOT ENABLED ON THIS SERVER OR YOU HAVE NO AVAILABILITY GROUPS'',
''N/A''

END
END;';


IF OBJECT_ID('Inspector.DatabaseFilesInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseFilesInsert] AS;');

SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
ALTER PROCEDURE [Inspector].[DatabaseFilesInsert]
AS
BEGIN

--Revision date: 06/04/2019

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME
DECLARE @DataDrives VARCHAR(255) = (SELECT NULLIF([Value],'''') FROM [Inspector].[Settings] WHERE [Description] = ''DataDrives'');
DECLARE @LogDrives VARCHAR(255) = (SELECT NULLIF([Value],'''') FROM [Inspector].[Settings] WHERE [Description] = ''LogDrives'');

IF OBJECT_ID(''tempdb.dbo.#SplitDrives'') IS NOT NULL 
DROP TABLE #SplitDrives;

CREATE TABLE #SplitDrives (
DriveType CHAR(4),
DriveLabel NVARCHAR(20)
);


DELETE 
FROM [Inspector].[DatabaseFiles]
WHERE Servername = @Servername;

INSERT INTO #SplitDrives (DriveType,DriveLabel)
'+CASE 
	WHEN @Compatibility = 0 THEN 'SELECT ''Data'',[StringElement] FROM master.dbo.fn_SplitString(@DataDrives,'','')'
	ELSE 'SELECT ''Data'',[value] FROM STRING_SPLIT(@DataDrives,'','')'
  END +'
UNION ALL
'+CASE 
	WHEN @Compatibility = 0 THEN 'SELECT ''Log'',[StringElement] FROM master.dbo.fn_SplitString(@LogDrives,'','')'
	ELSE 'SELECT ''Log'',[value] FROM STRING_SPLIT(@LogDrives,'','')'
  END +';


--Remove any duplicate drive letters i.e C:\ labelled as both Data and Log
DELETE FROM #SplitDrives
WHERE DriveLabel IN 
(
	SELECT DriveLabel 
	FROM #SplitDrives DataDrives
	WHERE DriveType = ''Data'' 
	INTERSECT
	SELECT DriveLabel
	FROM #SplitDrives LogDrives
	WHERE DriveType = ''Log'' 
);


INSERT INTO  [Inspector].[DatabaseFiles] (Servername,Log_Date,Databasename,FileType,FilePath)
SELECT
@Servername,
GETDATE(),
DB_NAME(database_id),
type_desc,
physical_name 
FROM sys.master_files
INNER JOIN (SELECT DriveLabel FROM #SplitDrives WHERE DriveType = ''Data'') AS DataDrives ON physical_name LIKE DriveLabel+''%''
WHERE physical_name LIKE ''%.ldf''

UNION ALL

SELECT
@Servername,
GETDATE(),
DB_NAME(database_id),
type_desc,
physical_name 
FROM sys.master_files
INNER JOIN (SELECT DriveLabel FROM #SplitDrives WHERE DriveType = ''Log'') AS DataDrives ON physical_name LIKE DriveLabel+''%''
WHERE physical_name LIKE ''%.mdf'';


IF NOT EXISTS (SELECT Servername
			FROM [Inspector].[DatabaseFiles]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO [Inspector].[DatabaseFiles] (Servername,Log_Date,Databasename,FileType,FilePath)
			VALUES(@Servername,GETDATE(),''No Database File issues present'',NULL,NULL)
			END
			
END;'


EXEC(@SQLStatement);


IF OBJECT_ID('Inspector.DatabaseStatesInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseStatesInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseStatesInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM [Inspector].[DatabaseStates]
WHERE Servername = @Servername;

INSERT INTO [Inspector].[DatabaseStates] (Servername,Log_Date,DatabaseState,Total,DatabaseNames)
SELECT 
@Servername,
GETDATE(),
state_desc,
COUNT(state_desc),
CASE WHEN state_desc IN (''ONLINE'',''SNAPSHOT (less than 10 days old)'') THEN ''-'' ELSE DBName END
FROM 
(
    SELECT CASE WHEN source_database_id IS NOT NULL AND create_date < DATEADD(DAY,-10,GETDATE()) THEN ''SNAPSHOT (more than 10 days old)''
    WHEN source_database_id IS NOT NULL AND create_date > DATEADD(DAY,-10,GETDATE()) THEN ''SNAPSHOT (less than 10 days old)'' 
    WHEN EXISTS (SELECT 1 FROM msdb.dbo.log_shipping_secondary_databases Logshipped WHERE Logshipped.secondary_database = Databases.name) AND Databases.state = 1 THEN ''LOG SHIPPED RESTORING''
    WHEN EXISTS (SELECT 1 FROM msdb.dbo.log_shipping_secondary_databases Logshipped WHERE Logshipped.secondary_database = Databases.name) AND Databases.is_in_standby = 1 THEN ''LOG SHIPPED STANDBY''
    ELSE state_desc END AS state_desc,
    STUFF(COALESCE(LogShipped.Databasename,NonOnlineDBs.Databasename,OldSnapshotDBs.Databasename,''''),1,2,'''') As DBName
    FROM sys.databases Databases
    CROSS APPLY (SELECT '' , '' + QUOTENAME(name) 
    			 FROM sys.databases NonOnlineDBs
    			 WHERE Databases.state_desc = NonOnlineDBs.state_desc
    			 AND (NonOnlineDBs.state_desc != ''Online'' AND source_database_id IS NULL)
    			 AND NOT EXISTS (SELECT 1 FROM msdb.dbo.log_shipping_secondary_databases Logshipped WHERE Logshipped.secondary_database = NonOnlineDBs.name)
    			 FOR XML PATH('''')) NonOnlineDBs (Databasename)
    CROSS APPLY (SELECT '' , '' + QUOTENAME(name) 
    			 FROM sys.databases OldSnapshotDBs
    			 WHERE Databases.state_desc = OldSnapshotDBs.state_desc
    			 AND source_database_id IS NOT NULL 
    			 AND create_date < DATEADD(DAY,-10,GETDATE())
    			 FOR XML PATH('''')) OldSnapshotDBs (Databasename)
    CROSS APPLY (SELECT '' , '' + QUOTENAME(secondary_database)
    			 FROM msdb.dbo.log_shipping_secondary_databases Logshipped 
				 INNER JOIN sys.databases DatabasesLS ON Logshipped.secondary_database = DatabasesLS.name
				 WHERE Databases.state_desc = DatabasesLS.state_desc
    			 FOR XML PATH('''')) LogShipped (Databasename)
    ) DatabaseStates
GROUP BY state_desc,DBName
ORDER BY COUNT(state_desc) DESC

END;';


IF OBJECT_ID('Inspector.DriveSpaceInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DriveSpaceInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DriveSpaceInsert] 
AS
BEGIN

/**************************
Revision date: 01/05/2021

DistinctDrives derived table updated to show all database_id and file_id combinations grouped by file path.
Row number is applied so that we can filter just one database_id and file_id combination per file path and then these 
combinations are passed to the sys.dm_os_volume_stats system TVF , the reason for the filtering within the derived table is
to reduce the number of executions performed by the TVF because on instances with lots of databases this can slow execution.

**************************/

DECLARE @Retention INT = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''DriveSpace'', ''DriveSpaceRetentionPeriodInDays'') AS INT), 90));

DELETE FROM [Inspector].[DriveSpace] 
WHERE Log_Date < DATEADD(DAY,-@Retention,GETDATE())
AND Servername = @@SERVERNAME;


INSERT INTO [Inspector].[DriveSpace] (Servername, Log_Date, Drive, Capacity_GB, AvailableSpace_GB, UsedSpaceGB,PrevUsedSpace_GB)
SELECT 
LatestDriveSpace.Servername,
LatestDriveSpace.Log_Date,
LatestDriveSpace.Drive,
LatestDriveSpace.Capacity_GB,
LatestDriveSpace.AvailableSpace_GB,
CAST(LatestDriveSpace.[Capacity_GB]-LatestDriveSpace.[AvailableSpace_GB] AS DECIMAL(10,2)),
ISNULL(LastRecordedSpace.PrevUsedSpace_GB,CAST(LatestDriveSpace.[Capacity_GB]-LatestDriveSpace.[AvailableSpace_GB] AS DECIMAL(10,2))) AS PrevUsedSpace_GB
FROM 
(
	SELECT DISTINCT
	@@SERVERNAME AS Servername,
	GETDATE() AS Log_Date,
	CAST(UPPER(volumestats.volume_mount_point) AS NVARCHAR(128)) AS Drive,
	CAST((CAST(volumestats.total_bytes AS DECIMAL(20,2)))/1024/1024/1024 AS DECIMAL(10,2)) Capacity_GB,
	CAST((CAST(volumestats.available_bytes AS DECIMAL(20,2)))/1024/1024/1024 AS DECIMAL(10,2)) AS AvailableSpace_GB
	FROM 
	(
		SELECT 
		[database_id],
		[file_id],
		ROW_NUMBER() OVER (PARTITION BY SUBSTRING(physical_name,1,LEN(physical_name)-CHARINDEX(''\'',REVERSE(physical_name))+1) 
							ORDER BY SUBSTRING(physical_name,1,LEN(physical_name)-CHARINDEX(''\'',REVERSE(physical_name))+1) ASC) AS RowNum
		FROM sys.master_files
		WHERE database_id IN (SELECT database_id FROM sys.databases WHERE state = 0)
	) DistinctDrives
	CROSS APPLY sys.dm_os_volume_stats([DistinctDrives].[database_id],[DistinctDrives].[file_id]) volumestats
	WHERE DistinctDrives.RowNum = 1
) AS LatestDriveSpace
OUTER APPLY (SELECT TOP (1) [UsedSpaceGB] AS PrevUsedSpace_GB
				FROM [Inspector].[DriveSpace] 
				WHERE LatestDriveSpace.Servername = DriveSpace.Servername
				AND LatestDriveSpace.[Drive] = DriveSpace.[Drive]
				ORDER BY [Log_Date] DESC) LastRecordedSpace;

END';


IF OBJECT_ID('Inspector.PopulateModuleWarningLevel') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[PopulateModuleWarningLevel] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PopulateModuleWarningLevel] 
AS 
BEGIN

--Revision date: 16/03/2019

/*
These modules are excluded from warning level control:
BackupsCheck
DriveSpace
TopFiveDatabases
DatabaseGrowthCheck
BackupSizesCheck
*/

	INSERT INTO [Inspector].[ModuleWarningLevel] ([ModuleConfig_Desc],[Module])
	SELECT [ModuleConfig_Desc],[Modulename]
	FROM [Inspector].[Modules] [ModulesList]
	WHERE NOT EXISTS (SELECT 1 
					FROM [Inspector].[ModuleWarningLevel] 
					WHERE [ModulesList].[ModuleConfig_Desc] = [ModuleWarningLevel].[ModuleConfig_Desc]
					AND [ModulesList].[Modulename] = [ModuleWarningLevel].[Module]
					)
   UNION  
   SELECT 
   [Modules].[ModuleConfig_Desc],
   [CatalogueModulesList].[Module]
   FROM [Inspector].[Modules]
   CROSS JOIN (SELECT [Module] FROM (VALUES(''CatalogueMissingLogins''),(''CatalogueDroppedTables''),(''CatalogueDroppedDatabases'')) ModuleList(Module)) AS CatalogueModulesList
   WHERE NOT EXISTS (SELECT 1 
					FROM [Inspector].[ModuleWarningLevel] 
					WHERE [ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc] 
					AND [Module] = [CatalogueModulesList].[Module]);

END';

--Run Proc for the first time to populate the Warning Level table
EXEC sp_executesql N'EXEC [Inspector].[PopulateModuleWarningLevel];';


IF OBJECT_ID('Inspector.FailedAgentJobsInsert') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[FailedAgentJobsInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[FailedAgentJobsInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM [Inspector].[FailedAgentJobs]
WHERE Servername = @Servername;

INSERT INTO [Inspector].[FailedAgentJobs] (Servername,Log_Date,Jobname,LastStepFailed,LastFailedDate,LastError)
SELECT 
@Servername,
GETDATE(),
Jobs.name,
JobHistory.step_id,
JobHistory.failedrundate,
CAST(JobHistory.lasterror AS VARCHAR(250))
FROM msdb.dbo.sysjobs Jobs
--Get the most recent Failure Datetime for each failed job within @FromDate and @ToDate
CROSS APPLY (SELECT TOP 1 JobHistory.step_id,JobHistory.run_date,
					CASE JobHistory.run_date WHEN 0 THEN NULL ELSE
					CONVERT(DATETIME, 
								STUFF(STUFF(CAST(JobHistory.run_date AS NCHAR(8)), 7, 0, ''-''), 5, 0, ''-'') + N'' '' + 
								STUFF(STUFF(SUBSTRING(CAST(1000000 + JobHistory.run_time AS NCHAR(7)), 2, 6), 5, 0, '':''), 3, 0, '':''), 
								120) END AS [failedrundate] ,
								[message] AS lasterror
					FROM msdb.dbo.sysjobhistory JobHistory
					WHERE 	run_status = 0 
					AND  Jobs.job_id = JobHistory.job_id
					ORDER BY 
					[failedrundate] DESC,
					[step_id] DESC) JobHistory
								
WHERE Jobs.enabled = 1
AND JobHistory.failedrundate > CAST(DATEADD(DAY,-1,CAST(GETDATE() AS DATE)) AS DATETIME)
--Check that each job has not succeeded since the last failure
AND NOT EXISTS (SELECT [LastSuccessfulRunDate] 
				FROM(
				SELECT CASE JobHistory.run_date WHEN 0 THEN NULL ELSE
				CONVERT(DATETIME, 
				STUFF(STUFF(CAST(JobHistory.run_date AS NCHAR(8)), 7, 0, ''-''), 5, 0, ''-'') + N'' '' + 
				STUFF(STUFF(SUBSTRING(CAST(1000000 + JobHistory.run_time AS NCHAR(7)), 2, 6), 5, 0, '':''), 3, 0, '':''), 
					120) END AS [LastSuccessfulRunDate] 
				FROM msdb.dbo.sysjobhistory JobHistory
				WHERE 	run_status = 1
				AND  Jobs.job_id = JobHistory.job_id
						) LastSuccessfulJobrun
WHERE LastSuccessfulJobrun.[LastSuccessfulRunDate] > JobHistory.[failedrundate])
--Ensure that the job is not currently running
AND NOT EXISTS (SELECT name
				FROM msdb.dbo.sysjobactivity JobActivity
				WHERE Jobs.job_id = JobActivity.job_id 
				AND start_execution_date > DATEADD(MINUTE,-30,GETDATE())
				AND stop_execution_date is null
					) 
--Only show failed jobs where the Failed step is NOT configured to quit reporting success on error
AND NOT EXISTS (SELECT 1
				FROM msdb.dbo.sysjobsteps ReportingSuccessSteps
				WHERE Jobs.job_id = ReportingSuccessSteps.job_id
				AND JobHistory.step_id = ReportingSuccessSteps.step_id
				AND on_fail_action = 1 -- quit job reporting success
				)
				
ORDER BY name ASC

IF NOT EXISTS (SELECT Servername
			FROM [Inspector].[FailedAgentJobs]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO [Inspector].[FailedAgentJobs] (Servername,Log_Date,Jobname,LastStepFailed,LastFailedDate,LastError)
			VALUES(@Servername,GETDATE(),''No Failed Jobs present'',NULL,NULL,NULL)
			END

END;';


IF OBJECT_ID('Inspector.LoginAttemptsInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[LoginAttemptsInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[LoginAttemptsInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM [Inspector].[LoginAttempts]
WHERE Servername = @Servername;
 
IF OBJECT_ID(''tempdb.dbo.#Errors'') IS NOT NULL
DROP TABLE #Errors; 

CREATE TABLE #Errors  
(
Logdate DATETIME,
Processinfo VARCHAR(30),
Text VARCHAR(255)
);

DECLARE @StartTime DATETIME = DATEADD(DAY,-1,GETDATE())

INSERT INTO #Errors ([Logdate],[Processinfo],[Text])
EXEC xp_readerrorlog 0, 1, N''FAILED'',N''login'',@StartTime,NULL;

INSERT INTO [Inspector].[LoginAttempts] (Servername,Log_Date,Username,Attempts,LastErrorDate,LastError)
SELECT 
@Servername,
GETDATE(), 
REPLACE(LoginErrors.Username,'''''''',''''),
CAST(LoginErrors.Attempts AS NVARCHAR(6)),
LatestDate.Logdate,
LatestDate.LastError
FROM (
SELECT SUBSTRING(Text,PATINDEX(''%''''%''''%'',Text),CHARINDEX(''.'',Text)-(PATINDEX(''%''''%''''%'',Text))) as Username,Count(*) Attempts
FROM #Errors Errors
GROUP BY SUBSTRING(Text,PATINDEX(''%''''%''''%'',Text),CHARINDEX(''.'',Text)-(PATINDEX(''%''''%''''%'',Text)))
) LoginErrors
CROSS APPLY (SELECT TOP 1 Logdate,Text as LastError
		  FROM #Errors LatestDate
		  WHERE  LoginErrors.Username = SUBSTRING(Text,Patindex(''%''''%''''%'',Text),charindex(''.'',Text)-(Patindex(''%''''%''''%'',Text)))
		  ORDER by Logdate DESC) LatestDate

ORDER BY Attempts DESC

IF NOT EXISTS (SELECT Servername
			FROM [Inspector].[LoginAttempts]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO [Inspector].[LoginAttempts] (Servername,Log_Date,Username,Attempts,LastErrorDate,LastError)
			VALUES(@Servername,GETDATE(),''No Failed Logins present'',NULL,NULL,NULL)
			END

END;';


IF OBJECT_ID('Inspector.JobOwnerInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[JobOwnerInsert] AS;');

SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
ALTER PROCEDURE [Inspector].[JobOwnerInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME
DECLARE @AgentjobOwnerExclusions VARCHAR(255) = (SELECT REPLACE([Value],'' '','''') FROM [Inspector].[Settings] WHERE [Description] = ''AgentJobOwnerExclusions'')

DELETE 
FROM [Inspector].[JobOwner]
WHERE Servername = @Servername;

INSERT INTO [Inspector].[JobOwner] (Servername,Log_Date,Job_ID,Jobname)
SELECT 
@Servername,
GETDATE(),
jobs.job_id,
jobs.[name] 
FROM msdb.dbo.sysjobs jobs
INNER join master.sys.syslogins logins ON jobs.owner_sid = logins.sid
WHERE logins.name NOT IN ('+CASE WHEN @Compatibility = 0 
					   THEN 'SELECT [StringElement]  
						   FROM master.dbo.fn_SplitString(@AgentjobOwnerExclusions,'','')'
					   ELSE 'SELECT [value]  
						   FROM STRING_SPLIT(@AgentjobOwnerExclusions,'','')'
					   END +
						  ')
AND jobs.enabled = 1

IF NOT EXISTS (SELECT Servername
			FROM [Inspector].[JobOwner]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO [Inspector].[JobOwner] (Servername,Log_Date,Job_ID,Jobname)
			VALUES(@Servername,GETDATE(),NULL,''No Job Owner issues present'')
			END

END;';

EXEC(@SQLStatement);


IF OBJECT_ID('Inspector.TopFiveDatabasesInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[TopFiveDatabasesInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[TopFiveDatabasesInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM [Inspector].[TopFiveDatabases]
WHERE Servername = @Servername;

INSERT INTO [Inspector].[TopFiveDatabases] (Servername,Log_Date,Databasename,TotalSize_MB)
SELECT TOP 5 
@Servername,
GETDATE(),
Databasename,
[TotalSize(MB)]
FROM 
(
    SELECT DBs.name AS Databasename,
    SUM((CAST(DBFiles.size AS BIGINT)*8)/1024 ) AS [TotalSize(MB)] 
    FROM [sys].[master_files] DBFiles
    INNER JOIN sys.databases DBs ON DBFiles.database_id = DBs.database_id
    GROUP BY DBs.name
) Sizes
ORDER BY [TotalSize(MB)] DESC

END;';


IF OBJECT_ID('Inspector.BackupsCheckInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[BackupsCheckInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[BackupsCheckInsert]
AS
BEGIN

--Revision date: 11/09/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @FullBackupThreshold INT = (Select [Value] FROM [Inspector].[Settings] WHERE Description = ''FullBackupThreshold'')

DELETE 
FROM [Inspector].[BackupsCheck]
WHERE Servername = @Servername;

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 


IF OBJECT_ID(''tempdb.dbo.#DatabaseList'') IS NOT NULL
DROP TABLE #DatabaseList;

CREATE TABLE #DatabaseList
(
Database_id INT,
Servername NVARCHAR(128),
Log_Date DATETIME,
Databasename NVARCHAR(128),
AGname NVARCHAR(128),
[State] TINYINT,
Source_database_id INT,
IsFullRecovery BIT,
IsSystemDB BIT,
backup_preference NVARCHAR(60)
);

IF OBJECT_ID(''tempdb.dbo.#BackupAggregation'') IS NOT NULL
DROP TABLE #BackupAggregation;


CREATE TABLE #BackupAggregation
(
Database_id INT,
Databasename NVARCHAR(128),
[Full] DATETIME,
[Diff] DATETIME,
[Log] DATETIME
);

INSERT INTO #DatabaseList ([Database_id],[Servername],[Log_Date],[Databasename],[AGname],[State],[Source_database_id],[IsFullRecovery],[IsSystemDB],[backup_preference])
SELECT DISTINCT
database_id,
@Servername,
GETDATE(),
sys.databases.name,
AG.name,
[state],
source_database_id,
CASE WHEN recovery_model_desc = ''FULL'' THEN 1 WHEN recovery_model_desc IS NULL THEN 1 ELSE 0 END AS IsFullRecovery,
CASE WHEN database_id <= 4 THEN 1 ELSE 0 END AS IsSystemDB,
UPPER(automated_backup_preference_desc) AS backup_preference
FROM sys.databases 
INNER JOIN sys.availability_replicas AR ON sys.databases.replica_id = AR.replica_id
INNER JOIN sys.availability_groups AG ON AR.group_id = AG.group_id 
WHERE database_id != 2
AND [state] = 0 
AND source_database_id IS NULL

UNION ALL 

SELECT
database_id,
@Servername,
GETDATE(),
sys.databases.name,
NULL,
[state],
source_database_id,
CASE WHEN recovery_model_desc = ''FULL'' THEN 1 WHEN recovery_model_desc IS NULL THEN 1 ELSE 0 END AS IsFullRecovery,
CASE WHEN database_id <= 4 THEN 1 ELSE 0 END AS IsSystemDB,
N''Non AG'' AS backup_preference
FROM sys.databases 
WHERE database_id != 2
AND [state] = 0 
AND source_database_id IS NULL
and replica_id is NULL
ORDER BY database_id


INSERT INTO #BackupAggregation ([Database_id],[Databasename],[Full],[Diff],[Log])
SELECT Database_id,database_name, [D], [I], [L]    
FROM 
(SELECT [Database_id],[backuplog].[database_name],[backuplog].[type],MAX([backuplog].[backup_finish_date]) AS backup_finish_date                                   
FROM msdb.dbo.backupset backuplog
INNER JOIN #DatabaseList ON #DatabaseList.Databasename = backuplog.database_name  
WHERE backup_finish_date > DATEADD(DAY,-@FullBackupThreshold,CAST(GETDATE() AS DATE))
GROUP BY Database_id,backuplog.database_name,backuplog.type ) p
PIVOT( MAX(backup_finish_date) FOR type IN ([D],[I],[L])) d
ORDER BY Database_id ASC

INSERT INTO [Inspector].[BackupsCheck] ([Servername],[Log_Date],[Databasename],[AGname],[FULL],[DIFF],[LOG],[IsFullRecovery],[IsSystemDB],[primary_replica],[backup_preference])
SELECT 
[Servername],
[Log_Date],
#DatabaseList.[Databasename],
COALESCE(#DatabaseList.AGname,''Not in an AG'') AS AGname,
ISNULL([Full],''19000101'') AS [FULL],
ISNULL([Diff],''19000101'') AS [DIFF],
ISNULL([Log],''19000101'') AS [LOG],
[IsFullRecovery],
[IsSystemDB],
CASE WHEN #DatabaseList.[AGname] IS NULL THEN @@servername ELSE primary_replica END AS primary_replica,
[backup_preference]
FROM #DatabaseList
LEFT JOIN #BackupAggregation ON #DatabaseList.Database_id = #BackupAggregation.Database_id
LEFT JOIN (SELECT Groups.name,States.primary_replica 
		   FROM master.sys.dm_hadr_availability_group_states States 
		   INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id WHERE States.group_id = Groups.group_id
		   GROUP BY Groups.name,States.primary_replica) AS primary_replicas ON primary_replicas.primary_replica = #DatabaseList.Servername AND #DatabaseList.AGname = primary_replicas.name 
WHERE ([State] = 0 AND Source_database_id IS NULL) 

END 
ELSE 
BEGIN 

INSERT INTO [Inspector].[BackupsCheck] ([Servername],[Log_Date],[Databasename],[AGname],[FULL],[DIFF],[LOG],[IsFullRecovery],[IsSystemDB],[primary_replica],[backup_preference])  
SELECT DISTINCT @Servername,GETDATE(),dbs.name,@Servername +''(Non AG)'' AS AGname,ISNULL([D],''19000101''),ISNULL([I],''19000101''),ISNULL([L],''19000101''),
CASE WHEN dbs.recovery_model_desc = ''FULL'' THEN 1 ELSE 0 END,
CASE WHEN dbs.database_id <= 4 THEN 1 ELSE 0 END AS IsSystemDB,
@Servername AS primary_replica,
N''Non AG'' AS backup_preference
FROM 
(SELECT [backuplog].[database_name],[backuplog].[type],MAX(backuplog.backup_finish_date) AS backup_finish_date                                     
FROM msdb.dbo.backupset backuplog                         
WHERE backup_finish_date > DATEADD(DAY,-@FullBackupThreshold,CAST(GETDATE() AS DATE))
GROUP BY backuplog.database_name,backuplog.type ) p
PIVOT( MAX(backup_finish_date) FOR type IN ([D],[I],[L])) d
RIGHT JOIN sys.databases dbs ON d.database_name = dbs.name
WHERE database_id != 2
AND [state] = 0 
AND source_database_id IS NULL
END

			
END;';


IF OBJECT_ID('Inspector.DatabaseGrowthsInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseGrowthsInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseGrowthsInsert]
AS

--Revision date: 06/06/2019

     SET NOCOUNT ON;

     BEGIN

        DECLARE @Servername NVARCHAR(128)= @@Servername;
	    DECLARE @LastUpdated DATETIME = GETDATE();
		DECLARE @Retention INT = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@Servername, ''DatabaseGrowths'', ''DatabaseGrowthRetentionPeriodInDays'') AS INT), 90));
		DECLARE @ScopeIdentity INT

--Insert any databases that are present on the serverbut not present in [Inspector].[DatabaseFileSizes]
         IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
             BEGIN
                 INSERT INTO [Inspector].[DatabaseFileSizes]
                 ([Servername],
                  [Database_id],
                  [Database_name],
                  [OriginalDateLogged],
                  [OriginalSize_MB],
                  [Type_desc],
                  [File_id],				
                  [Filename],
                  [PostGrowthSize_MB],
                  [GrowthRate],
                  [Is_percent_growth],
                  [NextGrowth]
                 )

                 SELECT    @Servername,
                           [Masterfiles].[database_id],
                           DB_NAME([Masterfiles].[database_id]) AS [Database_name],
                           @LastUpdated AS [OriginalDateLogged],
                           CAST([Masterfiles].[size] AS BIGINT) * 8 / 1024 AS [OriginalSize_MB],
                           [Masterfiles].[type_desc],
                           [Masterfiles].[file_id],						   
                           [Masterfiles].[physical_name],
                           CAST([Masterfiles].[size] AS BIGINT) * 8 / 1024 AS [PostGrowthSize_MB],
						   CASE [Masterfiles].[is_percent_growth]
								WHEN 0
								THEN CASE --handle divide by zero by defaulting to a 1
										WHEN growth = 0 
										THEN 1 
										ELSE ([Masterfiles].[growth] * 8) / 1024
									 END
								WHEN 1
								THEN CASE --handle divide by zero by defaulting to a 1
										WHEN (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100 = 0 
										THEN 1
										ELSE (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100
									 END
						   END AS [GrowthRate_MB],		
                           [Masterfiles].[is_percent_growth],
						   CASE [Masterfiles].[is_percent_growth]
								WHEN 0
								THEN CASE --handle divide by zero by defaulting to a 1
										WHEN growth = 0 
										THEN ((CAST([size] AS BIGINT) * 8)/ 1024) + 1
										ELSE ((CAST([size] AS BIGINT) * 8) / 1024) + ([growth] * 8) / 1024
									 END
								WHEN 1
								THEN CASE 
										WHEN ((CAST([size] AS BIGINT) * 8) / 1024) + (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100 = 0
										THEN ((CAST([size] AS BIGINT) * 8)/ 1024) + 1 
										ELSE ((CAST([size] AS BIGINT) * 8) / 1024) + (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100
									 END
                        END [NextGrowth]													
                 FROM      [sys].[master_files] [Masterfiles]
                           LEFT JOIN
                 (
                     SELECT DB_ID([ADC].[database_name]) AS [Database_ID]
                     FROM   [sys].[dm_hadr_availability_group_states] [ST]
                            INNER JOIN [sys].[availability_databases_cluster] [ADC] ON [ST].[group_id] = [ADC].[group_id]
                     WHERE  [primary_replica] = @@Servername
                 ) [DatabaseList] ON [DatabaseList].[Database_ID] = [Masterfiles].[database_id]
                 WHERE [Masterfiles].[database_id] > 3
                       AND [type_desc] != ''LOG''
                       AND NOT EXISTS
                 (
                     SELECT [Database_id]
                     FROM   [Inspector].[DatabaseFileSizes] [DatabaseFileSizes]
                     WHERE  [Servername] = @Servername
                            AND DB_NAME([Masterfiles].[database_id]) = [DatabaseFileSizes].[Database_name]
                            AND [Masterfiles].[file_id] = [DatabaseFileSizes].[File_id]
                 )


         END
             ELSE
             BEGIN
                 INSERT INTO [Inspector].[DatabaseFileSizes]
                 ([Servername],
                  [Database_id],
                  [Database_name],
                  [OriginalDateLogged],
                  [OriginalSize_MB],
                  [Type_desc],
                  [File_id],
                  [Filename],
                  [PostGrowthSize_MB],
                  [GrowthRate],
                  [Is_percent_growth],
                  [NextGrowth]
                 )

                 SELECT @Servername,
                        [Masterfiles].[database_id],
                        DB_NAME([Masterfiles].[database_id]) AS [Database_name],
                        GETDATE() AS [OriginalDateLogged],
                        CAST([Masterfiles].[size] AS BIGINT) * 8 / 1024 AS [OriginalSize_MB],
                        [Masterfiles].[type_desc],
                        [Masterfiles].[file_id],
                        [Masterfiles].[physical_name],
                        CAST([Masterfiles].[size] AS BIGINT) * 8 / 1024 AS [PostGrowthSize_MB],
						CASE [Masterfiles].[is_percent_growth]
							WHEN 0
							THEN CASE --handle divide by zero by defaulting to a 1
									WHEN growth = 0 
									THEN 1 
									ELSE ([Masterfiles].[growth] * 8) / 1024
								 END
							WHEN 1
							THEN CASE --handle divide by zero by defaulting to a 1
									WHEN (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100 = 0 
									THEN 1
									ELSE (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100
								 END
						END AS [GrowthRate_MB],			
                        [Masterfiles].[is_percent_growth],
						CASE [Masterfiles].[is_percent_growth]
							WHEN 0
								THEN CASE --handle divide by zero by defaulting to a 1
										WHEN growth = 0 
										THEN ((CAST([size] AS BIGINT) * 8)/ 1024) + 1
										ELSE ((CAST([size] AS BIGINT) * 8) / 1024) + ([growth] * 8) / 1024
									 END
							WHEN 1
							THEN CASE 
									WHEN ((CAST([size] AS BIGINT) * 8) / 1024) + (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100 = 0
									THEN ((CAST([size] AS BIGINT) * 8)/ 1024) + 1 
									ELSE ((CAST([size] AS BIGINT) * 8) / 1024) + (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100
								 END
                        END [NextGrowth] 													
                 FROM   [sys].[master_files] [Masterfiles]
                 WHERE  [Masterfiles].[database_id] > 3
                        AND [type_desc] != ''LOG''
                        AND NOT EXISTS
                 (
                     SELECT [Database_id]
                     FROM   [Inspector].[DatabaseFileSizes] [DatabaseFileSizes]
                     WHERE  [Servername] = @Servername
                            AND DB_NAME([Masterfiles].[database_id]) = [DatabaseFileSizes].[Database_name]
                            AND [Masterfiles].[file_id] = [DatabaseFileSizes].[File_id]
                 )

         END

--Remove any databases that have been dropped from SQL but still present in [Inspector].[DatabaseFileSizes]
         DELETE [Sizes]
         FROM [Inspector].[DatabaseFileSizes] [Sizes]
              LEFT JOIN [sys].[databases] [DatabasesList] ON [Sizes].[Database_name] = [DatabasesList].[name] COLLATE DATABASE_DEFAULT
         WHERE  [Sizes].[Servername] = @Servername
                AND [DatabasesList].[database_id] IS NULL;

--Ensure that the Database_Id column is synced in the base table as a database may have been dropped and restored as a new Database_id
         UPDATE [Sizes]
         SET
            [Database_id] = [DatabasesList].[database_id],
			[LastUpdated] = @LastUpdated
         FROM   [Inspector].[DatabaseFileSizes] [Sizes]
                INNER JOIN [sys].[databases] [DatabasesList] ON [Sizes].[Database_name] = [DatabasesList].[name] COLLATE DATABASE_DEFAULT
         WHERE  [Sizes].[Servername] = @Servername
                AND [DatabasesList].[database_id] != [Sizes].[Database_id];

--Keep the base table in sync by checking if the growth rates have changed - if they have then update the base table
         UPDATE [Sizes]
         SET
            [GrowthRate] = [GrowthCheck].[GrowthRate_MB],
            [Is_percent_growth] = [GrowthCheck].[is_percent_growth],
			[NextGrowth] = ([Sizes].[PostGrowthSize_MB]+[GrowthCheck].[GrowthRate_MB]),
			[LastUpdated] = @LastUpdated
         FROM
         (
             SELECT [Masterfiles].[database_id],
                    [Masterfiles].[file_id],
                    CASE [Masterfiles].[is_percent_growth]
                        WHEN 0
                        THEN CASE --handle divide by zero by defaulting to a 1
								WHEN growth = 0 
								THEN 1 
								ELSE ([Masterfiles].[growth] * 8) / 1024
							 END
                        WHEN 1
                        THEN CASE --handle divide by zero by defaulting to a 1
								WHEN (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100 = 0 
								THEN 1
								ELSE (((CAST([size] AS BIGINT) * 8) / 1024) * [growth]) / 100
							 END
                    END AS [GrowthRate_MB],			--IN MB , The physical value expressed as a number
                    [Masterfiles].[is_percent_growth]
             FROM   [sys].[master_files] [Masterfiles]
                    INNER JOIN [sys].[databases] [DatabasesList] ON [Masterfiles].[database_id] = [DatabasesList].[database_id]
             WHERE  [Masterfiles].[database_id] > 3
                    AND [type_desc] != ''LOG''
                    AND [DatabasesList].state = 0
         ) [GrowthCheck]
         INNER JOIN [Inspector].[DatabaseFileSizes] [Sizes] ON [GrowthCheck].[database_id] = [Sizes].[Database_id]
                                                                                      AND [Sizes].[File_id] = [GrowthCheck].[file_id]
         WHERE(([GrowthCheck].[GrowthRate_MB] != [Sizes].[GrowthRate])
               OR ([GrowthCheck].[is_percent_growth] != [Sizes].[Is_percent_growth]))
              AND [Servername] = @Servername;


--If database has shrunk in size update the PostGrowthSize_MB column and NextGrowth
         UPDATE [Sizes]
         SET
			[PostGrowthSize_MB] = [ShrunkDatabases].[size],
			[NextGrowth] = ([ShrunkDatabases].[size]+[Sizes].[GrowthRate]),
			[LastUpdated] = @LastUpdated
         FROM
         (
             SELECT [Masterfiles].[database_id],
                    [Masterfiles].[file_id],
					(CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024 AS size
             FROM   [sys].[master_files] [Masterfiles]
                    INNER JOIN [sys].[databases] [DatabasesList] ON [Masterfiles].[database_id] = [DatabasesList].[database_id]
             WHERE  [Masterfiles].[database_id] > 3
                    AND [type_desc] != ''LOG''
                    AND [DatabasesList].state = 0
         ) [ShrunkDatabases]
         INNER JOIN [Inspector].[DatabaseFileSizes] [Sizes] ON [ShrunkDatabases].[database_id] = [Sizes].[Database_id]
                                                                                      AND [Sizes].[File_id] = [ShrunkDatabases].[file_id]
         WHERE [ShrunkDatabases].[size] < [PostGrowthSize_MB]
         AND [Servername] = @Servername;


--Log the Database Growth event
		INSERT INTO [Inspector].[DatabaseFileSizeHistory]
         ([Servername],
          [Database_id],
          [Database_name],
          [Log_Date],
          [Type_Desc],
          [File_id],
		  [Drive],
          [FileName],
          [PreGrowthSize_MB],
          [GrowthRate_MB],
          [GrowthIncrements],
          [PostGrowthSize_MB]
         )

         SELECT [DatabaseFileSizes].[Servername],
                [Masterfiles].[database_id],
                DB_NAME([Masterfiles].[database_id]) AS [Database_name],
                @LastUpdated AS [Log_Date],
                [Masterfiles].[type_desc],
                [Masterfiles].[file_id],
				CAST(UPPER(volumestats.volume_mount_point) AS NVARCHAR(128)) AS Drive,
                RIGHT([Masterfiles].[physical_name],CHARINDEX(''\'',REVERSE([Masterfiles].[physical_name]))-1) AS [Filename], --Get the Filename
                [DatabaseFileSizes].[PostGrowthSize_MB],  --PostGrowth size is the Last recorded database size after a growth event
                [DatabaseFileSizes].[GrowthRate],
                (((CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024 - [DatabaseFileSizes].[PostGrowthSize_MB]) / [DatabaseFileSizes].[GrowthRate]) AS [TotalGrowthIncrements],  --IF Growth is in Percent then this will be calculated based on the Current DB size Less Originally logged size , Divided by the Growth percentage based on the original database size
                (CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024 AS [CurrentSize_MB] --Next approx Growth interval in MB
         FROM   [Inspector].[DatabaseFileSizes] [DatabaseFileSizes]
                INNER JOIN [sys].[master_files] [Masterfiles] ON [Masterfiles].[database_id] = [DatabaseFileSizes].[Database_id]
                                                                 AND [DatabaseFileSizes].[File_id] = [Masterfiles].[file_id]
				CROSS APPLY sys.dm_os_volume_stats([Masterfiles].[database_id],[Masterfiles].[file_id]) volumestats
         WHERE  [NextGrowth] <= (CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024
                AND [DatabaseFileSizes].[Servername] = @Servername
			 AND NOT EXISTS (
						  SELECT GrowthID
						  FROM [Inspector].[DatabaseFileSizeHistory] ExistingRecord
						  WHERE [Servername] = @Servername 
						  AND DB_NAME([Masterfiles].[database_id]) = [Database_name]
						  AND CAST([Log_Date] AS DATE) = CAST(GETDATE() AS DATE)
						  ); --Ensure that there has not been any growths logged for today before recording as this will affect thresholds. 
						     --(this allows the collection to be ran without worrying that the growths will be logged prematurely);
		
		SELECT @ScopeIdentity = MAX(GrowthID) FROM [Inspector].[DatabaseFileSizeHistory] WHERE Servername = @Servername AND Log_Date = @LastUpdated;
		
IF (@ScopeIdentity IS NOT NULL) --IF Growths have just been inserted
BEGIN
--Double check the databases sizes in the base table are correct and update as required
         UPDATE [Sizes]
         SET    [PostGrowthSize_MB] = (CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024,
			 [LastUpdated] = @LastUpdated
         FROM   [sys].[master_files] [Masterfiles]
                INNER JOIN [Inspector].[DatabaseFileSizes] [Sizes] ON [Masterfiles].[database_id] = [Sizes].[Database_id]
                                                                                             AND [Sizes].[File_id] = [Masterfiles].[file_id]
         WHERE  [Masterfiles].[database_id] > 3
                AND ((CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024 != [Sizes].[PostGrowthSize_MB])
                AND [Servername] = @Servername; 

--Set Next growth size for all Databases on this server which have grown
         UPDATE [Inspector].[DatabaseFileSizes]
         SET    [NextGrowth] = ([PostGrowthSize_MB] + [GrowthRate]),
			 [LastUpdated] = @LastUpdated
         WHERE  [NextGrowth] <= [PostGrowthSize_MB]
                AND [Servername] = @Servername;
END

--Clean up the history for growths older than @Retention in days
         DELETE FROM [Inspector].[DatabaseFileSizeHistory]
         WHERE [Log_Date] < DATEADD(DAY,-@Retention,GETDATE())
         AND [Servername] = @Servername;

     END;';


IF OBJECT_ID('Inspector.DatabaseOwnershipInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseOwnershipInsert] AS;');

SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
ALTER PROCEDURE [Inspector].[DatabaseOwnershipInsert]
AS
BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @DatabaseOwnerExclusions NVARCHAR(255) = (SELECT REPLACE(Value,'' '','''') from Inspector.Settings WHERE Description = ''DatabaseOwnerExclusions'');

DELETE 
FROM [Inspector].[DatabaseOwnership]
WHERE Servername = @Servername;

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 
INSERT INTO Inspector.DatabaseOwnership ([Servername],[Log_Date],[AGname],[Database_name],[Owner])
SELECT 
@Servername,
GETDATE(),
AG.name as AGname,
Databases.[name],
COALESCE(SUSER_SNAME(Databases.[Owner_sid]),''Blank'')
FROM sys.dm_hadr_availability_group_states ST
INNER JOIN master.sys.availability_groups AG ON ST.group_id = AG.group_id
INNER JOIN sys.availability_databases_cluster ADC ON AG.group_id = ADC.group_id
INNER JOIN sys.databases Databases ON Databases.name = ADC.database_name
WHERE primary_replica = @@Servername
AND Databases.owner_sid NOT IN ('+CASE WHEN @Compatibility = 0 
						    THEN 'SELECT SUSER_SID([StringElement])  
								FROM master.dbo.fn_SplitString(@DatabaseOwnerExclusions,'','')'
						    ELSE 'SELECT SUSER_SID([value])  
								FROM STRING_SPLIT(@DatabaseOwnerExclusions,'','')'
						    END+
						  ')
AND Databases.state = 0 
UNION ALL 
SELECT 
@Servername,
GETDATE(),
''Not in an AG'' as AGname,
Databases.[name],
COALESCE(SUSER_SNAME(Databases.[owner_sid]),''Blank'')
FROM sys.databases Databases
WHERE replica_id IS NULL
AND Databases.owner_sid NOT IN ('+CASE WHEN @Compatibility = 0
						    THEN 'SELECT SUSER_SID([StringElement])  
								FROM master.dbo.fn_SplitString(@DatabaseOwnerExclusions,'','')'
						    ELSE 'SELECT SUSER_SID([value])  
								FROM STRING_SPLIT(@DatabaseOwnerExclusions,'','')'
						    END+
						  ')
AND Databases.state = 0 
AND source_database_id IS NULL
ORDER BY Databases.name ASC
END
ELSE 
BEGIN 
INSERT INTO Inspector.DatabaseOwnership ([Servername],[Log_Date],[AGname],[Database_name],[Owner])
SELECT 
@Servername,
GETDATE(),
''N/A'' as AGname,
Databases.[name],
COALESCE(SUSER_SNAME(Databases.[owner_sid]),''Blank'')
FROM sys.databases Databases
WHERE replica_id IS NULL
AND Databases.owner_sid NOT IN ('+CASE WHEN @Compatibility = 0
						    THEN 'SELECT SUSER_SID([StringElement])  
								FROM master.dbo.fn_SplitString(@DatabaseOwnerExclusions,'','')'
						    ELSE 'SELECT SUSER_SID([value])  
								FROM STRING_SPLIT(@DatabaseOwnerExclusions,'','')'
						    END+
						  ')
AND Databases.state = 0 
AND source_database_id IS NULL
ORDER BY Databases.name ASC
END

IF NOT EXISTS (SELECT Servername
			FROM [Inspector].[DatabaseOwnership]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO [Inspector].[DatabaseOwnership] ([Servername],[Log_Date],[AGname],[Database_name],[Owner])
			VALUES(@Servername,GETDATE(),NULL,''No Database Ownership issues present'',NULL)
			END
			
END;'

EXEC(@SQLStatement);

IF OBJECT_ID('Inspector.BackupSizesByDayInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[BackupSizesByDayInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[BackupSizesByDayInsert]
AS
BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE FROM [Inspector].[BackupSizesByDay]
WHERE Servername = @@Servername;

INSERT INTO [Inspector].[BackupSizesByDay] ([Servername],[Log_Date],[DayOfWeek],[CastedDate],[TotalSizeInBytes])
SELECT 
@Servername,
GETDATE(),
[DayOfWeek] ,
[CastedDate],
[TotalSizeInBytes]
FROM (
SELECT 
DATENAME(WEEKDAY,backup_start_date) AS [DayOfWeek],
CAST(backup_start_date AS DATE) AS [CastedDate] ,
SUM(COALESCE(compressed_backup_size,backup_size)) AS [TotalSizeInBytes]
FROM msdb.dbo.backupset 
WHERE backup_start_date >= DATEADD(DAY,-7,CAST(GETDATE() AS DATE))
GROUP BY DATENAME(WEEKDAY,backup_start_date) ,CAST(backup_start_date AS DATE)
) as BackupSizesbyDay;


IF NOT EXISTS (SELECT Servername
			FROM [Inspector].[BackupSizesByDay]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO [Inspector].[BackupSizesByDay] ([Servername],[Log_Date],[DayOfWeek],[CastedDate],[TotalSizeInBytes])
			VALUES(@Servername,NULL,NULL,NULL,NULL)
			END

END;';


IF OBJECT_ID('Inspector.DatabaseSettingsInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseSettingsInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseSettingsInsert]
AS
BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

DELETE FROM [Inspector].[DatabaseSettings]
WHERE Servername = @Servername

INSERT INTO [Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''Collation_name'',
ISNULL(collation_name,''None'')   ,
COUNT(collation_name)  
FROM sys.databases
GROUP BY collation_name


INSERT INTO [Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_close_on'',
CASE is_auto_close_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
COUNT(is_auto_close_on)  
FROM sys.databases
GROUP BY is_auto_close_on


INSERT INTO [Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_shrink_on'',
CASE is_auto_shrink_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
COUNT(is_auto_shrink_on)  
FROM sys.databases
GROUP BY is_auto_shrink_on


INSERT INTO [Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_update_stats_on'',
CASE is_auto_update_stats_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
COUNT(is_auto_update_stats_on)  
FROM sys.databases
GROUP BY is_auto_update_stats_on


INSERT INTO [Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_read_only'',
CASE is_read_only WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
COUNT(is_read_only)  
FROM sys.databases
GROUP BY is_read_only

INSERT INTO [Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''user_access_desc'', 
user_access_desc, 
COUNT(user_access_desc)  
FROM sys.databases
GROUP BY user_access_desc

INSERT INTO [Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''compatibility_level'',
[compatibility_level],
COUNT([compatibility_level])  
FROM sys.databases
GROUP BY [compatibility_level]


INSERT INTO [Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''recovery_model_desc'',
recovery_model_desc,
COUNT(recovery_model_desc)  
FROM sys.databases
GROUP BY recovery_model_desc

END;';


IF OBJECT_ID('Inspector.ServerSettingsInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[ServerSettingsInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[ServerSettingsInsert]
AS
BEGIN

--Revision date: 21/05/2021

SET NOCOUNT ON;
DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

/* INSERT any configuration options not currently in the Inspector table */
INSERT INTO [Inspector].[ServerSettings] ([Servername],[Log_Date],[configuration_id],[Setting],[value_in_use],[LastUpdated])
SELECT 
@Servername,
@LogDate,
[configuration_id],
CAST([name] AS NVARCHAR(128)), 
CAST([value_in_use] AS INT),
@LogDate AS LastUpdated
FROM sys.configurations
WHERE NOT EXISTS (SELECT 1 
					FROM [Inspector].[ServerSettings] 
					WHERE [ServerSettings].[configuration_id] = [configurations].[configuration_id]
					AND [ServerSettings].[Servername] = @Servername
				);

/* UPDATE Lastupdated to say we just checked if config has changed and update value_in_use */
UPDATE ss
SET 
[value_in_use] = CAST([configurations].[value_in_use] AS INT),
[LastUpdated] = @LogDate
FROM [Inspector].[ServerSettings] ss 
INNER JOIN sys.configurations ON [ss].[configuration_id] = [configurations].[configuration_id]
AND [ss].[Servername] = @Servername;

END;';


IF OBJECT_ID('Inspector.InstanceStartInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[InstanceStartInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[InstanceStartInsert]
AS
BEGIN

--Revision date: 02/07/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

DELETE FROM [Inspector].[InstanceStart]
WHERE Servername = @Servername;

INSERT INTO [Inspector].[InstanceStart] ([Servername],[Log_Date],[InstanceStart])
SELECT 
@Servername,
@LogDate,
[create_date]
FROM sys.databases
WHERE name = ''tempdb''

END;';


IF OBJECT_ID('Inspector.InstanceVersionInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[InstanceVersionInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[InstanceVersionInsert]
AS
BEGIN

--Revision date: 29/05/2021

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @PhysicalServername NVARCHAR(128) = CAST(SERVERPROPERTY(''ComputerNamePhysicalNetBIOS'') AS NVARCHAR(128));
DECLARE @Version NVARCHAR(20) =  CAST(SERVERPROPERTY(''ProductVersion'') AS NVARCHAR(20));
DECLARE @Edition NVARCHAR(50) = CAST(SERVERPROPERTY(''Edition'') AS NVARCHAR(50));

--Check for version and/or edition change
IF EXISTS(SELECT 1 FROM [Inspector].[InstanceVersion] WHERE Servername = @Servername)
BEGIN 
	--If the major version has changed we only want to advise of that change, if the major version has not changed 
	--then check for a minor version change and advise of the change.

	INSERT INTO [Inspector].[InstanceVersionHistory] ([Servername], [Log_Date], [CollectionDatetime], [VersionNo], [Edition])
	SELECT 
	@Servername,
	[Log_Date],
	GETDATE(),
	[VersionNo],
	[Edition]
	FROM
	(
		SELECT 
		[Log_Date],
		CASE 
			WHEN [VersionNo] != @Version
			THEN CASE 
					WHEN PARSENAME([VersionNo],4) != PARSENAME(@Version,4) 
						THEN N''Major Version changed from [''
						+ PARSENAME([VersionNo],4) 
						+ N''] to [''
						+ PARSENAME(@Version,4) 
						+ N''] ''
						+ ISNULL(N'' ''+CAST(SERVERPROPERTY(''ProductLevel'') AS NVARCHAR(6)),'''')
						+ ISNULL(N'' ''+CAST(SERVERPROPERTY(''ProductUpdateLevel'') AS NVARCHAR(6)),'''')
					WHEN PARSENAME([VersionNo],2) != PARSENAME(@Version,2) 
						THEN N''Minor Version changed from [''
						+ PARSENAME([VersionNo],2) 
						+ N''] to [''
						+ PARSENAME(@Version,2)
						+ N''] ''
						+ ISNULL(N'' ''+CAST(SERVERPROPERTY(''ProductLevel'') AS NVARCHAR(6)),'''')
						+ ISNULL(N'' ''+CAST(SERVERPROPERTY(''ProductUpdateLevel'') AS NVARCHAR(6)),'''')
				 END
			ELSE NULL
		END AS [VersionNo],
		CASE 
			WHEN [Edition] != @Edition 
				THEN N''Edition Changed from [''
				+ [Edition]
				+ N''] to [''
				+ @Edition
				+ N'']''
			ELSE NULL
		END AS [Edition]
		FROM
		(--Split Version and Edition into two columns
			SELECT 
			[Log_Date],
			SUBSTRING([VersionInfo],0,CHARINDEX('' - '',[VersionInfo])) AS  VersionNo,
			SUBSTRING([VersionInfo],CHARINDEX('' - '',[VersionInfo])+3,LEN([VersionInfo])-CHARINDEX('' - '',[VersionInfo])) AS Edition
			FROM [Inspector].[InstanceVersion]
			WHERE Servername = @Servername
		) AS LastLoggedVersionInfo
	) AS VersionCheck
	WHERE ([VersionNo] IS NOT NULL OR [Edition] IS NOT NULL)
	AND NOT EXISTS (SELECT 1 
					FROM [Inspector].[InstanceVersionHistory] 
					WHERE Servername = @Servername 
					AND CAST(VersionCheck.[Log_Date] AS DATE) = CAST([InstanceVersionHistory].[Log_Date] AS DATE) 
					AND ([VersionNo] = [VersionCheck].[VersionNo] OR [Edition] = [VersionCheck].[Edition]))

END 

DELETE FROM [Inspector].[InstanceVersion]
WHERE Servername = @Servername;

INSERT INTO [Inspector].[InstanceVersion] ([Servername], [PhysicalServername], [Log_Date], [VersionInfo])
SELECT @Servername, @PhysicalServername, GETDATE(), @Version + N'' - '' + @Edition

/* Log server info */
DELETE FROM [Inspector].[ServerInfo]
WHERE Servername = @Servername;

INSERT INTO [Inspector].[ServerInfo] ([Servername], [Log_Date], [cpu_count], [hyperthread_count], [physical_memory_gb], [scheduler_count], [affinity_type_desc], [machine_type])
SELECT 
	@Servername,
	GETDATE(),
	cpu_count,
	hyperthread_ratio as hyperthread_count,
	(physical_memory_kb/1024)/1000 AS physical_memory_gb,
	scheduler_count,
	affinity_type_desc,
	CASE 
		WHEN virtual_machine_type_desc = N''HYPERVISOR'' THEN N''Virtual'' 
		ELSE N''Physical'' 
	END
FROM sys.dm_os_sys_info;
END;';


IF OBJECT_ID('Inspector.SuspectPagesInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[SuspectPagesInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[SuspectPagesInsert]
AS
BEGIN

--Revision date: 30/07/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

DELETE FROM [Inspector].[SuspectPages]
WHERE Servername = @Servername

INSERT INTO [Inspector].[SuspectPages] ([Servername],[Log_Date],[Databasename],[file_id],[page_id],[event_type],[error_count],[last_update_date])
SELECT
@Servername,
@LogDate,
DB_NAME([database_id]),
[file_id],
[page_id],	
[event_type],
[error_count],	
[last_update_date]
FROM msdb.dbo.suspect_pages

IF NOT EXISTS (SELECT Servername FROM [Inspector].[SuspectPages] WHERE Servername = @Servername)
BEGIN 
	INSERT INTO [Inspector].[SuspectPages] ([Servername],[Log_Date],[Databasename],[file_id],[page_id],[event_type],[error_count],[last_update_date])
	VALUES(@Servername,GETDATE(),NULL,NULL,NULL,NULL,NULL,NULL)
END


END;';


IF OBJECT_ID('Inspector.AGDatabasesInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[AGDatabasesInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[AGDatabasesInsert]
AS
BEGIN

--Revision date: 10/08/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @AGEnabled BIT;

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups) 
BEGIN 
	SET @AGEnabled = 1 
END
ELSE 
BEGIN
	SET @AGEnabled = 0
END
	
--Delete databases from the table when the state is not online OR Database is no longer on the server.
DELETE FROM [Inspector].[AGDatabases] 
WHERE AGDatabases.Servername = @Servername
AND (EXISTS (SELECT 1 FROM sys.databases DBs WHERE AGDatabases.Databasename = DBs.name COLLATE DATABASE_DEFAULT AND AGDatabases.Servername = @Servername AND state != 0)
OR NOT EXISTS (SELECT 1 FROM sys.databases DBs WHERE AGDatabases.Databasename = DBs.name COLLATE DATABASE_DEFAULT AND AGDatabases.Servername = @Servername));

--INSERT databases missing from the table and assume they should be joined to an AG.
INSERT INTO [Inspector].[AGDatabases] ([Servername], [Log_Date], [LastUpdated], [Databasename], [Is_AG], [Is_AGJoined])
SELECT 
@Servername,
GETDATE(),
GETDATE(),
[name],
@AGEnabled,
CASE WHEN AGDBs.database_name IS NULL THEN 0 ELSE 1 END
FROM sys.databases DBs
LEFT JOIN (SELECT JoinedDBs.group_id,database_name
		   FROM sys.availability_databases_cluster JoinedDBs 
		   WHERE EXISTS (SELECT 1 FROM sys.availability_groups Groups WHERE JoinedDBs.group_id = Groups.group_id)
		   ) AS AGDBs ON DBs.name COLLATE DATABASE_DEFAULT = AGDBs.database_name
LEFT JOIN sys.availability_replicas AGReplicas ON AGDBs.group_id = AGReplicas.group_id AND AGReplicas.replica_server_name = @Servername
WHERE DBs.database_id > 4 
AND state = 0
AND source_database_id IS NULL
AND NOT EXISTS (SELECT 1 FROM [Inspector].[AGDatabases] WHERE Databasename = DBs.name COLLATE DATABASE_DEFAULT AND Servername = @Servername);


--Update Is_AGJoined 
UPDATE DBs
SET 
[Is_AGJoined] = CASE WHEN [AGReplicas].[replica_server_name] IS NULL THEN 0 ELSE 1 END, 
[LastUpdated] = GETDATE()
FROM [Inspector].[AGDatabases] DBs
LEFT JOIN (SELECT JoinedDBs.group_id,database_name
		   FROM sys.availability_databases_cluster JoinedDBs 
		   WHERE EXISTS (SELECT 1 FROM sys.availability_groups Groups WHERE JoinedDBs.group_id = Groups.group_id)
		   ) AS AGDBs ON DBs.Databasename COLLATE DATABASE_DEFAULT = AGDBs.database_name
LEFT JOIN sys.availability_replicas AGReplicas ON AGDBs.group_id = AGReplicas.group_id AND AGReplicas.replica_server_name = @Servername
WHERE DBs.Servername = @Servername;
	

END';


IF OBJECT_ID('Inspector.LongRunningTransactionsInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[LongRunningTransactionsInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[LongRunningTransactionsInsert]
AS
BEGIN

--Revision date: 09/06/2021

SET NOCOUNT ON;

DECLARE @TransactionDurationThreshold INT = (SELECT CAST([Value] AS INT) FROM [Inspector].[Settings] WHERE [Description] = ''LongRunningTransactionThreshold'');
DECLARE @Now DATETIME = GETDATE();
DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @Retention INT;

SET @Retention = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''LongRunningTransactions'', ''LongRunningTransactionsHistoryRetentionDays'') AS INT), 7));

IF (@Retention IS NULL)
BEGIN 
	SET @Retention = 7;
END 

SET @Retention = @Retention*-1;

DELETE FROM [Inspector].[LongRunningTransactionsHistory]
WHERE Servername = @Servername
AND [Log_Date] < DATEADD(DAY,@Retention,GETDATE());

INSERT INTO [Inspector].[LongRunningTransactionsHistory] ([Servername], [Log_Date], [session_id], [transaction_begin_time], [Duration_DDHHMMSS], [TransactionState], [SessionState], [login_name], [host_name], [program_name], [Databasename],[Querytext])
SELECT [Servername], [Log_Date], [session_id], [transaction_begin_time], [Duration_DDHHMMSS], [TransactionState], [SessionState], [login_name], [host_name], [program_name], [Databasename],[Querytext]
FROM [Inspector].[LongRunningTransactions]
WHERE [session_id] IS NOT NULL;

DELETE FROM [Inspector].[LongRunningTransactions]
WHERE Servername = @Servername;

--Set a default value of 300 (5 Mins) if NULL
IF @TransactionDurationThreshold IS NULL 
BEGIN 
	SET @TransactionDurationThreshold = 300;
END

INSERT INTO [Inspector].[LongRunningTransactions] ([Servername], [Log_Date], [session_id], [transaction_begin_time], [Duration_DDHHMMSS], [TransactionState], [SessionState], [login_name], [host_name], [program_name], [Databasename],[Querytext])
SELECT
@Servername,
@Now,
SessionTrans.session_id
,ActiveTrans.transaction_begin_time
,RIGHT(''0'' + CONVERT(VARCHAR(4),DATEDIFF(SECOND,ActiveTrans.transaction_begin_time,@Now)%31536000/86400),2)
+'':''+RIGHT(''0'' + CONVERT(VARCHAR(2),DATEDIFF(SECOND,ActiveTrans.transaction_begin_time,@Now)%86400/3600),2)
+'':''+RIGHT(''0'' + CONVERT(VARCHAR(2),DATEDIFF(SECOND,ActiveTrans.transaction_begin_time,@Now)%3600/60), 2)
+'':''+RIGHT(''0'' + CONVERT(VARCHAR(2),(DATEDIFF(SECOND,ActiveTrans.transaction_begin_time,@Now)%60)), 2) AS [Duration_DDHHMMSS]        
,CASE ActiveTrans.transaction_state
WHEN 0 THEN ''Uninitialised''
WHEN 1 THEN ''Not Started''
WHEN 2 THEN ''Active''
WHEN 3 THEN ''Ended''
WHEN 4 THEN ''Commit Initiated''
WHEN 5 THEN ''Prepared''
WHEN 6 THEN ''Commited''
WHEN 7 THEN ''Rolling Back''
WHEN 8 THEN ''Rolled Back''
ELSE CAST(ActiveTrans.transaction_state AS VARCHAR(20))
END AS TransactionState
,Sessions.status
,Sessions.login_name
,Sessions.host_name
,Sessions.program_name
,DB_NAME(Sessions.database_id)
,[Querytext].[text]
FROM sys.dm_tran_session_transactions SessionTrans
JOIN sys.dm_tran_active_transactions ActiveTrans ON SessionTrans.transaction_id = ActiveTrans.transaction_id
JOIN sys.dm_exec_sessions Sessions ON Sessions.session_id = SessionTrans.session_id
JOIN sys.dm_exec_connections Connections ON Connections.session_id = Sessions.session_id
OUTER APPLY sys.dm_exec_sql_text(Connections.most_recent_sql_handle) aS Querytext
WHERE ActiveTrans.transaction_begin_time <= DATEADD(SECOND,-@TransactionDurationThreshold,@Now)
ORDER BY ActiveTrans.transaction_begin_time ASC;

IF NOT EXISTS (SELECT 1 FROM [Inspector].[LongRunningTransactions] WHERE Servername = @Servername)
BEGIN 
	INSERT INTO [Inspector].[LongRunningTransactions] ([Servername], [Log_Date], [session_id], [transaction_begin_time], [Duration_DDHHMMSS], [TransactionState], [SessionState], [login_name], [host_name], [program_name], [Databasename])
	VALUES(@Servername,@Now,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
END

END';


IF OBJECT_ID('Inspector.UnusedLogshipConfigInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[UnusedLogshipConfigInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[UnusedLogshipConfigInsert]
AS
BEGIN

--Revision date: 30/11/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM [Inspector].[UnusedLogshipConfig]
WHERE Servername = @Servername;

INSERT INTO [Inspector].[UnusedLogshipConfig] (Servername,Log_Date,Databasename,Databasestate)
SELECT 
@Servername,
GETDATE(),
LogshippedDBs.secondary_database, 
CAST(
CASE 
	WHEN DBs.state_desc IS NULL THEN ''Database does not exist''
	ELSE LOWER(DBs.state_desc)
END AS NVARCHAR(128)
) AS Databasestate
FROM msdb.dbo.log_shipping_secondary_databases LogshippedDBs
LEFT JOIN sys.databases DBs ON LogshippedDBs.secondary_database = DBs.name
WHERE DBs.name IS NULL OR DBs.state != 1 --Database does not exist or is not in a restoring state

END;';


IF OBJECT_ID('Inspector.DatacollectionsOverdueInsert') IS NULL
EXEC('CREATE PROCEDURE [Inspector].[DatacollectionsOverdueInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatacollectionsOverdueInsert]
AS
--Revision date:13/10/2019
SET NOCOUNT ON;

DELETE FROM [Inspector].[DatacollectionsOverdue]
WHERE Servername = @@SERVERNAME;

--Warn if the Collection has overun the minimum Frequency set for a Module or Modules with the same ModuleConfig_Desc 
INSERT INTO [Inspector].[DatacollectionsOverdue] ([ExecutionLogID], [Servername], [Log_Date], [ModuleConfig_Desc], [Procname], [DurationInSeconds], [ExecutionDate], [PreviousRunDateTime], [RunNumber], [FrequencyInSeconds], [Variance], [PSCollection])
SELECT 
[ExecutionLogDetails].[ID] AS ExecutionLogID, 
[ExecutionLogDetails].[Servername], 
GETDATE(),
[ExecutionLogDetails].[ModuleConfig_Desc], 
[ExecutionLogDetails].[Procname],
CAST([ExecutionLogDetails].[Duration] AS INT) AS DurationInSeconds, 
[ExecutionLogDetails].[ExecutionDate], 
[ExecutionLogDetails].[PreviousRunDateTime], 
[ExecutionLogDetails].[RunNumber], 
([ExecutionLogDetails].[ActualFrequency]*60) AS FrequencyInSeconds, 
ABS(([ExecutionLogDetails].[ActualFrequency]*60) - CAST([ExecutionLogDetails].[Duration] AS INT)) AS Variance,
[ExecutionLogDetails].[PSCollection]
FROM [Inspector].[ExecutionLogDetails]
INNER JOIN (SELECT [ModuleConfig_Desc],MIN(Frequency) AS Frequency 
			FROM [Inspector].[Modules] 
			WHERE [IsActive] = 1
			GROUP BY [ModuleConfig_Desc]) AS MinFrequencies ON MinFrequencies.ModuleConfig_Desc = [ExecutionLogDetails].ModuleConfig_Desc
WHERE [ExecutionLogDetails].Procname = ''InspectorDataCollection''
AND ([ExecutionLogDetails].[Duration]/60) > MinFrequencies.Frequency;';


IF OBJECT_ID('Inspector.DatacollectionsOverdueReport') IS NULL
EXEC('CREATE PROCEDURE [Inspector].[DatacollectionsOverdueReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatacollectionsOverdueReport] (
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

--Revision date: 01/11/2019
BEGIN
--Excluded from Warning level control
	DECLARE @HtmlTableHead VARCHAR(4000);
	DECLARE @Columnnames VARCHAR(2000);
	DECLARE @SQLtext NVARCHAR(4000);
	DECLARE @Frequency INT;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);
	SET @Frequency = (SELECT ([Frequency]+60) FROM [Inspector].[ModuleConfig] WHERE [ModuleConfig_Desc] = @ModuleConfig);

/********************************************************/
	--Your query MUST have a case statement that determines which colour to highlight rows
	--Your query MUST use an INTO clause to populate the temp table so that the column names can be determined for the report
	--@bgcolor is used the for table highlighting , Warning,Advisory and Info highlighting colours are determined from 
	--the ModuleWarningLevel table and your Case expression And/or Where clause will determine which rows get the highlight
	--query example:

--for collected data reference an Inspector table
SELECT 
CASE 
	WHEN @WarningLevel = 1 THEN @WarningHighlight
	WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
	WHEN @WarningLevel = 3 THEN @InfoHighlight
END AS [@bgcolor],
[ExecutionLogID], 
[Servername], 
[ModuleConfig_Desc], 
[Procname], 
[DurationInSeconds], 
[ExecutionDate], 
[PreviousRunDateTime], 
[RunNumber], 
[FrequencyInSeconds], 
[Variance], 
[PSCollection]
INTO #InspectorModuleReport
FROM [Inspector].[DatacollectionsOverdue] 
WHERE Servername = @Servername
AND [ExecutionDate] > DATEADD(MINUTE,-@Frequency,GETDATE());

	--OR 

---- for an adhoc query against this server only here is an example
--SELECT
--CAST(
--CASE 
--	WHEN @WarningLevel = 1 THEN @WarningHighlight
--	WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
--	WHEN @WarningLevel = 3 THEN @InfoHighlight
--END AS VARCHAR(7)) AS [@bgcolor],
--DB_NAME(database_id) AS Databasename,
--COUNT(*) AS DataFileCount
--INTO #InspectorModuleReport
--FROM sys.master_files 
--WHERE database_id = 2
--AND type = 0
--GROUP BY DB_NAME(database_id) 
--HAVING COUNT(*) < 4;


/********************************************************/

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
	''Data collections overun schedules in the past (''+CAST(@Frequency AS VARCHAR(10))+'' mins)'', --Title for the HTML table, you can use a string here instead such as ''My table title here'' if you want to
	@TableHeaderColour,
	@Columnnames)
	);


	SET @SQLtext = N''
	SELECT @HtmlOutput =
	(SELECT ''
	+''[@bgcolor],''
	+REPLACE(@Columnnames,'','','' AS ''''td'''','''''''',+ '') + '' AS ''''td'''','''''''''' 
	+'' FROM #InspectorModuleReport
	FOR XML PATH(''''tr''''),Elements);''
	--Add an ORDER BY if required

	EXEC sp_executesql @SQLtext,N''@HtmlOutput VARCHAR(MAX) OUTPUT'',@HtmlOutput = @HtmlOutput OUTPUT;

	--Optional
	--If in the above query you populate the table with something like ''No issues present'' then you probably do not want that to 
	--show when @Noclutter mode is on
	--IF (@NoClutter = 1)
	--BEGIN 
	--	IF(@HtmlOutput LIKE ''%<Your No issues present text here>%'')
	--	BEGIN
	--		SET @HtmlOutput = NULL;
	--	END
	--END

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

END';


IF OBJECT_ID('Inspector.ExecutionLogInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[ExecutionLogInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[ExecutionLogInsert]
(
@RunDatetime DATETIME,
@Servername NVARCHAR(128),
@ModuleConfigDesc VARCHAR(20),
@Procname NVARCHAR(128),
@Frequency SMALLINT = NULL,
@ErrorMessage NVARCHAR(128) = NULL,
@Duration MONEY,
@PSCollection BIT
)
AS
--Revision Date: 13/05/2021

INSERT INTO [Inspector].[ExecutionLog] (ExecutionDate,Servername,ModuleConfig_Desc,Procname,Frequency,Duration,PSCollection,ErrorMessage)
VALUES(@RunDatetime,@Servername,@ModuleConfigDesc,@Procname,@Frequency,@Duration,@PSCollection,@ErrorMessage);
';


IF OBJECT_ID('Inspector.ResetHtmlColors') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[ResetHtmlColors] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[ResetHtmlColors]
AS
BEGIN 

	UPDATE [Inspector].[ModuleWarnings]
	SET 
	[HighlightHtmlColor] = CASE 
							WHEN [WarningLevel] IS NULL THEN NULL 
							WHEN [WarningLevel] = 1 THEN ''#fc5858'' 
							WHEN [WarningLevel] = 2 THEN ''#FAFCA4''
							WHEN [WarningLevel] = 3 THEN ''#FEFFFF''
						   END,
	[GradientLeftHtmlColor] = CASE 
								WHEN [WarningLevel] IS NULL THEN NULL 
								WHEN [WarningLevel] IN (1,2,3) THEN ''#000000'' 
							 END,
	[GradientRightHtmlColor] = CASE 
								WHEN [WarningLevel] IS NULL THEN NULL 
								WHEN [WarningLevel] = 1 THEN ''#fc5858'' 
								WHEN [WarningLevel] = 2 THEN ''#FAFCA4''
								WHEN [WarningLevel] = 3 THEN ''#FEFFFF''
							   END
END';


IF OBJECT_ID('Inspector.DriveCapacityHistory') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[DriveCapacityHistory] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DriveCapacityHistory]
(
@Servername NVARCHAR(128),
@Drive VARCHAR(20)
)
AS
BEGIN
--Revision date 25/03/2019

SELECT 
Servername,
Log_Date,
Drive,
Capacity_GB,
AvailableSpace_GB,
DATEDIFF(DAY,LEAD(Log_Date,1,Log_Date) OVER(Partition by Drive ORDER BY Log_Date DESC),Log_Date) AS DaysSinceCapacityChange,
Capacity_GB-LEAD(Capacity_GB,1,Capacity_GB) OVER(Partition by Drive ORDER BY Log_Date DESC) AS CapacityChange
FROM 
(
	SELECT 
	Servername,
	Log_Date,
	Drive,
	Capacity_GB,
	AvailableSpace_GB,
	ROW_NUMBER() OVER(Partition by Capacity_GB,Drive ORDER BY Log_Date DESC) as CapacityChange
	FROM [Inspector].[DriveSpace] 
	WHERE Drive = @Drive
	AND Servername = @Servername
) CapacityChanges
WHERE CapacityChange = 1
ORDER BY Log_Date DESC

END';


IF OBJECT_ID('Inspector.SuppressAdHocDatabase') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[SuppressAdHocDatabase] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[SuppressAdHocDatabase]
(
@Databasename NVARCHAR(128),
@Servername NVARCHAR(128)
)
AS 
BEGIN 
--Revision date: 05/04/2019
SET NOCOUNT ON;

	UPDATE [Inspector].[ADHocDatabaseSupression] 
	SET [Suppress] = 1 
	WHERE [Databasename] = @Databasename 
	AND [Servername] = @Servername;

END';


IF OBJECT_ID('Inspector.SuppressAGDatabase') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[SuppressAGDatabase] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[SuppressAGDatabase]
(
@Databasename NVARCHAR(128),
@Servername NVARCHAR(128)
)
AS 
BEGIN 
--Revision date: 05/04/2019
SET NOCOUNT ON;

	UPDATE [Inspector].[AGDatabases] 
	SET [Is_AG] = 0
	WHERE [Databasename] = @Databasename 
	AND [Servername] = @Servername;

END';


IF OBJECT_ID('Inspector.DatabaseGrowthFilenameSync') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseGrowthFilenameSync] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseGrowthFilenameSync]
AS
BEGIN

--Revision date: 01/05/2019
SET NOCOUNT ON;
	UPDATE Growths
	SET [Drive] = [ServerDrives].[Drive]
	--SELECT 
	--[Growths].GrowthID,
	--[Growths].[Database_name],
	--[Growths].[FileName],
	--[DatabaseFileSizes].[Filename],
	--[ServerDrives].[Drive],
	--[Growths].[Drive]
	FROM [Inspector].[DatabaseFileSizeHistory] Growths
	INNER JOIN [Inspector].[DatabaseFileSizes] 
			ON [DatabaseFileSizes].Servername = [Growths].Servername 
			AND [DatabaseFileSizes].[Database_name] = [Growths].[Database_name]
			AND [DatabaseFileSizes].Database_id = [Growths].Database_id
			AND [DatabaseFileSizes].[Filename] LIKE ''%''+[Growths].[FileName]
	INNER JOIN (SELECT [Servername],[Drive]
				FROM [Inspector].[DriveSpace]
				GROUP BY [Servername],[Drive]
				) [ServerDrives] ON 
			[DatabaseFileSizes].Servername = [ServerDrives].[Servername] 
			AND [DatabaseFileSizes].[Filename] LIKE [ServerDrives].[Drive]+''%''
	WHERE [Growths].[Drive] IS NULL;

	UPDATE [Inspector].[Settings] 
	SET [Value] = NULL
	WHERE [Description] = ''InspectorUpgradeFilenameSync'';
END';


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[TempDBInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Inspector].[TempDBInsert] AS' 
END

EXEC sp_executesql N'ALTER PROCEDURE [Inspector].[TempDBInsert]
AS
BEGIN

SET NOCOUNT ON;

DECLARE @SessionID INT;
DECLARE @TransactionStart DATETIME;
DECLARE @DurationMins DECIMAL(18,2);
DECLARE @TempDBPercentUsed DECIMAL(5,2);

SET @TempDBPercentUsed = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''TempDB'', ''TempDBPercentUsed'') AS DECIMAL(5,2)), 75.00));

IF (@TempDBPercentUsed IS NULL)
BEGIN 
	SET @TempDBPercentUsed = 75.00;
END 

/* we need to remove old records based on retention per server not just the global retention */
DELETE tdb
FROM [Inspector].[CurrentServers] cs
INNER JOIN [Inspector].[TempDB] tdb ON cs.Servername = tdb.Servername
WHERE [Log_Date] < DATEADD(DAY,ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](cs.[Servername], ''TempDB'', ''TempDBDataRetentionDays'') AS INT), 7)*-1,GETDATE())
AND cs.[IsActive] = 1;


/* oldest transaction */
SELECT 
@SessionID = SessionTrans.session_id,
@TransactionStart = MIN(ActiveTrans.transaction_begin_time)
FROM tempdb.sys.dm_tran_session_transactions SessionTrans
JOIN tempdb.sys.dm_tran_active_transactions ActiveTrans ON SessionTrans.transaction_id = ActiveTrans.transaction_id
JOIN tempdb.sys.dm_exec_sessions ExecSessions ON ExecSessions.session_id = SessionTrans.session_id
JOIN tempdb.sys.dm_exec_connections Connections ON Connections.session_id = ExecSessions.session_id
GROUP BY SessionTrans.session_id;

/* Calculate the duraion in mins for the oldest transaction */
SET @DurationMins = CAST(DATEDIFF(SECOND,MIN(@TransactionStart),GETDATE())/60.00 AS DECIMAL(18,2));

/* TempDB File utilisation */
INSERT INTO [Inspector].[TempDB] ([Servername],[Log_Date],[DatabaseFilename], [Reserved_MB], [Unallocated_MB], [Internal_object_reserved_MB], [User_object_reserved_MB], [Version_store_reserved_MB], [UsedPct], [OldestTransactionSessionId], [OldestTransactionDurationMins], [TransactionStartTime])
SELECT 
	[Servername],
	[Log_Date],
	[DatabaseFilename],
	[Reserved_MB],
	[Unallocated_MB], 
	[Internal_object_reserved_MB], 
	[User_object_reserved_MB], 
	[Version_store_reserved_MB], 
	[UsedPct], 
	[OldestTransactionSessionId], 
	[OldestTransactionDurationMins], 
	[TransactionStartTime]
FROM
(
	SELECT 
	@@SERVERNAME AS Servername,
	GETDATE() AS Log_Date,
	master_files.name AS DatabaseFilename,
	CAST((unallocated_extent_page_count+version_store_reserved_page_count+user_object_reserved_page_count+internal_object_reserved_page_count+mixed_extent_page_count)*8/1024.00 AS DECIMAL(18,2)) AS Reserved_MB,
	CAST(unallocated_extent_page_count*8/1024.00 AS DECIMAL(18,2)) AS Unallocated_MB, 
	CAST((internal_object_reserved_page_count*8)/1024.00 AS DECIMAL(18,2)) AS Internal_object_reserved_MB,
	CAST((user_object_reserved_page_count*8)/1024.00 AS DECIMAL(18,2)) AS User_object_reserved_MB,
	CAST(version_store_reserved_page_count*8/1024.00 AS DECIMAL(18,2)) AS Version_store_reserved_MB,
	CAST(
			(
				(
				CAST((internal_object_reserved_page_count*8)/1024.00 AS DECIMAL(18,2))+
				CAST((user_object_reserved_page_count*8)/1024.00 AS DECIMAL(18,2))+
				CAST(version_store_reserved_page_count*8/1024.00 AS DECIMAL(18,2))
				)
				/CAST((unallocated_extent_page_count+version_store_reserved_page_count+user_object_reserved_page_count+internal_object_reserved_page_count+mixed_extent_page_count)*8/1024.00 AS DECIMAL(18,2))
			 )*100.00 AS DECIMAL(18,2)
		) AS UsedPct,
	@SessionID AS OldestTransactionSessionId,
	@DurationMins AS OldestTransactionDurationMins,
	@TransactionStart AS TransactionStartTime
	FROM tempdb.sys.dm_db_file_space_usage 
	INNER JOIN tempdb.sys.master_files ON dm_db_file_space_usage.[file_id] = master_files.[file_id] AND dm_db_file_space_usage.[database_id] = master_files.[database_id]
) AS TempDBUsage
WHERE UsedPct >= @TempDBPercentUsed;

END';


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Inspector].[TempDBReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Inspector].[TempDBReport] AS' 
END

EXEC sp_executesql N'ALTER PROCEDURE [Inspector].[TempDBReport] (
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
--Revision date: 14/06/2021	

DECLARE @TempDBPercentUsed DECIMAL(5,2);
DECLARE @HtmlTableHead VARCHAR(2000);
DECLARE @AgentJobOwnerExclusions VARCHAR(255);
DECLARE @LastCollection DATETIME;
DECLARE @ReportFrequency INT;
DECLARE @MonitorHourStart INT;
DECLARE @MonitorHourEnd INT;

SET @MonitorHourStart = (SELECT [MonitorHourStart] FROM [Inspector].[MonitorHours] WHERE [Servername] = @Servername AND [Modulename] = @Modulename);
SET @MonitorHourEnd = (SELECT [MonitorHourEnd] FROM [Inspector].[MonitorHours] WHERE [Servername] = @Servername AND [Modulename] = @Modulename);
SET @TempDBPercentUsed = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''TempDB'', ''TempDBPercentUsed'') AS DECIMAL(5,2)), 75.00));
SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
SET @ReportFrequency *= -1;
SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

IF @MonitorHourStart IS NULL BEGIN SET @MonitorHourStart = 0 END;
IF @MonitorHourEnd IS NULL BEGIN SET @MonitorHourEnd = 23 END;

--Set columns names for the Html table
SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
	@Servername,
	@Modulename,
	@ServerSpecific,
	''TempDB file Usage above ''+CAST(@TempDBPercentUsed AS VARCHAR(10))+''%''
	+'' in the last ''
	+CAST(ABS(@ReportFrequency) AS VARCHAR(6)) 
	+''mins between the hours of ''
	+CAST(@MonitorHourStart AS VARCHAR(10))
	+'' and ''
	+CAST(@MonitorHourEnd AS VARCHAR(10)),
	@TableHeaderColour,
	''Servername,Log_Date,DatabaseFilename,Reserved_MB,Unallocated_MB,Internal_object_reserved_MB,User_object_reserved_MB,Version_store_reserved_MB,UsedPct,OldestTransactionSessionId,OldestTransactionDurationMins,TransactionStartTime''
	)
);

/* if there has been a data collection since the last report frequency minutes ago then run the report */
IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
BEGIN
	SET @HtmlOutput = 
	(SELECT 
	CASE 
		WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
		WHEN @WarningLevel = 1 THEN @WarningHighlight
		WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
		WHEN @WarningLevel = 3 THEN @InfoHighlight
	END AS [@bgcolor],
	[Servername] AS ''td'','''',+
	CONVERT(VARCHAR(17),[Log_Date],113) AS ''td'','''',+ 
	[DatabaseFilename] AS ''td'','''',+ 
	[Reserved_MB] AS ''td'','''',+ 
	[Unallocated_MB] AS ''td'','''',+ 
	[Internal_object_reserved_MB] AS ''td'','''',+ 
	[User_object_reserved_MB] AS ''td'','''',+ 
	[Version_store_reserved_MB] AS ''td'','''',+ 
	[UsedPct] AS ''td'','''',+ 
	ISNULL(CAST([OldestTransactionSessionId] AS VARCHAR(10)),''N/A'') AS ''td'','''',+ 
	ISNULL(CAST([OldestTransactionDurationMins] AS VARCHAR(10)),''N/A'') AS ''td'','''',+ 
	ISNULL(CONVERT(VARCHAR(24),[TransactionStartTime],113),''N/A'') AS ''td'',''''
	FROM [Inspector].[TempDB]
	WHERE Servername = @Servername
	AND Log_Date >= DATEADD(MINUTE,@ReportFrequency,GETDATE())
	AND [DateHour] BETWEEN @MonitorHourStart AND @MonitorHourEnd
	FOR XML PATH(''tr''),ELEMENTS);
END
ELSE 
BEGIN 
	SET @HtmlOutput = 
	(SELECT 
	CASE 
		WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
		WHEN @WarningLevel = 1 THEN @WarningHighlight
		WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
		WHEN @WarningLevel = 3 THEN @InfoHighlight
	END AS [@bgcolor],
	@Servername AS ''td'','''',+
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'',''''
	FOR XML PATH(''tr''),ELEMENTS);

	--Mark Collection as out of date
	SET @CollectionOutOfDate = 1;
END

	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail
		+''<p><BR><p>''


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


IF OBJECT_ID('Inspector.PSGetColumns') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetColumns] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetColumns]
(
@Tablename NVARCHAR(128)
)
AS
BEGIN
SET NOCOUNT ON;

--Revision date: 23/09/2019

SELECT CAST(STUFF(Columnname,1,1,'''') AS VARCHAR(4000)) AS Columnnames
FROM 
(
	SELECT '',''+QUOTENAME(columns.name) 
	FROM sys.tables
	INNER JOIN sys.columns ON tables.object_id = columns.object_id
	WHERE tables.name = @Tablename
	AND [schema_id] = SCHEMA_ID(N''Inspector'')
	AND [is_computed] = 0
	AND [is_ms_shipped] = 0
	ORDER BY tables.name ASC,columns.column_id ASC
	FOR XML PATH('''')
) AS ColumnList (Columnname)
END';


IF OBJECT_ID('Inspector.PSGetInspectorBuild') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetInspectorBuild] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetInspectorBuild]
AS
BEGIN 
--Revision date: 14/09/2018

	SELECT 
	@@SERVERNAME AS Servername,
	CAST([Value] AS DECIMAL(4,2)) AS Build
	FROM [Inspector].[Settings]
	WHERE [Description] = ''InspectorBuild''
END';


IF OBJECT_ID('Inspector.PSGetConfig') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetConfig] AS;')

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetConfig]
(
@Servername NVARCHAR(128),
@ModuleConfig VARCHAR(20) = NULL,
@PSExecModules BIT = 0
)
AS
BEGIN
--Revision date: 01/02/2020
--TableAction: 1 delete, 2 delete with retention, 3 Stage/merge
--InsertAction: 1 ALL, 2 Todays'' data only, 3 Frequency based

DECLARE @DriveSpaceRetentionPeriodInDays VARCHAR(6) = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''DriveSpace'', ''DriveSpaceRetentionPeriodInDays'') AS INT), 90));

IF EXISTS (SELECT 1 FROM [Inspector].[CurrentServers] WHERE [Servername] = @Servername)
BEGIN
SELECT DISTINCT
[PSConfig].Servername,
[PSConfig].ModuleConfig_Desc,
[PSConfig].Modulename,
[PSConfig].Procedurename,
[PSConfig].Tablename,
[PSConfig].StageTablename,
[PSConfig].StageProcname,
[PSConfig].TableAction,
[PSConfig].InsertAction,
[PSConfig].RetentionInDays,
(SELECT [Frequency] FROM [Inspector].[Modules] WHERE [Modules].[ModuleConfig_Desc] = [PSConfig].[ModuleConfig_Desc] AND [Modules].[Modulename] = [PSConfig].[Modulename]) AS [Frequency]
FROM
(
	SELECT 
	[Servername], 
	COALESCE(@ModuleConfig,[ModuleConfig_Desc], ''Default'') AS [ModuleConfig_Desc]
	FROM [Inspector].[CurrentServers]
	WHERE Servername = @Servername
	AND IsActive = 1
) AS ActiveServers
INNER JOIN [Inspector].[PSConfig] ON [ActiveServers].ModuleConfig_Desc = [PSConfig].[ModuleConfig_Desc]
									AND [ActiveServers].[Servername] = [PSConfig].[Servername]
WHERE [PSConfig].[IsActive] = 1
AND (EXISTS(SELECT 1 FROM [Inspector].[ModuleSchedulesDue] WHERE ([PSConfig].ModuleConfig_Desc = [ModuleSchedulesDue].[ModuleConfig_Desc] AND [PSConfig].[Modulename] = [ModuleSchedulesDue].[Modulename]))
OR @PSExecModules = 1)
UNION
SELECT 
@Servername, 
[ActiveServers].[ModuleConfig_Desc], 
[NonModuleColection].[Module], 
[NonModuleColection].[Module]+''Insert'' AS Procedurename, 
CASE 
	WHEN [NonModuleColection].[Module] = ''InstanceVersion'' THEN ''InstanceVersion,InstanceVersionHistory''
	ELSE [NonModuleColection].[Module]
END AS Tablename, 
CASE 
	WHEN [NonModuleColection].[Module] = ''InstanceVersion'' THEN ''N/A,PSInstanceVersionHistoryStage''
	ELSE NULL 
END AS StageTablename, 
CASE 
	WHEN [NonModuleColection].[Module] = ''InstanceVersion'' THEN ''N/A,PSGetInstanceVersionHistoryStage''
	ELSE NULL 
END AS StageProcname, 
CASE 
	WHEN [NonModuleColection].[Module] = ''InstanceVersion'' THEN ''1,3''
	ELSE ''1'' 
END AS TableAction, 
CASE 
	WHEN [NonModuleColection].[Module] = ''InstanceVersion'' THEN ''1,1''
	ELSE ''2'' 
END	AS InsertAction, 
NULL AS RetentionInDays,
1 AS [Frequency]
FROM
(
	SELECT 
	[Servername], 
	COALESCE(@ModuleConfig,[ModuleConfig_Desc], ''Default'') AS [ModuleConfig_Desc]
	FROM [Inspector].[CurrentServers]
	WHERE Servername = @Servername
	AND IsActive = 1
) AS ActiveServers
CROSS APPLY(VALUES(''InstanceStart''), (''InstanceVersion'')) AS NonModuleColection([Module])
ORDER BY [Modulename] ASC;
END

END';


IF OBJECT_ID('Inspector.PSGetServers') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetServers] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetServers]
AS 
BEGIN 
--Revision date: 20/01/2020

	SELECT 
	[Servername]
	FROM [Inspector].[CurrentServers]
	WHERE [IsActive] = 1
	ORDER BY 
	CASE 
		WHEN [Servername] = @@SERVERNAME THEN 2 
		ELSE 1
	END
END';


IF OBJECT_ID('Inspector.PSGetADHocDatabaseCreationsStage') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetADHocDatabaseCreationsStage] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetADHocDatabaseCreationsStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN 
--Revision date: 14/09/2018

SET NOCOUNT ON;

--Delete previous data for server
DELETE 
FROM [Inspector].[ADHocDatabaseCreations]
WHERE Servername = @Servername;

--Insert new data for recent collection
INSERT INTO [Inspector].[ADHocDatabaseCreations] ([Servername], [Log_Date], [Databasename], [Create_Date])
SELECT [Servername], [Log_Date], [Databasename], [Create_Date]
FROM [Inspector].[PSADHocDatabaseCreationsStage] Stage
WHERE Servername = @Servername
AND NOT EXISTS (SELECT 1 
				FROM [Inspector].[ADHocDatabaseCreations] Base
				WHERE Base.Servername = Stage.Servername
				AND Base.Log_Date = Stage.Log_Date 
				AND Base.Databasename = Stage.Databasename)


--Insert if not exists
INSERT INTO [Inspector].[ADHocDatabaseSupression] (Servername, Log_Date, Databasename, Suppress)
SELECT
@Servername,
GETDATE(),
Databasename,
0
FROM [Inspector].[ADHocDatabaseCreations] Creations
WHERE Servername = @Servername
AND Databasename != ''No Ad hoc database creations present''
AND NOT EXISTS (SELECT Databasename 
				FROM [Inspector].[ADHocDatabaseSupression] SuppressList
				WHERE SuppressList.Servername = @Servername AND SuppressList.Databasename = Creations.Databasename);


END';


IF OBJECT_ID('Inspector.PSGetAGDatabasesStage') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetAGDatabasesStage] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetAGDatabasesStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN 
--Revision date: 05/04/2019

SET NOCOUNT ON;

--Insert new data for recent collection
INSERT INTO [Inspector].[AGDatabases] ([Servername], [Log_Date], [LastUpdated], [Databasename], [Is_AG], [Is_AGJoined])
SELECT [Servername], [Log_Date], [LastUpdated], [Databasename], [Is_AG], [Is_AGJoined]
FROM [Inspector].[PSAGDatabasesStage] Stage
WHERE Servername = @Servername
AND NOT EXISTS (SELECT 1 
				FROM [Inspector].[AGDatabases] Base
				WHERE Base.Servername = Stage.Servername
				AND Base.Databasename = Stage.Databasename)


--Update any changes and set LastUpdated Datetime (Is_AG is not updated , this is controlled within the Central Table)
UPDATE Base
SET 
[Is_AGJoined] = Stage.[Is_AGJoined],
[LastUpdated] = GETDATE()
FROM [Inspector].[PSAGDatabasesStage] Stage
INNER JOIN [Inspector].[AGDatabases] Base ON Base.Servername = Stage.Servername	AND Base.Databasename = Stage.Databasename
WHERE Stage.Servername = @Servername;


END';


IF OBJECT_ID('Inspector.PSGetDriveSpaceStage') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetDriveSpaceStage] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetDriveSpaceStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN 

DECLARE @DriveSpaceRetentionPeriodInDays INT = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''DriveSpace'', ''DriveSpaceRetentionPeriodInDays'') AS INT), 90));


--Remove old data for the server
DELETE 
FROM [Inspector].[DriveSpace]
WHERE Servername = @Servername 
AND Log_Date < DATEADD(DAY,-@DriveSpaceRetentionPeriodInDays,DATEADD(DAY,1,CAST(GETDATE() AS DATE)))


--Insert new data for recent collection
INSERT INTO [Inspector].[DriveSpace] ([Servername], [Log_Date], [Drive], [Capacity_GB], [AvailableSpace_GB])
SELECT [Servername], [Log_Date], [Drive], [Capacity_GB], [AvailableSpace_GB]
FROM [Inspector].[PSDriveSpaceStage] Stage
WHERE Servername = @Servername
AND NOT EXISTS (SELECT 1 
				FROM [Inspector].[DriveSpace] Base
				WHERE Base.Servername = Stage.Servername
				AND Base.Log_Date = Stage.Log_Date)

END';


IF OBJECT_ID('Inspector.PSGetDatabaseGrowthsStage') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetDatabaseGrowthsStage] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetDatabaseGrowthsStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN
--Revision date: 08/04/2019

--Update existing records
UPDATE Base 
SET [Database_name] = [PSStage].[Database_name],
[OriginalSize_MB] = [PSStage].[OriginalSize_MB],
[Type_desc] = [PSStage].[Type_desc],
[File_id] = [PSStage].[File_id],
[Filename] = [PSStage].[Filename],
[PostGrowthSize_MB] = [PSStage].[PostGrowthSize_MB],
[GrowthRate] = [PSStage].[GrowthRate],
[Is_percent_growth] = [PSStage].[Is_percent_growth],
[NextGrowth] = [PSStage].[NextGrowth],
[LastUpdated] = [PSStage].[LastUpdated]
FROM [Inspector].[PSDatabaseFileSizesStage] PSStage
INNER JOIN [Inspector].[DatabaseFileSizes] Base ON PSStage.Database_id = Base.Database_id AND PSStage.[File_id] = Base.[File_id] AND Base.[Servername] = @Servername
WHERE PSStage.Servername = @Servername
AND ((PSStage.LastUpdated > Base.LastUpdated OR PSStage.LastUpdated IS NOT NULL AND Base.LastUpdated IS NULL) 
OR [Base].[Filename] != [PSStage].[Filename])

--Insert missing rows in base from stage table
INSERT INTO [Inspector].[DatabaseFileSizes] ([Servername], [Database_id], [Database_name], [OriginalDateLogged], [OriginalSize_MB], [Type_desc], [File_id], [Filename], [PostGrowthSize_MB], [GrowthRate], [Is_percent_growth], [NextGrowth], [LastUpdated])
SELECT 
[Servername], 
[Database_id], 
[Database_name], 
[OriginalDateLogged], 
[OriginalSize_MB], 
[Type_desc], 
[File_id], 
[Filename], 
[PostGrowthSize_MB], 
[GrowthRate], 
[Is_percent_growth], 
[NextGrowth], 
[LastUpdated]
FROM [Inspector].[PSDatabaseFileSizesStage] PSStage
WHERE PSStage.Servername = @Servername
AND NOT EXISTS (SELECT 1 
				FROM [Inspector].[DatabaseFileSizes] Base 
				WHERE PSStage.Database_id = Base.Database_id 
				AND PSStage.[File_id] = Base.[File_id]
				AND Base.Servername = @Servername)

--Insert growth events
INSERT INTO [Inspector].[DatabaseFileSizeHistory] ([Servername], [Database_id], [Database_name], [Log_Date], [Type_Desc], [File_id], [Drive], [FileName], [PreGrowthSize_MB], [GrowthRate_MB], [GrowthIncrements], [PostGrowthSize_MB])
SELECT [Servername], [Database_id], [Database_name], [Log_Date], [Type_Desc], [File_id], [Drive], [FileName], [PreGrowthSize_MB], [GrowthRate_MB], [GrowthIncrements], [PostGrowthSize_MB]
FROM [Inspector].[PSDatabaseFileSizeHistoryStage] PSStage
WHERE NOT EXISTS (SELECT 1 
				FROM [Inspector].[DatabaseFileSizeHistory] Base 
				WHERE PSStage.Database_id = Base.Database_id 
				AND PSStage.[File_id] = Base.[File_id]
				AND Base.Servername = PSStage.Servername
				AND PSStage.Log_Date = Base.Log_Date)

END';


IF OBJECT_ID('Inspector.PSGetInstanceVersionHistoryStage') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetInstanceVersionHistoryStage] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetInstanceVersionHistoryStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN 
--Revision date: 11/01/2019

SET NOCOUNT ON;

--Insert new data for recent collection
INSERT INTO [Inspector].[InstanceVersionHistory] ([Servername], [Log_Date], [CollectionDatetime], [VersionNo], [Edition])
SELECT [Servername], [Log_Date], [CollectionDatetime], [VersionNo], [Edition]
FROM [Inspector].[PSInstanceVersionHistoryStage] Stage
WHERE Servername = @Servername
AND NOT EXISTS (SELECT 1 
				FROM [Inspector].[InstanceVersionHistory] Base
				WHERE Base.Servername = Stage.Servername
				AND Base.Log_Date = Stage.Log_Date 
				AND CAST(Base.Log_Date AS DATE) = CAST(Stage.Log_Date AS DATE)
				);

END';


IF OBJECT_ID('Inspector.PSGetAGPrimaryHistoryStage') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetAGPrimaryHistoryStage] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetAGPrimaryHistoryStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN
--Revision date: 08/05/2019

SET NOCOUNT ON;

--Insert growth events
INSERT INTO [Inspector].[AGPrimaryHistory] ([Log_Date], [CollectionDateTime], [Servername], [AGname])
SELECT [Log_Date], [CollectionDateTime], [Servername], [AGname]
FROM [Inspector].[PSAGPrimaryHistoryStage] PSStage
WHERE NOT EXISTS (SELECT 1 
				FROM [Inspector].[AGPrimaryHistory] Base 
				WHERE PSStage.[AGname] = Base.[AGname]
				AND Base.[Servername] = PSStage.[Servername]
				AND PSStage.[CollectionDateTime] = Base.[CollectionDateTime])

END';


IF OBJECT_ID('Inspector.PSHistCleanup') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSHistCleanup] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSHistCleanup]
AS 
BEGIN 
--Revision date: 07/07/2021
	
DECLARE @Retention INT = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''DriveSpace'', ''DriveSpaceRetentionPeriodInDays'') AS INT), 90));

	--Clean up Drivespace table for history older than @Retention in days
	DELETE FROM [Inspector].[DriveSpace] 
	WHERE Log_Date < DATEADD(DAY,-@Retention,DATEADD(DAY,1,CAST(GETDATE() AS DATE)));
	
	--Clean up the history for growths older than @Retention in days
	DELETE FROM [Inspector].[DatabaseFileSizeHistory]
	WHERE [Log_Date] < DATEADD(DAY,-@Retention,GETDATE());

END';


IF OBJECT_ID('Inspector.PopulatePSConfig') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[PopulatePSConfig] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PopulatePSConfig]
AS
BEGIN
--Revision date: 27/01/2020
--TableAction: 1 delete, 2 delete with retention, 3 Stage/merge
--InsertAction: 1 ALL, 2 Todays'' data only
DECLARE @DriveSpaceRetentionPeriodInDays VARCHAR(6);

SET @DriveSpaceRetentionPeriodInDays = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@@SERVERNAME, ''DriveSpace'', ''DriveSpaceRetentionPeriodInDays'') AS INT), 90));


INSERT INTO [Inspector].[PSConfig] ([Servername], [ModuleConfig_Desc], [Modulename], [Procedurename], [Tablename], [StageTablename], [StageProcname], [TableAction], [InsertAction], [RetentionInDays], [IsActive])
SELECT 
Servername,
ModuleConfig_Desc,
Modulename,
Procedurename,
Tablename,
StageTablename,
StageProcname,
TableAction,
InsertAction,
RetentionInDays,
1
FROM
(
	SELECT 
	[ActiveServers].[Servername], 
	[ActiveServers].[ModuleConfig_Desc], 
	[PSEnabledModules].[Modulename], 
	[CollectionProcedurename] AS Procedurename,
	CASE
		WHEN [PSEnabledModules].[Modulename] = ''DatabaseGrowths''
		THEN ''DatabaseFileSizes,DatabaseFileSizeHistory''
		WHEN [PSEnabledModules].[Modulename] = ''ADHocDatabaseCreations''
		THEN ''ADHocDatabaseCreations,ADHocDatabaseSupression''
		WHEN [PSEnabledModules].[Modulename] = ''AGCheck''
		THEN ''AGCheck,AGPrimaryHistory''
		WHEN [CollectionProcedurename] IS NULL THEN NULL
		ELSE [PSEnabledModules].[Modulename]
	END AS Tablename,
	CASE
		WHEN [PSEnabledModules].[Modulename] IN (''AGDatabases'',''DriveSpace'')
		THEN ''PS''+[PSEnabledModules].[Modulename]+''Stage''
		WHEN [PSEnabledModules].[Modulename] = ''ADHocDatabaseCreations''
		THEN ''PSADHocDatabaseCreationsStage,PSADHocDatabaseSupressionStage''
		WHEN [PSEnabledModules].[Modulename] = ''DatabaseGrowths''
		THEN ''PSDatabaseFileSizesStage,PSDatabaseFileSizeHistoryStage''
		WHEN [PSEnabledModules].[Modulename] = ''AGCheck''
		THEN ''N/A,PSAGPrimaryHistoryStage''
		ELSE NULL
	END AS StageTablename,
	CASE
		WHEN [PSEnabledModules].[Modulename] IN (''AGDatabases'', ''DriveSpace'', ''DatabaseGrowths'', ''ADHocDatabaseCreations'')
		THEN ''PSGet''+[PSEnabledModules].[Modulename]+''Stage''
		WHEN [PSEnabledModules].[Modulename] = ''AGCheck''
		THEN ''N/A,PSGetAGPrimaryHistoryStage''
		ELSE NULL
	END AS StageProcname,
	CASE
		WHEN [PSEnabledModules].[Modulename] IN (''AGDatabases'',''DriveSpace'')
		THEN ''3''
		WHEN [PSEnabledModules].[Modulename] IN (''ADHocDatabaseCreations'',''DatabaseGrowths'')
		THEN ''3,3''
		WHEN [PSEnabledModules].[Modulename] = ''AGCheck''
		THEN ''1,3''
		ELSE ''1''
	END AS TableAction, --1 delete, 2 delete with retention, 3 Stage/merge
	CASE
		WHEN [PSEnabledModules].[Modulename] IN (''AGDatabases'',''BackupSizesByDay'')
		THEN ''1''
		WHEN [PSEnabledModules].[Modulename] IN (''ADHocDatabaseCreations'',''AGCheck'')
		THEN ''1,1''
		WHEN [PSEnabledModules].[Modulename] = ''DatabaseGrowths''
		THEN ''1,2''
		ELSE ''2''
	END AS InsertAction, --1 ALL, 2 Todays'' data only
	CASE 
		WHEN [PSEnabledModules].[Modulename] = (''DatabaseGrowths'') THEN @DriveSpaceRetentionPeriodInDays+'',''+@DriveSpaceRetentionPeriodInDays
		WHEN [PSEnabledModules].[Modulename] = (''DriveSpace'') THEN @DriveSpaceRetentionPeriodInDays
		ELSE NULL 
	END AS RetentionInDays
	FROM
	(
		SELECT 
		[Servername], 
		ISNULL([ModuleConfig_Desc], ''Default'') AS [ModuleConfig_Desc]
		FROM [Inspector].[CurrentServers]
		--WHERE Servername = @Servername
		WHERE IsActive = 1
	) AS ActiveServers
	INNER JOIN [Inspector].[PSEnabledModules] ON [ActiveServers].ModuleConfig_Desc = [PSEnabledModules].[ModuleConfig_Desc]
) AS PSConfigList
WHERE NOT EXISTS (SELECT 1 
						FROM [Inspector].[PSConfig]
						WHERE [PSConfig].[Servername] = [PSConfigList].[Servername]
						AND [PSConfig].[ModuleConfig_Desc] = [PSConfigList].[ModuleConfig_Desc]
						AND [PSConfig].[Modulename] = [PSConfigList].[Modulename]);



END';


IF OBJECT_ID('Inspector.PSGetSettingsTables') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[PSGetSettingsTables] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[PSGetSettingsTables]
(
@SortOrder BIT, --0 FOR ORDER BY TableOrder ASC , 1 FOR ORDER BY TableOrder DESC
@PSCollection BIT = 0 --If its a powershell collection ensure that the WarningLevel table is populated
)
AS 
--Revision date: 24/11/2020

--Config for Powershell collection use only
--TruncateTable - 0 Delete contents, 1 Truncate table
--ReseedTable - 0 do not reseed identity, 1 reseed identity
BEGIN 
	IF @SortOrder IS NULL 
	BEGIN 
		SET @SortOrder = 0;
	END

	IF @PSCollection IS NULL 
	BEGIN 
		SET @PSCollection = 0;
	END

	IF @PSCollection = 1
	BEGIN 
		EXEC [Inspector].[PopulateModuleWarningLevel];
	END

	IF @SortOrder = 0 
	BEGIN 
		SELECT Tablename,TruncateTable,ReseedTable 
		FROM (VALUES
			(1,''Settings'',1,1),
			(2,''CurrentServers'',0,0), 
			--(3,''EmailRecipients'',0,0), 
			(4,''EmailConfig'',0,0),
			(5,''CatalogueModules'',0,0),
			(6,''ModuleWarningLevel'',0,0),
			(7,''AGCheckConfig'',1,0),
			(8,''ServerSettingThresholds'',1,0)
		) SettingsTables(TableOrder,Tablename,TruncateTable,ReseedTable)
		ORDER BY TableOrder ASC;
	END

	IF @SortOrder = 1 
	BEGIN 
		SELECT Tablename,TruncateTable,ReseedTable 
		FROM (VALUES
			(1,''Settings'',1,1),
			(2,''CurrentServers'',0,0), 
			--(3,''EmailRecipients'',0,0), 
			(4,''EmailConfig'',0,0),
			(5,''CatalogueModules'',0,0),
			(6,''ModuleWarningLevel'',0,0),
			(7,''AGCheckConfig'',1,0),
			(8,''ServerSettingThresholds'',1,0)
		) SettingsTables(TableOrder,Tablename,TruncateTable,ReseedTable)
		ORDER BY TableOrder DESC;
	END

END';


IF OBJECT_ID('Inspector.CatalogueMissingLogins') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[CatalogueMissingLogins] AS;');

--Catalogue reporting procs
EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[CatalogueMissingLogins]
(
@Servername NVARCHAR(128),
@TableHeaderColour VARCHAR(7) = NULL,
@WarningLevelFontColour VARCHAR(7) = NULL,
@HtmlOutput VARCHAR(MAX) OUTPUT,
@ModuleConfig VARCHAR(20),
@PSCollection BIT
)
AS
--Revision date: 09/05/2019
BEGIN
SET NOCOUNT ON;

DECLARE @PreReqsEnabled INT
DECLARE @ReportStart DATETIME = GETDATE();
DECLARE @Duration MONEY

--Ensure that all modules required for this check are enabled
EXEC sp_executesql N''SELECT @EnabledCount = COUNT([Active]) FROM [Catalogue].[ConfigModules] WHERE ModuleName IN (''''Availability Groups'''',''''Databases'''',''''Logins'''',''''Users'''') AND [Active] = 1;'',
N''@EnabledCount INT OUTPUT'',@EnabledCount = @PreReqsEnabled OUTPUT


IF @PreReqsEnabled < 4
BEGIN 
	RAISERROR(''PreRequisites for the Catalogue Missing Logins module are not enabled in the Catalogue'',0,0) WITH NOWAIT;
	RETURN;
END 

IF @TableHeaderColour IS NULL BEGIN SET @TableHeaderColour = ''#E6E6FA'' END;

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
AND AGs.LastRecorded >= DATEADD(DAY,-1,GETDATE())
AND Logins.LastRecorded >= DATEADD(DAY,-1,GETDATE())
AND AGs2.LastRecorded >= DATEADD(DAY,-1,GETDATE())
AND EXISTS (SELECT 1 FROM [Catalogue].[ExecutionLog] WHERE [ExecutionDate] >= DATEADD(DAY,-1,GETDATE()))

SET @HtmlOutput = (
SELECT  
@WarningLevelFontColour AS [@bgcolor],
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
	AND AGs.LastRecorded >= DATEADD(DAY,-1,GETDATE())
	AND Logins.LastRecorded >= DATEADD(DAY,-1,GETDATE())
	AND Users.LastRecorded >= DATEADD(DAY,-1,GETDATE())
	AND Databases.LastRecorded >= DATEADD(DAY,-1,GETDATE())
) AS MissingLoginInfo
FOR XML PATH(''''tr''''),ELEMENTS);'',N''@Servername NVARCHAR(128), @WarningLevelFontColour VARCHAR(7), @HtmlOutput VARCHAR(MAX) OUTPUT'',
@Servername = @Servername, @WarningLevelFontColour = @WarningLevelFontColour, @HtmlOutput = @HtmlOutput OUTPUT;


IF @HtmlOutput IS NOT NULL 
BEGIN 
    SET @HtmlOutput = 
    ''<b><A NAME = "''+REPLACE(@Servername,''\'','''')+''MissingLogins''+''"></a>Missing Logins:</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Servername</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>LoginName</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>CreateCommand</b></font></td>	
	''+@HtmlOutput
	+''</table><p><A HREF = "#Warnings">Back to Top</a><p>'';
END 

SET @Duration = CAST(DATEDIFF(MILLISECOND,@ReportStart,GETDATE()) AS MONEY)/1000;

EXEC [Inspector].[ExecutionLogInsert] 
@RunDatetime = @ReportStart, 
@Servername = @Servername, 
@ModuleConfigDesc = @ModuleConfig,
@Procname = N''CatalogueMissingLogins'', 
@Duration = @Duration,
@PSCollection = @PSCollection;

END';


IF OBJECT_ID('Inspector.CatalogueDroppedTables') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[CatalogueDroppedTables] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[CatalogueDroppedTables]
(
@Servername NVARCHAR(128),
@TableHeaderColour VARCHAR(7) = NULL,
@WarningLevelFontColour VARCHAR(7) = NULL,
@HtmlOutput VARCHAR(MAX) OUTPUT,
@ModuleConfig VARCHAR(20),
@PSCollection BIT
)
AS
--Revision date: 16/03/2019
BEGIN

DECLARE @LastestExecution DATETIME
DECLARE @ReportStart DATETIME = GETDATE();
DECLARE @Duration MONEY

IF @TableHeaderColour IS NULL BEGIN SET @TableHeaderColour = ''#E6E6FA'' END;

EXEC sp_executesql N''SELECT @LastestExecution = MAX(ExecutionDate) FROM [Catalogue].[ExecutionLog];'',
N''@LastestExecution DATETIME OUTPUT'',@LastestExecution = @LastestExecution OUTPUT;

EXEC sp_executesql 
N''
SET @HtmlOutput = (
SELECT 
@WarningLevelFontColour AS [@bgcolor],
CatalogueTables.ServerName AS ''''td'''','''''''', +
CatalogueTables.DatabaseName AS ''''td'''','''''''', +
CatalogueTables.SchemaName AS ''''td'''','''''''', +
CatalogueTables.TableName AS ''''td'''','''''''', +
CONVERT(VARCHAR(17),CatalogueTables.LastRecorded,113) AS ''''td'''','''''''' 
FROM [Inspector].[CurrentServers] InspectorServers
INNER JOIN [Catalogue].[Tables] CatalogueTables ON CatalogueTables.ServerName = InspectorServers.Servername 
WHERE CatalogueTables.ServerName = @Servername
AND [CatalogueTables].[LastRecorded] >= DATEADD(DAY,-1,GETDATE())
AND [CatalogueTables].[LastRecorded] < @LastestExecution
AND [DatabaseName] != ''''tempdb''''
AND NOT EXISTS (SELECT 1 FROM [Catalogue].[Databases] CatalogueDatabases 
				WHERE CatalogueDatabases.ServerName = InspectorServers.Servername 
				AND  CatalogueDatabases.DBName= CatalogueTables.DatabaseName 
				AND  [CatalogueDatabases].[LastRecorded] < @LastestExecution)
FOR XML PATH(''''tr''''),ELEMENTS);'',N''@Servername NVARCHAR(128), @WarningLevelFontColour VARCHAR(7), @LastestExecution DATETIME,@HtmlOutput VARCHAR(MAX) OUTPUT'',
@Servername = @Servername, @WarningLevelFontColour = @WarningLevelFontColour,@LastestExecution = @LastestExecution,@HtmlOutput = @HtmlOutput OUTPUT;


IF @HtmlOutput IS NOT NULL 
BEGIN 
    SET @HtmlOutput = 
    ''<b><A NAME = "''+REPLACE(@Servername,''\'','''')+''DroppedTables''+''"></a>Tables dropped in the last 24hrs:</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Servername</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Database name</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Schema name</b></font></td>	
	<td bgcolor=''+@TableHeaderColour+''><b>Table name</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>LastSeenByCatalogue</b></font></td>
	''+@HtmlOutput
	+''</table><p><A HREF = "#Warnings">Back to Top</a><p>'';
END 

SET @Duration = CAST(DATEDIFF(MILLISECOND,@ReportStart,GETDATE()) AS MONEY)/1000;

EXEC [Inspector].[ExecutionLogInsert] 
@RunDatetime = @ReportStart, 
@Servername = @Servername, 
@ModuleConfigDesc = @ModuleConfig,
@Procname = N''CatalogueDroppedTables'', 
@Duration = @Duration,
@PSCollection = @PSCollection;

END';


IF OBJECT_ID('Inspector.CatalogueDroppedDatabases') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[CatalogueDroppedDatabases] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[CatalogueDroppedDatabases]
(
@Servername NVARCHAR(128),
@TableHeaderColour VARCHAR(7) = NULL,
@WarningLevelFontColour VARCHAR(7) = NULL,
@HtmlOutput VARCHAR(MAX) OUTPUT,
@ModuleConfig VARCHAR(20),
@PSCollection BIT
)
AS
--Revision date: 16/03/2019
BEGIN

DECLARE @LastestExecution DATETIME
DECLARE @ReportStart DATETIME = GETDATE();
DECLARE @Duration MONEY

IF @TableHeaderColour IS NULL BEGIN SET @TableHeaderColour = ''#E6E6FA'' END;

EXEC sp_executesql N''SELECT @LastestExecution = MAX(ExecutionDate) FROM [Catalogue].[ExecutionLog];'',
N''@LastestExecution DATETIME OUTPUT'',@LastestExecution = @LastestExecution OUTPUT;

EXEC sp_executesql 
N''
SET @HtmlOutput = (
SELECT 
@WarningLevelFontColour AS [@bgcolor], 
CatalogueDatabases.ServerName AS ''''td'''','''''''', +
CatalogueDatabases.DBName AS ''''td'''','''''''', +
ISNULL(AGName,N''''Not in an AG'''') AS ''''td'''','''''''', +
CatalogueDatabases.FilePaths AS ''''td'''','''''''', +
DATEDIFF(DAY,FirstRecorded,LastRecorded) AS ''''td'''','''''''', +
CONVERT(VARCHAR(17),CatalogueDatabases.LastRecorded,113) AS ''''td'''',''''''''
FROM [Catalogue].[Databases] CatalogueDatabases
INNER JOIN [Inspector].[CurrentServers] InspectorServers ON CatalogueDatabases.ServerName = InspectorServers.Servername 
WHERE CatalogueDatabases.ServerName = @Servername
AND [CatalogueDatabases].[LastRecorded] >= DATEADD(DAY,-1,GETDATE())
AND [CatalogueDatabases].[LastRecorded] < @LastestExecution
FOR XML PATH(''''tr''''),ELEMENTS);'',N''@Servername NVARCHAR(128), @WarningLevelFontColour VARCHAR(7), @LastestExecution DATETIME,@HtmlOutput VARCHAR(MAX) OUTPUT'',
@Servername = @Servername, @WarningLevelFontColour = @WarningLevelFontColour,@LastestExecution = @LastestExecution,@HtmlOutput = @HtmlOutput OUTPUT;


IF @HtmlOutput IS NOT NULL 
BEGIN 
    SET @HtmlOutput = 
    ''<b><A NAME = "''+REPLACE(@Servername,''\'','''')+''DroppedDatabases''+''"></a>Databases dropped in the last 24hrs:</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Servername</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Database name</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>AG name</b></font></td>	
	<td bgcolor=''+@TableHeaderColour+''><b>File paths</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>DaysSeenByCatalogue</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>LastSeenByCatalogue</b></font></td>
	''+@HtmlOutput
	+''</table><p><A HREF = "#Warnings">Back to Top</a><p>'';
END 

SET @Duration = CAST(DATEDIFF(MILLISECOND,@ReportStart,GETDATE()) AS MONEY)/1000;

EXEC [Inspector].[ExecutionLogInsert] 
@RunDatetime = @ReportStart, 
@Servername = @Servername, 
@ModuleConfigDesc = @ModuleConfig,
@Procname = N''CatalogueDroppedDatabases'', 
@Duration = @Duration,
@PSCollection = @PSCollection;

END';


IF OBJECT_ID('Inspector.ADHocDatabaseCreationsReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[ADHocDatabaseCreationsReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[ADHocDatabaseCreationsReport]
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
BEGIN
--Revision date: 20/04/2021

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Potential Ad hoc database creations in the last 7 days'',
		@TableHeaderColour,
		''Database name,Create date,Suppress database'')
	);

	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Databasename AS ''td'','''', + 
		CONVERT(VARCHAR(17),Create_Date,113) AS ''td'','''', +
		''EXEC [''+DB_NAME()+''].[Inspector].[SuppressAdHocDatabase] @Databasename = ''''''+Databasename+'''''', @Servername = ''''''+@Servername+'''''';'' AS ''td'',''''
		FROM [Inspector].[ADHocDatabaseCreations]
		WHERE Servername = @Servername
		AND Databasename != ''No Ad hoc database creations present''
		AND Databasename NOT IN (
				SELECT Databasename 
				FROM [Inspector].[ADHocDatabaseSupression] Suppressed
				WHERE Servername = @Servername 
				AND Suppressed.Suppress = 1)
		ORDER BY Create_Date ASC
		FOR XML PATH(''tr''),ELEMENTS);

		IF @HtmlOutput IS NULL
		BEGIN 
			SET @HtmlOutput =
			(SELECT 
			''#FFFFFF''  AS [@bgcolor],
			''No Ad hoc database creations present'' AS ''td'','''', + 
			''N/A'' AS ''td'','''', +
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN
		SET @HtmlOutput =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	IF (@NoClutter = 1)
	BEGIN
		IF (@HtmlOutput LIKE ''%No Ad hoc database creations present%'')
		BEGIN 
			SET @HtmlOutput = NULL;
		END
	END


	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail 
		+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.AGCheckReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[AGCheckReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[AGCheckReport]
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
BEGIN
--Revision date: 20/04/2021

	DECLARE @HtmlTableHeadAG VARCHAR(2000);
	DECLARE @HtmlTableHeadFailover VARCHAR(2000);
	DECLARE @FailoverCheckHTML VARCHAR(MAX);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHeadAG = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,@Modulename,
		@ServerSpecific,
		''Availability Group Health Check'',
		@TableHeaderColour,
		''Server name,AG name,State,Replica Server Name,Replica Role,Failover Ready,Suspended,Suspend Reason,Failover Ready Threshold'')
	);

	SET @HtmlTableHeadFailover = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''New Primary servers in the last 24 hours'',
		@TableHeaderColour,
		''Previously checked,Last checked,AG name,Primary Replica'')
	);

	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput = (
		SELECT 
		CASE 
			WHEN @WarningLevel IS NULL AND (([AGCheck].[State] != ''HEALTHY'' AND [AGCheck].[State] != ''N/A'' ) OR ([FailoverReadyCount] < ISNULL([FailoverReadyNodeCount],2)) AND [AGCheck].[ReplicaServername] = @Servername AND [AGCheck].[ReplicaRole] = N''PRIMARY'') THEN @WarningHighlight
			WHEN @WarningLevel = 1 AND (([AGCheck].[State] != ''HEALTHY'' AND [AGCheck].[State] != ''N/A'') OR ([FailoverReadyCount] < ISNULL([FailoverReadyNodeCount],2)) AND [AGCheck].[ReplicaServername] = @Servername AND [AGCheck].[ReplicaRole] = N''PRIMARY'') THEN @WarningHighlight
			WHEN @WarningLevel = 2 AND (([AGCheck].[State] != ''HEALTHY'' AND [AGCheck].[State] != ''N/A'') OR ([FailoverReadyCount] < ISNULL([FailoverReadyNodeCount],2)) AND [AGCheck].[ReplicaServername] = @Servername AND [AGCheck].[ReplicaRole] = N''PRIMARY'') THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 AND (([AGCheck].[State] != ''HEALTHY'' AND [AGCheck].[State] != ''N/A'') OR ([FailoverReadyCount] < ISNULL([FailoverReadyNodeCount],2)) AND [AGCheck].[ReplicaServername] = @Servername AND [AGCheck].[ReplicaRole] = N''PRIMARY'') THEN @InfoHighlight
			ELSE ''#FFFFFF''
		END AS [@bgcolor],
		[AGCheck].Servername  AS ''td'','''', +
		[AGCheck].[AGname]  AS ''td'','''', +
		[AGCheck].[State]  AS ''td'','''', +
		ISNULL([AGCheck].[ReplicaServername],''N/A'') AS ''td'','''', +
		ISNULL([AGCheck].[ReplicaRole],''N/A'') AS ''td'','''', +
		CASE 
			WHEN [AGCheck].[FailoverReady] = 1 THEN ''Y'' 
			WHEN [AGCheck].[FailoverReady] = 0 THEN ''N''
			ELSE ''N/A'' 
		END AS ''td'','''', +
		CASE 
			WHEN [AGCheck].[Suspended] = 1 THEN ''Y'' 
			WHEN [AGCheck].[Suspended] = 0 THEN ''N''
			ELSE ''N/A'' 
		END  AS ''td'','''', +
		ISNULL([AGCheck].[SuspendReason],''N/A'') AS ''td'','''', +
		ISNULL([FailoverReadyNodeCount],2) AS ''td'',''''
		FROM [Inspector].[AGCheck]
		LEFT JOIN (SELECT AGname, COUNT(AGname) AS FailoverReadyCount 
					FROM [Inspector].[AGCheck] 
					WHERE [FailoverReady] = 1 AND [Servername] = @Servername 
					GROUP BY AGname) AS FailoverReadyCounts 
					ON FailoverReadyCounts.AGname = [AGCheck].AGname
		LEFT JOIN (SELECT 
					AGname,
					CASE 
						WHEN [FailoverReadyNodeCount] > 10 THEN [FailoverReadyNodePercentCount]
						ELSE [FailoverReadyNodeCount]
					END AS [FailoverReadyNodeCount]
					FROM [Inspector].[AGCheckConfig]) AS FailoverReadyConfig
					ON [FailoverReadyConfig].[AGname] = [AGCheck].[AGname]
		WHERE [AGCheck].[Servername] = @Servername
		ORDER BY [AGCheck].[AGname] ASC,[AGCheck].[ReplicaServername] ASC
		FOR XML PATH(''tr''),ELEMENTS);
		
		--Failover check added in V1.4
		/* if there has been a data collection since the last report frequency minutes ago then run the report */
		IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
		BEGIN 			
			SET @FailoverCheckHTML +=
			(SELECT 
			 CASE 
				WHEN @WarningLevel IS NULL THEN @WarningHighlight
				WHEN @WarningLevel = 1 THEN @WarningHighlight
				WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
				WHEN @WarningLevel = 3 THEN @InfoHighlight
			 	ELSE ''#FFFFFF''
			 END AS [@bgcolor],
			 CONVERT(VARCHAR(17),[Log_Date],113) AS ''td'','''', +
			 CONVERT(VARCHAR(17),[CollectionDateTime],113) AS ''td'','''', +
			 [AGname] AS ''td'','''', +
			 [Servername] AS ''td'',''''
			 FROM [Inspector].[AGPrimaryHistory]
			 WHERE [Servername] = @Servername
			 AND [CollectionDateTime] >= DATEADD(DAY,-1,GETDATE())
			 ORDER BY [AGname] ASC, [Servername] ASC
			 FOR XML PATH(''tr''),ELEMENTS);

			 SET @FailoverCheckHTML += ISNULL(@TableTail,'''') + ''<p><BR><p>''
		END	

		--If @NoClutter is on we do not want to show the table if it has @InfoHighlight against the row/s
		IF (@NoClutter = 1)
		BEGIN 
			IF (@HtmlOutput LIKE ''%HADR IS NOT ENABLED ON THIS SERVER OR YOU HAVE NO AVAILABILITY GROUPS%'')
			BEGIN 
				SET @HtmlOutput = NULL;
			END
		END

		IF (@HtmlOutput IS NOT NULL)
		BEGIN 
		SET @HtmlOutput = 
			@HtmlTableHeadAG
			+ @HtmlOutput
			+ @TableTail 
			+''<p><BR><p>''
			+ CASE 
				WHEN @FailoverCheckHTML IS NOT NULL THEN ISNULL(@HtmlTableHeadFailover,'''')
				+ ISNULL(@FailoverCheckHTML,'''')
				ELSE ''''
			END;
		END
	
	END
	ELSE
	BEGIN
		SET @HtmlOutput = (
		SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @WarningHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Servername  AS ''td'','''', +
		''Data collection out of date'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FROM [Inspector].[AGCheck]
		WHERE Servername = @Servername
		ORDER BY AGname ASC
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;

		SET @HtmlOutput = 
			@HtmlTableHeadAG
			+ @HtmlOutput
			+ @TableTail 
			+''<p><BR><p>''
	END

	--If @NoClutter is on we do not want to show the table if it has @InfoHighlight against the row/s
	IF (@HtmlOutput LIKE ''%''+@InfoHighlight+''%'')
	BEGIN 
		SET @HtmlOutput = NULL;
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
	@HtmlTableHeadAG AS ''@HtmlTableHeadAG'',
	@HtmlTableHeadFailover AS ''@HtmlTableHeadFailover'',
	@FailoverCheckHTML AS ''@FailoverCheckHTML'',
	@CollectionOutOfDate AS ''@CollectionOutOfDate'',
	@PSCollection AS ''@PSCollection''
END 

END';


IF OBJECT_ID('Inspector.AGDatabasesReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[AGDatabasesReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[AGDatabasesReport]
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
BEGIN
--Revision date: 20/04/2021

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Databases not in an AG'',
		@TableHeaderColour,
		''Server name,Last Checked,Database name,Suppress database'')
	);


	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput =(
		SELECT
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		[Servername] AS ''td'','''', +
		CONVERT(VARCHAR(17),[LastUpdated],113) AS ''td'','''', +
		[Databasename] AS ''td'','''', +
		''EXEC [''+DB_NAME()+''].[Inspector].[SuppressAGDatabase] @Databasename = ''''''+Databasename+'''''', @Servername = ''''''+@Servername+'''''';'' AS ''td'',''''
		FROM [Inspector].[AGDatabases]
		WHERE [Is_AG] = 1
		AND [Is_AGJoined] = 0
		AND Servername = @Servername
		ORDER BY [Databasename] ASC
		FOR XML PATH(''tr''),ELEMENTS);
		
		IF @HtmlOutput IS NULL
		BEGIN
			SET @HtmlOutput =(
			SELECT
			''#FFFFFF'' AS [@bgcolor], 
			@Servername AS ''td'','''', +
			''No Databases marked as AG and not joined'' AS ''td'','''', +
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END

		--If @NoClutter is on we do not want to show the table if it has @InfoHighlight against the row/s
		IF (@NoClutter = 1)
		BEGIN 
			IF (@HtmlOutput LIKE ''%No Databases marked as AG and not joined%'')
			BEGIN 
				SET @HtmlOutput = NULL;
			END
		END

		IF (@HtmlOutput IS NOT NULL)
		BEGIN 
		SET @HtmlOutput = 
			@HtmlTableHead
			+ @HtmlOutput
			+ @TableTail 
			+''<p><BR><p>''
		END
	END
	ELSE
	BEGIN
		SET @HtmlOutput =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor], 
		@Servername AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),Elements);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;

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

 
IF OBJECT_ID('Inspector.BackupsCheckReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[BackupsCheckReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[BackupsCheckReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @FullBackupThreshold INT = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold] (@Servername,@Modulename,''FullBackupThreshold'') AS INT),8));
	DECLARE @DiffBackupThreshold INT = (SELECT TRY_CAST([Inspector].[GetServerModuleThreshold] (@Servername,@Modulename,''DiffBackupThreshold'') AS INT));
	DECLARE @LogBackupThreshold	INT = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold] (@Servername,@Modulename,''LogBackupThreshold'') AS INT),20));
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

--Excluded from Warning level control
	IF OBJECT_ID(''tempdb.dbo.#RawData'') IS NOT NULL 
	DROP TABLE #RawData;

	CREATE TABLE #RawData
	(
	Log_Date DATETIME,
	Databasename NVARCHAR(128),
	LastFull DATETIME,
	LastDiff DATETIME,
	LastLog DATETIME,
	AGname NVARCHAR(128),
	GroupingMethod NVARCHAR(128), 
	Servername NVARCHAR(128),
	IsFullRecovery BIT,
	IsSystemDB BIT,
	primary_replica NVARCHAR(128),
	backup_preference NVARCHAR(60)
	);

	IF OBJECT_ID(''tempdb.dbo.#Aggregates'') IS NOT NULL
	DROP TABLE #Aggregates;

	CREATE TABLE #Aggregates
	(
	Log_Date DATETIME,
	Databasename NVARCHAR(128),
	LastFull DATETIME,
	LastDiff DATETIME,
	LastLog DATETIME,
	AGname NVARCHAR(128),
	GroupingMethod NVARCHAR(128), 
	IsFullRecovery BIT,
	IsSystemDB BIT,
	primary_replica NVARCHAR(128),
	backup_preference NVARCHAR(60)
	);

	CREATE CLUSTERED INDEX [CIX_RawData] ON #RawData
	(GroupingMethod,Databasename,IsFullRecovery,IsSystemDB,AGname);

	IF OBJECT_ID(''tempdb.dbo.#Validations'') IS NOT NULL 
	DROP TABLE #Validations; 

	CREATE TABLE #Validations
	(
	Databasename NVARCHAR(128),
    AGname NVARCHAR(128),
	FullState VARCHAR(25),
	DiffState VARCHAR(25),
	LogState VARCHAR(25),
	IsFullRecovery CHAR(1),
	Serverlist VARCHAR(1000),
	primary_replica NVARCHAR(128),
	backup_preference NVARCHAR(60),
	NamedInstance BIT
	);

	DECLARE @NamedInstance BIT

	IF @Servername LIKE ''%\%'' BEGIN SET @NamedInstance = 1 END ELSE BEGIN SET @NamedInstance = 0 END;


	DECLARE @HtmlTableHead VARCHAR(2000);

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (@Servername,@Modulename,@ServerSpecific,''The following Databases are missing database backups:'',@TableHeaderColour,''Servername,Database name,AG name,Last Full,Last Diff,Last Log,Full Recovery,AG Backup Pref,Preferred Servers''));


	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		INSERT INTO #RawData (Log_Date,Databasename,LastFull,LastDiff,LastLog,AGname,GroupingMethod,Servername,IsFullRecovery,IsSystemDB,primary_replica,backup_preference)
		SELECT 
		Log_Date,
		LTRIM(RTRIM(BackupSet.Databasename)), --Added trim as Leading and trailing spaces can cause misreporting
		[FULL] AS LastFull,
		[DIFF] AS LastDiff,
		[LOG] AS LastLog,
		BackupSet.AGname,
		CASE WHEN BackupSet.AGname = ''Not in an AG'' THEN Servername
		ELSE BackupSet.AGname END AS GroupingMethod,  
		Servername,
		BackupSet.IsFullRecovery,
		BackupSet.IsSystemDB,
		BackupSet.primary_replica,
		BackupSet.backup_preference
		FROM [Inspector].[BackupsCheck] BackupSet
		WHERE NOT EXISTS (SELECT 1 
					FROM [Inspector].[BackupsCheckExcludes] 
					WHERE [Servername] = [BackupSet].[Servername] 
					AND [Databasename] = [BackupSet].[Databasename]
					AND ([SuppressUntil] IS NULL OR [SuppressUntil] >= GETDATE())
					);
		  	
			
		INSERT INTO #Aggregates (Log_Date,Databasename,LastFull,LastDiff,LastLog,AGname,GroupingMethod,IsFullRecovery,IsSystemDB,primary_replica,backup_preference)
		SELECT 
		MAX(Log_Date),
		RawData.Databasename,
		MAX(LastFull) AS LastFull,
		MAX(LastDiff) AS LastDiff,
		MAX(LastLog) AS LastLog,
		AGname,
		GroupingMethod,
		IsFullRecovery,
		IsSystemDB,
		MAX(primary_replica),
		UPPER(backup_preference) AS backup_preference
		FROM #RawData RawData
		GROUP BY Databasename,AGname,GroupingMethod,IsFullRecovery,IsSystemDB,backup_preference;
		  
		  
		INSERT INTO #Validations (Databasename,AGname,FullState,DiffState,LogState,IsFullRecovery,Serverlist,primary_replica,backup_preference,NamedInstance)
		SELECT 
		Databasename,
		AGname,
		CASE
			WHEN [LastFull] = ''19000101'' THEN ''More than ''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Days Ago''
			WHEN ([LastFull] >= ''19000101'' AND [LastFull] < DATEADD(DAY,-@FullBackupThreshold,[Log_Date]) OR [LastFull] IS NULL) THEN ISNULL(CONVERT(VARCHAR(17),[LastFull],113),''More then ''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' days ago'')
			ELSE ''OK'' 
		END AS [FullState], 
		CASE 
			WHEN @DiffBackupThreshold IS NOT NULL 
			THEN CASE
					WHEN [LastDiff] = ''19000101'' AND IsSystemDB = 0 THEN ''More than ''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Days Ago''
					WHEN ([LastDiff] >= ''19000101'' AND [LastDiff] < DATEADD(HOUR,-@DiffBackupThreshold,[Log_Date])  OR [LastDiff] IS NULL) AND IsSystemDB = 0 THEN ISNULL(CONVERT(VARCHAR(17),[LastDiff],113),''More then ''+CAST(@DiffBackupThreshold AS VARCHAR(3))+'' Hours ago'')
					WHEN IsSystemDB = 1 THEN ''N/A''
		  			ELSE ''OK'' 
				 END 
			ELSE ''N/A''
		END AS [DiffState],		  	
		CASE 
			WHEN  [LastLog] = ''19000101'' AND IsSystemDB = 0 AND Aggregates.IsFullRecovery = 1 THEN ''More than ''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Days Ago''
			WHEN (([LastLog] >= ''19000101'' AND [LastLog] < DATEADD(MINUTE,-@LogBackupThreshold,[Log_Date]) OR [LastLog] IS NULL) AND IsSystemDB = 0 AND (Aggregates.IsFullRecovery = 1 OR CAST(Aggregates.IsFullRecovery AS VARCHAR(3)) = ''N/A'')) THEN ISNULL(CONVERT(VARCHAR(17),[LastLog] ,113),''More than ''+CAST(@LogBackupThreshold AS VARCHAR(3))+'' Minutes ago'')
			WHEN Aggregates.IsFullRecovery = 0  OR IsSystemDB = 1 THEN ''N/A''
			ELSE ''OK'' 
		END AS [LogState],
		CASE IsFullRecovery WHEN 1 THEN ''Y'' ELSE ''N'' END AS IsFullRecovery,
		STUFF(Serverlist.Serverlist,1,1,'''') AS Serverlist,
		primary_replica,
		backup_preference,
		CASE 
			WHEN primary_replica LIKE ''%\%'' THEN 1 
			ELSE 0 
		END		
		FROM #Aggregates Aggregates
		CROSS APPLY (SELECT 
			CASE 
				WHEN backup_preference IN (''PRIMARY'',''NON AG'') THEN '', '' + primary_replica
				ELSE '', '' + Servername	
			END
			FROM #RawData RawData
			WHERE Aggregates.GroupingMethod = RawData.GroupingMethod
			AND Aggregates.Databasename = RawData.Databasename 
			AND Aggregates.IsFullRecovery = RawData.IsFullRecovery
			AND Aggregates.IsSystemDB = RawData.IsSystemDB
			AND Aggregates.AGname = RawData.AGname
			ORDER BY 1 ASC
			FOR XML PATH('''')
		) AS Serverlist (Serverlist);
		  
		  
		SET @HtmlOutput = (
		SELECT 
		@WarningHighlight AS [@bgcolor],
		Servername AS ''td'','''', +  
		Databasename AS ''td'','''', +
		AGname AS ''td'','''', +
		FullState AS ''td'','''', +
		DiffState AS ''td'','''', +
		LogState AS ''td'','''', +
		IsFullRecovery AS ''td'','''', +
		backup_preference AS ''td'','''', +
		Serverlist AS ''td'',''''
		FROM
		(
			SELECT
			@Servername AS Servername,
			Databasename,
			AGname,
			FullState,
			DiffState,
			LogState,
			IsFullRecovery,
			CASE 
				WHEN backup_preference = ''PRIMARY'' THEN ''Primary only''
				WHEN backup_preference = ''SECONDARY'' THEN ''Prefer secondary''
				WHEN backup_preference = ''SECONDARY_ONLY'' THEN ''Secondary only''
				WHEN backup_preference = ''NONE'' THEN ''Any replica''
				WHEN backup_preference = ''NON AG'' THEN ''N/A''
				ELSE backup_preference  
			END AS backup_preference,
			CASE --Ensure only the relevant server names are being shown in the Server list
				WHEN ([FullState] != ''OK'' OR [DiffState] != ''OK'' AND [DiffState] != ''N/A'') AND [LogState] = ''OK'' THEN primary_replica
				WHEN backup_preference = ''SECONDARY_ONLY'' THEN REPLACE(REPLACE(Serverlist,'', ''+@Servername,''''),@Servername+'', '','''')
				ELSE Serverlist
			END AS Serverlist
			FROM #Validations
			WHERE ([FullState] != ''OK'' OR ([DiffState] != ''OK'' AND [DiffState] != ''N/A'') OR ([LogState] != ''OK'' AND [LogState] != ''N/A''))
			AND Serverlist like ''%''+@Servername+''%''
			AND NamedInstance = @NamedInstance
		) AS DerivedValidations
		WHERE (Serverlist = Servername OR Serverlist LIKE ''%''+Servername+''%'')
		ORDER BY Databasename ASC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		IF @HtmlOutput IS NULL
		BEGIN
			SET @HtmlOutput = (
			SELECT 
			''#FFFFFF'' [@bgcolor], 
			@Servername AS ''td'','''', + 
			''No backup issues present''  AS ''td'','''', +
			''N/A''  AS ''td'','''', +
			''N/A''  AS ''td'','''', +
			''N/A''  AS ''td'','''', +
			''N/A''  AS ''td'','''', +
			''N/A''  AS ''td'','''', +
			''N/A''  AS ''td'','''', +
			''N/A''  AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS)
		END


		--Append html table to the report
		SET  @HtmlOutput =  
		CASE 
			WHEN @HtmlOutput LIKE ''%No backup issues present%'' AND @NoClutter = 1 THEN ''''
			ELSE ISNULL(@HtmlTableHead, '''') + ISNULL(@HtmlOutput, '''') +''</table><p><font style="color: Black; background-color: ''+@WarningHighlight+''">Warning Highlight Thresholds:</font><br>
		Last FULL backup older than <b>''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Day/s</b><br>
		''+ CASE WHEN @DiffBackupThreshold IS NOT NULL THEN ''Last DIFF backup older than <b>''+ CAST(@DiffBackupThreshold AS VARCHAR(3))+'' Hour/s</b><br>'' ELSE ''DIFF backups excluded from check</b><br>'' END +
		''Last Log backup older than <b>''+CAST(@LogBackupThreshold AS VARCHAR(3))+'' Minute/s</b><br>
		Databases Excluded for this server: <b>''+(SELECT CAST(COUNT(Servername) AS VARCHAR(6)) FROM [Inspector].[BackupsCheckExcludes] WHERE Servername = @Servername AND ([SuppressUntil] IS NULL OR [SuppressUntil] >= GETDATE()))+''</b></p></b>''
		+ ISNULL(REPLACE(@TableTail,''</table>'',''''),'''') +''<p><BR><p>''
		END;


		--IF (@HtmlOutput IS NOT NULL)
		--BEGIN 
		--SET @HtmlOutput = 
		--	@HtmlTableHead
		--	+ @HtmlOutput
		--	+ @TableTail 
		--	+''<p><BR><p>''
		--END
	END
	ELSE
	BEGIN
		SET @HtmlOutput = (
		SELECT 
		@WarningHighlight [@bgcolor],
		@Servername AS ''td'','''', +  
		''Data Collection out of date''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS)

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;

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


IF OBJECT_ID('Inspector.BackupSizesByDayReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[BackupSizesByDayReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[BackupSizesByDayReport]
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
BEGIN
--Revision date: 20/04/2021	
	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (@Servername,@Modulename,@ServerSpecific,''Backup Sizes by Day for server:'',@TableHeaderColour,''Day Of Week,Total Backup Size GB''));


--Excluded from Warning level control
	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput =   
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		[DayOfWeek] AS ''td'','''', + 
		[TotalBackupSize_GB] AS ''td'','''' 
		FROM (
		SELECT 
		[DayOfWeek],
		[CastedDate],
		CAST(SUM(((TotalSizeInBytes)/1024)/1024)/1024 AS DECIMAL (10,1)) AS [TotalBackupSize_GB]
		FROM [Inspector].[BackupSizesByDay]
		WHERE Servername = @Servername
		AND Log_Date IS NOT NULL
		GROUP BY [DayOfWeek],[CastedDate]
		) BackupSizesByDay
		ORDER BY CastedDate ASC
		FOR XML PATH(''tr''),ELEMENTS);  	
		
		IF (@HtmlOutput IS NOT NULL)
		BEGIN 
		SET @HtmlOutput = 
			@HtmlTableHead
			+ @HtmlOutput
			+ @TableTail 
			+''<p><BR><p>''
		END
	END
	ELSE 
	BEGIN  
		IF EXISTS (SELECT Log_Date FROM [Inspector].[BackupSizesByDay] WHERE Servername = @Servername AND Log_Date IS NULL) 
		BEGIN
			SET @HtmlOutput =  
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			''No Backups for the past 7 days'' AS ''td'','''', + 
			''N/A'' AS ''td'','''' 
			FOR XML PATH(''tr''),ELEMENTS);

		END
		
		IF @HtmlOutput IS NULL
		BEGIN
			SET @HtmlOutput =  
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			''Data collection out of Date'' AS ''td'','''', + 
			''N/A'' AS ''td'','''' 
			FOR XML PATH(''tr''),ELEMENTS);

			--Mark Collection as out of date
			SET @CollectionOutOfDate = 1;
		END


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


IF OBJECT_ID('Inspector.DatabaseFilesReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseFilesReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseFilesReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Data or Log files on incorrect drives'',
		@TableHeaderColour,
		''Server name,Database name,File type,File path''
		)
	);


	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''', +
		Databasename AS ''td'','''', + 
		FileType AS ''td'','''', +
		FilePath AS ''td'',''''
		FROM [Inspector].[DatabaseFiles]
		WHERE Servername = @Servername
		AND Databasename != ''No Database File issues present''
		FOR XML PATH(''tr''),ELEMENTS);
	
	
		IF @HtmlOutput IS NULL 
		BEGIN
			SET @HtmlOutput = 
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			@Servername AS ''td'','''', +
			''No Database File issues present'' AS ''td'','''', + 
			''N/A'' AS ''td'','''', +
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN 
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Servername AS ''td'','''', +
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);
	
		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END
		

	--If @NoClutter is on we do not want to show the table if it has @InfoHighlight against the row/s
	IF (@NoClutter = 1)
	BEGIN 
		IF (@HtmlOutput LIKE ''%No Database File issues present%'')
		BEGIN 
			SET @HtmlOutput = NULL;
		END
	END
	
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


IF OBJECT_ID('Inspector.DatabaseGrowthsReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseGrowthsReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseGrowthsReport]
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
BEGIN
--Revision date: 12/09/2019
--Excluded from Warning level control
	
	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @DatabaseGrowthsAllowedPerDay INT = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold] (@Servername,@Modulename,''DatabaseGrowthsAllowedPerDay'') AS INT),1));
	DECLARE @MAXDatabaseGrowthsAllowedPerDay INT = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold] (@Servername,@Modulename,''MAXDatabaseGrowthsAllowedPerDay'') AS INT),10));

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''The following Database files have grown more than ''+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' time(s) in the past 24hours:'',
		@TableHeaderColour,
		''Server name,Database name,Type desc,File ID,Filename,Pre Growth Size MB,Growth Rate MB,Growth Increments,Post Growth Size MB,Suggested Growth Rate MB,Growth Rate trend (Last 5 days)''
		)
	);
	
	SELECT @HtmlOutput = 
	(SELECT  
	CASE   
		WHEN [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay AND [GrowthIncrements] < @MAXDatabaseGrowthsAllowedPerDay THEN @AdvisoryHighlight
		WHEN [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay AND [GrowthIncrements] >= @MAXDatabaseGrowthsAllowedPerDay THEN @WarningHighlight
	END AS [@bgcolor], 
	[Servername] AS ''td'','''', + 
	[Database_name] AS ''td'','''', +
	[Type_Desc] AS ''td'','''', +
	[File_id] AS ''td'','''', +
	[FileName] AS ''td'','''', +
	[PreGrowthSize_MB] AS ''td'','''', +
	[GrowthRate_MB] AS ''td'','''', +
	[GrowthIncrements] AS ''td'','''', +
	[PostGrowthSize_MB] AS ''td'','''',+
	CASE 
		WHEN [GrowthRate_MB] < 100 THEN 100  -- if current growth rate is less than 100MB then suggest a minimum of 100MB
		ELSE [GrowthRate_MB] * [GrowthIncrements] 
	END AS ''td'','''',+
	[HistoricGrowths].[LastFiveDaysGrowth] AS ''td'',''''
	FROM [Inspector].[DatabaseFileSizeHistory] LatestGrowths
	CROSS APPLY (SELECT STUFF((SELECT TOP 5 '', ['' 
		+ DATENAME(WEEKDAY,DATEADD(DAY,-1,[HistoricGrowths].[Log_Date])) 
		+ '' '' 
		+ CAST([GrowthRate_MB]*[GrowthIncrements] AS VARCHAR(10))
		+'' MB]''
		FROM [Inspector].[DatabaseFileSizeHistory] HistoricGrowths
		WHERE [LatestGrowths].[Servername] = [HistoricGrowths].[Servername]
		AND [LatestGrowths].[Database_id] = [HistoricGrowths].[Database_id]
		AND [LatestGrowths].[File_id] = [HistoricGrowths].[File_id]
		AND [HistoricGrowths].[Log_Date] >= DATEADD(DAY,-5,CAST(GETDATE() AS DATE))
		ORDER BY [HistoricGrowths].[Log_Date] DESC 
		FOR XML PATH('''')),1,1,'''')
		) AS [HistoricGrowths](LastFiveDaysGrowth)
	WHERE [Log_Date] >= DATEADD(HOUR,-24,GETDATE())
	AND [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay
	AND [Type_Desc] = ''ROWS''
	ORDER BY [Servername],[Database_name],[File_id]
	FOR XML PATH(''tr''),Elements);

	IF (@HtmlOutput IS NOT NULL) 
	BEGIN 
		SET @HtmlOutput = 
		''<hr><BR><p> <b>Server [ALL Servers]<b><p><BR>''
		+ @HtmlTableHead
		+ @HtmlOutput
		+ ''</table><p><font style="color: Black; background-color: ''+@AdvisoryHighlight+''">Advisory Highlight</font> - More than ''+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' growth event/s in the past 24 hours<br>
		<font style="color: Black; background-color: ''+@WarningHighlight+''">Warning Highlight</font> - ''+CAST(@MAXDatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' or more growth event/s in the past 24 hours</b></p>'' + ISNULL(REPLACE(@TableTail,''</table>'',''''),'''') + ''<p><BR><p>''
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
	@DatabaseGrowthsAllowedPerDay AS ''@DatabaseGrowthsAllowedPerDay'',
	@MAXDatabaseGrowthsAllowedPerDay AS ''@MAXDatabaseGrowthsAllowedPerDay'',
	@CollectionOutOfDate AS ''@CollectionOutOfDate'',
	@PSCollection AS ''@PSCollection''
END 

END';


IF OBJECT_ID('Inspector.DatabaseOwnershipReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseOwnershipReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseOwnershipReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @DatabaseOwnerExclusions VARCHAR(255) = (SELECT REPLACE([Value],'' '' ,'''') FROM [Inspector].[Settings] WHERE [Description] = ''DatabaseOwnerExclusions'')
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''The following Databases have an owner that is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]''),
		@TableHeaderColour,
		''Server name,AG name,Database name,Owner'')
	);

	SET @DatabaseOwnerExclusions = REPLACE(REPLACE(@DatabaseOwnerExclusions,'' '',''''),'','','', '');


	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		[Servername] AS ''td'','''', + 
		[AGname] AS ''td'','''', + 
		[Database_name] AS ''td'','''', + 
		[Owner] AS ''td'',''''
		FROM [Inspector].[DatabaseOwnership]
		WHERE [Servername] = @Servername
		AND [Database_name] != ''No Database Ownership issues present''
		ORDER BY [Database_name]
		FOR XML PATH(''tr''),ELEMENTS);

		IF @HtmlOutput IS NULL
		BEGIN
			SET @HtmlOutput = 
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			''N/A'' AS ''td'','''', + 
			''N/A'' AS ''td'','''', + 
			''No Database Ownership issues present'' AS ''td'','''', + 
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE
	BEGIN
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END


	--If @NoClutter is on we do not want to show the table if it has @InfoHighlight against the row/s
	IF (@NoClutter = 1)
	BEGIN 
		IF (@HtmlOutput LIKE ''%No Database Ownership issues present%'')
		BEGIN 
			SET @HtmlOutput = NULL;
		END
	END

	
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


IF OBJECT_ID('Inspector.DatabaseSettingsReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseSettingsReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseSettingsReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @HtmlOutput = '''';
	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Database settings'',
		@TableHeaderColour,
		''Collation,Total'')
	);


	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SELECT @HtmlOutput = @HtmlOutput +
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM [Inspector].[DatabaseSettings]
		WHERE Servername = @Servername 
		AND Setting = ''Collation_name''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @HtmlOutput  = @HtmlOutput + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Auto Close</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @HtmlOutput = @HtmlOutput +
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL AND [Description] = ''Enabled'' THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 AND [Description] = ''Enabled'' THEN @WarningHighlight
			WHEN @WarningLevel = 2 AND [Description] = ''Enabled'' THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 AND [Description] = ''Enabled'' THEN @InfoHighlight
			ELSE ''#FFFFFF''
		END AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM [Inspector].[DatabaseSettings]
		WHERE Servername = @Servername 
		AND Setting = ''is_auto_close_on''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @HtmlOutput  = @HtmlOutput + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Auto Shrink</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @HtmlOutput = @HtmlOutput +
		(SELECT
		CASE 
			WHEN @WarningLevel IS NULL AND [Description] = ''Enabled'' THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 AND [Description] = ''Enabled'' THEN @WarningHighlight
			WHEN @WarningLevel = 2 AND [Description] = ''Enabled'' THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 AND [Description] = ''Enabled'' THEN @InfoHighlight
			ELSE ''#FFFFFF''
		END AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM [Inspector].[DatabaseSettings]
		WHERE Servername = @Servername 
		AND Setting = ''is_auto_shrink_on''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @HtmlOutput  = @HtmlOutput + ''
		<tr>
		<td bgcolor=''+@TableHeaderColour+''><b>Auto Update Stats</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @HtmlOutput = @HtmlOutput +
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL AND [Description] = ''Disabled'' THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 AND [Description] = ''Disabled'' THEN @WarningHighlight
			WHEN @WarningLevel = 2 AND [Description] = ''Disabled'' THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 AND [Description] = ''Disabled'' THEN @InfoHighlight
			ELSE ''#FFFFFF''
		END AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'','''' 
		FROM [Inspector].[DatabaseSettings]
		WHERE Servername = @Servername 
		AND Setting = ''is_auto_update_stats_on''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @HtmlOutput  = @HtmlOutput + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Read Only</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @HtmlOutput = @HtmlOutput +
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],		  
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM [Inspector].[DatabaseSettings]
		WHERE Servername = @Servername 
		AND Setting = ''is_read_only''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @HtmlOutput  = @HtmlOutput + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>User Access</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @HtmlOutput = @HtmlOutput +
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM [Inspector].[DatabaseSettings]
		WHERE Servername = @Servername 
		AND Setting = ''user_access_desc''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @HtmlOutput  = @HtmlOutput + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Compatibility Level</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @HtmlOutput = @HtmlOutput +
		(SELECT  
		''#FFFFFF'' AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM [Inspector].[DatabaseSettings]
		WHERE Servername = @Servername 
		AND Setting = ''compatibility_level''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @HtmlOutput  = @HtmlOutput + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Recovery Model</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @HtmlOutput = @HtmlOutput +
		(SELECT  
		''#FFFFFF'' AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM [Inspector].[DatabaseSettings]
		WHERE Servername = @Servername 
		AND Setting = ''recovery_model_desc''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
	END
	ELSE
	BEGIN
		SET @HtmlOutput =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		''Data Collection out of date''  AS ''td'','''', + 
		''N/A''   AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;

	END



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


IF OBJECT_ID('Inspector.DatabaseStatesReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DatabaseStatesReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DatabaseStatesReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Database count by state'',
		@TableHeaderColour,
		''Server name,Database state,Total,Database names''
		)
	);



	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput =(
		SELECT 
		CASE 
			WHEN DatabaseState IN (''RECOVERY_PENDING'',''SUSPECT'',''EMERGENCY'') THEN @WarningHighlight --Cannot be overidden using Warning levels
			WHEN @WarningLevel IS NULL AND DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 AND DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @WarningHighlight
			WHEN @WarningLevel = 2 AND DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 AND DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @InfoHighlight
		ELSE ''#FFFFFF'' END AS [@bgcolor],
		Servername AS ''td'','''', +
		DatabaseState AS ''td'','''', +
		Total AS ''td'','''', +
		DatabaseNames AS ''td'',''''
		FROM [Inspector].[DatabaseStates]
		WHERE Servername = @Servername
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
	   
	END
	ELSE
	BEGIN
		SET @HtmlOutput =(
		SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight 
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Servername AS ''td'','''', +
		''Data collection out of date'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END


		SET @HtmlOutput = 
			@HtmlTableHead
			+ @HtmlOutput
			+ @TableTail
			+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.DriveSpaceReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[DriveSpaceReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[DriveSpaceReport]
(
@Servername NVARCHAR(128),
@Modulename VARCHAR(50),
@TableHeaderColour VARCHAR(7) = ''#E6E6FA'',
@WarningHighlight VARCHAR(7),
@AdvisoryHighlight VARCHAR(7),
@InfoHighlight VARCHAR(7),
@DriveLetterExcludes VARCHAR(10),
@ServerSpecific BIT,
@ModuleConfig VARCHAR(20),
@UseMedian BIT,
@NoClutter BIT,
@TableTail VARCHAR(256),
@DriveSpaceTableOnly VARCHAR(MAX) OUTPUT,
@HtmlOutput VARCHAR(MAX) OUTPUT,
@CollectionOutOfDate BIT OUTPUT,
@PSCollection BIT,
@Debug BIT = 0
)
AS

--Revision date: 01/05/2021
BEGIN
	SET NOCOUNT ON;
 /* Excluded from Warning level control */
	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @DaysUntilDriveFullThreshold INT;
	DECLARE @FreeSpaceRemainingPercent DECIMAL(5,2);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug, @ModuleConfig, @Modulename);
	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

/*Set columns names for the Html table*/

SET @HtmlTableHead =
(
    SELECT [Inspector].[GenerateHtmlTableheader]
(@Servername, @Modulename, @ServerSpecific, ''Drive space Report:'',
/*Title for the HTML table*/
 @TableHeaderColour, ''Server name,Drive,Total GB,Available GB,% Free,Est.Daily Growth GB,Days Until Disk Full,Days Recorded,Usage Trend,Usage Trend AVG GB,Calculation method,Thresholds''
)

);

SET @DaysUntilDriveFullThreshold =
(
    SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@Servername, @Modulename, ''DaysUntilDriveFullThreshold'') AS INT), 56)
);

SET @FreeSpaceRemainingPercent =
(
    SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold](@Servername, @Modulename, ''FreeSpaceRemainingPercent'') AS DECIMAL(5, 2)), 10.00)
);

/* if there has been a data collection since the last report frequency minutes ago then run the report */
IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
BEGIN
	IF OBJECT_ID(''tempdb.dbo.#TotalDriveEntries'') IS NOT NULL 
	DROP TABLE [#TotalDriveEntries];

	CREATE TABLE #TotalDriveEntries (
	Servername NVARCHAR(128) NOT NULL,
	Drive NVARCHAR(128) NULL,
	TotalEntries INT NOT NULL,
	MedianCalc BIT NULL,
	Excluded BIT NOT NULL,
	DaysRecorded INT NULL,
	AverageDailyGrowth_GB DECIMAL(10,2)
	);

	 INSERT INTO #TotalDriveEntries ([Servername], [Drive], [TotalEntries], [MedianCalc],[Excluded])
     SELECT Servername, 
            Drive, 
            COUNT(Drive) AS TotalEntries,
			CASE 
				WHEN EXISTS (SELECT 1 FROM [Inspector].[DriveSpaceCalc] 
												WHERE [DriveSpaceCalc].Servername = [DriveSpace].Servername
												AND [DriveSpaceCalc].Drive = [DriveSpace].Drive 
												AND [DriveSpaceCalc].MedianCalc = 1) THEN 1 
				ELSE 0 
			END,
			CASE 
				WHEN EXISTS (SELECT 1 FROM [master].[dbo].fn_SplitString(@DriveLetterExcludes, '','')  
												WHERE [StringElement] + '':\'' = [DriveSpace].Drive) THEN 1
				ELSE 0 
			END
     FROM [Inspector].[DriveSpace]
     WHERE Servername = @Servername
     GROUP BY Servername, 
              Drive;

	
	 UPDATE #TotalDriveEntries
	 SET DaysRecorded = Total
	 FROM 
	 (
		SELECT 
			DriveByDay.Drive,
			COUNT(*) AS Total 
		FROM 
			(
				SELECT DISTINCT Drive,CAST(Log_Date AS DATE) AS Log_Date
				FROM Inspector.DriveSpace
				GROUP BY Drive,CAST(Log_Date AS DATE)
			) DriveByDay
		GROUP BY DriveByDay.Drive
	 ) DriveByDayCounts
	 INNER JOIN #TotalDriveEntries ON DriveByDayCounts.Drive = #TotalDriveEntries.Drive;
	 
	 
	 WITH AverageDailyGrowth AS (
     SELECT #TotalDriveEntries.Servername, 
            #TotalDriveEntries.Drive, 
            MedianCalc,
            CASE
                WHEN MedianCalc = 1 THEN
     CAST(
	 (
         SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY [UsedSpaceVarianceGB]) OVER(PARTITION BY Drive)
         FROM Inspector.DriveSpace Median
         WHERE Median.Drive = #TotalDriveEntries.Drive
     ) AS DECIMAL(10,2))
		ELSE CAST(SUM(([UsedSpaceVarianceGB])/#TotalDriveEntries.TotalEntries) AS DECIMAL(10,2)) 
	END AS AverageDailyGrowth_GB
     FROM #TotalDriveEntries 
	 INNER JOIN Inspector.DriveSpace ON DriveSpace.Drive = #TotalDriveEntries.Drive
                                          AND DriveSpace.Servername = #TotalDriveEntries.Servername

     GROUP BY #TotalDriveEntries.Servername, 
              #TotalDriveEntries.Drive, 
              MedianCalc)
	UPDATE #TotalDriveEntries
	SET AverageDailyGrowth_GB = AverageDailyGrowth.AverageDailyGrowth_GB
	FROM AverageDailyGrowth
	INNER JOIN #TotalDriveEntries ON #TotalDriveEntries.Servername = AverageDailyGrowth.Servername AND #TotalDriveEntries.Drive = AverageDailyGrowth.Drive;
	
	SELECT @HtmlOutput = (
     SELECT CASE
                WHEN AverageDailyGrowth_GB > 0
                     AND CAST(COALESCE((LastRecordedFreeSpace.AvailableSpace_GB) / NULLIF(AverageDailyGrowth_GB, 0), 0) AS DECIMAL(20, 2)) < ISNULL(Overrides.[DaysUntilDriveFull], @DaysUntilDriveFullThreshold)
                THEN @WarningHighlight
                WHEN CAST((LastRecordedFreeSpace.AvailableSpace_GB / LastRecordedFreeSpace.Capacity_GB) * 100 AS DECIMAL(10, 2)) < COALESCE(CAST((Overrides.[MinAvailableSpace_GB] / LastRecordedFreeSpace.Capacity_GB) * 100.00 AS DECIMAL(5, 2)), Overrides.[FreeSpaceRemainingPercent], @FreeSpaceRemainingPercent)
                     AND TotalDriveEntries.Excluded = 0
                THEN @AdvisoryHighlight
                ELSE ''#FFFFFF''
            END AS [@bgcolor], 
            TotalDriveEntries.Servername AS ''td'', 
            '''', 
            +TotalDriveEntries.Drive AS ''td'', 
            '''', 
            +LastRecordedFreeSpace.Capacity_GB AS ''td'', 
            '''', 
            +LastRecordedFreeSpace.AvailableSpace_GB AS ''td'', 
            '''', 
            +CAST((LastRecordedFreeSpace.AvailableSpace_GB / LastRecordedFreeSpace.Capacity_GB) * 100 AS DECIMAL(10, 2)) AS ''td'', 
            '''', 
            +ISNULL(TotalDriveEntries.AverageDailyGrowth_GB, 0.00) AS ''td'', 
            '''', 
            +CASE
                 WHEN AverageDailyGrowth_GB <= 0
                 THEN ''N/A''
                 ELSE CAST(CAST(COALESCE((LastRecordedFreeSpace.AvailableSpace_GB) / NULLIF(AverageDailyGrowth_GB, 0), 0) AS DECIMAL(20, 2)) AS VARCHAR(10))
             END AS ''td'', 
            '''', 
            +TotalDriveEntries.DaysRecorded AS ''td'', 
            '''', 
            +ISNULL(STUFF(
     (
         SELECT '', ['' + DATENAME(WEEKDAY, x.Log_Date) + '' '' + CAST(SUM([UsedSpaceVarianceGB]) AS VARCHAR(10)) + '' GB]''
         FROM
         (
             SELECT 
			 CAST(SpaceVariation.Log_Date AS DATE) AS Log_Date, 
			 [UsedSpaceVarianceGB]
             FROM Inspector.DriveSpace SpaceVariation
             WHERE SpaceVariation.Drive = TotalDriveEntries.Drive
                   AND SpaceVariation.Servername = TotalDriveEntries.Servername
                   AND SpaceVariation.Log_Date >= DATEADD(DAY, -5, GETDATE())
         ) x
         GROUP BY x.Log_Date
     ORDER BY x.Log_Date DESC FOR XML PATH('''')
     ), 1, 1, ''''), '' No data available'') AS ''td'', 
            '''', 
            +ISNULL(FiveDayTotal.SUMFiveDayTotal, 0.00) AS ''td'', 
            '''', 
            +CASE
                 WHEN TotalDriveEntries.MedianCalc = 1
                 THEN ''Median''
                 WHEN TotalDriveEntries.MedianCalc = 0
                 THEN ''Average''
				 ELSE ''Average''
             END AS ''td'', 
            '''', 
            +''Minimum available space: '' + ISNULL(CAST(CAST(CASE
                                                                WHEN Overrides.[MinAvailableSpace_GB] IS NOT NULL
                                                                THEN Overrides.[MinAvailableSpace_GB]
                                                                ELSE(LastRecordedFreeSpace.Capacity_GB * 1.00) * (CAST(ISNULL(Overrides.[FreeSpaceRemainingPercent], @FreeSpaceRemainingPercent) AS DECIMAL(5, 2)) / 100.00)
                                                            END AS DECIMAL(10, 2)) AS VARCHAR(128)) + '' GB'', ''Not set'') + '' ('' + ISNULL(CAST(COALESCE(CAST((Overrides.[MinAvailableSpace_GB] / LastRecordedFreeSpace.Capacity_GB) * 100.00 AS DECIMAL(5, 2)), Overrides.[FreeSpaceRemainingPercent], @FreeSpaceRemainingPercent) AS VARCHAR(128)) + ''%'', ''Not set'') + ''), '' + ''Estimated days remaining: '' + ISNULL(CAST(ISNULL(Overrides.[DaysUntilDriveFull], @DaysUntilDriveFullThreshold) AS VARCHAR(128)), ''Not set'') AS ''td'', 
            ''''
     FROM #TotalDriveEntries TotalDriveEntries 
          LEFT JOIN [Inspector].[DriveSpaceThresholds] Overrides ON TotalDriveEntries.Drive = Overrides.Drive
                                                                    AND TotalDriveEntries.Servername = Overrides.Servername
          CROSS APPLY
     (
         SELECT TOP 1 [Capacity_GB], 
                      [AvailableSpace_GB]
         FROM [Inspector].[DriveSpace] DriveSpace
         WHERE DriveSpace.Drive = TotalDriveEntries.Drive
               AND DriveSpace.Servername = TotalDriveEntries.Servername
     ORDER BY Log_Date DESC
     ) AS LastRecordedFreeSpace
          CROSS APPLY
     (
         SELECT CAST(AVG([UsedSpaceVarianceGB]) AS DECIMAL(20, 2)) AS SUMFiveDayTotal
         FROM
     (
         SELECT	TOP	(7200)  /* Maximum of 5 days worth of 1 min collections per drive per server */
					  Drive, 
					  UsedSpaceVarianceGB
         FROM Inspector.DriveSpace FiveDay
         WHERE FiveDay.Drive = TotalDriveEntries.Drive
               AND FiveDay.Servername = TotalDriveEntries.Servername
               AND FiveDay.Log_Date >= DATEADD(DAY, -5, GETDATE())
         ORDER BY FiveDay.Log_Date DESC
     ) AS LastFiveDays
     ) AS FiveDayTotal
     WHERE TotalDriveEntries.Servername = @Servername
     ORDER BY TotalDriveEntries.Drive ASC
	 FOR XML PATH(''tr''),Elements)

	/* If @NoClutter is on we do not want to show the table if it has @InfoHighlight against the row/s
	@NoClutter not applicable to DriveSpace module */

	IF (@HtmlOutput LIKE ''%''+@InfoHighlight+''%'')
	BEGIN 
		SET @HtmlOutput = NULL;
	END


	IF (@HtmlOutput IS NOT NULL)
	BEGIN 
		/* @DriveSpaceTableOnly is for internal use only */
		SET @DriveSpaceTableOnly = @HtmlOutput;

		SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail 
		+''<p><BR><p>'';
	END

	END
	ELSE
	BEGIN
		SET @HtmlOutput = 
		(SELECT 
		@WarningHighlight AS [@bgcolor], 
		@Servername AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),Elements);
		
		SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail 
		+''<p><BR><p>'';
		
		SET @CollectionOutOfDate = 1;

	END

IF (@Debug = 1)
BEGIN 
	SELECT 
	OBJECT_NAME(@@PROCID) AS ''Procname'',
	@Servername AS ''@Servername'',
	@Modulename AS ''@Modulename'',
	@TableHeaderColour AS ''@TableHeaderColour'',
	@HtmlTableHead AS ''@HtmlTableHead'',
	@WarningHighlight AS ''@WarningHighlight'',
	@AdvisoryHighlight AS ''@AdvisoryHighlight'',
	@InfoHighlight AS ''@InfoHighlight'',
	@DaysUntilDriveFullThreshold AS ''@DaysUntilDriveFullThreshold'',
	@FreeSpaceRemainingPercent AS ''@FreeSpaceRemainingPercent'',
	@DriveLetterExcludes AS ''@DriveLetterExcludes'',
	@ModuleConfig AS ''@ModuleConfig'',
	@UseMedian AS ''@UseMedian'',
	@NoClutter AS ''@NoClutter'',
	@TableTail AS ''@TableTail'',
	@HtmlOutput AS ''@HtmlOutput'',
	@CollectionOutOfDate AS ''@CollectionOutOfDate'',
	@PSCollection AS ''@PSCollection''
END 

END';


IF OBJECT_ID('Inspector.FailedAgentJobsReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[FailedAgentJobsReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[FailedAgentJobsReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Failed Agent Jobs'',
		@TableHeaderColour,
		''Server name,Log Date,Job name,Last Step Failed,Last Failed Date,Last Error''
		)
	);

	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @WarningHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''', + 
		CONVERT(VARCHAR(17),Log_Date,113) AS ''td'','''', + 
		Jobname AS ''td'','''', +  
		LastStepFailed AS ''td'','''', +  
		CONVERT(VARCHAR(17),LastFailedDate,113) AS ''td'','''',+  
		LastError + ''...'' AS ''td'',''''
		FROM [Inspector].[FailedAgentJobs]
		WHERE Servername = @Servername
		AND Jobname != ''No Failed Jobs present''
		FOR XML PATH(''tr''),ELEMENTS);

		IF @HtmlOutput IS NULL
		BEGIN
			SET @HtmlOutput = 
			(SELECT ''#FFFFFF'' AS [@bgcolor],
			@Servername AS ''td'','''', + 
			''N/A'' AS ''td'','''', + 
			''No Failed Jobs present'' AS ''td'','''', +  
			''N/A'' AS ''td'','''', + 
			''N/A'' AS ''td'','''', +   
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN 
		SET @HtmlOutput = 
		(SELECT
		CASE 
			WHEN @WarningLevel IS NULL THEN @WarningHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Servername AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', +  
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', +   
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	--Append html table to the report
	IF (@NoClutter = 1)
	BEGIN 
		IF (@HtmlOutput LIKE ''%No Failed Jobs present%'')
		BEGIN
			SET @HtmlOutput = NULL;
		END
	END


	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail
		+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.GenerateHeaderInfo') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[GenerateHeaderInfo] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[GenerateHeaderInfo] (
@Servername NVARCHAR(128),
@ModuleConfig VARCHAR(20),
@Modulename VARCHAR(50),
@ModuleBodyText VARCHAR(MAX),
@WarningHighlight VARCHAR(7),
@AdvisoryHighlight VARCHAR(7),
@InfoHighlight VARCHAR(7),
@WarningLevelFontColour VARCHAR(7),
@CollectionOutOfDate BIT,
@NoClutter BIT,
@WarningLevel TINYINT,
@ServerSpecific BIT,
@TableTail VARCHAR(65) OUTPUT,
@Importance VARCHAR(6) OUTPUT,
@CountWarning INT OUTPUT,
@CountAdvisory INT OUTPUT,
@AlertHeader VARCHAR(1000) OUTPUT,
@AdvisoryHeader VARCHAR(1000) OUTPUT,
@InfoHeader VARCHAR(1000) OUTPUT,
@Debug BIT = 0
)
AS 
--Revision date: 13/05/2021
BEGIN
	DECLARE @HeaderText VARCHAR(100);
	DECLARE @CountInfo INT = 0;
	DECLARE @MultiWarningModule BIT = (SELECT 1 FROM [Inspector].[MultiWarningModules]  WHERE [Modulename] = @Modulename)

	--If the module passed in is not server specific then replace @servername with ''ALL_SERVERS''
	IF (@ServerSpecific = 0) 
	BEGIN 
		SET @Servername = ''ALL_SERVERS'';
	END 

	--Remove table tail as a colour key might exist in the table tail (DriveSpace for example) and this will affect header counts counts.
	IF CHARINDEX(''</table>'',@ModuleBodyText) > 0
	BEGIN 
		SET @ModuleBodyText = LEFT(@ModuleBodyText,CHARINDEX(''</table>'',@ModuleBodyText)-1);
	END

	--Set the header text for the module
	SET @HeaderText = (SELECT [HeaderText] FROM [Inspector].[Modules] WHERE [Modulename] = @Modulename AND [ModuleConfig_Desc] = @ModuleConfig);

	--Set a default value of the module name if no row was returned from above query
	IF (@HeaderText IS NULL)
	BEGIN --Set default header text
		SET @HeaderText = (SELECT [HeaderText] FROM [Inspector].[DefaultHeaderText] WHERE [Modulename] = @Modulename);
		
		IF (@HeaderText IS NULL) --If it is still NULL just set to the Modulename
		BEGIN 
			SET @HeaderText = @Modulename;
		END 
	END 

	IF (@WarningLevel > 3)
	BEGIN 
		SET @WarningLevel = 3;
	END 

	IF (@WarningLevelFontColour IS NULL)
	BEGIN 
		SET @WarningLevelFontColour = CASE 
										WHEN @WarningLevel = 1 THEN @WarningHighlight
										WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
										WHEN @WarningLevel = 3 THEN @InfoHighlight
									  END;
	END 

	--Multi warning modules need to be treated differently as there are two highlights 
	--Populate Alert header 
	IF (@WarningLevel = 1 OR @MultiWarningModule = 1)
	BEGIN 
		IF @ModuleBodyText LIKE ''%''+@WarningHighlight+''%''
		BEGIN
			--Multi warning modules need to be overidden as they use two highlights
			IF (@MultiWarningModule = 1) BEGIN SET @WarningLevelFontColour = @WarningHighlight END

			SET @CountWarning = (LEN(@ModuleBodyText) - LEN(REPLACE(@ModuleBodyText,@WarningHighlight, '''')))/LEN(@WarningHighlight)
			SELECT @AlertHeader = CAST('''' AS VARCHAR(200)) +
			CASE --Add hyperlinks to the respective table and also Anchors for Back to Top for each table
				WHEN @CollectionOutOfDate = 0 THEN ''<A class="linkWarning" HREF = "#''+REPLACE(@Servername,''\'','''')+@Modulename+''">''+@Servername+''</a><A NAME = "''+REPLACE(@Servername,''\'','''')+@Modulename+''Back"></a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountWarning AS VARCHAR(5))+'') ''+@HeaderText+''</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A class="linkWarning" HREF = "#''+REPLACE(@Servername,''\'','''')+@Modulename+''">''+@Servername+''</a><A NAME = "''+REPLACE(@Servername,''\'','''')+@Modulename+''Back"></a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountWarning AS VARCHAR(5))+'') ''+@HeaderText+'' <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High''; 
		END
	END
	
	--Populate Advisory header 
	IF (@WarningLevel = 2 OR @MultiWarningModule = 1)
	BEGIN 
		IF @ModuleBodyText LIKE ''%''+@AdvisoryHighlight+''%''
		BEGIN
			--Multi warning modules need to be overidden as they use two highlights
			IF (@MultiWarningModule = 1) BEGIN SET @WarningLevelFontColour = @AdvisoryHighlight END

			SET @CountAdvisory = (LEN(@ModuleBodyText) - LEN(REPLACE(@ModuleBodyText,@AdvisoryHighlight, '''')))/LEN(@AdvisoryHighlight)
			SELECT @AdvisoryHeader = CAST('''' AS VARCHAR(200)) +
			CASE --Add hyperlinks to the respective table and also Anchors for Back to Top for each table
				WHEN @CollectionOutOfDate = 0 THEN ''<A class="linkAdvisory" HREF = "#''+REPLACE(@Servername,''\'','''')+@Modulename+''">''+@Servername+''</a><A NAME = "''+REPLACE(@Servername,''\'','''')+@Modulename+''Back"></a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAdvisory AS VARCHAR(5))+'') ''+@HeaderText+''</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A class="linkAdvisory" HREF = "#''+REPLACE(@Servername,''\'','''')+@Modulename+''">''+@Servername+''</a><A NAME = "''+REPLACE(@Servername,''\'','''')+@Modulename+''Back"></a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAdvisory AS VARCHAR(5))+'') ''+@HeaderText+'' <b>(Data collection out of Date)</b></font><p>''  
			END

			--If Multi warning is enabled for this module and Importance was set to high in the previous block then do not reset Importance
			SET @Importance = (
				SELECT 
				CASE 
					WHEN (@MultiWarningModule = 1 AND @Importance IN (''High'')) THEN @Importance
					WHEN (@MultiWarningModule = 1 AND @Importance IS NULL) THEN ''Normal''
					WHEN (@MultiWarningModule = 0) THEN ''Normal''
					ELSE ''Normal''
				END
			);
		END
	END
	
	--Populate Info header 
	IF (@WarningLevel = 3 OR @MultiWarningModule = 1)
	BEGIN 
		IF @ModuleBodyText LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			--Multi warning modules need to be overidden as they use two highlights
			IF (@MultiWarningModule = 1) BEGIN SET @WarningLevelFontColour = @InfoHighlight END

			SET @CountInfo = (LEN(@ModuleBodyText) - LEN(REPLACE(@ModuleBodyText,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = CAST('''' AS VARCHAR(200)) +
			CASE --Add hyperlinks to the respective table and also Anchors for Back to Top for each table
				WHEN @CollectionOutOfDate = 0 THEN ''<A class="linkInfo" HREF = "#''+REPLACE(@Servername,''\'','''')+@Modulename+''">''+@Servername+''</a><A NAME = "''+REPLACE(@Servername,''\'','''')+@Modulename+''Back"></a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountInfo AS VARCHAR(5))+'') ''+@HeaderText+''</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A class="linkInfo" HREF = "#''+REPLACE(@Servername,''\'','''')+@Modulename+''">''+@Servername+''</a><A NAME = "''+REPLACE(@Servername,''\'','''')+@Modulename+''Back"></a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountInfo AS VARCHAR(5))+'') ''+@HeaderText+'' <b>(Data collection out of Date)</b></font><p>''  
			END

			--If Multi warning is enabled for this module and Importance was set to high or Normal in the previous blocks then do not reset Importance
			SET @Importance = (
				SELECT 
				CASE 
					WHEN (@MultiWarningModule = 1 AND @Importance IN (''High'',''Normal'')) THEN @Importance
					WHEN (@MultiWarningModule = 1 AND @Importance IS NULL) THEN ''Low''
					WHEN (@MultiWarningModule = 0) THEN ''Low''
					ELSE ''Low''
				END
			);
		END
	END

	--If no Headers are populated then revert the table tail to the standard back to top
	IF COALESCE(@AlertHeader,@AdvisoryHeader,@InfoHeader) IS NULL
	BEGIN 
		SET @TableTail = ''</table></div><p><A HREF = "#Warnings">Back to Top</a><p>'';
	END 

IF (@Debug = 1)
BEGIN 
	SELECT
	OBJECT_NAME(@@PROCID) AS ''Procname'',
	@Servername AS ''@Servername'',
	@ModuleConfig AS ''@ModuleConfigDetermined'',
	@Modulename AS ''@Modulename'',
	@ModuleBodyText AS ''@ReportModuleHtml'',
	@WarningHighlight AS ''@WarningHighlight'',
	@AdvisoryHighlight AS ''@AdvisoryHighlight'',
	@InfoHighlight AS ''@InfoHighlight'',
	@WarningLevelFontColour AS ''@WarningLevelFontColour'',
	@CollectionOutOfDate AS ''@CollectionOutOfDate'',
	@NoClutter AS ''@NoClutter'',
	@WarningLevel AS ''@WarningLevel'',
	@Importance AS ''@Importance'',
	@CountWarning AS ''@CountWarning'',
	@CountAdvisory AS ''@CountAdvisory'',
	@CountInfo AS ''@CountInfo'',
	@AlertHeader AS ''@AlertHeader'',
	@AdvisoryHeader AS ''@AdvisoryHeader'',
	@InfoHeader AS ''@InfoHeader'',
	@TableTail AS ''@TableTail'';
END 

END';

        
SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
CREATE FUNCTION [Inspector].[GenerateHtmlTableheader] (
@Servername NVARCHAR(128),
@Modulename VARCHAR(128),
@ServerSpecific BIT,
@Tableheadermessage VARCHAR(128) = '''', 
@TableHeaderColour VARCHAR(7) = ''#E6E6FA'',
@Columnnames VARCHAR(4000)
)
RETURNS VARCHAR(MAX)
AS 
BEGIN 
DECLARE @TableHeader VARCHAR(MAX)

IF (@ServerSpecific = 0)
BEGIN 
	SET @Servername = N''ALL_SERVERS'';
END 

--Remove space following commas
SET @Columnnames = REPLACE(@Columnnames,'', '','','');

SELECT @TableHeader = 
    ''<b><A NAME = "''+REPLACE(@Servername,''\'','''')+''''+@Modulename+''''+''"></a>''+@Tableheadermessage+''</b>
    <br> 
	<div style="overflow-x:auto;">
	<table cellpadding=0 cellspacing=0 border=0> 
    <tr>''+
	(SELECT ''<th bgcolor=''+ISNULL(@TableHeaderColour,'''')+''><b>''+ISNULL([StringElement],'''')+''</b></font></th>'' FROM master.dbo.fn_SplitString(@Columnnames,'','') FOR XML PATH(''''), TYPE) .value(''.'', ''VARCHAR(MAX)'');

	RETURN(@TableHeader);
END
'
EXEC(@SQLStatement);

        
SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
CREATE FUNCTION [Inspector].[GetDebugFlag] (
@Debug BIT,
@ModuleConfig VARCHAR(20),
@Modulename VARCHAR(50)
)
RETURNS BIT 
AS
BEGIN 
	--IF @Debug = 1 check that it is enabled for debug in the Modules table - this can get spammy if there is a blanket debug
	IF (@Debug = 1)
	BEGIN 
		IF NOT EXISTS (SELECT 1 FROM [Inspector].[Modules] WHERE [ModuleConfig_Desc] = @ModuleConfig AND [Modulename] = @Modulename AND [Debug] = @Debug)
		BEGIN 
			SET @Debug = 0;
		END
	END
	ELSE --If Debug is active in the Modules table then this will override @Debug = 0
	BEGIN 
		IF EXISTS (SELECT 1 FROM [Inspector].[Modules] WHERE [ModuleConfig_Desc] = @ModuleConfig AND [Modulename] = @Modulename AND [Debug] = 1)
		BEGIN 
			SET @Debug = 1;
		END
	END 

	RETURN(@Debug);
END
'
EXEC(@SQLStatement);

        
SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
CREATE FUNCTION [Inspector].[GetWarningLevel] 
(
@ModuleConfig VARCHAR(20),
@Modulename VARCHAR(50)
)
RETURNS TINYINT
AS 
--Revision date: 08/09/2019
BEGIN 
	DECLARE @WarningLevel TINYINT;

	--Determine warning level for the module
	SET @WarningLevel = (SELECT [WarningLevel] 
							FROM [Inspector].[Modules] 
							WHERE [ModuleConfig_Desc] = @ModuleConfig 
							AND [Modulename] = @Modulename);
	
	RETURN(@WarningLevel);
END'
EXEC(@SQLStatement);

SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
CREATE FUNCTION [Inspector].[GetServerInfo] (
@Servername NVARCHAR(128)
)
RETURNS VARCHAR(256)
AS 
BEGIN
	DECLARE @ServerInfo VARCHAR(256);

	SELECT @ServerInfo = 
	(SELECT  
	ISNULL(''Machine type: <b>''+CAST([machine_type] AS VARCHAR(10))+''</b><BR>'','''')+CHAR(13),
	ISNULL(''Total RAM: <b>''+CAST([physical_memory_gb] AS VARCHAR(10))+'' GB</b><BR>'','''')+CHAR(13),
	ISNULL(''CPU Count: <b>''+CAST([cpu_count] AS VARCHAR(10))+''</b><BR>'','''')+CHAR(13),
	ISNULL(''Hyperthread Count: <b>''+CAST([hyperthread_count] AS VARCHAR(10))+''</b><BR>'','''')+CHAR(13),
	ISNULL(''Scheduler Count: <b>''+CAST([scheduler_count] AS VARCHAR(10))+''</b><BR>'','''')+CHAR(13),
	ISNULL(''CPU Affinity: <b>''+CAST([affinity_type_desc] AS VARCHAR(10))+''</b><BR>'','''')+CHAR(13)	
	FROM [Inspector].[ServerInfo]
	WHERE Servername = @Servername
	FOR XML PATH(''''), TYPE).value(''.'', ''VARCHAR(256)'');

	RETURN(@ServerInfo);
END'

EXEC(@SQLStatement);

IF OBJECT_ID('Inspector.JobOwnerReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[JobOwnerReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[JobOwnerReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @AgentJobOwnerExclusions VARCHAR(255);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @AgentJobOwnerExclusions = (SELECT REPLACE([Value],'' '' ,'''') FROM [Inspector].[Settings] WHERE [Description] = ''AgentJobOwnerExclusions'');

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Agent Jobs where the owner is not ''+ISNULL(REPLACE(REPLACE(@AgentJobOwnerExclusions,'' '',''''),'','','', ''),''[N/A - No Exclusions Set]''),
		@TableHeaderColour,
		''Server name,Job ID,Job name''
		)
	);

	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''',+
		Job_ID AS ''td'','''', + 
		Jobname AS ''td'',''''
		FROM [Inspector].[JobOwner]
		WHERE Servername = @Servername
		AND Jobname != ''No Job Owner issues present''
		FOR XML PATH(''tr''),ELEMENTS);

		IF @HtmlOutput IS NULL
		BEGIN
			SET @HtmlOutput = 
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			@Servername AS ''td'','''',+
			''N/A'' AS ''td'','''', + 
			''No Job Owner issues present'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
    BEGIN 
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Servername AS ''td'','''',+
		''N/A'' AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
    END

	IF (@NoClutter = 1)
	BEGIN
		IF (@HtmlOutput LIKE ''%No Job Owner issues present%'')
		BEGIN
			SET @HtmlOutput = NULL;
		END
	END


	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail
		+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.LoginAttemptsReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[LoginAttemptsReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[LoginAttemptsReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Failed Login Attempts'',
		@TableHeaderColour,
		''Server name,Username,Attempts,Last Failed Attempt,Last Error''
		)
	);

	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput = 
		(SELECT
		CASE 
			WHEN @WarningLevel IS NULL THEN @InfoHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''',+
		Username AS ''td'','''',+
		Attempts AS ''td'','''',+
		CONVERT(VARCHAR(17),LastErrorDate,113) AS ''td'','''',+
		LastError AS ''td'',''''
		FROM [Inspector].[LoginAttempts]
		WHERE Servername = @Servername
		AND Username != ''No Failed Logins present''
		FOR XML PATH(''tr''),ELEMENTS)

		IF @HtmlOutput IS NULL
		BEGIN 
			SET @HtmlOutput = (SELECT
			''#FFFFFF'' AS [@bgcolor],
			@Servername AS ''td'','''',+
			''No Failed Logins present'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS)
		END
	END
	ELSE
	BEGIN 
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @InfoHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Servername AS ''td'','''',+
		''Data Collection out of date'' AS ''td'','''',+
		''N/A'' AS ''td'','''',+
		''N/A'' AS ''td'','''',+
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	IF (@NoClutter = 1)
	BEGIN
		IF (@HtmlOutput LIKE ''%No Failed Logins present%'')
		BEGIN 
			SET @HtmlOutput = NULL;
		END
	END


	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail
		+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.LongRunningTransactionsReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[LongRunningTransactionsReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[LongRunningTransactionsReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @AgentJobOwnerExclusions VARCHAR(255);
	DECLARE @LongRunningTransactionThreshold VARCHAR(255);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;
	
	SET @LongRunningTransactionThreshold = (SELECT CAST([Value] AS INT) FROM [Inspector].[Settings] WHERE [Description] = ''LongRunningTransactionThreshold'');

		--Default value
	IF @LongRunningTransactionThreshold IS NULL 
	BEGIN 
		SET @LongRunningTransactionThreshold = 300
	END

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Transactions that exceed the threshold of ''+CAST(@LongRunningTransactionThreshold AS VARCHAR(8))+'' seconds ''+CASE WHEN @LongRunningTransactionThreshold > 300 THEN ''(''+CAST(CAST(CAST(@LongRunningTransactionThreshold AS MONEY)/60.00 AS MONEY) AS VARCHAR(10))+'' Minutes)'' ELSE '''' END,
		@TableHeaderColour,
		''Server name,Session id,Transaction begin time,Duration (DDHHMMSS),Transaction state,Session state,Login name,Host name,Program name,Database name''
		)
	);

	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput = (SELECT 
		CASE
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		[Servername] AS ''td'','''',+
		[session_id] AS ''td'','''',+
		CONVERT(VARCHAR(20),[transaction_begin_time],113) AS ''td'','''',+
		[Duration_DDHHMMSS] AS ''td'','''',+
		[TransactionState] AS ''td'','''',+
		[SessionState] AS ''td'','''',+
		[login_name] AS ''td'','''',+
		[host_name] AS ''td'','''',+
		[program_name] AS ''td'','''',+
		[Databasename] AS ''td'',''''
		FROM [Inspector].[LongRunningTransactions]
		WHERE Servername = @Servername
		AND [transaction_begin_time] IS NOT NULL
		ORDER BY [transaction_begin_time] ASC
		FOR XML PATH(''tr''),ELEMENTS);

		IF @HtmlOutput IS NULL 
		BEGIN 
			SET @HtmlOutput = (SELECT 
			''#FFFFFF'' AS [@bgcolor],
			[Servername] AS ''td'','''',+
			''No Long running transactions'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'',''''
			FROM [Inspector].[LongRunningTransactions]
			WHERE Servername = @Servername
			AND [transaction_begin_time] IS NULL
			ORDER BY [transaction_begin_time] ASC
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN 
		SET @HtmlOutput = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Servername AS ''td'','''',+
		''Data Collection out of date'' AS ''td'','''',+
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', + 
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);
			
		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	IF (@NoClutter = 1)
	BEGIN
		IF (@HtmlOutput LIKE ''%No Long running transactions%'')
		BEGIN
			SET @HtmlOutput = NULL;
		END
	END


	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail
		+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.ModuleReportProcTemplate') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[ModuleReportProcTemplate] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[ModuleReportProcTemplate] (
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

--Revision date: 20/04/2021	
BEGIN
	DECLARE @HtmlTableHead VARCHAR(4000);
	DECLARE @Columnnames VARCHAR(2000);
	DECLARE @SQLtext NVARCHAR(4000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);


/********************************************************/
	--Your query MUST have a case statement that determines which colour to highlight rows
	--Your query MUST use an INTO clause to populate the temp table so that the column names can be determined for the report
	--@bgcolor is used the for table highlighting , Warning,Advisory and Info highlighting colours are determined from 
	--the ModuleWarningLevel table and your Case expression And/or Where clause will determine which rows get the highlight
	--Look for /**  OPTIONAL  **/ headings throughout the query as you may want to change defaults.
	--query example:

/**  REQUIRED  **/ --Add your query below

--for collected data reference an Inspector table
/*
SELECT 
CASE 
	WHEN @WarningLevel = 1 THEN @WarningHighlight
	WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
	WHEN @WarningLevel = 3 THEN @InfoHighlight
END AS [@bgcolor],
Servername, 
CONVERT(VARCHAR(17),Log_Date,113) AS Log_Date,
Jobname,
LastStepFailed,  
CONVERT(VARCHAR(17),LastFailedDate,113) AS LastFailedDate,
LastError + ''...''
INTO #InspectorModuleReport
FROM [Inspector].[FailedAgentJobs]
WHERE Servername = @Servername
AND Jobname != ''No Failed Jobs present'';
*/
	--OR 

-- For an adhoc query against this server only at report time here is an example
/*
SELECT 
CASE 
	WHEN SUM(size) > 16384 THEN @WarningHighlight
	WHEN SUM(size) BETWEEN 8096 AND 16384 THEN @AdvisoryHighlight
	WHEN SUM(size) BETWEEN 4096 AND 8096 THEN @InfoHighlight
	ELSE ''#ffffff'',
''TempDB Data file size'' AS Checkname,
SUM(size) AS TotalSize
INTO #InspectorModuleReport
FROM sys.master_files 
WHERE database_id = 2
AND type = 0
*/

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
	@Modulename, --/**  OPTIONAL  **/ Title for the HTML table, you can use a string here instead such as ''My table title here'' if you want to
	@TableHeaderColour,
	@Columnnames)
	);


	SET @SQLtext = N''
	SELECT @HtmlOutput =
	(SELECT ''
	+''[@bgcolor],''
	+REPLACE(@Columnnames,'','','' AS ''''td'''','''''''',+ '') + '' AS ''''td'''','''''''''' 
	+'' FROM #InspectorModuleReport
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

END';


IF OBJECT_ID('Inspector.ServerSettingsReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[ServerSettingsReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[ServerSettingsReport]
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
BEGIN
--Revision date: 21/05/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime](@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Server settings'',
		@TableHeaderColour,
		''Setting name,Value in use,Old value in use,Your config value,Config is active,Change type,Time of change'')
	);

	
	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SELECT @HtmlOutput = 
(
SELECT  
CASE 
	WHEN [ChangeType] = N''A change to server configuration was detected'' THEN @WarningHighlight
	WHEN [ChangeType] = N''A change to server configuration was detected. Server value differs from your config value'' THEN @WarningHighlight
	WHEN [ChangeType] = N''A change to server configuration was detected. Server value matches your config value'' THEN @InfoHighlight
	WHEN [ChangeType] = N''No change detected. Server value differs from your config value'' THEN @AdvisoryHighlight
	WHEN [ChangeType] LIKE ''%Installation default in use'' THEN @AdvisoryHighlight
	ELSE ''#FFFFFF''
END AS [@bgcolor],
[Setting] AS ''td'','''', + 
ISNULL([ssavalue_in_use],[ServerSettingInUse]) AS ''td'','''', + 
[old_value_in_use] AS ''td'','''', + 
ISNULL(CAST([ssaconfig_value_in_use] AS NVARCHAR(10)),[YourConfigValue]) AS ''td'','''', + 
ISNULL([IsActive],0) AS ''td'','''', + /* ConfigIsActive */
[ChangeType] AS ''td'','''', + 
CASE 
	WHEN [AuditDate] IS NOT NULL THEN N''Change occurred between ''+ISNULL(CONVERT(NVARCHAR(17),[PrevLastUpdated],113),N''N/A'')+N'' and ''+ISNULL(CONVERT(NVARCHAR(17),[AuditDate],113),N''N/A'')
	ELSE N''N/A''
END AS ''td'',''''
FROM 
(
	SELECT 
	[ss].[Setting],
	[ss].[value_in_use] AS ServerSettingInUse,
	[ssc].[value_in_use] AS sscvalue_in_use,
	[ssa].[value_in_use] AS ssavalue_in_use,
	ISNULL(CAST([ssc].[value_in_use] AS NVARCHAR(10)),N''N/A'') AS YourConfigValue,
	CASE /* Check if a aetting has been changed since the last report */
		WHEN [AuditDate] IS NOT NULL THEN N''A change to server configuration was detected''
		ELSE N''No change detected''
	END+
	CASE 
		WHEN [SQLDefaultSetting] = 1 THEN N'', Installation default in use''
		WHEN ISNULL(ssa.[value_in_use],[ss].[value_in_use]) != ISNULL(ssa.[config_value_in_use],[ssc].[value_in_use]) THEN N''. Server value differs from your config value''
		WHEN ISNULL(ssa.[value_in_use],[ss].[value_in_use]) = ISNULL(ssa.[config_value_in_use],[ssc].[value_in_use]) THEN N''. Server value matches your config value''
		WHEN [ssc].[value_in_use] IS NULL THEN N'', No config value set in Inspector.ServerSettingsConfig''
		ELSE ''''
	END AS ChangeType,
	--ISNULL(CONVERT(VARCHAR(20),[ss].[LastUpdated],113),N''N/A'') AS LastUpdated,
	ssa.[AuditDate],
	ssa.[PrevLastUpdated],
	ISNULL(CAST(ssa.[old_value_in_use] AS VARCHAR(10)),N''N/A'') AS old_value_in_use,
	ssa.[config_value_in_use] AS ssaconfig_value_in_use,
	ssc.[IsActive]
	FROM [Inspector].[ServerSettings] ss
	LEFT JOIN (SELECT [Servername],[Setting],[value_in_use],0 AS SQLDefaultSetting,IsActive
				FROM [Inspector].[ServerSettingsConfig] 
				WHERE [ServerSettingsConfig].[IsActive] = 1
				AND [Servername] = @Servername
				UNION
			   SELECT [Servername],[Setting],[value_in_use],1,0 AS IsActive
			    FROM [Inspector].[ServerSettings]
				WHERE 
				[Servername] = @Servername
				AND
				(
					([ServerSettings].[Setting] = N''max server memory (MB)'' AND [value_in_use] = 2147483647)
					OR 
					([ServerSettings].[Setting] = N''max degree of parallelism'' AND [value_in_use] = 0)
				) AND EXISTS (SELECT 1 
								FROM [Inspector].[ServerSettingsConfig] 
								WHERE [ServerSettingsConfig].[IsActive] = 0 
								AND [ServerSettingsConfig].[Setting] = [ServerSettings].[Setting]
								AND [ServerSettingsConfig].[Servername] = [ServerSettings].[Servername]
				)
				) [ssc] ON [ss].[Setting] = [ssc].[Setting]
						AND [ss].[Servername] = [ssc].[Servername]
	LEFT JOIN [Inspector].[ServerSettingsAudit] ssa ON ss.Servername = ssa.Servername
														AND ss.Setting = ssa.Setting
														AND [AuditDate] > DATEADD(MINUTE,@ReportFrequency,GETDATE())
	
	WHERE ([ss].Servername = @Servername)
) ServerSettings 
WHERE (	/* A change has been detected */
		([ChangeType] LIKE ''A change to server configuration%'') 
		OR 
		/* No change detected but the current value in use differs from your config value */
		([ChangeType] = N''No change detected. Server value differs from your config value'' OR [ChangeType] = N''No change detected, Installation default in use'') 
		OR
		/* You have set warning level 0 (show all) */
		(@WarningLevel = 0)
	  )
ORDER BY 
[AuditDate] DESC,
CASE 
	WHEN [ChangeType] = N''A change to server configuration was detected'' THEN 1
	WHEN [ChangeType] = N''A change to server configuration was detected. Server value differs from your config value'' THEN 2
	WHEN [ChangeType] = N''A change to server configuration was detected. Server value matches your config value'' THEN 3
	WHEN [ChangeType] = N''No change detected. Server value differs from your config value'' THEN 5
	WHEN [ChangeType] LIKE ''%Installation default in use'' THEN 4
	ELSE 6
END ASC
FOR XML PATH(''tr''),ELEMENTS);
	END
	ELSE
	BEGIN
		SET @HtmlOutput =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @WarningHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		''Data Collection out of date''  AS ''td'','''', + 
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END


	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail
		+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.SuspectPagesReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[SuspectPagesReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[SuspectPagesReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Suspect Pages Check'',
		@TableHeaderColour,
		''Server name,Database name,File ID,Page ID,Event type,Error count,Last update''
		)
	);
		
		/* if there has been a data collection since the last report frequency minutes ago then run the report */
		IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
		BEGIN
			SELECT @HtmlOutput =
			(SELECT 
			CASE 
				WHEN @WarningLevel IS NULL AND [Databasename] IS NOT NULL THEN @WarningHighlight
				WHEN @WarningLevel = 1 AND [Databasename] IS NOT NULL THEN @WarningHighlight
				WHEN @WarningLevel = 2 AND [Databasename] IS NOT NULL THEN @AdvisoryHighlight
				WHEN @WarningLevel = 3 AND [Databasename] IS NOT NULL THEN @InfoHighlight
				ELSE ''#FFFFFF''
			END AS [@bgcolor],
			[Servername] AS ''td'','''', +  
			ISNULL([Databasename],''No Suspect pages found'') AS ''td'','''', + 
			ISNULL([file_id],''-'') AS ''td'','''', + 
			ISNULL([page_id],''-'') AS ''td'','''', + 	
			ISNULL([event_type],''-'') AS ''td'','''', + 
			ISNULL([error_count],''-'') AS ''td'','''', + 
			ISNULL(CONVERT(VARCHAR(17),[last_update_date],113),''-'') AS ''td'',''''  
			FROM [Inspector].[SuspectPages]
			WHERE Servername = @Servername
			ORDER BY [last_update_date] ASC
			FOR XML PATH(''tr''),ELEMENTS);
		END
		ELSE
		BEGIN
			SET @HtmlOutput =
			(SELECT 
			CASE 
				WHEN @WarningLevel IS NULL THEN @WarningHighlight
				WHEN @WarningLevel = 1 THEN @WarningHighlight
				WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
				WHEN @WarningLevel = 3 THEN @InfoHighlight
			END AS [@bgcolor],
			@Servername AS ''td'','''', + 
			''N/A'' AS ''td'','''', + 
			''N/A'' AS ''td'','''', + 
			''N/A'' AS ''td'','''', + 
			''Data Collection out of date'' AS ''td'','''', + 
			''N/A'' AS ''td'','''', + 
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),Elements);

			--Mark Collection as out of date
			SET @CollectionOutOfDate = 1;
		END
	
	IF (@NoClutter = 1)	 
	BEGIN 
		IF (@HtmlOutput LIKE ''%No Suspect pages found%'')
		BEGIN 
			SET @HtmlOutput = NULL;
		END
	END


	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail 
		+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.TopFiveDatabasesReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[TopFiveDatabasesReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[TopFiveDatabasesReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Top 5 Databases by size'',
		@TableHeaderColour,
		''Server name,Database name,Total size(MB)''
		)
	);
		
	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
	SET @HtmlOutput = 
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		Servername AS ''td'','''', + 
		Databasename AS ''td'','''', + 
		TotalSize_MB AS ''td'',''''
		FROM [Inspector].[TopFiveDatabases] 
		WHERE Servername = @Servername
		FOR XML PATH(''tr''),ELEMENTS);
	END
	ELSE
	BEGIN
		SET @HtmlOutput = 
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		@Servername AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);
	END
	

	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail 
		+''<p><BR><p>''



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


IF OBJECT_ID('Inspector.UnusedLogshipConfigReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[UnusedLogshipConfigReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[UnusedLogshipConfigReport]
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
BEGIN
--Revision date: 20/04/2021	

	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @LastCollection DATETIME;
	DECLARE @ReportFrequency INT;

	SET @LastCollection = [Inspector].[GetLastCollectionDateTime] (@Modulename);
	EXEC [Inspector].[GetModuleConfigFrequency] @ModuleConfig, @Frequency = @ReportFrequency OUTPUT;
	SET @ReportFrequency *= -1;

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
		@Servername,
		@Modulename,
		@ServerSpecific,
		''Unused secondary log shipping config'',
		@TableHeaderColour,
		''Servername,Database name,State''
		)
	);

	/* if there has been a data collection since the last report frequency minutes ago then run the report */
	IF(@LastCollection >= DATEADD(MINUTE,@ReportFrequency,GETDATE()))
	BEGIN
		SET @HtmlOutput =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''', + 
		Databasename AS ''td'','''', +
		Databasestate AS ''td'',''''
		FROM [Inspector].[UnusedLogshipConfig]
		WHERE Servername = @Servername
		ORDER BY [Databasename] ASC
		FOR XML PATH(''tr''),ELEMENTS);

		IF @HtmlOutput IS NULL
		BEGIN 
			SET @HtmlOutput =
			(SELECT 
			''#FFFFFF''  AS [@bgcolor],
			@Servername AS ''td'','''', + 
			''No unused log shipping config present'' AS ''td'','''', + 
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN
		SET @HtmlOutput =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @AdvisoryHighlight
			WHEN @WarningLevel = 1 THEN @WarningHighlight
			WHEN @WarningLevel = 2 THEN @AdvisoryHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Servername AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	IF (@NoClutter = 1)
	BEGIN 
		IF (@HtmlOutput LIKE ''%No unused log shipping config present%'')
		BEGIN 
			SET @HtmlOutput = NULL;
		END
	END

	

	SET @HtmlOutput = 
		@HtmlTableHead
		+ @HtmlOutput
		+ @TableTail 
		+''<p><BR><p>''



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

  
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Inspector.InspectorReportMaster') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Inspector].[InspectorReportMaster] AS';
END

	EXEC dbo.sp_executesql @statement = N'
	ALTER PROCEDURE [Inspector].[InspectorReportMaster] (
	@EmailGroup VARCHAR(50) = ''DBA'',
	@PSCollection BIT = 0,
	@CachedReportID UNIQUEIDENTIFIER = NULL
	)
	AS

	--Revision date: 22/05/2020
	
	DECLARE @ModuleConfigDesc VARCHAR(20);
	DECLARE @ReportWarningsOnly TINYINT;
	DECLARE @NoClutter BIT;
	DECLARE @Frequency SMALLINT; 
	DECLARE @Procname NVARCHAR(128) = OBJECT_NAME(@@PROCID);
	DECLARE @Duration MONEY;
	DECLARE @ReportStart DATETIME = GETDATE();
	DECLARE @EmailProfile NVARCHAR(128);
	DECLARE @EmailAsAttachment BIT;

	DECLARE InspectorReportmaster_cur CURSOR LOCAL STATIC
	FOR
	SELECT 
	ModuleConfig_Desc,ReportWarningsOnly,NoClutter,Frequency,EmailGroup,EmailProfile,EmailAsAttachment
	FROM  [Inspector].[ReportSchedulesDue]
	UNION --We want to be sure we are not duplicating rows
	SELECT 
	ModuleConfig_Desc,ReportWarningsOnly,NoClutter,Frequency,EmailGroup,EmailProfile,EmailAsAttachment
	FROM [Inspector].[ReportsDueCache]
	WHERE ID = @CachedReportID
	
	OPEN InspectorReportmaster_cur
	
	FETCH NEXT FROM InspectorReportmaster_cur INTO @ModuleConfigDesc,@ReportWarningsOnly,@NoClutter,@Frequency,@EmailGroup,@EmailProfile,@EmailAsAttachment
	
	WHILE @@FETCH_STATUS = 0 
	BEGIN 
	
		RAISERROR(''Executing [Inspector].[SQLUnderCoverInspectorReport] for config ''''%s'''''',0,0,@ModuleConfigDesc) WITH NOWAIT;
	
		EXEC sp_executesql N''
		EXEC [Inspector].[SQLUnderCoverInspectorReport]
		@EmailDistributionGroup = @EmailGroup,
		@EmailProfile = @EmailProfile,
		@TestMode = 0, 
		@ModuleDesc = @ModuleConfigDesc,
		@ReportWarningsOnly = @ReportWarningsOnly, 
		@Theme = ''''Dark'''',
		@NoClutter = @NoClutter,
		@EmailAsAttachment = @EmailAsAttachment;'',
		N''@ModuleConfigDesc VARCHAR(20),@ReportWarningsOnly TINYINT,@NoClutter BIT,@EmailGroup VARCHAR(50),@EmailProfile NVARCHAR(128),@EmailAsAttachment BIT'',
		@ModuleConfigDesc = @ModuleConfigDesc,
		@ReportWarningsOnly = @ReportWarningsOnly,
		@NoClutter = @NoClutter,
		@EmailGroup = @EmailGroup,
		@EmailProfile = @EmailProfile,
		@EmailAsAttachment = @EmailAsAttachment;
	
		UPDATE [Inspector].[ModuleConfig]
		SET LastRunDateTime = GETDATE() 
		WHERE ModuleConfig_Desc = @ModuleConfigDesc;

		IF (@CachedReportID IS NOT NULL)
		BEGIN 
			DELETE 
			FROM [Inspector].[ReportsDueCache]
			WHERE ID = @CachedReportID
			AND ModuleConfig_Desc = @ModuleConfigDesc;
		END 
	
		FETCH NEXT FROM InspectorReportmaster_cur INTO @ModuleConfigDesc,@ReportWarningsOnly,@NoClutter,@Frequency,@EmailGroup,@EmailProfile,@EmailAsAttachment
	END 
	
	CLOSE InspectorReportmaster_cur
	DEALLOCATE InspectorReportmaster_cur';


IF OBJECT_ID('Inspector.BackupSpaceInsert') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[BackupSpaceInsert] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[BackupSpaceInsert]
AS
BEGIN
SET NOCOUNT ON;
--Revision date: 18/12/2019

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME
DECLARE @BackupPath NVARCHAR(1000) = (SELECT NULLIF([Value],'''') From [Inspector].[Settings] where [Description] = ''BackupsPath'');

DELETE FROM [Inspector].[BackupSpace]
WHERE Servername = @Servername;

WITH BackupPaths AS (
SELECT CAST(StringElement AS VARCHAR(256)) AS BackupPath 
FROM master.dbo.fn_SplitString(@BackupPath,'','')
)
INSERT INTO [Inspector].[BackupSpace] ([Servername],[Log_Date],[DayOfWeek],[CastedDate],[BackupPath],[TotalSizeInBytes])
SELECT 
@Servername,
GETDATE(),
[DayOfWeek] ,
[CastedDate],
BackupPath,
[TotalSizeInBytes]
FROM (
    SELECT 
    DATENAME(WEEKDAY,backup_start_date) AS [DayOfWeek],
    CAST(backup_start_date AS DATE) AS [CastedDate],
    CASE 
        WHEN physical_device_name LIKE ''''+BackupPath+''%'' 
        THEN BackupPath
        ELSE ''Other Path - Not tracked in [Inspector].[Settings]''
    END AS BackupPath,
    SUM(ISNULL(compressed_backup_size,backup_size)) AS [TotalSizeInBytes]
    FROM msdb.dbo.backupset 
    INNER JOIN msdb.dbo.backupmediafamily ON backupset.media_set_id = backupmediafamily.media_set_id
    LEFT JOIN BackupPaths ON backupmediafamily.physical_device_name LIKE ''''+BackupPath+''%''
    WHERE backup_start_date >= DATEADD(DAY,-7,CAST(GETDATE() AS DATE))
	AND backup_start_date < CAST(GETDATE() AS DATE)
	AND NOT EXISTS (SELECT 1 FROM msdb.dbo.restorehistory WHERE backupset.backup_set_id = restorehistory.backup_set_id)
    GROUP BY 
    DATENAME(WEEKDAY,backup_start_date),
    CAST(backup_start_date AS DATE),
    CASE 
        WHEN physical_device_name LIKE ''''+BackupPath+''%'' 
        THEN BackupPath
        ELSE ''Other Path - Not tracked in [Inspector].[Settings]''
    END
) as BackupSizesbyDay;

END';


IF OBJECT_ID('Inspector.BackupSpaceReport') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[BackupSpaceReport] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[BackupSpaceReport]
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
BEGIN
--Revision date: 23/11/2020
--Excluded from Warning level control
	DECLARE @BackupPathToCheck VARCHAR(256)
	DECLARE @BackupPaths NVARCHAR(1000) 
	DECLARE @HtmlTableHead VARCHAR(2000);
	DECLARE @Server NVARCHAR(128);
	DECLARE @WeekdayOffset INT;

	SET @HtmlOutput = '''';

	SET @WeekdayOffset = (SELECT ISNULL(TRY_CAST([Inspector].[GetServerModuleThreshold] (@Servername,@Modulename,''BackupSpaceWeekdayOffset'') AS INT),0));

	IF @WeekdayOffset IS NULL BEGIN SET @WeekdayOffset = 0 END;
	IF @WeekdayOffset > 1 BEGIN SET @WeekdayOffset = 1 END;

	SET @BackupPaths = (SELECT NULLIF([Value],'''') From [Inspector].[Settings] where [Description] = ''BackupsPath'');

	SET @Debug = [Inspector].[GetDebugFlag](@Debug,@ModuleConfig,@Modulename);

	--Set columns names for the Html table
	SET @HtmlTableHead = (SELECT [Inspector].[GenerateHtmlTableheader] (
	@Servername,
	@Modulename,
	@ServerSpecific,
	''Backup space information against backup path(s): ''+ISNULL(@BackupPaths,''''),
	@TableHeaderColour,
	''Servername,Backup location,Backup Estimate For ''+CASE WHEN @WeekdayOffset = 1 THEN ''tomorrow'' ELSE ''Tonight'' END+'' GB,Backup Server FreeSpace GB,Backup Server Free Space After Backups GB'')
	);

	DECLARE DriveSpace_cur CURSOR LOCAL STATIC
	FOR 
  	SELECT 
	ISNULL(BackupSpace.Servername,''N\A''),
	StringElement
	FROM master.dbo.fn_SplitString(@BackupPaths,'','') Paths
	LEFT JOIN (SELECT DISTINCT Servername,BackupPath FROM [Inspector].[BackupSpace]) AS BackupSpace ON Paths.StringElement COLLATE DATABASE_DEFAULT = BackupSpace.BackupPath;

	OPEN DriveSpace_cur

	FETCH NEXT FROM DriveSpace_cur INTO @Server,@BackupPathToCheck

	WHILE @@FETCH_STATUS = 0 
	BEGIN 

		IF (Select [value] FROM sys.configurations WHERE name = ''xp_cmdshell'') = 1
		BEGIN
			DECLARE @ErrorEncountered BIT = 0
			DECLARE @ErrorEncounteredText VARCHAR(100)
			DECLARE @BackupSizeForNextWeekday AS DECIMAL(10,1)
			DECLARE @BackupSpaceLessStorageSpace AS DECIMAL(10,1) 
			DECLARE @ExtractedInformation VARCHAR(MAX) = ''''
			DECLARE @FreeSpace_Bytes DECIMAL(18,1);
			DECLARE @FreeSpace_GB DECIMAL(18,1);
			DECLARE @BackupPathRaw VARCHAR(256) = @BackupPathToCheck
			DECLARE @Xpcmd VARCHAR(128)  
			
			IF OBJECT_ID(''tempdb.dbo.#BackupDriveSpace'') IS NOT NULL
			DROP TABLE #BackupDriveSpace;
			   
			CREATE TABLE #BackupDriveSpace (
			BytesFree NVARCHAR(MAX)
			); 
			  
			IF @BackupPathToCheck LIKE ''%\'' 
			BEGIN 
				SET @BackupPathToCheck = LEFT(@BackupPathToCheck,LEN(@BackupPathToCheck)-1);
			END
			  
			SET @Xpcmd =  ''DIR\ ''+@BackupPathToCheck;

			INSERT INTO #BackupDriveSpace (BytesFree)
			EXEC xp_cmdshell @Xpcmd;
			  
			IF EXISTS (SELECT TOP 1 BytesFree
						FROM #BackupDriveSpace
						WHERE BytesFree IS NOT NULL 
						AND BytesFree NOT IN (''The device is not ready.'', ''The system cannot find the path specified.'',''The network path was not found.'',''The specified path is invalid'',''The filename, directory name, or volume label syntax is incorrect.'')
						)
			BEGIN
				--Extract the drive information based on the @BackupPathToCheck value (Start the string at this point ignoring any drives letters prior to it)
				SELECT @ExtractedInformation = @ExtractedInformation + (
				SELECT RIGHT(BytesFree,LEN(BytesFree)-CHARINDEX(@BackupPathToCheck,BytesFree)+1) as DriveidentificationSTART
				FROM (SELECT BytesFree as BytesFree
						FROM #BackupDriveSpace 
						FOR XML PATH('''')
						) IdentifyDriveSpace (BytesFree))
				
				IF (@ExtractedInformation LIKE ''%File Not Found%'')
				BEGIN 
					SET @ErrorEncountered = 1;
					SET @ErrorEncounteredText = ''Invalid Backup Path Specified in [Inspector].[Settings]'';
				END
				ELSE IF (@ExtractedInformation LIKE ''%Access is denied%'') 
				BEGIN 
					SET @ErrorEncountered = 1;
					SET @ErrorEncounteredText = ''Access denied to Backup Path Specified in [Inspector].[Settings]'';
				END
				ELSE
				BEGIN
					SELECT @FreeSpace_Bytes = TRY_CONVERT(BIGINT,
					REPLACE(RIGHT(LEFT(@ExtractedInformation,CHARINDEX(''bytes free'',@ExtractedInformation)-1),
					LEN(LEFT(@ExtractedInformation,CHARINDEX(''bytes free'',@ExtractedInformation)-1))-
					CHARINDEX(''Dir(s)'',LEFT(@ExtractedInformation,CHARINDEX(''bytes free'',@ExtractedInformation)-1))-6),'','',''''));
				
					IF @FreeSpace_Bytes IS NULL 
					BEGIN 
						SET @ErrorEncountered = 1;
						SET @ErrorEncounteredText = ''Unable to determine free space for the Backup Path Specified in [Inspector].[Settings]'';
					END 
					
					SET @FreeSpace_GB = ((CAST(@FreeSpace_Bytes AS MONEY)/1024)/1000)/1000;
				END
					
			END
			ELSE
			BEGIN
				SET @ErrorEncountered = 1;
				SET @ErrorEncounteredText = ''Invalid Backup Path Specified in [Inspector].[Settings]'';
			END
		END
		ELSE
		BEGIN 
			SET @ErrorEncountered = 1;
			SET @ErrorEncounteredText = ''xp_cmdshell must be enabled'';
		END

		
		SET @BackupSizeForNextWeekday = 
		(SELECT ISNULL(CAST(SUM(((TotalSizeInBytes)/1024)/1024)/1024 AS DECIMAL (10,1)),0) 
		FROM [Inspector].[BackupSpace]
		WHERE [DayOfWeek] = DATENAME(WEEKDAY,DATEADD(DAY,@WeekdayOffset,Getdate()))
		AND [Servername] = @Server
		AND [BackupPath] = @BackupPathRaw
		)

		IF @BackupSizeForNextWeekday IS NULL 
		BEGIN 
			SET @BackupSizeForNextWeekday = 0 ;
		END

		IF @BackupPathToCheck IS NOT NULL
		BEGIN
			IF @ErrorEncountered = 0 
			BEGIN 
				SET @BackupSpaceLessStorageSpace = CAST(@FreeSpace_GB AS DECIMAL(10,1)) - @BackupSizeForNextWeekday
				SELECT @HtmlOutput = @HtmlOutput +
				(SELECT 
				CASE 
					WHEN @FreeSpace_GB < (@BackupSizeForNextWeekday + (@BackupSizeForNextWeekday*10) /100) --Warn when the free space on the backup location is less than the estimated size for the next days backups multiplied by 10%.
					THEN @WarningHighlight 
					ELSE ''#FFFFFF'' 
				END AS [@bgcolor],
				@Server AS ''td'','''',+
				@BackupPathToCheck AS ''td'','''',+
				@BackupSizeForNextWeekday AS ''td'','''',+
				@FreeSpace_GB  AS ''td'','''',+
				@BackupSpaceLessStorageSpace  AS ''td'',''''
				FOR XML PATH(''tr''),ELEMENTS);
			END 

			IF @ErrorEncountered = 1 
			BEGIN
				SELECT @HtmlOutput = @HtmlOutput +
				(SELECT 
				@WarningHighlight AS [@bgcolor],
				@Server AS ''td'','''',+
				@BackupPathToCheck AS ''td'','''',+
				@BackupSizeForNextWeekday AS ''td'','''',+
				@ErrorEncounteredText  AS ''td'','''',+
				''N/A''  AS ''td'',''''
				FOR XML PATH(''tr''),ELEMENTS);
			END
		END
		ELSE 
		BEGIN 
			SET @BackupSpaceLessStorageSpace = CAST(@FreeSpace_GB AS DECIMAL(10,1)) - @BackupSizeForNextWeekday;
			SELECT @HtmlOutput = @HtmlOutput +
			(SELECT @WarningHighlight AS [@bgcolor],
			@Server AS ''td'','''',+
			@BackupPathToCheck AS ''td'','''',+
			@BackupSizeForNextWeekday AS ''td'','''',+
			''BackupPath is Set to NULL, Check Inspector.Settings''  AS ''td'','''',+
			''N/A''  AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END 

	FETCH NEXT FROM DriveSpace_cur INTO @Server,@BackupPathToCheck
END

CLOSE DriveSpace_cur
DEALLOCATE DriveSpace_cur

SET @HtmlOutput = 
	''<hr><BR><p> <b>Server [ALL Servers]<b><p><BR>''
	+ @HtmlTableHead
	+ @HtmlOutput
	+ @TableTail 
	+''<p><BR><p>'';


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


IF OBJECT_ID('Inspector.ExecutionLogTruncate') IS NULL
EXEC('CREATE PROCEDURE  [Inspector].[ExecutionLogTruncate] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[ExecutionLogTruncate] 
AS 
BEGIN 
	DECLARE @LastTruncate DATE;

	SET @LastTruncate = (SELECT TOP 1 [LastTruncate] FROM [Inspector].[ExecutionLogLastTruncate] ORDER BY [LastTruncate] DESC);

	IF (@LastTruncate IS NULL OR @LastTruncate < CAST(GETDATE() AS DATE)) 
	BEGIN 
		TRUNCATE TABLE [Inspector].[ExecutionLog];

		UPDATE [Inspector].[ExecutionLogLastTruncate] SET [LastTruncate] = CAST(GETDATE() AS DATE);
	END	

END';


IF OBJECT_ID('Inspector.InspectorDataCollection') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[InspectorDataCollection] AS;');

EXEC sp_executesql N'
ALTER PROCEDURE [Inspector].[InspectorDataCollection]
(
@ModuleConfig VARCHAR(20)  = NULL,
@PSCollection BIT = 0,
@PSExecModules BIT = 0,
@PSGenerateReport BIT = 0,
@PSCentralServer NVARCHAR(128) = @@SERVERNAME,
@IgnoreSchedules BIT = 0
)
AS 
BEGIN 

--Revision date: 24/05/2020

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @CollectionProcedurename NVARCHAR(128);
DECLare @FullCollectionProcedurename NVARCHAR(256);
DECLARE @ModuleConfig_Desc VARCHAR(20);
DECLARE @Modulename VARCHAR(128);
DECLARE @CollectionStart DATETIME;
DECLARE @ReportStart DATETIME = GETDATE();
DECLARE @Procname NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @Frequency SMALLINT; 
DECLARE @Duration MONEY;
DECLARE @ReportWarningsOnly TINYINT;
DECLARE @ErrorMessage NVARCHAR(128);
DECLARE @CachedReportID UNIQUEIDENTIFIER;

IF EXISTS(SELECT 1 FROM [Inspector].[CurrentServers] WHERE [IsActive] = 1 AND Servername = @Servername)
BEGIN
    IF EXISTS (SELECT ModuleConfig_Desc FROM [Inspector].[Modules] WHERE ModuleConfig_Desc = @ModuleConfig) OR @ModuleConfig IS NULL 
    BEGIN

		--Truncate ExecutionLog if required
		EXEC [Inspector].[ExecutionLogTruncate];

		--Check for reports due and cache them in case the collection procs executed in the cursor below exceed the current minute
		IF EXISTS (SELECT 1 FROM [Inspector].[ReportSchedulesDue])
		BEGIN 
			SET @CachedReportID = NEWID();

			INSERT INTO [Inspector].[ReportsDueCache] (ID,ModuleConfig_Desc,CurrentScheduleStart,ReportWarningsOnly,NoClutter,Frequency,EmailGroup,EmailProfile,EmailAsAttachment) 
			SELECT @CachedReportID,ModuleConfig_Desc,[CurrentScheduleStart],ReportWarningsOnly,NoClutter,Frequency,EmailGroup,EmailProfile,EmailAsAttachment
			FROM [Inspector].[ReportSchedulesDue];
		END 

		--Populate needs to occur here rather than the other @PSCollection = 1 block because the Modules table trigger is fired upon the Modules LatRunDateTime update
		--and we want to control the format of the data through this proc.
		IF @PSCollection = 1 
		BEGIN 
			RAISERROR(''Populating PSConfig where required'',0,0) WITH NOWAIT;
			EXEC [Inspector].[PopulatePSConfig];
		END
		
	    --If @ModuleConfig IS NULL check if specific server has a Moduleconfig set against it and set @ModuleConfig accordingly, if none found then set ''Default''
	    IF (@ModuleConfig IS NULL)
	    BEGIN
		   SELECT @ModuleConfig = ISNULL(ModuleConfig_Desc,''Default'')
		   FROM [Inspector].[CurrentServers]
		   WHERE IsActive = 1 
		   AND Servername = @Servername;
	    END

		SET @ReportWarningsOnly = (SELECT ReportWarningsOnly FROM [Inspector].[ModuleConfig] WHERE ModuleConfig_Desc = @ModuleConfig);

	   RAISERROR(''ModuleConfig selected for server: %s'',0,0,@ModuleConfig) WITH NOWAIT;
	    
		IF @PSCollection = 1
		BEGIN
			RAISERROR(''Displaying executed modules list for Powershell collection'',0,0) WITH NOWAIT;
	   		EXEC [Inspector].[PSGetConfig] @Servername = @Servername, @ModuleConfig = @ModuleConfig, @PSExecModules = @PSExecModules; 
		END

			DECLARE InspectorCollection_cur CURSOR LOCAL STATIC
			FOR
			--Get enabled module list for @ModuleConfig
			SELECT 
			[ModuleConfig_Desc],
			[Modulename],
			[CollectionProcedurename],
			[Frequency]
			FROM [Inspector].[ModuleSchedulesDue]
			WHERE [ModuleConfig_Desc] = @ModuleConfig
			UNION 
			--Ignore schedule and get all Enabled modules for @ModuleConfig or all if NULL
			SELECT
			[ModuleConfig_Desc],
			[Modulename],
			[CollectionProcedurename],
			[Frequency]
			FROM [Inspector].[Modules]
			WHERE (@IgnoreSchedules = 1 OR @PSExecModules = 1)
			AND IsActive = 1
			AND [CollectionProcedurename] IS NOT NULL
			AND [ModuleConfig_Desc] = ISNULL(@ModuleConfig,[ModuleConfig_Desc])
			UNION 
			--Get modules due for collection that are not part of @ModuleConfig but due a collection
			SELECT
			[ModuleConfig_Desc],
			[Modulename],
			[CollectionProcedurename],
			[Frequency]
			FROM [Inspector].[ModuleSchedulesDue]
			WHERE [ModuleConfig_Desc] != @ModuleConfig
			ORDER BY [CollectionProcedurename] ASC;

			OPEN InspectorCollection_cur 

			FETCH NEXT FROM InspectorCollection_cur INTO @ModuleConfig_Desc,@Modulename, @CollectionProcedurename, @Frequency
			
			WHILE @@FETCH_STATUS = 0 
			BEGIN
				SET @FullCollectionProcedurename = N''Inspector.''+@CollectionProcedurename;

				IF OBJECT_ID(@FullCollectionProcedurename) IS NOT NULL 
				BEGIN 
					SET @CollectionStart = GETDATE();

					RAISERROR(''Running [Inspector].[%s]'',0,0,@CollectionProcedurename) WITH NOWAIT;
					
					BEGIN TRY 
						EXEC(''EXEC [Inspector].[''+@CollectionProcedurename+''];'');
						SET @ErrorMessage = NULL;
					END TRY 
					BEGIN CATCH 
						SET @ErrorMessage = CAST(ERROR_MESSAGE() AS NVARCHAR(128));
					END CATCH 

					SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

					EXEC [Inspector].[ExecutionLogInsert] 
						@RunDatetime = @CollectionStart, 
						@Servername = @Servername, 
						@ModuleConfigDesc = @ModuleConfig_Desc,
						@Procname = @CollectionProcedurename, 
						@Frequency = @Frequency,
						@Duration = @Duration,
						@PSCollection = @PSCollection,
						@ErrorMessage = @ErrorMessage;
				END
				ELSE 
				BEGIN 
					RAISERROR(''No collection required for Module: %s'',0,0,@Modulename) WITH NOWAIT;
				END 
	   
				--Update LastRunDateTime
				UPDATE [Inspector].[Modules] 
				SET LastRunDateTime = GETDATE() 
				WHERE ModuleConfig_Desc = @ModuleConfig_Desc
				AND Modulename = @Modulename;
	   
				FETCH NEXT FROM InspectorCollection_cur INTO @ModuleConfig_Desc,@Modulename, @CollectionProcedurename, @Frequency
			END
	  
			CLOSE InspectorCollection_cur
			DEALLOCATE InspectorCollection_cur

			RAISERROR(''Running [Inspector].[InstanceStartInsert]'',0,0) WITH NOWAIT;
			EXEC [Inspector].[InstanceStartInsert]; 	   

			RAISERROR(''Running [Inspector].[InstanceVersionInsert]'',0,0) WITH NOWAIT;
			EXEC [Inspector].[InstanceVersionInsert]; 	
		

		IF @PSCollection = 1 
		BEGIN 
			RAISERROR(''Cleaning up history tables'',0,0) WITH NOWAIT;
			EXEC [Inspector].[PSHistCleanup];
		END


    END
    ELSE
    BEGIN
	   RAISERROR(''@ModuleConfig supplied: ''''%s'''' is not a valid module config description, for valid options query [Inspector].[Modules]'',11,0,@ModuleConfig);
    END


	IF @PSCentralServer = @@SERVERNAME
	BEGIN 
		--Run InspectorReportMaster to pick up any scheduled reports
		RAISERROR(''Running [Inspector].[InspectorReportMaster]'',0,0) WITH NOWAIT;
		EXEC [Inspector].[InspectorReportMaster] @PSCollection = @PSCollection, @CachedReportID = @CachedReportID;
	END


	--Log InspectorDataCollection proc duration to the ExecutionLog
	SET @Duration = CAST(DATEDIFF(MILLISECOND,@ReportStart,GETDATE()) AS MONEY)/1000;

	EXEC [Inspector].[ExecutionLogInsert] 
		@RunDatetime = @ReportStart, 
		@Servername = @Servername, 
		@ModuleConfigDesc = @ModuleConfig,
		@Procname = @Procname, 
		@Duration = @Duration,
		@PSCollection = @PSCollection;

END
ELSE --Server not present in CurrentServer or IsActive = 1
BEGIN 
	SET @ModuleConfig = ISNULL(@ModuleConfig,''Default'');

	IF @PSCollection = 1 
	BEGIN 
		RAISERROR(''Cleaning up history tables'',0,0) WITH NOWAIT;
		EXEC [Inspector].[PSHistCleanup];
	END

	IF @PSCentralServer = @@SERVERNAME
	BEGIN 
		--Run InspectorReportMaster to pick up any scheduled reports
		RAISERROR(''Running [Inspector].[InspectorReportMaster]'',0,0) WITH NOWAIT;
		EXEC [Inspector].[InspectorReportMaster] @PSCollection = @PSCollection, @CachedReportID = @CachedReportID;
	END


	--Log InspectorDataCollection proc duration to the ExecutionLog
	SET @Duration = CAST(DATEDIFF(MILLISECOND,@ReportStart,GETDATE()) AS MONEY)/1000;

	EXEC [Inspector].[ExecutionLogInsert] 
		@RunDatetime = @ReportStart, 
		@Servername = @Servername, 
		@ModuleConfigDesc = @ModuleConfig,
		@Procname = @Procname, 
		@Duration = @Duration,
		@PSCollection = @PSCollection;

	RAISERROR(''Server: %s not present or IsActive = 0 in [Inspector].[CurrentServers]'',0,0,@Servername);
END

END';


IF OBJECT_ID('Inspector.SQLUnderCoverInspectorReport') IS NULL 
EXEC('CREATE PROCEDURE  [Inspector].[SQLUnderCoverInspectorReport] AS;');

--Create Main Inspector Report Stored Procedure
EXEC sp_executesql N'
/*********************************************
--Author: Adrian Buckman
--Revision date: 29/05/2021
--Description: SQLUnderCoverInspectorReport - Report and email from Central logging tables.
*********************************************/

ALTER PROCEDURE [Inspector].[SQLUnderCoverInspectorReport] 
(
@EmailDistributionGroup VARCHAR(50) = ''DBA'',
@TestMode BIT = 0,
@ModuleDesc VARCHAR(20)	= NULL,
@ReportWarningsOnly TINYINT = 0,
@EmailProfile NVARCHAR(128) = NULL,
@EmailAsAttachment BIT = 0,
@Theme VARCHAR(5) = ''Dark'',
@PSCollection BIT = 0,
@NoClutter BIT = 0,
@Debug BIT = 0
)
AS 
BEGIN
SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM [Inspector].[Modules] WHERE ModuleConfig_Desc = @ModuleDesc)
OR @ModuleDesc IS NULL
BEGIN

--Check if a database filename resync is required following installation of V1.4 or manually triggered via the setting 
DECLARE @DatabaseFilenameSync BIT = (SELECT TRY_CONVERT(BIT,ISNULL(NULLIF([Value],''''),1)) FROM [Inspector].[Settings] WHERE [Description] = ''InspectorUpgradeFilenameSync'')

IF (@DatabaseFilenameSync = 1)
BEGIN 
	EXEC [Inspector].[DatabaseGrowthFilenameSync];
END

IF OBJECT_ID(''tempdb.dbo.#TrafficLightSummary'') IS NOT NULL
DROP TABLE #TrafficLightSummary;

CREATE TABLE #TrafficLightSummary
(
SummaryHeader VARCHAR(1000),
WarningPriority TINYINT
);

SET @Theme = UPPER(@Theme);

DECLARE @Procname NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @ModuleConfig VARCHAR(20);
DECLARE @ModuleConfigDetermined VARCHAR(20);
DECLARE @InspectorBuild	VARCHAR(6) = (SELECT ISNULL([Value],'''') FROM [Inspector].[Settings] WHERE [Description] = ''InspectorBuild'');
DECLARE @ReportStart DATETIME = GETDATE();
DECLARE @ModuleReportStart DATETIME;
DECLARE @SQLstatement NVARCHAR(1000);
DECLARE @TotalWarningCount INT = 0;
DECLARE @TotalAdvisoryCount INT = 0;
DECLARE @CountWarning INT = 0;
DECLARE @CountAdvisory INT = 0;
DECLARE @WarningLevel TINYINT;
DECLARE @WarningLevelFontColour VARCHAR(7);
DECLARE @VersionNo VARCHAR(128);
DECLARE @Edition VARCHAR(128);
DECLARE @DatabaseGrowthCheckRunEnabled BIT;
DECLARE @Duration MONEY;
DECLARE @Frequency SMALLINT; 
DECLARE @CatalogueInstalled BIT;
DECLARE @CatalogueBuild	VARCHAR(10);
DECLARE @MinCatalogueBuild VARCHAR(10) = ''0.2.0'';
DECLARE @CatalogueModuleEnabled BIT;
DECLARE @CatalogueModulename VARCHAR(20);
DECLARE @CatalogueHtml VARCHAR(MAX);
DECLARE @ReportModuleHtml VARCHAR(MAX);
DECLARE @CountCatalogueWarnings INT;
DECLARE @CatalogueLastExecution DATETIME;
DECLARE @CatalogueModuleReport BIT;

DECLARE @Stack VARCHAR(255) = (SELECT [Value] from [Inspector].[Settings] WHERE [Description] = ''SQLUndercoverInspectorEmailSubject'');

DECLARE @EmailHeader VARCHAR(2000) = CASE 
										WHEN @PSCollection = 0 
										THEN ''<img src="''+(SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''EmailBannerURL'')+''">''
										ELSE ''<img src="''+(SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = ''PSEmailBannerURL'')+''">''
									 END;
DECLARE @SubjectText VARCHAR(255);
DECLARE @AlertSubjectText VARCHAR(255);
DECLARE @Importance VARCHAR(6);
DECLARE @HighestImportance TINYINT;
DECLARE @EmailBody VARCHAR(MAX) = '''';
DECLARE @AlertHeader VARCHAR(MAX) = '''';
DECLARE @AdvisoryHeader VARCHAR(MAX) = '''';
DECLARE @InfoHeader VARCHAR(MAX) = '''';
DECLARE @AlertHeaderOutput VARCHAR(1000);
DECLARE @AdvisoryHeaderOutput VARCHAR(1000);
DECLARE @InfoHeaderOutput VARCHAR(1000);
DECLARE @AlertOutput VARCHAR(1000) = '''';
DECLARE @RecipientsList VARCHAR(1000) = (SELECT Recipients FROM [Inspector].[EmailRecipients] WHERE [Description] = @EmailDistributionGroup)
DECLARE @WarningHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([HighlightHtmlColor],''''),''#fc5858'') FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 1);
DECLARE @AdvisoryHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([HighlightHtmlColor],''''),''#FAFCA4'') FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 2);
DECLARE @InfoHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([HighlightHtmlColor],''''),''#FEFFFF'') FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 3);
DECLARE @GradientLeftWarningHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientLeftHtmlColor],''''),CASE WHEN @Theme = ''LIGHT'' THEN ''#FFFFFF'' ELSE ''#000000'' END) FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 1);
DECLARE @GradientLeftAdvisoryHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientLeftHtmlColor],''''),CASE WHEN @Theme = ''LIGHT'' THEN ''#FFFFFF'' ELSE ''#000000'' END) FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 2);
DECLARE @GradientLeftInfoHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientLeftHtmlColor],''''),CASE WHEN @Theme = ''LIGHT'' THEN ''#FFFFFF'' ELSE ''#000000'' END) FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 3);
DECLARE @GradientRightWarningHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientRightHtmlColor],''''),@WarningHighlight) FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 1);
DECLARE @GradientRightAdvisoryHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientRightHtmlColor],''''),@AdvisoryHighlight) FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 2);
DECLARE @GradientRightInfoHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientRightHtmlColor],''''),CASE WHEN @Theme = ''LIGHT'' THEN ''#000000'' ELSE ''#FFFFFF'' END) FROM [Inspector].[ModuleWarnings] WHERE [WarningLevel] = 3);
DECLARE @TableTail VARCHAR(256) 
DECLARE @StandardTableTail VARCHAR(65)
DECLARE @TableHeaderColour VARCHAR(7) 
DECLARE @ServerSummaryHeader VARCHAR(MAX) = ''<A NAME = "Warnings"></a><b>SQLUndercover Inspector Build: ''+@InspectorBuild+''<div style="text-align: right;"><b>Report date:</b> ''+CONVERT(VARCHAR(17),GETDATE(),113)+''<p><b>No clutter mode:</b> ''+CASE WHEN @NoClutter = 1 THEN ''On'' ELSE ''Off'' END+''</div><hr><p>Server Summary:</b><br></br>'';
DECLARE @ServerSummaryFontColour VARCHAR(30)
DECLARE @DriveLetterExcludes VARCHAR(10) = (SELECT REPLACE(REPLACE([Value],'':'',''''),''\'','''') FROM [Inspector].[Settings] WHERE [Description] = ''DriveSpaceDriveLetterExcludes'');
DECLARE @DisabledModules VARCHAR(2000)
DECLARE @InstanceStart DATETIME
DECLARE @InstanceVersionInfo NVARCHAR(128)
DECLARE @InstanceUptime INT
DECLARE @PhysicalServername NVARCHAR(128)
DECLARE @ReportDataRetention INT = (SELECT ISNULL(NULLIF(CAST([Value] AS INT),''''),30) from [Inspector].[Settings] WHERE [Description] = ''ReportDataRetention'');
DECLARE @UseMedian BIT = (SELECT ISNULL(NULLIF(CAST([Value] AS BIT),''''),0) from [Inspector].[Settings] WHERE [Description] = ''UseMedianCalculationForDriveSpaceCalc'');
DECLARE @CollectionOutOfDate BIT
DECLARE @ReportProcedurename NVARCHAR(128)
DECLare @FullReportProcedurename NVARCHAR(256)
DECLARE @Modulename VARCHAR(50)
DECLARE @ServerSpecific BIT;
DECLARE @ReportSummary VARCHAR(MAX) = '''';
DECLARE @DetailedSummary BIT = (SELECT CASE WHEN [Value] IS NULL OR [Value] != 1 THEN 0 ELSE 1 END FROM [Inspector].[Settings] WHERE [Description] = ''ReportDataDetailedSummary'')
DECLARE @MultiWarningModule BIT;
DECLARE @ShowDisabledModules BIT;
DECLARE @ErrorMessage NVARCHAR(128);
DECLARE @ReportId INT;
DECLARE @Databasename NVARCHAR(128) = DB_NAME();
DECLARE @AttachmentQuery NVARCHAR(256);

--------------Internal use only----------------------
DECLARE @DriveExtensionRequest VARCHAR(MAX)
DECLARE @DriveExtensionRequestStage VARCHAR(MAX) = ''''
DECLARE @DriveSpaceTableOnly VARCHAR(MAX);
-----------------------------------------------------

--Replace HTML white with slight variance as white will break non warning/Advisory/Info
IF @WarningHighlight = ''#FFFFFF'' BEGIN SET @WarningHighlight = ''#FEFFFF''; END 
IF @AdvisoryHighlight = ''#FFFFFF'' BEGIN SET @AdvisoryHighlight = ''#FEFFFF''; END 
IF @InfoHighlight = ''#FFFFFF'' BEGIN SET @InfoHighlight = ''#FEFFFF''; END 

IF @ModuleDesc IS NULL 
BEGIN 
	SET @SubjectText = (SELECT [EmailSubject] FROM [Inspector].[EmailConfig] WHERE [ModuleConfig_Desc] = ''Default''); 
END
ELSE 
BEGIN 
	SET @SubjectText = (SELECT [EmailSubject] FROM [Inspector].[EmailConfig] WHERE [ModuleConfig_Desc] = @ModuleDesc); 
END

IF @SubjectText IS NULL 
BEGIN 
	SET @SubjectText = ''SQLUndercover Inspector check''; 
END

SET @SubjectText= @SubjectText +'' for [''+ISNULL(@Stack,'''')+'']'';
SET @AlertSubjectText = @SubjectText +'' - WARNINGS FOUND! '';

IF @Theme IS NOT NULL BEGIN SET @Theme = UPPER(@Theme) END;
IF @Theme IS NULL BEGIN SET @Theme = ''DARK'' END;
IF @Theme NOT IN (''LIGHT'',''DARK'') BEGIN SET @Theme = ''DARK'' END;

IF (@ReportWarningsOnly > 3) BEGIN SET @ReportWarningsOnly = 0 END;

--Check if the Undercover Catalogue is installed
IF (OBJECT_ID(''Catalogue.ConfigInstances'') IS NOT NULL 
AND OBJECT_ID(''Catalogue.ConfigPoSH'') IS NOT NULL 
AND OBJECT_ID(''Catalogue.ExecutionLog'') IS NOT NULL)
BEGIN 
	SET @CatalogueInstalled = 1; 
END 

--Get Catalogue build and append to the Server summary header.
IF @CatalogueInstalled = 1 
BEGIN 
	EXEC sp_executesql N''SELECT @CatalogueBuild = [ParameterValue] FROM [Catalogue].[ConfigPoSH] WHERE [ParameterName] = ''''CatalogueVersion'''';'',N''@CatalogueBuild VARCHAR(10) OUTPUT'',@CatalogueBuild = @CatalogueBuild OUTPUT
	EXEC sp_executesql N''SELECT TOP 1 @CatalogueLastExecution = [ExecutionDate] FROM [Catalogue].[ExecutionLog] WHERE [CompletedSuccessfully] = 1 ORDER BY [ID] DESC;'',N''@CatalogueLastExecution DATETIME OUTPUT'',@CatalogueLastExecution = @CatalogueLastExecution OUTPUT
	SET @ServerSummaryHeader = ''<A NAME = "Warnings"></a><b>SQLUndercover Inspector Build: ''+ISNULL(@InspectorBuild,'''')+''<p><b>SQLUndercover Catalogue Build: ''+ISNULL(@CatalogueBuild,'''')+ISNULL(CASE WHEN @CatalogueBuild < @MinCatalogueBuild THEN '' (Incompatible)'' ELSE'''' END,'''')+''</b><div style="text-align: right;"><b>Catalogue last executed: ''+ISNULL(CONVERT(VARCHAR(17),NULLIF(@CatalogueLastExecution,''1900-01-01 00:00:00.000''),113),''N/A'')+''</b><p><b>Report date:</b> ''+CONVERT(VARCHAR(17),GETDATE(),113)+''<p><b>No clutter mode:</b> ''+CASE WHEN @NoClutter = 1 THEN ''On'' ELSE ''Off'' END+''</div><hr><p>Server Summary:</b><br></br>'';
END

--Build beginning of the HTML 
SET @EmailHeader = ''
<html>
<head>
<title>SQLUndercover Inspector</title>
<style>
td {
	color: Black; 
	border: solid black;
	border-width: 1px;
	padding-left:10px;
	padding-right:10px;
	padding-top:10px;
	padding-bottom:10px;
	font: 11px arial;
}
th {
	color: Black; 
	border: solid black;
	border-width: 1px;
	padding-left:10px;
	padding-right:10px;
	padding-top:10px;
	padding-bottom:10px;
	font: 11px arial;
}
tr:hover {
	opacity: 0.8;
}
.linkWarning {
  background-color: ''+@WarningHighlight+'';
  color: white;
  padding: 2px 10px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  border-radius:5px;
}
.linkWarning:hover {
	  background-color: ''+@WarningHighlight+'';
	  opacity: 0.6;
}
.linkAdvisory {
  background-color: ''+@AdvisoryHighlight+'';
  color: black;
  padding: 2px 10px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  border-radius:5px;
}
.linkAdvisory:hover {
	  background-color: ''+@AdvisoryHighlight+'';
	  opacity: 0.6;
}
.linkInfo {
  background-color: ''+@InfoHighlight+'';
  color: black;
  padding: 2px 10px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  border-radius:5px;
}
.linkInfo:hover {
	  background-color: ''+@InfoHighlight+'';
	  opacity: 0.6;
}
</style>
</head>
<body style="background-color: ''+CASE WHEN @Theme = ''LIGHT'' THEN ''White'' ELSE ''Black'' END +'';" text="''+CASE WHEN @Theme = ''LIGHT'' THEN ''Black'' ELSE ''White'' END +''">
<div style="text-align: center;">'' +ISNULL(@EmailHeader,'''')+''</div>
<BR>
<BR>
'';

--If DatabaseGrowth is enabled for any ModuleConfig to be included in this run then set the flag here 
IF EXISTS (
SELECT DistinctModuleConfig.[ModuleConfig_Desc]
FROM 
(
	SELECT DISTINCT COALESCE(@ModuleDesc,[ModuleConfig_Desc],''Default'') AS ModuleConfig_Desc
	FROM [Inspector].[CurrentServers]
	WHERE IsActive = 1
) AS DistinctModuleConfig
INNER JOIN [Inspector].[Modules] ON DistinctModuleConfig.ModuleConfig_Desc = Modules.ModuleConfig_Desc
WHERE Modulename = ''DatabaseGrowths''
AND IsActive = 1
)
BEGIN 
	SET @DatabaseGrowthCheckRunEnabled = 1; 
END 
	

DECLARE @Serverlist NVARCHAR(128)
DECLARE ServerCur CURSOR LOCAL STATIC
FOR 
SELECT Servername
FROM [Inspector].[CurrentServers]
WHERE IsActive = 1
AND (ModuleConfig_Desc = @ModuleDesc OR ModuleConfig_Desc IS NULL)
ORDER BY Servername ASC;


OPEN ServerCur

FETCH NEXT FROM ServerCur INTO @Serverlist

WHILE @@FETCH_STATUS = 0 
BEGIN

	--Set Defaults if no ModuleConfig and/or tableheader colour specified in the CurrentServers table
	IF @ModuleConfig IS NULL BEGIN SET @ModuleConfig = ''Default'' END; 
	IF @TableHeaderColour IS NULL BEGIN SET @TableHeaderColour = ''#E6E6FA'' END;
	
	SET @InstanceStart = NULL;
	SET @InstanceUptime = NULL;
	SET @InstanceVersionInfo = NULL;
	SET @PhysicalServername = NULL;	
	
	SET @ModuleConfigDetermined = ISNULL(@ModuleDesc,@ModuleConfig); 

	IF (@DetailedSummary = 1)
	BEGIN 
		SET @ReportSummary += @Serverlist+''(''+@ModuleConfigDetermined+''):''+CHAR(13)+CHAR(10);
	END

	SET @ShowDisabledModules = (SELECT ISNULL([ShowDisabledModules],0) FROM [Inspector].[ModuleConfig] WHERE ModuleConfig_Desc = @ModuleConfigDetermined);

	IF @ModuleConfigDetermined != ''PeriodicBackupCheck''
	BEGIN 
		IF (@ShowDisabledModules = 1) 
		BEGIN 
			--Disabled Modules List
			SELECT @DisabledModules = 
			ISNULL(STUFF(Modulename,1,2,''''),''None'')
			FROM 
			(
				SELECT '', ''+Modulename 
				FROM [Inspector].[Modules]
				WHERE ModuleConfig_Desc = @ModuleConfigDetermined
				AND [IsActive] = 0
				FOR XML PATH('''')
			) AS DisabledModules (Modulename)
		END
		ELSE 
		BEGIN 
			SET @DisabledModules = ''Feature disabled'';
		END 
	
	END 
	
	IF @ModuleConfigDetermined = ''PeriodicBackupCheck''
	BEGIN 
		SET @DisabledModules = ''N/A''
	END 
	
	IF @DisabledModules IS NULL BEGIN SET @DisabledModules = ''None'' END;
	
	SET @InstanceStart = (SELECT [InstanceStart] FROM [Inspector].[InstanceStart] WHERE Servername = @Serverlist AND Log_Date >= CAST(GETDATE() AS DATE));
	SET @InstanceUptime = (SELECT DATEDIFF(DAY,@InstanceStart,GETDATE()));
	SELECT @InstanceVersionInfo = [VersionInfo], @PhysicalServername = [PhysicalServername] FROM [Inspector].[InstanceVersion] WHERE Servername = @Serverlist AND Log_Date >= CAST(GETDATE() AS DATE);
	
	SELECT  @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server <A NAME = "''+REPLACE(@Serverlist,''\'','''')+''Servername''+''"></a>[''+@Serverlist+'']</b><BR></BR>
	Instance start: <b>''+ISNULL(CONVERT(VARCHAR(17),@InstanceStart,113),''Not Recorded'')+'' (Uptime: ''+ISNULL(CAST(@InstanceUptime AS VARCHAR(6)),''N/A'')+CASE WHEN @InstanceUptime IS NOT NULL THEN '' Days)'' ELSE '')'' END + ''</b><BR>
	Instance Version/Edition: <b>''+ISNULL(@InstanceVersionInfo,''Not Recorded'')+''</b><BR>
	Physical Servername: <b>''+ISNULL(@PhysicalServername,''Not Recorded'')+''</b><BR>''
	+[Inspector].[GetServerInfo](@Serverlist)
	+''<p></p>''
	+''ModuleConfig used: <b>''+@ModuleConfigDetermined+ ''</b><BR> 
	Disabled Modules: <b>''+@DisabledModules+''</b><BR></p><p></p><BR></BR>''

	DECLARE ReportProc_cur CURSOR LOCAL STATIC
	FOR 
	SELECT 
	[Modules].[ModuleConfig_Desc],
	ISNULL([ActiveServers].[TableHeaderColour],''#E6E6FA''),
	[Modules].[Modulename],
	[Modules].[ReportProcedurename],
	[Modules].[ServerSpecific],
	(SELECT Frequency 
		FROM Inspector.ModuleConfig 
		WHERE [ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc]
		) AS Frequency
	FROM 
	(
	  SELECT 
	  [Servername],
	  [ModuleConfig_Desc],
	  [TableHeaderColour]
	  FROM [Inspector].[CurrentServers]
	  WHERE [IsActive] = 1
	  AND [Servername] = @Serverlist
	) AS ActiveServers
	INNER JOIN [Inspector].[Modules] ON ([ActiveServers].[ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc] OR ActiveServers.ModuleConfig_Desc IS NULL)
	WHERE [Modules].[IsActive] = 1
	AND [ServerSpecific] = 1
	AND ReportProcedurename IS NOT NULL
	AND [Modules].[ModuleConfig_Desc] = @ModuleConfigDetermined
	AND NOT EXISTS (SELECT 1 FROM [Inspector].[ModuleConfigReportExclusions] ExcludedReports WHERE [ExcludedReports].[Servername] = [ActiveServers].[Servername] AND [ExcludedReports].[Modulename] = [Modules].[Modulename] AND [ExcludedReports].[IsActive] = 1)
	ORDER BY 
	[ActiveServers].[Servername] ASC,
	[Modules].[ReportOrder] ASC;

	OPEN ReportProc_cur

	FETCH NEXT FROM ReportProc_cur INTO @ModuleConfig,@TableHeaderColour,@Modulename,@ReportProcedurename,@ServerSpecific,@Frequency  

	WHILE @@FETCH_STATUS = 0 
	BEGIN 
		
	SET @FullReportProcedurename = N''Inspector.''+@ReportProcedurename;

	IF OBJECT_ID(@FullReportProcedurename) IS NOT NULL 
	BEGIN 
		SET @CountWarning = 0;
		SET @CountAdvisory = 0;
		SET @ModuleReportStart = GETDATE();
		SET @CollectionOutOfDate = 0;
		SET @TableTail = ''</table></div><p><A HREF = "#''+REPLACE(@Serverlist,''\'','''')+@Modulename+''Back">Back to Top</a><p>'';
		SET @StandardTableTail = NULL;
		SET @MultiWarningModule = NULL;
		SET @MultiWarningModule = (SELECT 1 FROM [Inspector].[MultiWarningModules]  WHERE [Modulename] = @Modulename);
		
		RAISERROR(''Reporting on Module: [%s] for server [%s] '',0,0,@Modulename,@Serverlist) WITH NOWAIT;

		--Only Server specific procs will be executed inside the cursor
		IF (@ServerSpecific = 1)
		BEGIN 
			--The DriveSpace module needs to be executed slightly different to other modules.
			IF (@Modulename = N''DriveSpace'')
			BEGIN 
				
				--Reset header output variables
				SET @AlertHeaderOutput = NULL;
				SET @AdvisoryHeaderOutput = NULL;
				SET @InfoHeaderOutput = NULL;
				SET @DriveSpaceTableOnly = NULL;

				EXEC [Inspector].[DriveSpaceReport]
						@Servername = @Serverlist, 
						@Modulename = @Modulename,
						@TableHeaderColour = @TableHeaderColour, 
						@WarningHighlight = @WarningHighlight, 
						@AdvisoryHighlight = @AdvisoryHighlight,
						@InfoHighlight = @InfoHighlight,
						@DriveLetterExcludes = @DriveLetterExcludes,
						@ServerSpecific = @ServerSpecific,
						@PSCollection = @PSCollection, 
						@ModuleConfig = @ModuleConfigDetermined, 
						@UseMedian = @UseMedian,
						@NoClutter = @NoClutter,
						@TableTail = @TableTail,
						@DriveSpaceTableOnly = @DriveSpaceTableOnly OUTPUT,
						@CollectionOutOfDate = @CollectionOutOfDate OUTPUT,
						@HtmlOutput = @ReportModuleHtml OUTPUT,
						@Debug = @Debug;
	
						RAISERROR(''Generating header info for Module: [%s] for server [%s] '',0,0,@Modulename,@Serverlist) WITH NOWAIT;

						--Generate header information
						EXEC [Inspector].[GenerateHeaderInfo] 
						@Servername = @Serverlist,
						@ModuleConfig = @ModuleConfigDetermined,
						@Modulename = @Modulename,
						@ModuleBodyText = @ReportModuleHtml,
						@WarningHighlight = @WarningHighlight,
						@AdvisoryHighlight = @AdvisoryHighlight,
						@InfoHighlight = @InfoHighlight,
						@WarningLevelFontColour = @WarningLevelFontColour,
						@CollectionOutOfDate = @CollectionOutOfDate,
						@NoClutter = @NoClutter,
						@Importance = @Importance OUTPUT,
						@WarningLevel = @WarningLevel,
						@ServerSpecific = @ServerSpecific,
						@TableTail = @StandardTableTail OUTPUT,
						@CountWarning = @CountWarning OUTPUT,
						@CountAdvisory = @CountAdvisory OUTPUT,
						@AlertHeader = @AlertHeaderOutput OUTPUT,
						@AdvisoryHeader = @AdvisoryHeaderOutput OUTPUT,
						@InfoHeader = @InfoHeaderOutput OUTPUT,
						@Debug = @Debug;

						--Check @Importance and set to the highest Importance seen so far
						SET @HighestImportance = (
						SELECT
						CASE 
							WHEN @HighestImportance IS NULL THEN Importance
							WHEN @HighestImportance > Importance THEN Importance
							ELSE @HighestImportance
						END
						FROM 
						(
							SELECT
							CASE @Importance
								WHEN ''High'' THEN 1 
								WHEN ''Normal'' THEN 2 
								WHEN ''Low'' THEN 3 
							END AS Importance
						) Importance
						);

						--If no headers were populated by the module then revert the back to top hyperlink
						IF @StandardTableTail IS NOT NULL 
						BEGIN 
							SET @ReportModuleHtml = REPLACE(@ReportModuleHtml,@TableTail,@StandardTableTail);
						END 

						-- Append the Report module html to the main report body.
						SELECT  @EmailBody = @EmailBody + ISNULL(@ReportModuleHtml,'''');

						--Append to the Headers
						--Add warning counts for summary column in ReportData table
						IF (@AlertHeaderOutput IS NOT NULL)
						BEGIN 
							SET @AlertHeader += ISNULL(@AlertHeaderOutput,'''');
							SET @TotalWarningCount += @CountWarning;
							
							--Internal use only
							IF OBJECT_ID(''Inspector.DriveExtensionRequest'') IS NOT NULL
							BEGIN 
								RAISERROR(''Executing DriveExtensionRequest with @Email = 0'',0,0) WITH NOWAIT;

								EXEC sp_executesql N''EXEC [Inspector].[DriveExtensionRequest] @html = @DriveSpaceTableOnly, @WarningHighlight = @WarningHighlight,@Email = 0, @EmailOutput = @DriveExtensionRequest OUTPUT;'',
								N''@DriveSpaceTableOnly VARCHAR(MAX),
								@WarningHighlight VARCHAR(7),
								@DriveExtensionRequest VARCHAR(MAX) OUTPUT'',
								@DriveSpaceTableOnly = @DriveSpaceTableOnly,
								@WarningHighlight = @WarningHighlight,
								@DriveExtensionRequest = @DriveExtensionRequest OUTPUT;
								
								SET @DriveExtensionRequestStage = @DriveExtensionRequestStage + ISNULL(@DriveExtensionRequest,'''');
							END 
						END 

						IF (@AdvisoryHeaderOutput IS NOT NULL)
						BEGIN 
							SET @AdvisoryHeader += ISNULL(@AdvisoryHeaderOutput,'''');
							SET @TotalAdvisoryCount += @CountAdvisory;
						END 

						IF (@InfoHeaderOutput IS NOT NULL)
						BEGIN 
							--No count required here just append to header
							SET @InfoHeader += ISNULL(@InfoHeaderOutput,'''');
						END 
					
			END 
			ELSE --for all other modules use this block
			BEGIN

				--Reset header output variables
				SET @AlertHeaderOutput = NULL;
				SET @AdvisoryHeaderOutput = NULL;
				SET @InfoHeaderOutput = NULL;

				--Get Module warning level 
				SELECT @WarningLevel = [Inspector].[GetWarningLevel](@ModuleConfigDetermined, @Modulename);

				BEGIN TRY
					SET @SQLstatement = N''
					EXEC [Inspector].[''+@ReportProcedurename+'']
						@Servername = @Serverlist, 
						@Modulename = @Modulename,
						@TableHeaderColour = @TableHeaderColour, 
						@WarningHighlight = @WarningHighlight, 
						@AdvisoryHighlight = @AdvisoryHighlight,
						@InfoHighlight = @InfoHighlight,
						@PSCollection = @PSCollection, 
						@ModuleConfig = @ModuleConfigDetermined, 
						@WarningLevel = @WarningLevel,
						@ServerSpecific = @ServerSpecific,
						@NoClutter = @NoClutter,
						@TableTail = @TableTail,
						@CollectionOutOfDate = @CollectionOutOfDate OUTPUT,
						@HtmlOutput = @ReportModuleHtml OUTPUT,
						@Debug = @Debug;''

					EXEC sp_executesql @SQLstatement,
						N''@Serverlist NVARCHAR(128),
						@Modulename VARCHAR(50),
						@TableHeaderColour VARCHAR(7),
						@WarningHighlight VARCHAR(7),
						@AdvisoryHighlight VARCHAR(7),
						@InfoHighlight VARCHAR(7),
						@PSCollection BIT,
						@ModuleConfigDetermined VARCHAR(20),
						@WarningLevel TINYINT,
						@ServerSpecific BIT,
						@NoClutter BIT,
						@TableTail VARCHAR(256),
						@CollectionOutOfDate BIT OUTPUT,
						@ReportModuleHtml VARCHAR(MAX) OUTPUT,
						@Debug BIT'',
						@Serverlist = @Serverlist, 
						@Modulename = @Modulename,
						@TableHeaderColour = @TableHeaderColour, 
						@WarningHighlight = @WarningHighlight,
						@AdvisoryHighlight = @AdvisoryHighlight,
						@InfoHighlight = @InfoHighlight,
						@PSCollection = @PSCollection, 
						@ModuleConfigDetermined = @ModuleConfigDetermined, 
						@WarningLevel = @WarningLevel,
						@ServerSpecific = @ServerSpecific,
						@NoClutter = @NoClutter,
						@TableTail = @TableTail,
						@CollectionOutOfDate = @CollectionOutOfDate OUTPUT,
						@ReportModuleHtml = @ReportModuleHtml OUTPUT,
						@Debug = @Debug;

					SET @ErrorMessage = NULL;
					END TRY 
					BEGIN CATCH 
						SET @ErrorMessage = CAST(ERROR_MESSAGE() AS NVARCHAR(128));
					END CATCH 

					RAISERROR(''Generating header info for Module: [%s] for server [%s] '',0,0,@Modulename,@Serverlist) WITH NOWAIT;

					--Generate header information
					EXEC [Inspector].[GenerateHeaderInfo] 
					@Servername = @Serverlist,
					@ModuleConfig = @ModuleConfigDetermined,
					@Modulename = @Modulename,
					@ModuleBodyText = @ReportModuleHtml,
					@WarningHighlight = @WarningHighlight,
					@AdvisoryHighlight = @AdvisoryHighlight,
					@InfoHighlight = @InfoHighlight,
					@WarningLevelFontColour = @WarningLevelFontColour,
					@CollectionOutOfDate = @CollectionOutOfDate,
					@NoClutter = @NoClutter,
					@Importance = @Importance OUTPUT,
					@WarningLevel = @WarningLevel,
					@ServerSpecific = @ServerSpecific,
					@TableTail = @StandardTableTail OUTPUT,
					@CountWarning = @CountWarning OUTPUT,
					@CountAdvisory = @CountAdvisory OUTPUT,
					@AlertHeader = @AlertHeaderOutput OUTPUT,
					@AdvisoryHeader = @AdvisoryHeaderOutput OUTPUT,
					@InfoHeader = @InfoHeaderOutput OUTPUT,
					@Debug = @Debug;

					--Check @Importance and set to the highest Importance seen so far
					SET @HighestImportance = (
					SELECT
					CASE 
						WHEN @HighestImportance IS NULL THEN Importance
						WHEN @HighestImportance > Importance THEN Importance
						ELSE @HighestImportance
					END
					FROM 
					(
						SELECT
						CASE @Importance
							WHEN ''High'' THEN 1 
							WHEN ''Normal'' THEN 2 
							WHEN ''Low'' THEN 3 
						END AS Importance
					) Importance
					);

					--If no headers were populated by the module then revert the back to top hyperlink
					IF @StandardTableTail IS NOT NULL 
					BEGIN 
						SET @ReportModuleHtml = REPLACE(@ReportModuleHtml,@TableTail,@StandardTableTail);
					END

					-- Append the Report module html to the main report body.
					SELECT  @EmailBody = @EmailBody + ISNULL(@ReportModuleHtml,'''');

					--Append to the Headers
					--Add warning counts for summary column in ReportData table
					IF (@WarningLevel = 1 OR @MultiWarningModule = 1)
					BEGIN 
						SET @AlertHeader += ISNULL(@AlertHeaderOutput,'''');
						SET @TotalWarningCount += @CountWarning;
					END 

					IF (@WarningLevel = 2 OR @MultiWarningModule = 1)
					BEGIN 
						SET @AdvisoryHeader += ISNULL(@AdvisoryHeaderOutput,'''');
						SET @TotalAdvisoryCount += @CountAdvisory;
					END 

					IF (@WarningLevel = 3 OR @MultiWarningModule = 1)
					BEGIN 
						--No count required here just append to header
						SET @InfoHeader += ISNULL(@InfoHeaderOutput,'''');
					END 
			END

			IF (@DetailedSummary = 1)
			BEGIN 
				IF (@Modulename IS NOT NULL)
				BEGIN 
					SET @ReportSummary += ''     ''+@Modulename+'': Warnings(''+CAST(ISNULL(@CountWarning,0) AS VARCHAR(10))+'') Advisories(''+CAST(ISNULL(@CountAdvisory,0) AS VARCHAR(10))+'')''+CHAR(13)+CHAR(10);
				END
			END

			SET @Duration = CAST(DATEDIFF(MILLISECOND,@ModuleReportStart,GETDATE()) AS MONEY)/1000;

			EXEC [Inspector].[ExecutionLogInsert] 
				@RunDatetime = @ModuleReportStart, 
				@Servername = @Serverlist, 
				@ModuleConfigDesc = @ModuleConfig,
				@Procname = @ReportProcedurename, 
				@Frequency = @Frequency,
				@Duration = @Duration,
				@PSCollection = @PSCollection,
				@ErrorMessage = @ErrorMessage;
		END
	END 
	ELSE 
	BEGIN 
		RAISERROR(''No Report procedure found for Module: %s'',0,0,@Modulename,@Serverlist) WITH NOWAIT;

		EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @ModuleReportStart, 
			@Servername = @Serverlist, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = @ReportProcedurename, 
			@Frequency = @Frequency,
			@Duration = 0,
			@PSCollection = @PSCollection,
			@ErrorMessage = ''No Report procedure found for Module'';

	END 


	FETCH NEXT FROM ReportProc_cur INTO @ModuleConfig,@TableHeaderColour,@Modulename,@ReportProcedurename,@ServerSpecific,@Frequency  
	END

	CLOSE ReportProc_cur
	DEALLOCATE ReportProc_cur


--Only populate the Advisory header with Version/Edition changes if this run is not the PeriodicBackupCheck
IF ISNULL(@ModuleDesc,@ModuleConfig) != ''PeriodicBackupCheck''
BEGIN
	--Check for Instance version or edition changes in [Inspector].[InstanceVersionHistory]
	--Excluded from Warning level control
	SET @VersionNo = NULL;
	SET @Edition = NULL;

	SELECT 
	@VersionNo = CAST([VersionNo] AS VARCHAR(128)),
	@Edition = CAST([Edition] AS VARCHAR(128))
	FROM [Inspector].[InstanceVersionHistory] 
	WHERE [Servername] = @Serverlist 
	AND [CollectionDatetime] >= DATEADD(DAY,-1,GETDATE());

	--If version has changed then create an entry in the advisory header
	IF @VersionNo IS NOT NULL  
	BEGIN 
		SET @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+@Serverlist+''</a><font color=''+@AdvisoryHighlight+''> - SQL ''+@VersionNo+''</font><p>'';
	END

	--If Edition has changed then create an entry in the advisory header
	IF @Edition IS NOT NULL
	BEGIN
		SET @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+@Serverlist+''</a><font color=''+@AdvisoryHighlight+''> - SQL ''+@Edition+''</font><p>'';
	END

END

IF @AlertHeader LIKE ''%''+@Serverlist+''%''
BEGIN
   SET @ServerSummaryFontColour = ''<font color= ''+@WarningHighlight+''>''
END
ELSE 
IF @AdvisoryHeader LIKE ''%''+@Serverlist+''%''
BEGIN
	SET @ServerSummaryFontColour = ''<font color= ''+@AdvisoryHighlight+''>''
END
ELSE
IF @InfoHeader LIKE ''%''+@Serverlist+''%''
BEGIN
	SET @ServerSummaryFontColour = ''<font color= ''+CASE WHEN @Theme = ''LIGHT'' THEN ''Black'' ELSE @InfoHighlight END+''>''
END
ELSE
BEGIN
   SET @ServerSummaryFontColour = ''<font color= "Green">''
END


--Evaluate server and colour code accordingly  
INSERT INTO #TrafficLightSummary ([SummaryHeader],[WarningPriority])
SELECT 
CASE
WHEN @ServerSummaryFontColour = ''<font color= ''+@WarningHighlight+''>'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color=''+@WarningHighlight+''>''+@Serverlist+''</font>]</a></b></font> ''
WHEN @ServerSummaryFontColour = ''<font color= ''+@AdvisoryHighlight+''>'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color= ''+@AdvisoryHighlight+''>''+@Serverlist+''</font>]</a></b></font> ''
WHEN @ServerSummaryFontColour = ''<font color= ''+@InfoHighlight+''>'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color=''+CASE WHEN @Theme = ''LIGHT'' THEN ''Black'' ELSE @InfoHighlight END+''>''+@Serverlist+''</font>]</a></b></font> ''
WHEN @ServerSummaryFontColour = ''<font color= "Green">'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color="Green">''+@Serverlist+''</font>]</a></b></font> ''
END,
CASE
WHEN @ServerSummaryFontColour = ''<font color= ''+@WarningHighlight+''>'' THEN 1
WHEN @ServerSummaryFontColour = ''<font color= ''+@AdvisoryHighlight+''>'' THEN 2
WHEN @ServerSummaryFontColour = ''<font color= ''+CASE WHEN @Theme = ''LIGHT'' THEN ''Black'' ELSE @InfoHighlight END+''>'' THEN 3
WHEN @ServerSummaryFontColour = ''<font color= "Green">'' THEN 4
END

--Add Break to the end of the Server warning ready for the next
IF @AlertHeader LIKE ''%''+@Serverlist+''%'' BEGIN SET @AlertHeader = @AlertHeader + ''<BR></BR>'' END

--Add Break to the end of the Server Advisory Condition ready for the next
IF @AdvisoryHeader LIKE ''%''+@Serverlist+''%'' BEGIN SET @AdvisoryHeader = @AdvisoryHeader + ''<BR></BR>'' END

--Add Break to the end of the Server Info header ready for the next
IF @InfoHeader LIKE ''%''+@Serverlist+''%'' BEGIN SET @InfoHeader = @InfoHeader + ''<BR></BR>'' END


FETCH NEXT FROM ServerCur INTO @Serverlist

END
CLOSE ServerCur
DEALLOCATE ServerCur



--Internal use Only
IF OBJECT_ID(''Inspector.DriveExtensionRequest'') IS NOT NULL 
BEGIN 
	IF @DriveExtensionRequest IS NOT NULL 
	BEGIN 
		RAISERROR(''Executing DriveExtensionRequest with @Email = 1'',0,0) WITH NOWAIT;
		
		EXEC sp_executesql N''EXEC [Inspector].[DriveExtensionRequest] @html = @DriveExtensionRequestStage, @WarningHighlight = @WarningHighlight,@Email = 1, @EmailOutput = @DriveExtensionRequest OUTPUT'',
		N''@DriveExtensionRequestStage VARCHAR(MAX),
		@WarningHighlight VARCHAR(7),
		@DriveExtensionRequest VARCHAR(MAX) OUTPUT'',
		@DriveExtensionRequestStage = @DriveExtensionRequestStage,
		@WarningHighlight = @WarningHighlight,
		@DriveExtensionRequest = @DriveExtensionRequest OUTPUT;
	END
END

	IF (@DetailedSummary = 1)
	BEGIN 
		SET @ReportSummary += ''ALL_SERVERS (''+@ModuleConfigDetermined+''):''+CHAR(13)+CHAR(10);
	END

	SET @ErrorMessage = NULL;

	DECLARE OneoffsReportProc_cur CURSOR LOCAL STATIC
	FOR 
	SELECT 
	[ModuleConfig_Desc],
	[Modulename],
	[ReportProcedurename],
	[ServerSpecific],
	[Frequency]
	FROM [Inspector].[GetNonServerSpecificModules](@ModuleConfigDetermined,@DatabaseGrowthCheckRunEnabled)
	ORDER BY [ReportOrder] ASC
	
	OPEN OneoffsReportProc_cur
	
	FETCH NEXT FROM OneoffsReportProc_cur INTO @ModuleConfig,@Modulename,@ReportProcedurename,@ServerSpecific,@Frequency
	
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		SET @FullReportProcedurename = N''Inspector.''+@ReportProcedurename;

		IF OBJECT_ID(@FullReportProcedurename) IS NOT NULL 
		BEGIN
			RAISERROR(''Reporting on Module: [%s] for server [%s] '',0,0,@Modulename,@Serverlist) WITH NOWAIT;

			--Reset header output variables
			SET @AlertHeaderOutput = NULL;
			SET @AdvisoryHeaderOutput = NULL;
			SET @InfoHeaderOutput = NULL;
			SET @ModuleReportStart = GETDATE();
			SET @TableTail = ''</table><p><A HREF = "#ALL_SERVERS''+@Modulename+''Back">Back to Top</a><p>'';
			SET @MultiWarningModule = NULL;
			SET @MultiWarningModule = (SELECT 1 FROM [Inspector].[MultiWarningModules]  WHERE [Modulename] = @Modulename);

			--Get Module warning level 
			SELECT @WarningLevel = [Inspector].[GetWarningLevel](@ModuleConfigDetermined, @Modulename);

			BEGIN TRY
				SET @SQLstatement = N''
				EXEC [Inspector].[''+@ReportProcedurename+'']
					@Servername = @Serverlist, 
					@Modulename = @Modulename,
					@TableHeaderColour = @TableHeaderColour, 
					@WarningHighlight = @WarningHighlight, 
					@AdvisoryHighlight = @AdvisoryHighlight,
					@InfoHighlight = @InfoHighlight,
					@PSCollection = @PSCollection, 
					@ModuleConfig = @ModuleConfigDetermined, 
					@WarningLevel = @WarningLevel,
					@ServerSpecific = @ServerSpecific,
					@NoClutter = @NoClutter,
					@TableTail = @TableTail,
					@CollectionOutOfDate = @CollectionOutOfDate OUTPUT,
					@HtmlOutput = @ReportModuleHtml OUTPUT,
					@Debug = @Debug;''

				EXEC sp_executesql @SQLstatement,
					N''@Serverlist NVARCHAR(128),
					@Modulename VARCHAR(50),
					@TableHeaderColour VARCHAR(7),
					@WarningHighlight VARCHAR(7),
					@AdvisoryHighlight VARCHAR(7),
					@InfoHighlight VARCHAR(7),
					@PSCollection BIT,
					@ModuleConfigDetermined VARCHAR(20),
					@WarningLevel TINYINT,
					@ServerSpecific BIT,
					@NoClutter BIT,
					@TableTail VARCHAR(256),
					@CollectionOutOfDate BIT OUTPUT,
					@ReportModuleHtml VARCHAR(MAX) OUTPUT,
					@Debug BIT'',
					@Serverlist = @Serverlist, 
					@Modulename = @Modulename,
					@TableHeaderColour = @TableHeaderColour, 
					@WarningHighlight = @WarningHighlight,
					@AdvisoryHighlight = @AdvisoryHighlight,
					@InfoHighlight = @InfoHighlight,
					@PSCollection = @PSCollection, 
					@ModuleConfigDetermined = @ModuleConfigDetermined, 
					@WarningLevel = @WarningLevel,
					@ServerSpecific = @ServerSpecific,
					@NoClutter = @NoClutter,
					@TableTail = @TableTail,
					@CollectionOutOfDate = @CollectionOutOfDate OUTPUT,
					@ReportModuleHtml = @ReportModuleHtml OUTPUT,
					@Debug = @Debug;

				SET @ErrorMessage = NULL;
				END TRY 
				BEGIN CATCH 
					SET @ErrorMessage = CAST(ERROR_MESSAGE() AS NVARCHAR(128));
				END CATCH 			

				SET @Duration = CAST(DATEDIFF(MILLISECOND,@ModuleReportStart,GETDATE()) AS MONEY)/1000;

				EXEC [Inspector].[ExecutionLogInsert] 
					@RunDatetime = @ModuleReportStart, 
					@Servername = @Serverlist, 
					@ModuleConfigDesc = @ModuleConfig,
					@Procname = @ReportProcedurename, 
					@Frequency = @Frequency,
					@Duration = @Duration,
					@PSCollection = @PSCollection,
					@ErrorMessage = @ErrorMessage;

				
				--Generate header information
				EXEC [Inspector].[GenerateHeaderInfo] 
				@Servername = ''ALL_SERVERS'',
				@ModuleConfig = @ModuleConfigDetermined,
				@Modulename = @Modulename,
				@ModuleBodyText = @ReportModuleHtml,
				@WarningHighlight = @WarningHighlight,
				@AdvisoryHighlight = @AdvisoryHighlight,
				@InfoHighlight = @InfoHighlight,
				@WarningLevelFontColour = @WarningLevelFontColour,
				@CollectionOutOfDate = @CollectionOutOfDate,
				@NoClutter = @NoClutter,
				@Importance = @Importance OUTPUT,
				@WarningLevel = @WarningLevel,
				@ServerSpecific = @ServerSpecific,
				@TableTail = @StandardTableTail OUTPUT,
				@CountWarning = @CountWarning OUTPUT,
				@CountAdvisory = @CountAdvisory OUTPUT,
				@AlertHeader = @AlertHeaderOutput OUTPUT,
				@AdvisoryHeader = @AdvisoryHeaderOutput OUTPUT,
				@InfoHeader = @InfoHeaderOutput OUTPUT,
				@Debug = @Debug;

				--Check @Importance and set to the highest Importance seen so far
				SET @HighestImportance = (
				SELECT
				CASE 
					WHEN @HighestImportance IS NULL THEN Importance
					WHEN @HighestImportance > Importance THEN Importance
					ELSE @HighestImportance
				END
				FROM 
				(
					SELECT
					CASE @Importance
						WHEN ''High'' THEN 1 
						WHEN ''Normal'' THEN 2 
						WHEN ''Low'' THEN 3 
					END AS Importance
				) Importance
				);

				IF (@DetailedSummary = 1)
				BEGIN 
					IF @Modulename IS NOT NULL 
					BEGIN 
						SET @ReportSummary += ''     ''+@Modulename+'': Warnings(''+CAST(ISNULL(@CountWarning,0) AS VARCHAR(10))+'') Advisories(''+CAST(ISNULL(@CountAdvisory,0) AS VARCHAR(10))+'')''+CHAR(13)+CHAR(10);
					END
				END

				--If no headers were populated by the module then revert the back to top hyperlink
				IF @StandardTableTail IS NOT NULL 
				BEGIN 
					SET @ReportModuleHtml = REPLACE(@ReportModuleHtml,@TableTail,@StandardTableTail);
				END

				-- Append the Report module html to the main report body.
				SELECT  @EmailBody = @EmailBody + ISNULL(@ReportModuleHtml,'''');

				--Append to the Headers
				--Add warning counts for summary column in ReportData table
				IF (@WarningLevel = 1 OR @MultiWarningModule = 1)
				BEGIN 
					SET @AlertHeader += ISNULL(@AlertHeaderOutput,'''');
					SET @TotalWarningCount += @CountWarning;
				END 

				IF (@WarningLevel = 2 OR @MultiWarningModule = 1)
				BEGIN 
					SET @AdvisoryHeader += ISNULL(@AdvisoryHeaderOutput,'''');
					SET @TotalAdvisoryCount += @CountAdvisory;
				END 

				IF (@WarningLevel = 3 OR @MultiWarningModule = 1)
				BEGIN 
					--No count required here just append to header
					SET @InfoHeader += ISNULL(@InfoHeaderOutput,'''');
				END 	
		END
		ELSE
		BEGIN 
			RAISERROR(''No Report procedure found for Module: %s'',0,0,@Modulename,@Serverlist) WITH NOWAIT;

			EXEC [Inspector].[ExecutionLogInsert] 
				@RunDatetime = @ModuleReportStart, 
				@Servername = @Serverlist, 
				@ModuleConfigDesc = @ModuleConfig,
				@Procname = @ReportProcedurename, 
				@Frequency = @Frequency,
				@Duration = 0,
				@PSCollection = @PSCollection,
				@ErrorMessage = ''No Report procedure found for Module'';
		END

		FETCH NEXT FROM OneoffsReportProc_cur INTO @ModuleConfig,@Modulename,@ReportProcedurename,@ServerSpecific,@Frequency
	END
	
	CLOSE OneoffsReportProc_cur
	DEALLOCATE OneoffsReportProc_cur
 
																
IF @Importance = ''High'' 
BEGIN 
	SET @SubjectText = @AlertSubjectText;
END


IF @AlertHeader != '''' 
BEGIN
SET @AlertHeader = ''
<BR></BR>
<B>Warning Conditions:</b>
<p>''
+@AlertHeader
END 
ELSE
BEGIN 
SET @AlertHeader = ''
<BR></BR>
<B>No Warnings are present</B>
<p></p>
''
END

IF @AdvisoryHeader != ''''
BEGIN
SET @AdvisoryHeader = ''
<HR></HR>
<br></br>
<b>Advisory Conditions:</b> 
<p></p>
''+@AdvisoryHeader
END
ELSE 
BEGIN 
SET @AdvisoryHeader = ''
<HR></HR>
<BR></BR>
<B>No Advisories are present</B>
<p></p>
''
END

IF @InfoHeader != ''''
BEGIN
SET @InfoHeader = ''
<HR></HR>
<br></br>
<b>Informational Conditions:</b> 
<p></p>
''+@InfoHeader
END
ELSE 
BEGIN
SET @InfoHeader = ''
<HR></HR>
<BR></BR>
<B>No Informational conditions are present</B>
<p></p>
''
END


--Red 
IF EXISTS (SELECT SummaryHeader FROM #TrafficLightSummary WHERE WarningPriority = 1 )
BEGIN
SELECT @ServerSummaryHeader = @ServerSummaryHeader +
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= ''+@WarningHighlight+''>Warnings Present - </font></b><BR></BR>'')
FROM
(
SELECT SummaryHeader + '' '' 
FROM #TrafficLightSummary
WHERE WarningPriority = 1
FOR XML PATH('''')
) AS SummaryHeader(SummaryHeader)
) 
END

--Amber 
IF EXISTS (SELECT SummaryHeader FROM #TrafficLightSummary WHERE WarningPriority = 2 )
BEGIN
SELECT @ServerSummaryHeader = @ServerSummaryHeader + ''<BR></BR>'' +
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= ''+@AdvisoryHighlight+''>Advisories/No Warnings - </font></b><BR></BR>'')
FROM
(
SELECT SummaryHeader + '' '' 
FROM #TrafficLightSummary
WHERE WarningPriority = 2
FOR XML PATH('''')
) AS SummaryHeader(SummaryHeader)
)
END

--White
IF EXISTS (SELECT SummaryHeader FROM #TrafficLightSummary WHERE WarningPriority = 3 )
BEGIN
SELECT @ServerSummaryHeader = @ServerSummaryHeader + ''<BR></BR>'' + 
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= ''+@InfoHighlight+''>Informational/No Advisories or Warnings - </font></b><BR></BR>'')
FROM
(
SELECT SummaryHeader + '' '' 
FROM #TrafficLightSummary
WHERE WarningPriority = 3
FOR XML PATH('''')
) AS SummaryHeader(SummaryHeader)
)
END

--Green
IF EXISTS (SELECT SummaryHeader FROM #TrafficLightSummary WHERE WarningPriority = 4 )
BEGIN
SELECT @ServerSummaryHeader = @ServerSummaryHeader + ''<BR></BR>'' + 
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= "Green">OK - </font></b><BR></BR>'')
FROM
(
SELECT SummaryHeader + '' '' 
FROM #TrafficLightSummary
WHERE WarningPriority = 4
FOR XML PATH('''')
) AS SummaryHeader(SummaryHeader)
)
END

/* Reuse the ServerSummaryHeader parameter setting to a new value */
SET @ServerSummaryHeader = ''
<div style="text-align: center;">''+@ServerSummaryHeader+''</div>'' 
+ ''
<BR></BR>
<HR></HR>
<div style="background:linear-gradient(to right, ''+@GradientLeftWarningHighlight+'' 35%, ''+@GradientRightWarningHighlight+'' 110%)">
<text>''+ISNULL(@AlertHeader,'''') +''<BR></text>
</div>
<div style="background: linear-gradient(to right, ''+@GradientLeftAdvisoryHighlight+'' 35%, ''+@GradientRightAdvisoryHighlight+'' 110%)">
<text>'' + ISNULL(@AdvisoryHeader,'''') + ''</text>
</div>
<div style="background: linear-gradient(to right, ''+@GradientLeftInfoHighlight+'' 35%, ''+@GradientRightInfoHighlight+'' 110%)">
<text>'' + ISNULL(@InfoHeader,'''') + ''</text>
</div>
'';

SET @EmailBody = @ServerSummaryHeader + @EmailBody;
SET @EmailBody = Replace(Replace(@EmailBody,''&lt;'',''<''),''&gt;'',''>'');
SET @EmailBody = @EmailHeader + @EmailBody + ''
</body>
</html>
'';

IF (@EmailAsAttachment = 1)
BEGIN 
	SET @ServerSummaryHeader = @EmailHeader + @ServerSummaryHeader+ ''
<br>
<div style="text-align: center;" color:White>See attachment for the complete report</div>
</body>
</html>
'';
	SET @ServerSummaryHeader = Replace(Replace(@ServerSummaryHeader,''&lt;'',''<''),''&gt;'',''>'');
END;

IF (@DetailedSummary = 1)
BEGIN 
	SET @ReportSummary = STUFF(@ReportSummary,1,0,''Total: Warnings (''+CAST(@TotalWarningCount AS VARCHAR(6))+''), Advisories (''+CAST(@TotalAdvisoryCount AS VARCHAR(6))+'')''+CHAR(13)+CHAR(10));
END 
ELSE 
BEGIN 
	SET @ReportSummary = ''Total: Warnings (''+CAST(@TotalWarningCount AS VARCHAR(6))+''), Advisories (''+CAST(@TotalAdvisoryCount AS VARCHAR(6))+'')'';
END 

IF @ModuleDesc IS NULL BEGIN SET @ModuleDesc = ''NULL'' END;

SET @Importance = (SELECT CASE @HighestImportance WHEN 1 THEN ''High'' WHEN 2 THEN ''Normal'' WHEN 3 THEN ''Low'' ELSE ''Low'' END);

IF @TestMode = 1 OR (@RecipientsList IS NULL OR @RecipientsList = '''')
BEGIN
	IF (@ReportWarningsOnly > 0)
	BEGIN
		IF (@HighestImportance <= @ReportWarningsOnly)
		BEGIN
			INSERT INTO [Inspector].[ReportData] (ReportDate,ModuleConfig,ReportData,Summary,Importance,EmailGroup,ReportWarningsOnly)
			SELECT GETDATE(),ISNULL(@ModuleDesc,@ModuleConfig),@EmailBody,CAST(@ReportSummary AS XML),@Importance,@EmailDistributionGroup,@ReportWarningsOnly;
		END
	END
	ELSE 
	BEGIN
		INSERT INTO [Inspector].[ReportData] (ReportDate,ModuleConfig,ReportData,Summary,Importance,EmailGroup,ReportWarningsOnly)
		SELECT GETDATE(),ISNULL(@ModuleDesc,@ModuleConfig),@EmailBody,CAST(@ReportSummary AS XML),@Importance,@EmailDistributionGroup,@ReportWarningsOnly;
	END
END
ELSE
BEGIN
BEGIN TRY
IF (@ReportWarningsOnly > 0)
	BEGIN
		IF (@HighestImportance <= @ReportWarningsOnly)
		BEGIN
			INSERT INTO [Inspector].[ReportData] (ReportDate,ModuleConfig,ReportData,Summary,Importance,EmailGroup,ReportWarningsOnly)
			SELECT GETDATE(),ISNULL(@ModuleDesc,@ModuleConfig),@EmailBody,CAST(@ReportSummary AS XML),@Importance,@EmailDistributionGroup,@ReportWarningsOnly;

			SELECT @ReportId = SCOPE_IDENTITY();

			IF (@EmailAsAttachment = 1)
			BEGIN 

			SET @AttachmentQuery = N''EXEC sp_executesql N''''SET NOCOUNT ON; SELECT TOP (1) [ReportData] FROM [Inspector].[ReportData] WHERE [ID] = @ReportID'''',N''''@ReportID INT'''',@ReportID = ''+CAST(@ReportId AS NVARCHAR(20))+'';'';

				EXEC msdb.dbo.sp_send_dbmail 
				@recipients = @RecipientsList,
				@subject = @SubjectText,
				@importance = @Importance,
				@body = @ServerSummaryHeader, /* We only want to add the header to the email body as we attach the report as a file */
				@body_format = ''HTML'',
				@profile_name = @EmailProfile,
				@attach_query_result_as_file = 1,
				@query_attachment_filename = N''Inspector.html'',
				@query = @AttachmentQuery,
				@execute_query_database = @Databasename,
				@query_result_width = 32767,
				@query_no_truncate = 1,
				@query_result_header = 1;

			END
			ELSE
			BEGIN
				EXEC msdb.dbo.sp_send_dbmail 
				@recipients = @RecipientsList,
				@subject = @SubjectText,
				@importance = @Importance,
				@body=@EmailBody ,
				@body_format = ''HTML'',
				@profile_name = @EmailProfile;
			END

		END
	END
	ELSE 
	BEGIN
			INSERT INTO [Inspector].[ReportData] (ReportDate,ModuleConfig,ReportData,Summary,Importance,EmailGroup,ReportWarningsOnly)
			SELECT GETDATE(),ISNULL(@ModuleDesc,@ModuleConfig),@EmailBody,CAST(@ReportSummary AS XML),@Importance,@EmailDistributionGroup,@ReportWarningsOnly;

			SELECT @ReportId = SCOPE_IDENTITY();

			IF (@EmailAsAttachment = 1)
			BEGIN 

			SET @AttachmentQuery = N''EXEC sp_executesql N''''SET NOCOUNT ON; SELECT TOP (1) [ReportData] FROM [Inspector].[ReportData] WHERE [ID] = @ReportID'''',N''''@ReportID INT'''',@ReportID = ''+CAST(@ReportId AS NVARCHAR(20))+'';'';
			
				EXEC msdb.dbo.sp_send_dbmail 
				@recipients = @RecipientsList,
				@subject = @SubjectText,
				@importance = @Importance,
				@body = @ServerSummaryHeader, /* We only want to add the header to the email body as we attach the report as a file */
				@body_format = ''HTML'',
				@profile_name = @EmailProfile,
				@attach_query_result_as_file = 1,
				@query_attachment_filename = N''Inspector.html'',
				@query = @AttachmentQuery,
				@execute_query_database = @Databasename,
				@query_result_width = 32767,
				@query_no_truncate = 1,
				@query_result_header = 1;
			END
			ELSE
			BEGIN
				EXEC msdb.dbo.sp_send_dbmail 
				@recipients = @RecipientsList,
				@subject = @SubjectText,
				@importance = @Importance,
				@body=@EmailBody ,
				@body_format = ''HTML'',
				@profile_name = @EmailProfile;
			END
	END

END TRY 
BEGIN CATCH 
	SET @ErrorMessage = N''Error occured whilst executing sp_send_dbmail: ''+ CAST(ERROR_MESSAGE() AS NVARCHAR(80));
	RAISERROR(''%s'',0,0,@ErrorMessage); --Severity is 0 as we are logging the error in the next code block
END CATCH 

END

SET @Duration = CAST(DATEDIFF(MILLISECOND,@ReportStart,GETDATE()) AS MONEY)/1000;
IF @ModuleDesc IS NULL BEGIN SET @ModuleDesc = @ModuleConfig END

EXEC [Inspector].[ExecutionLogInsert] 
@RunDatetime = @ReportStart, 
@Servername = @@SERVERNAME, 
@ModuleConfigDesc = @ModuleDesc,
@Procname = @Procname, 
@Duration = @Duration,
@PSCollection = @PSCollection,
@ErrorMessage = @ErrorMessage;

--Report Data cleanup
DELETE FROM [Inspector].[ReportData]
WHERE ReportDate < DATEADD(DAY,-@ReportDataRetention,GETDATE());

END
ELSE
BEGIN 
	RAISERROR(''@ModuleDesc supplied does not exist in [Inspector].[Modules]'',15,1) 
END

END';


SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
-- =============================================
-- Get a list of all non server specific modules with DatabaseGrowth and BackupSpace modules forced to look at the Default 
-- moduleconfig rows for report order , all custom non server specific modules 
-- =============================================
CREATE FUNCTION [Inspector].[GetNonServerSpecificModules]
(	
@ModuleDesc VARCHAR(20),
@DatabaseGrowthCheckRunEnabled BIT
)
--Revision date: 13/04/2020
RETURNS TABLE 
AS
RETURN 
(
	SELECT DISTINCT
	[ModuleConfig_Desc],
	[Modulename],
	[ReportProcedurename],
	[ServerSpecific],
	[ReportOrder],
	(SELECT [Frequency] 
	FROM [Inspector].[ModuleConfig] 
	WHERE NonServerSpecificModules.[ModuleConfig_Desc] = [ModuleConfig_Desc]
	) AS [Frequency]
	FROM
	(
		SELECT
		[Modules].[ModuleConfig_Desc],
		CASE 
			WHEN [Modulename] = ''DatabaseGrowths'' AND (@DatabaseGrowthCheckRunEnabled IS NULL OR @DatabaseGrowthCheckRunEnabled = 0) THEN NULL
			ELSE [Modulename]
		END AS [Modulename],
		[ReportProcedurename],
		[ServerSpecific],
		[ReportOrder]
		FROM 
		( --All Active servers and their ModuleConfig as ServerSpecific = 0 reports on ALL active servers
		  SELECT 
		  [Servername],
		  [ModuleConfig_Desc],
		  [TableHeaderColour]
		  FROM [Inspector].[CurrentServers]
		  WHERE [IsActive] = 1
		) AS ActiveServers
		INNER JOIN [Inspector].[Modules] ON ([ActiveServers].[ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc] OR ActiveServers.ModuleConfig_Desc IS NULL)
		WHERE [Modules].[IsActive] = 1
		AND ReportProcedurename IS NOT NULL
		AND [ServerSpecific] = 0
		AND [Modules].[ModuleConfig_Desc] = @ModuleDesc 
	) AS NonServerSpecificModules
	WHERE [Modulename] IS NOT NULL
)'

EXEC(@SQLStatement);


--Agent job creation
SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
USE [msdb];

IF NOT EXISTS (SELECT name FROM sysjobs WHERE name = ''Inspector Auto ['+@Databasename+']'')
BEGIN
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''Inspector Auto ['+@Databasename+']'', 
		@enabled='+CASE WHEN @EnableAgentJob = 1 THEN '1' ELSE '0' END+', 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''SQLUndercover Inspector Auto will check for Modules due to be executed from the Modules table and Reports due to be created
from the ModuleConfig table'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Collect data and report on schedules automatically'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ['+@Databasename+'].[Inspector].[InspectorDataCollection] @ModuleConfig = NULL,@IgnoreSchedules = 0,@PSCollection = 0;'', 
		@database_name=N''master'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every minute'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20191006, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
END'

EXEC (@SQLStatement);


--Update job command to use Collection stored procedure introduced with issue #13
--Tidied Agent job descriptions and changed equality job searches to LIKE searches as some users may rename jobs slightly , such as prefixing or suffixing.
SET @SQLStatement = CONVERT(NVARCHAR(MAX), '')+N'
DECLARE @JobID UNIQUEIDENTIFIER = NULL

SET @JobID = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name LIKE ''%SQLUndercover Inspector Data Collection%'')

IF @JobID IS NOT NULL 
BEGIN 
    EXEC msdb.dbo.sp_update_jobstep @job_id = @JobID, @step_id=1 ,@command=N''EXEC ['+@Databasename+'].[Inspector].[InspectorDataCollection] @ModuleConfig = NULL;'';
END

SET @JobID = NULL

SET @JobID = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name LIKE ''%SQLUndercover Periodic Backups Collection%'')

IF @JobID IS NOT NULL 
BEGIN
    EXEC msdb.dbo.sp_update_jobstep @job_id = @JobID, @step_id=1 ,@command=N''EXEC ['+@Databasename+'].[Inspector].[InspectorDataCollection] @ModuleConfig = ''''PeriodicBackupCheck'''';'';
END

SET @JobID = NULL

SET @JobID = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name LIKE ''%SQLUndercover Inspector Report%'')

IF @JobID IS NOT NULL 
BEGIN
    EXEC msdb.dbo.sp_update_job @job_id = @JobID, @description=N''Produce SQLUndercover Inspector HTML report from the collected data in ['+@Databasename+']''
END

SET @JobID = NULL

SET @JobID = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name LIKE ''%SQLUndercover Periodic Backups Report%'')

IF @JobID IS NOT NULL 
BEGIN
    EXEC msdb.dbo.sp_update_job @job_id = @JobID, @description=N''SQLUndercover Periodic Backup Report, check Backup information inserted into: ['+@Databasename+'] and report.''
END'

EXEC (@SQLStatement);


--Only transfer job schedules when you are upgrading from a build less than 2.00
IF (@CurrentBuild < '2.00') 
BEGIN 
RAISERROR('Transferring agent job shedules to the Modules and ModuleConfig tables',0,0) WITH NOWAIT;
--Transfer schedules for existing Agent jobs and disable the existing Agent jobs.
SELECT @SQLStatement = 
(
SELECT 
'UPDATE [Inspector].['+[Tablename]+']
SET Frequency = '+CASE WHEN [Frequency] > 1440 THEN CAST(1440 AS VARCHAR(4)) ELSE CAST([Frequency] AS VARCHAR(4)) END+', 
StartTime = '''+CAST([StartTime] AS VARCHAR(8))+''', 
EndTime = '''+CAST([EndTime] AS VARCHAR(8))+''',
IsActive = '+CAST([enabled] AS CHAR(1))+'
WHERE ModuleConfig_Desc = '''+ModuleConfig_Desc+'''; 

EXEC msdb.dbo.sp_update_job @job_name = '''+Jobname+''',@enabled = 0;

'
FROM
(
	--Get Schedule details for the Data collection and report jobs if there is one that is enabled for this database
	SELECT TOP 1
	'Default' AS ModuleConfig_Desc,
	'Modules' AS Tablename,
	Jobs.[name] AS Jobname,
	Jobs.[enabled],
	CASE [freq_subday_type]
	        WHEN 1 THEN 1440 
	        WHEN 2 THEN [freq_subday_interval]/60
	        WHEN 4 THEN [freq_subday_interval]
	        WHEN 8 THEN [freq_subday_interval]*60
	END [Frequency],
	CAST(msdb.dbo.agent_datetime(active_start_date,active_start_time) AS TIME(0)) AS StartTime,
	CAST(msdb.dbo.agent_datetime(active_end_date,active_end_time) AS TIME(0)) AS EndTime
	FROM msdb.dbo.sysjobs Jobs
	INNER JOIN msdb.dbo.sysjobsteps Steps ON Jobs.job_id = Steps.job_id
	INNER JOIN msdb.dbo.sysjobschedules JobSchedules ON JobSchedules.job_id = Jobs.job_id
	INNER JOIN msdb.dbo.sysschedules Schedules ON Schedules.schedule_id = JobSchedules.schedule_id
	WHERE 
	Schedules.[enabled] = 1
	AND Jobs.[name] LIKE '%SQLUndercover Inspector Data Collection%'
	AND (Steps.[command] LIKE '%'+@Databasename+'%' OR Steps.[database_name] = @Databasename)

	UNION

	SELECT TOP 1
	'Default' AS ModuleConfig_Desc,
	'ModuleConfig' AS Tablename,
	Jobs.[name] AS Jobname,
	Jobs.[enabled],
	CASE [freq_subday_type]
	        WHEN 1 THEN 1440 
	        WHEN 2 THEN [freq_subday_interval]/60
	        WHEN 4 THEN [freq_subday_interval]
	        WHEN 8 THEN [freq_subday_interval]*60
	END [Frequency],
	CAST(msdb.dbo.agent_datetime(active_start_date,active_start_time) AS TIME(0)),
	CAST(msdb.dbo.agent_datetime(active_end_date,active_end_time) AS TIME(0))
	FROM msdb.dbo.sysjobs Jobs
	INNER JOIN msdb.dbo.sysjobsteps Steps ON Jobs.job_id = Steps.job_id
	INNER JOIN msdb.dbo.sysjobschedules JobSchedules ON JobSchedules.job_id = Jobs.job_id
	INNER JOIN msdb.dbo.sysschedules Schedules ON Schedules.schedule_id = JobSchedules.schedule_id
	WHERE 
	Schedules.[enabled] = 1
	AND Jobs.[name] LIKE '%SQLUndercover Inspector Report%'
	AND (Steps.[command] LIKE '%'+@Databasename+'%' OR Steps.[database_name] = @Databasename)

	UNION

	SELECT TOP 1
	'PeriodicBackupCheck' AS ModuleConfig_Desc,
	'Modules' AS Tablename,
	Jobs.[name] AS Jobname,
	Jobs.[enabled],
	CASE [freq_subday_type]
	        WHEN 1 THEN 1440 
	        WHEN 2 THEN [freq_subday_interval]/60
	        WHEN 4 THEN [freq_subday_interval]
	        WHEN 8 THEN [freq_subday_interval]*60
	END [Frequency],
	CAST(msdb.dbo.agent_datetime(active_start_date,active_start_time) AS TIME(0)),
	CAST(msdb.dbo.agent_datetime(active_end_date,active_end_time) AS TIME(0))
	FROM msdb.dbo.sysjobs Jobs
	INNER JOIN msdb.dbo.sysjobsteps Steps ON Jobs.job_id = Steps.job_id
	INNER JOIN msdb.dbo.sysjobschedules JobSchedules ON JobSchedules.job_id = Jobs.job_id
	INNER JOIN msdb.dbo.sysschedules Schedules ON Schedules.schedule_id = JobSchedules.schedule_id
	WHERE 
	Schedules.[enabled] = 1
	AND Jobs.[name] LIKE '%SQLUndercover Periodic Backups Collection%'
	AND (Steps.[command] LIKE '%'+@Databasename+'%' OR Steps.[database_name] = @Databasename)

	UNION

	SELECT TOP 1
	'PeriodicBackupCheck' AS ModuleConfig_Desc,
	'ModuleConfig' AS Tablename,
	Jobs.[name] AS Jobname,
	Jobs.[enabled],
	CASE [freq_subday_type]
	        WHEN 1 THEN 1440 
	        WHEN 2 THEN [freq_subday_interval]/60
	        WHEN 4 THEN [freq_subday_interval]
	        WHEN 8 THEN [freq_subday_interval]*60
	END [Frequency],
	CAST(msdb.dbo.agent_datetime(active_start_date,active_start_time) AS TIME(0)),
	CAST(msdb.dbo.agent_datetime(active_end_date,active_end_time) AS TIME(0))
	FROM msdb.dbo.sysjobs Jobs
	INNER JOIN msdb.dbo.sysjobsteps Steps ON Jobs.job_id = Steps.job_id
	INNER JOIN msdb.dbo.sysjobschedules JobSchedules ON JobSchedules.job_id = Jobs.job_id
	INNER JOIN msdb.dbo.sysschedules Schedules ON Schedules.schedule_id = JobSchedules.schedule_id
	WHERE 
	Schedules.[enabled] = 1
	AND Jobs.[name] LIKE '%SQLUndercover Periodic Backups Report%'
	AND (Steps.[command] LIKE '%'+@Databasename+'%' OR Steps.[database_name] = @Databasename)
) AgentJobs
FOR XML PATH('') ,TYPE).value('.','nvarchar(max)');

EXEC(@SQLStatement);
END

EXEC sp_executesql N'
--Update any Tablenames in PSConfig for Report only modules issue #204 , PopulatePSConfig proc also updated to accomodate.
UPDATE PSConfig 
SET [Tablename] = NULL,[Procedurename] = [CollectionProcedurename]
FROM [Inspector].[PSConfig] 
INNER JOIN [Inspector].[Modules] ON [PSConfig].[ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc] AND [PSConfig].[Modulename] = [Modules].[Modulename]
WHERE [Modules].[CollectionProcedurename] IS NULL 
AND [PSConfig].[Tablename] IS NOT NULL;';

--Set Frequency based Insert action as the default
EXEC sp_executesql N'
UPDATE [Inspector].[PSConfig]
SET [InsertAction] = REPLACE(REPLACE([InsertAction],''1'',''3''),''2'',''3'');';

--Update Inspector Build 
UPDATE [Inspector].[Settings]
SET [Value] = @Build
WHERE [Description] = 'InspectorBuild'
AND ([Value] != @Build OR [Value] IS NULL);

--Log Upgrade/Installation in Upgrade history table 
EXEC sp_executesql N'
INSERT INTO [Inspector].[InspectorUpgradeHistory] ([Log_Date], [PreserveData], [CurrentBuild], [TargetBuild], [RevisionDate], [SetupCommand])
VALUES (GETDATE(),CASE WHEN @InitialSetup = 0 THEN 1 ELSE 0 END,CAST(@CurrentBuild AS DECIMAL(4,2)),CAST(@Build AS DECIMAL(4,2)),@Revisiondate,
''EXEC [Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = ''''''+@Databasename+'''''',	
@DataDrive = ''''''+@DataDrive+'''''',	
@LogDrive = ''''''+@LogDrive+'''''',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = ''+ISNULL(''''''''+@BackupsPath+'''''''',''NULL'')+'', 
@StackNameForEmailSubject = ''+ISNULL(''''''''+@StackNameForEmailSubject+'''''''',''SQLUndercover'')+'',	
@EmailRecipientList = ''+ISNULL(''''''''+@EmailRecipientList+'''''''',''NULL'')+'',	  
@DriveSpaceHistoryRetentionInDays = ''+CAST(ISNULL(@DriveSpaceHistoryRetentionInDays,90) AS VARCHAR(6))+'', 
@DaysUntilDriveFullThreshold = ''+CAST(ISNULL(@DaysUntilDriveFullThreshold,56) AS VARCHAR(6))+'', 
@FreeSpaceRemainingPercent = ''+CAST(ISNULL(@FreeSpaceRemainingPercent,10) AS VARCHAR(6))+'',
@DriveLetterExcludes = ''+ISNULL(''''''''+@DriveLetterExcludes+'''''''',''NULL'')+'', 
@DatabaseGrowthsAllowedPerDay = ''+CAST(ISNULL(@DatabaseGrowthsAllowedPerDay,1) AS VARCHAR(6))+'',  
@MAXDatabaseGrowthsAllowedPerDay = ''+CAST(ISNULL(@MAXDatabaseGrowthsAllowedPerDay,10) AS VARCHAR(6))+'', 
@AgentJobOwnerExclusions = ''+ISNULL(''''''''+@AgentJobOwnerExclusions+'''''''',''''''sa'''''')+'', 
@FullBackupThreshold = ''+CAST(ISNULL(@FullBackupThreshold,8) AS VARCHAR(6))+'',		
@DiffBackupThreshold = ''+CAST(ISNULL(@DiffBackupThreshold,24) AS VARCHAR(6))+'',		
@LogBackupThreshold = ''+CAST(ISNULL(@LogBackupThreshold,20) AS VARCHAR(6))+'',		
@DatabaseOwnerExclusions = ''+ISNULL(''''''''+@DatabaseOwnerExclusions+'''''''',''''''sa'''''')+'',  
@LongRunningTransactionThreshold = ''+CAST(ISNULL(@LongRunningTransactionThreshold,300) AS VARCHAR(6))+'',	
@InitialSetup = ''+CAST(ISNULL(@InitialSetup,0) AS VARCHAR(1))+'',
@EnableAgentJob = ''+CAST(ISNULL(@EnableAgentJob,0) AS VARCHAR(1))+'',
@Help = ''+CAST(ISNULL(@Help,''NULL'') AS VARCHAR(1))+'';''
);',
N'@Build DECIMAL(4,2),
@CurrentBuild DECIMAL(4,2),
@Databasename NVARCHAR(128),
@DataDrive VARCHAR(50),
@LogDrive VARCHAR(50),
@BackupsPath VARCHAR(255),
@StackNameForEmailSubject VARCHAR(255),
@EmailRecipientList VARCHAR(1000),
@DriveSpaceHistoryRetentionInDays INT,
@DaysUntilDriveFullThreshold TINYINT,
@FreeSpaceRemainingPercent TINYINT,
@DriveLetterExcludes VARCHAR(10),
@DatabaseGrowthsAllowedPerDay TINYINT,
@MAXDatabaseGrowthsAllowedPerDay TINYINT,
@AgentJobOwnerExclusions VARCHAR(255),
@FullBackupThreshold TINYINT,
@DiffBackupThreshold TINYINT,
@LogBackupThreshold TINYINT,
@DatabaseOwnerExclusions VARCHAR(255),
@LongRunningTransactionThreshold INT,
@InitialSetup BIT,
@EnableAgentJob BIT,
@Revisiondate DATE,
@Help BIT',
@Build = @Build,
@CurrentBuild = @CurrentBuild,
@Databasename = @Databasename,
@DataDrive = @DataDrive,
@LogDrive = @LogDrive,
@BackupsPath = @BackupsPath,
@StackNameForEmailSubject = @StackNameForEmailSubject,
@EmailRecipientList = @EmailRecipientList,
@DriveSpaceHistoryRetentionInDays = @DriveSpaceHistoryRetentionInDays,
@DaysUntilDriveFullThreshold = @DaysUntilDriveFullThreshold,
@FreeSpaceRemainingPercent = @FreeSpaceRemainingPercent,
@DriveLetterExcludes = @DriveLetterExcludes,
@DatabaseGrowthsAllowedPerDay = @DatabaseGrowthsAllowedPerDay,
@MAXDatabaseGrowthsAllowedPerDay = @MAXDatabaseGrowthsAllowedPerDay,
@AgentJobOwnerExclusions = @AgentJobOwnerExclusions,
@FullBackupThreshold = @FullBackupThreshold,
@DiffBackupThreshold = @DiffBackupThreshold,
@LogBackupThreshold = @LogBackupThreshold,
@DatabaseOwnerExclusions = @DatabaseOwnerExclusions,
@LongRunningTransactionThreshold = @LongRunningTransactionThreshold,
@InitialSetup = @InitialSetup,
@EnableAgentJob = @EnableAgentJob,
@Revisiondate = @Revisiondate,
@Help = @Help;

--Inspector Information
PRINT '
===================================================================================================================================
Our Getting started guide can be found here: https://sqlundercover.com/2018/02/19/getting-started-with-the-sqlundercover-inspector/
===================================================================================================================================

'
PRINT '
====================================================================
Be sure to check the following settings prior to using the solution:
====================================================================
 
[Inspector].[CurrentServers]  - Ensure that ALL servers that you want to report on are here, the data needs to stored within this database so be sure to setup a centraliation solution if storing 
								more than just this servers data.

[Inspector].[EmailRecipients] - Default group is ''DBA'' set the Recipients column to a recipient email address or addesses seperated with a comma i.e Email1@Email.com,Email2@Email.com

[Inspector].[Settings]		  - DriveSpaceRetentionPeriodInDays - Days of Drive space information to retain in the table [Inspector].[DriveSpace]
							  - DatabaseGrowthsAllowedPerDay - Total Database Growths acceptable for a 24hour period (Yellow Advisory Condition)
							  - MAXDatabaseGrowthsAllowedPerDay - MAX Database Growths for a 24hour period when you want to start seeing Red Warnings
							  - DatabaseOwnerExclusions - Set Server login names that you want excluded from the database ownership check.
							  - AgentJobOwnerExclusions - Set Server login names that you want excluded from the Agent job ownership check.
							  - BackupsPath - Specify the backup path here for backup server free space vs estimated size required estimates (Requires Xp_cmdshell enabled)

[Inspector].[Modules]		  - By Default all modules are enabled but you can control which ones you would like to have enabled, you can also add a new Row for 
							    customized configurations e.g different modules per server.

___________________________________________________________________________________________________________________________________________________________________________________________

'


END
ELSE 
BEGIN 
RAISERROR('Please double check your database context, this script needs to be executed against the database [%s]',11,0,@Databasename) WITH NOWAIT;
END


END
ELSE
BEGIN 
RAISERROR ('@Datadrive and @LogDrive cannot be NULL or Blank',11,0) WITH NOWAIT;
END


END
ELSE
BEGIN
RAISERROR('fn_SplitString does not exist, SQLUndercover Inspector requires fn_SplitString because your system is not compatible with STRING_SPLIT.
Download fn_SplitString here - http://bit.ly/fn_SplitString
and create the Function in the Master Database',0,0)
END



END

GO

DECLARE @DBname NVARCHAR(128) = DB_NAME();
RAISERROR('
--Inspector setup stored procedure is now available to run, below is an example call to the procedure.

EXEC [%s].[Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = ''%s'',	
@DataDrive = ''S,U'',	
@LogDrive = ''T,V'',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = ''F:\Backups'',
@StackNameForEmailSubject = ''SQLUndercover'',	
@EmailRecipientList = NULL,	  
@DriveSpaceHistoryRetentionInDays = 90, 
@DaysUntilDriveFullThreshold = 56, 
@FreeSpaceRemainingPercent = 10,
@DriveLetterExcludes = NULL, 
@DatabaseGrowthsAllowedPerDay = 1,  
@MAXDatabaseGrowthsAllowedPerDay = 10, 
@AgentJobOwnerExclusions = ''sa'', 
@FullBackupThreshold = 8,		
@DiffBackupThreshold = 24,		
@LogBackupThreshold = 20,		
@DatabaseOwnerExclusions = ''sa'',  
@LongRunningTransactionThreshold = 300,	
@StartTime = ''08:55'',
@EndTime = ''17:30'',
@EnableAgentJob = 1,
@InitialSetup = 0; 
',0,0,@DBname,@DBname) WITH NOWAIT;