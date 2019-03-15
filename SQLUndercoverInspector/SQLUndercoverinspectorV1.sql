SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
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
Created Date: 25/7/2017
Revision date: 07/03/2019
Version: 1.4
Description: SQLUndercover Inspector setup script Case sensitive compatible.

URL: https://github.com/SQLUndercover/UndercoverToolbox/blob/master/SQLUndercoverInspector/SQLUndercoverinspectorV1.sql

© www.sqlundercover.com 


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

*/

CREATE PROCEDURE [Inspector].[InspectorSetup]
(
@LinkedServername NVARCHAR(128) = NULL,  --Name of the Linked Server , SET to NULL if you are not using Linked Servers for this solution
									     --Run against the Target of the linked server First!! then the remaining servers you want to monitor.
@Databasename NVARCHAR(128) = NULL,	--Name of the Logging Database
@DataDrive VARCHAR(7) = NULL,	--List Data Drives here (Maximum of 4 - comma delimited e.g 'P,Q,R,S')
@LogDrive VARCHAR(7)= NULL, 	--List Log Drives here (Maximum of 4 - comma delimited e.g 'T,U,V,W')
@StackNameForEmailSubject VARCHAR(255) = 'SQLUndercover',	  --Specify the name for this stack that you want to show in the email subject
@EmailRecipientList VARCHAR(1000) = NULL,	  -- This will populate the EmailRecipients table for 'DBA'
@BackupsPath VARCHAR(255) = NULL,	  -- Backup Drive and path
@DriveSpaceHistoryRetentionInDays TINYINT = 90, -- Also controls growth history retention (Since V1.2)
@DaysUntilDriveFullThreshold	  TINYINT = 56, -- Estimated days until drive is full - Specify the threshold for when you will start to receive alerts (Red highlight and Alert header entry)
@FreeSpaceRemainingPercent		  TINYINT = 10,-- Specify the percentage of drive space remaining where you want to start seeing a yellow highlight against the drive
@DriveLetterExcludes			  VARCHAR(10) = NULL, -- Exclude Drive letters from showing Yellow Advisory warnings when @FreeSpaceRemainingPercent has been reached/exceeded e.g C,D (Comma Delimited)
@DatabaseGrowthsAllowedPerDay	  TINYINT = 1,  -- Total Database Growths acceptable for a 24hour period If exceeded a Yellow Advisory condition will be shown
@MAXDatabaseGrowthsAllowedPerDay  TINYINT = 10, -- MAX Database Growths for a 24 hour period If equal or exceeded a Red Warning condition will be shown
@AgentJobOwnerExclusions VARCHAR(50) = 'sa',  --Exclude agent jobs with these owners (Comma delimited)
@FullBackupThreshold TINYINT = 8,		-- X Days older than Getdate()
@DiffBackupThreshold TINYINT = 2,		-- X Days older than Getdate() 
@LogBackupThreshold  TINYINT = 20,		-- X Minutes older than Getdate()
@DatabaseOwnerExclusions VARCHAR(255) = 'sa',  --Exclude databases with these owners (Comma delimited)
@LongRunningTransactionThreshold INT = 300,	-- Threshold in seconds, display running transactions that exceed this duration during collection
@InitialSetup BIT = 0,	 --Set to 1 for intial setup, 0 to Upgrade or re deploy to preserve previously logged data and settings config.
@Help BIT = 0 --Show example Setup command
)
AS
BEGIN 

--Allowing NULL values but only when @Help = 1 otherwise raise an error stating that values need to be specified.
IF ((@Databasename IS NULL OR @DataDrive IS NULL OR @LogDrive IS NULL) AND @Help = 0)
BEGIN 
	RAISERROR('@Databasename, @DataDrive, @LogDrive, @BackupsPath cannot be NULL when @Help = 0 is specified',11,0) WITH NOWAIT;
	RETURN;
END


IF @Help = 1
BEGIN 
PRINT '
--Inspector V1.4
--Revision date: 25/01/2019
--You specified @Help = 1 - No setup has been carried out , here is an example command:

EXEC [Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = '''+DB_NAME()+''',	
@DataDrive = ''S'',	
@LogDrive = ''T'',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = ''F:\Backups\'',
@LinkedServername = NULL,  
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
@DiffBackupThreshold = 2,		
@LogBackupThreshold = 20,		
@DatabaseOwnerExclusions = ''sa'',  
@LongRunningTransactionThreshold = 300,	
@InitialSetup = 0,
@Help = 0; 
'
RETURN;
END

IF @InitialSetup IS NULL 
BEGIN 
	RAISERROR('@InitialSetup cannot be NULL , please specify 0 or 1',11,0) WITH NOWAIT;
	RETURN;
END 

DECLARE @LinkedServernameParam NVARCHAR(128) = @LinkedServername;
DECLARE @Compatibility BIT
--SET compatibility to 1 if server version includes STRING_SPLIT
SELECT	@Compatibility = CASE
			WHEN SERVERPROPERTY ('productversion') >= '13.0.4001.0' AND compatibility_level >= 130 THEN 1
			ELSE 0
		END
FROM sys.databases
WHERE name = DB_NAME()

IF @LinkedServername IS NOT NULL BEGIN SET @LinkedServername = UPPER(@LinkedServername) END;

IF @Compatibility = 1 OR (@Compatibility = 0 AND OBJECT_ID('master.dbo.fn_SplitString') IS NOT NULL) 
BEGIN

IF (@DataDrive IS NOT NULL AND @LogDrive IS NOT NULL) 
	BEGIN
	SET  @DataDrive = REPLACE(@DataDrive,' ','')
	SET  @LogDrive  = REPLACE(@LogDrive,' ','')

	IF LEN(@DataDrive) <= 7 AND LEN(@LogDrive) <= 7
	BEGIN
		IF DB_NAME() = @Databasename
		BEGIN
			IF @LinkedServername IS NULL OR EXISTS (SELECT name FROM sys.servers WHERE name = @LinkedServername)
			BEGIN
			SET NOCOUNT ON;

			DECLARE @SQLStatement VARCHAR(MAX) 
			DECLARE @DatabaseFileSizesResult INT
			DECLARE @Build VARCHAR(6) ='1.4'
			DECLARE @CurrentBuild VARCHAR(6)
			 
			
			IF RIGHT(@BackupsPath,1) != '\' BEGIN SET @BackupsPath = @BackupsPath +'\' END
			
			IF @LinkedServername IS NOT NULL BEGIN SET @LinkedServername = QUOTENAME(@LinkedServername)+'.' END
			IF @LinkedServername IS NULL BEGIN SET @LinkedServername = '' END

			IF OBJECT_ID('Inspector.Settings') IS NOT NULL
			BEGIN
				SELECT @CurrentBuild = (SELECT NULLIF([Value],'') FROM [Inspector].[Settings] WHERE [Description] = 'InspectorBuild')
			END
			
			IF @CurrentBuild IS NOT NULL
			BEGIN 
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
			CurrentBuild DECIMAL(4,1) NULL,
			TargetBuild DECIMAL(4,1) NULL,
			SetupCommand VARCHAR(1000) NULL
			);

			
			IF OBJECT_ID('Inspector.ReportData') IS NULL 
			CREATE TABLE [Inspector].[ReportData](
				[ID] INT IDENTITY(1,1),
				[ReportDate] DATETIME NOT NULL,
				[ModuleConfig] VARCHAR(20),
				[ReportData] VARCHAR(MAX) NULL,
				[Summary] VARCHAR(60) NULL
			);

			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Summary' AND [object_id] = OBJECT_ID(N'Inspector.ReportData'))
			BEGIN
				--New column for 1.2 for Inspector.ReportData
				ALTER TABLE [Inspector].[ReportData] ADD [Summary] VARCHAR(60) NULL;
			END

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.ReportData') AND name='IX_ReportDate')
			BEGIN
				CREATE NONCLUSTERED INDEX [IX_ReportDate] ON [Inspector].[ReportData]
				(ReportDate ASC);
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

			IF OBJECT_ID('Inspector.Modules') IS NULL
			CREATE TABLE [Inspector].[Modules]
			(
			ID INT IDENTITY(1,1),
			ModuleConfig_Desc VARCHAR(20) NOT NULL,
			AGCheck	BIT,
			BackupsCheck	BIT,
			BackupSizesCheck	BIT,
			DatabaseGrowthCheck	BIT,
			DatabaseFileCheck	BIT,
			DatabaseOwnershipCheck	BIT,
			DatabaseStatesCheck	BIT,
			DriveSpaceCheck	BIT,
			FailedAgentJobCheck	BIT,
			JobOwnerCheck	BIT,
			FailedLoginsCheck	BIT,
			TopFiveDatabaseSizeCheck	BIT,
			ADHocDatabaseCreationCheck	BIT,
			BackupSpaceCheck	BIT,
			DatabaseSettings	BIT,
			ServerSettings	BIT,
			SuspectPages	BIT,
			AGDatabases	BIT,
			LongRunningTransactions BIT,
			UseMedianCalculationForDriveSpaceCalc	BIT
			CONSTRAINT PK_ModuleConfig_Desc PRIMARY KEY (ModuleConfig_Desc)
			);


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


			IF OBJECT_ID('Inspector.ADHocDatabaseCreations') IS NULL
			CREATE TABLE [Inspector].[ADHocDatabaseCreations]
			(
			[Servername] NVARCHAR(128) NOT NULL,
			[Log_Date] DATETIME NULL,
			[Databasename] NVARCHAR(128) NOT NULL,
			[Create_Date] DATETIME NULL
			);

			
			IF OBJECT_ID('Inspector.ADHocDatabaseSupression') IS NULL
			CREATE TABLE [Inspector].[ADHocDatabaseSupression]
			(
			[Servername] NVARCHAR(128),
			[Log_Date] DATETIME,
			[Databasename] NVARCHAR(128),
			[Suppress] BIT
			);		
				
			
			IF OBJECT_ID('Inspector.AGCheck') IS NULL
			CREATE TABLE [Inspector].[AGCheck]
			(
			[Servername] NVARCHAR(128) NOT NULL,
			[Log_Date] DATETIME NOT NULL,
			[AGname] NVARCHAR(128) NULL,
			[State] VARCHAR(50) NULL,
			[ReplicaServername] NVARCHAR(256) NULL,
			[Suspended] BIT NULL,
			[SuspendReason] VARCHAR(50) NULL
			); 
			
			 
			
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
			[Drive] NVARCHAR(3),
			[Capacity_GB] DECIMAL(10,2),
			[AvailableSpace_GB] DECIMAL(10,2)
			);

			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND type = 1)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.DriveSpace') AND name='CIX_Servername_LogDate_Drive')
				BEGIN 
					CREATE CLUSTERED INDEX [CIX_Servername_LogDate_Drive] ON [Inspector].[DriveSpace] ([Servername] ASC,[Log_Date] ASC,[Drive] ASC);
				END
			END
			
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
			--New Column [LastUpdated] for 1.0.1
			CREATE TABLE [Inspector].[DatabaseFileSizes](
			[Servername] NVARCHAR(128)  NOT NULL,
			[Database_id] INT NOT NULL,
			[Database_name] [NVARCHAR](128) NULL,
			[OriginalDateLogged] [DATETIME] NOT NULL,
			[OriginalSize_MB] BIGINT NULL,
			[Type_desc] [NVARCHAR](60) NULL,
			[File_id] TINYINT NOT NULL,
			[Filename] [NVARCHAR](260) NULL,
			[PostGrowthSize_MB] BIGINT NULL,
			[GrowthRate] [int] NULL,
			[Is_percent_growth] [BIT] NOT NULL,
			[NextGrowth] BIGINT  NULL,
			[LastUpdated] DATETIME NULL	  
			); 

			--New Column [LastUpdated] for 1.0.1
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Inspector.DatabaseFileSizes') AND name ='LastUpdated')
			BEGIN 
				ALTER TABLE [Inspector].[DatabaseFileSizes] ADD [LastUpdated] DATETIME NULL;
			END 
			
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
			[File_id] TINYINT NOT NULL,
			[FileName] NVARCHAR(260) NOT NULL,
			[PreGrowthSize_MB] BIGINT NOT NULL,
			[GrowthRate_MB] INT NOT NULL,
			[GrowthIncrements] INT NOT NULL,
			[PostGrowthSize_MB] BIGINT NOT NULL
			);
			
			IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inspector.DatabaseFileSizeHistory') AND name='IX_Servername_Includes_Log_Date')
			BEGIN
				CREATE NONCLUSTERED INDEX [IX_Servername_Includes_Log_Date] ON [Inspector].[DatabaseFileSizeHistory]
				([Servername] ASC) INCLUDE ([Log_Date]); 
			END

			END

			IF OBJECT_ID('Inspector.EmailRecipients') IS NULL		
			CREATE TABLE [Inspector].[EmailRecipients]
			(
			ID INT IDENTITY(1,1),
			Description VARCHAR(50) NOT NULL,
			Recipients VARCHAR(1000) DEFAULT NULL
			CONSTRAINT UC_EmailDescription UNIQUE (Description)
			); 
			
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
			ADD CONSTRAINT FK_ModuleConfig_Desc
			FOREIGN KEY (ModuleConfig_Desc) REFERENCES Inspector.Modules(ModuleConfig_Desc);
			END

			IF OBJECT_ID('Inspector.EmailConfig') IS NULL
			CREATE TABLE [Inspector].[EmailConfig]
			(
			ModuleConfig_Desc VARCHAR(20),
			EmailSubject VARCHAR(100) DEFAULT NULL,
			CONSTRAINT FK_ModuleConfig_Email FOREIGN KEY (ModuleConfig_Desc) REFERENCES Inspector.Modules(ModuleConfig_Desc)
			);
			
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
			VALUES(NULL,''InspectorDefault'',NULL,NULL,NULL),(1,''Red'',''#F78181'',''#000000'',''#F78181''),(2,''Yellow'',''#FAFCA4'',''#000000'',''#FAFCA4''),(3,''Information (white)'',''#FEFFFF'',''#000000'',''#FEFFFF'');';

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
				SET [HighlightHtmlColor] = ''#F78181''
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
			SET [GradientRightHtmlColor] = ''#F78181''
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
			[value_in_use] INT NULL
			);

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
			[Databasename] NVARCHAR(128) NULL
			);

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
				[Duration] MONEY,
				[PSCollection] BIT NOT NULL
				); 

				CREATE CLUSTERED INDEX [CIX_ExecutionLog_ID] ON [Inspector].[ExecutionLog]
				([ID] ASC);
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


		    IF OBJECT_ID('Inspector.CatalogueModules') IS NULL
			BEGIN
				CREATE TABLE [Inspector].[CatalogueModules] (
				[ModuleConfig_Desc] VARCHAR(20),
				[Module] VARCHAR(50),
				[Enabled] BIT
				);
				
				ALTER TABLE [Inspector].[CatalogueModules] ADD CONSTRAINT [FK_CatalogueModules_ModuleConfig_Desc]
				FOREIGN KEY (ModuleConfig_Desc) REFERENCES [Inspector].[Modules](ModuleConfig_Desc);
				
				ALTER TABLE [Inspector].[CatalogueModules]
				ADD CONSTRAINT [CatalogueModules_ModuleConfig_Desc] UNIQUE ([ModuleConfig_Desc]);

				--One off population
				INSERT INTO [Inspector].[CatalogueModules] ([ModuleConfig_Desc],[Module],[Enabled])
				SELECT 
				[Modules].[ModuleConfig_Desc],
				[CatalogueModulesList].[Module],
				CASE WHEN [ModuleConfig_Desc] = 'Default' THEN 1 ELSE 0 END AS [Enabled]
				FROM [Inspector].[Modules]
				CROSS JOIN (SELECT [Module] FROM (VALUES('CatalogueMissingLogins')) ModuleList(Module)) AS CatalogueModulesList
				WHERE NOT EXISTS (SELECT 1 FROM [Inspector].[CatalogueModules] WHERE [ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc] AND [Module] = [CatalogueModulesList].[Module])
			END
			ELSE 
			BEGIN 
				--Added this block for future Catalogue module additions
				INSERT INTO [Inspector].[CatalogueModules] ([ModuleConfig_Desc],[Module],[Enabled])
				SELECT 
				[Modules].[ModuleConfig_Desc],
				[CatalogueModulesList].[Module],
				CASE WHEN [ModuleConfig_Desc] = 'Default' THEN 1 ELSE 0 END AS [Enabled]
				FROM [Inspector].[Modules]
				CROSS JOIN (SELECT [Module] FROM (VALUES('CatalogueMissingLogins')) ModuleList(Module)) AS CatalogueModulesList
				WHERE NOT EXISTS (SELECT 1 FROM [Inspector].[CatalogueModules] WHERE [ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc] AND [Module] = [CatalogueModulesList].[Module])
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


			--New Setting for 1.2 - Powershell banner.
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'PSEmailBannerURL')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES ('PSEmailBannerURL','http://bit.ly/PSInspectorEmailBanner');
			END

			--New Setting for 1.2 - Is Linked Server being used.
			IF NOT EXISTS (SELECT 1 FROM [Inspector].[Settings] WHERE [Description] = 'LinkedServername')
			BEGIN
				INSERT INTO [Inspector].[Settings] ([Description],[Value])
				VALUES ('LinkedServername',@LinkedServernameParam);
			END
			ELSE 
				BEGIN
					UPDATE [Inspector].[Settings] 
					SET [Value] = @LinkedServernameParam
					WHERE [Description] = 'LinkedServername'
				END

			--New URL for standard email banner
			IF (SELECT [Value] FROM [Inspector].[Settings] WHERE [Description] = 'EmailBannerURL') = 'https://i2.wp.com/sqlundercover.files.wordpress.com/2017/11/inspector_whitehandle.png?ssl=1&w=450'
			BEGIN
				UPDATE [Inspector].[Settings] 
				SET [Value] = 'http://bit.ly/InspectorEmailBanner'
				WHERE [Description] = 'EmailBannerURL';
			END

			
			IF OBJECT_ID('Inspector.Modules') IS NOT NULL 
			BEGIN 

				--New columns for V1.2 for Inspector.Modules
				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ServerSettings' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
				BEGIN
					ALTER TABLE [Inspector].[Modules] ADD [ServerSettings] BIT NULL;
				END

				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'SuspectPages' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
				BEGIN
					ALTER TABLE [Inspector].[Modules] ADD [SuspectPages] BIT NULL;
				END

				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'AGDatabases' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
				BEGIN
					ALTER TABLE [Inspector].[Modules] ADD [AGDatabases] BIT NULL;
				END

				IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'LongRunningTransactions' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
				BEGIN
					ALTER TABLE [Inspector].[Modules] ADD [LongRunningTransactions] BIT NULL;
				END

				IF (SELECT CAST([Value] AS DECIMAL(4,1)) FROM [Inspector].[Settings] WHERE [Description] = 'InspectorBuild') < 1.2
				BEGIN 
					IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ServerSettings' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
					BEGIN
						EXEC sp_executesql N'UPDATE [Inspector].[Modules] SET [ServerSettings] = CASE WHEN ModuleConfig_Desc = ''Default'' THEN 1 ELSE 0 END;';	
					END

					IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'SuspectPages' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
					BEGIN
						EXEC sp_executesql N'UPDATE [Inspector].[Modules] SET [SuspectPages] = CASE WHEN ModuleConfig_Desc = ''Default'' THEN 1 ELSE 0 END;';				
					END

					IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'AGDatabases' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
					BEGIN
						EXEC sp_executesql N'UPDATE [Inspector].[Modules] SET [AGDatabases] = CASE WHEN ModuleConfig_Desc = ''Default'' THEN 1 ELSE 0 END;';
					END

					IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'LongRunningTransactions' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
					BEGIN
						EXEC sp_executesql N'UPDATE [Inspector].[Modules] SET [LongRunningTransactions] = CASE WHEN ModuleConfig_Desc = ''Default'' THEN 1 ELSE 0 END;';
					END
				END
			END

			--New columns for V1.3 for Inspector.Modules
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'UnusedLogshipConfig' AND [object_id] = OBJECT_ID(N'Inspector.Modules'))
			BEGIN
				ALTER TABLE [Inspector].[Modules] ADD [UnusedLogshipConfig] BIT NULL;
				EXEC sp_executesql N'UPDATE [Inspector].[Modules] SET [UnusedLogshipConfig] = CASE WHEN ModuleConfig_Desc = ''Default'' THEN 1 ELSE 0 END;';	
			END

--Populate config
IF @InitialSetup = 1 
BEGIN
--Truncate tables - Settings,Modules,EmailConfig,ModuleWarnings,ModuleWarningLevel,EmailRecipients
TRUNCATE TABLE [Inspector].[Settings];
TRUNCATE TABLE [Inspector].[EmailConfig];
TRUNCATE TABLE [Inspector].[ModuleWarnings];
TRUNCATE TABLE [Inspector].[ModuleWarningLevel];
TRUNCATE TABLE [Inspector].[EmailRecipients];
DELETE FROM [Inspector].[Modules];
DBCC CHECKIDENT ('Inspector.Modules', RESEED, 0);

--Insert Settings into Inspector Base tables  
SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+'
INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES  (''SQLUndercoverInspectorEmailSubject'','''+@StackNameForEmailSubject+''');

		
INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES	(''DriveSpaceRetentionPeriodInDays'','+CAST(@DriveSpaceHistoryRetentionInDays AS VARCHAR(6))+'),
		(''FullBackupThreshold'','+CAST(@FullBackupThreshold AS VARCHAR(3))+'),
		(''DiffBackupThreshold'','+CAST(@DiffBackupThreshold AS VARCHAR(3))+'),
		(''LogBackupThreshold'' ,'+CAST(@LogBackupThreshold AS VARCHAR(6))+'),
		(''DaysUntilDriveFullThreshold'' ,'+CAST(@DaysUntilDriveFullThreshold AS VARCHAR(4))+'),
		(''FreeSpaceRemainingPercent'','+CAST(@FreeSpaceRemainingPercent AS VARCHAR(3))+'),
		(''DatabaseGrowthsAllowedPerDay'','+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'),
		(''MAXDatabaseGrowthsAllowedPerDay'','+CAST(@MAXDatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'),
		(''LongRunningTransactionThreshold'','+CAST(@LongRunningTransactionThreshold AS VARCHAR(8))+'),
		(''ReportDataRetention'',''30'');


INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES	(''BackupsPath'','''+ISNULL(@BackupsPath,'NULL')+'''),
		(''EmailBannerURL'',''http://bit.ly/InspectorEmailBanner''),
		(''PSEmailBannerURL'',''http://bit.ly/PSInspectorEmailBanner''),
		(''DatabaseOwnerExclusions'','''+@DatabaseOwnerExclusions+'''),
		(''AgentJobOwnerExclusions'','''+@AgentJobOwnerExclusions+'''),
		'+CASE 
			WHEN @LinkedServernameParam IS NULL 
			THEN 
			'(''LinkedServername'',NULL)
			'
			ELSE
			'(''LinkedServername'','''+@LinkedServernameParam+''');
			'
			END+';

INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES	(''InspectorBuild'','''+@Build+'''),
'+CASE 
			WHEN @DriveLetterExcludes IS NULL 
			THEN 
			'(''DriveSpaceDriveLetterExcludes'',NULL)
			'
			ELSE
			'(''DriveSpaceDriveLetterExcludes'','''+@DriveLetterExcludes+''');
			'
			END+
		'
		


INSERT INTO [Inspector].[Modules] (ModuleConfig_Desc,AGCheck,BackupsCheck,BackupSizesCheck,DatabaseGrowthCheck,DatabaseFileCheck,DatabaseOwnershipCheck,
					   DatabaseStatesCheck,DriveSpaceCheck,FailedAgentJobCheck,JobOwnerCheck,FailedLoginsCheck,TopFiveDatabaseSizeCheck,
					   ADHocDatabaseCreationCheck,BackupSpaceCheck,DatabaseSettings,ServerSettings,SuspectPages,AGDatabases,LongRunningTransactions,UnusedLogshipConfig,UseMedianCalculationForDriveSpaceCalc)
VALUES	(''Default'',1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0),(''PeriodicBackupCheck'',0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        
INSERT INTO [Inspector].[EmailConfig] (ModuleConfig_Desc,EmailSubject)
VALUES (''Default'',''SQLUndercover Inspector check ''),(''PeriodicBackupCheck'',''SQLUndercover Backups Report'');

INSERT INTO [Inspector].[ModuleWarnings] ([WarningLevel],[WarningDesc])
VALUES(NULL,''InspectorDefault''),(1,''Red''),(2,''Yellow''),(3,''Information (white)'');

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 
INSERT INTO '+CAST(@LinkedServername AS VARCHAR(128))+'['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers] (Servername,IsActive,ModuleConfig_Desc)
SELECT DISTINCT replica_server_name,1,NULL
FROM sys.dm_hadr_availability_replica_cluster_nodes AGServers
WHERE NOT EXISTS (SELECT Servername FROM '+CAST(@LinkedServername AS VARCHAR(128))+'['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers] WHERE Servername COLLATE DATABASE_DEFAULT = AGServers.replica_server_name)
END 
ELSE 
BEGIN 

INSERT INTO '+CAST(@LinkedServername AS VARCHAR(128))+'['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers] (Servername,IsActive,ModuleConfig_Desc)
SELECT @@SERVERNAME,1,NULL
WHERE NOT EXISTS (SELECT Servername FROM '+CAST(@LinkedServername AS VARCHAR(128))+'['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers] WHERE Servername = @@Servername)
END
'
+
CASE 
WHEN @EmailRecipientList IS NULL 
THEN 
'INSERT INTO [Inspector].[EmailRecipients] (Description)
VALUES (''DBA'');
'
ELSE
'
INSERT INTO [Inspector].[EmailRecipients] (Description,Recipients)
VALUES (''DBA'','''+@EmailRecipientList+''');

'
END

EXEC (@SQLStatement);

END


	IF OBJECT_ID('Inspector.PowerBIBackupsview') IS NULL
	BEGIN
	EXEC sp_executesql N'CREATE VIEW [Inspector].[PowerBIBackupsview]
	AS
	--Revision Date: 04/02/2019
	WITH RawData AS 
	(SELECT 
	Log_Date,
	LTRIM(RTRIM(BackupSet.Databasename)) AS Databasename, --Added trim as Leading and trailing spaces can cause misreporting
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
	WHERE CAST(GETDATE() AS DATE) >= CAST(GETDATE() AS DATE)
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
	AGname,
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
	--Revision Date: 04/02/2019
	WITH RawData AS 
	(SELECT 
	Log_Date,
	LTRIM(RTRIM(BackupSet.Databasename)) AS Databasename, --Added trim as Leading and trailing spaces can cause misreporting
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
	WHERE CAST(GETDATE() AS DATE) >= CAST(GETDATE() AS DATE)
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
	AGname,
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
			
			SELECT 
			[GrowthInfo].[Servername],
			[GrowthInfo].[Database_name],
			[GrowthInfo].[FirstRecordedGrowth],
			DATEDIFF(DAY,[GrowthInfo].[FirstRecordedGrowth],CAST(GETDATE() AS DATE)) AS FirstRecordedGrowthAge_Days,
			[GrowthInfo].[TotalGrowths],
			[GrowthInfo].[FileName],
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
				CAST(MIN([Log_Date]) AS DATE) AS FirstRecordedGrowth,
				COUNT([Log_Date]) AS TotalGrowths,
				[FileName],
				SUM([PostGrowthSize_MB]-[PreGrowthSize_MB]) AS TotalGrowth_MB
				FROM [Inspector].[DatabaseFileSizeHistory]
				GROUP BY 
				[Servername],
				[Database_name],
				[FileName]
			) GrowthInfo
			INNER JOIN [Inspector].[DatabaseFileSizes] ON [DatabaseFileSizes].[Database_name] = [GrowthInfo].[Database_name] 
			AND  [DatabaseFileSizes].[Servername] =  [GrowthInfo].[Servername] 
			AND [DatabaseFileSizes].[Filename] =  [GrowthInfo].[FileName];';
			END


			IF OBJECT_ID('Inspector.DriveSpaceInfo') IS NULL
			BEGIN
			EXEC sp_executesql N'CREATE VIEW [Inspector].[DriveSpaceInfo]
			AS
			
			/*
			Author: Adrian Buckman
			Created: 23/08/2018
			Revised: n/a
			Description: Show aggregated space used by drive by server, show Average daily,monthly and yearly usage and MIN/MAX Daily Increment variances.
			*/
			
			SELECT 
			Servername,
			Drive,
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
			SELECT [ModuleConfig_Desc],[Module],[Enabled]
			FROM 
			(
			    SELECT	
				ModuleConfig_Desc,						
			    ISNULL(AGCheck,0) AS AGCheck,					
			    ISNULL(BackupsCheck,0) AS BackupsCheck,					
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
			WHERE [Enabled] = 1;');
			END
			ELSE 
			BEGIN
			EXEC ('ALTER VIEW [Inspector].[PSEnabledModules]
			AS
			SELECT [ModuleConfig_Desc],[Module],[Enabled]
			FROM 
			(
			    SELECT	
				ModuleConfig_Desc,						
			    ISNULL(AGCheck,0) AS AGCheck,					
			    ISNULL(BackupsCheck,0) AS BackupsCheck,					
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
			WHERE [Enabled] = 1;');
			END

			IF OBJECT_ID('Inspector.PSInspectorTables') IS NULL
			BEGIN
			EXEC sp_executesql N'
			CREATE VIEW [Inspector].[PSInspectorTables]
			AS
			SELECT Tablename
			FROM (VALUES
			(''ADHocDatabaseCreations''),
			(''ADHocDatabaseSupression''),
			(''AGCheck''),
			(''AGDatabases''),
			(''BackupsCheck''),
			(''BackupSizesByDay''),
			(''CurrentServers''),
			(''DatabaseFiles''),
			(''DatabaseFileSizeHistory''),
			(''DatabaseFileSizes''),
			(''DatabaseOwnership''),
			(''DatabaseSettings''),
			(''DatabaseStates''),
			(''DriveSpace''),
			(''EmailConfig''),
			(''EmailRecipients''),
			(''FailedAgentJobs''),
			(''InstanceStart''),
			(''InstanceVersion''),
			(''InstanceVersionHistory''),
			(''JobOwner''),
			(''LoginAttempts''),
			(''LongRunningTransactions''),
			(''Modules''),
			(''ReportData''),
			(''ServerSettings''),
			(''Settings''),
			(''SuspectPages''),
			(''TopFiveDatabases''),
			(''ModuleWarningLevel''),
			(''UnusedLogshipConfig''),
			(''CatalogueModules'')
			) InspectorTables (Tablename);'
			END
			ELSE 
			BEGIN 
			EXEC sp_executesql N'
			ALTER VIEW [Inspector].[PSInspectorTables]
			AS
			SELECT Tablename
			FROM (VALUES
			(''ADHocDatabaseCreations''),
			(''ADHocDatabaseSupression''),
			(''AGCheck''),
			(''AGDatabases''),
			(''BackupsCheck''),
			(''BackupSizesByDay''),
			(''CurrentServers''),
			(''DatabaseFiles''),
			(''DatabaseFileSizeHistory''),
			(''DatabaseFileSizes''),
			(''DatabaseOwnership''),
			(''DatabaseSettings''),
			(''DatabaseStates''),
			(''DriveSpace''),
			(''EmailConfig''),
			(''EmailRecipients''),
			(''FailedAgentJobs''),
			(''InstanceStart''),
			(''InstanceVersion''),
			(''InstanceVersionHistory''),
			(''JobOwner''),
			(''LoginAttempts''),
			(''LongRunningTransactions''),
			(''Modules''),
			(''ReportData''),
			(''ServerSettings''),
			(''Settings''),
			(''SuspectPages''),
			(''TopFiveDatabases''),
			(''ModuleWarningLevel''),
			(''UnusedLogshipConfig''),
			(''CatalogueModules'')
			) InspectorTables (Tablename);'
			END
						
			IF OBJECT_ID('Inspector.PSADHocDatabaseSupressionStage') IS NULL
			CREATE TABLE [Inspector].[PSADHocDatabaseSupressionStage](
			[Servername] [nvarchar](128) NULL,
			[Log_Date] [datetime] NULL,
			[Databasename] [nvarchar](128) NULL,
			[Suppress] [bit] NULL
			);
			
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
			
			IF OBJECT_ID('Inspector.PSDatabaseFileSizeHistoryStage') IS NULL
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
			[PostGrowthSize_MB] [bigint] NOT NULL
			);
			
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
			[Drive] [nvarchar](3) NULL,
			[Capacity_GB] [decimal](10, 2) NULL,
			[AvailableSpace_GB] [decimal](10, 2) NULL
			);	 

			IF OBJECT_ID('Inspector.PSInstanceVersionHistoryStage') IS NULL
			CREATE TABLE [Inspector].[PSInstanceVersionHistoryStage](
			[Servername] NVARCHAR(128) NOT NULL,
			[Log_Date] DATETIME NOT NULL,
			[CollectionDatetime] DATETIME NOT NULL,
			[VersionNo] NVARCHAR(50) NULL,
			[Edition] NVARCHAR(128) NULL
			);
		

			--Drop procedures for recreation
			IF OBJECT_ID('Inspector.ADHocDatabaseCreationsInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[ADHocDatabaseCreationsInsert];
			
			IF OBJECT_ID('Inspector.AGCheckInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[AGCheckInsert];
			
			IF OBJECT_ID('Inspector.DatabaseFilesInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[DatabaseFilesInsert];
			
			IF OBJECT_ID('Inspector.DatabaseStatesInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[DatabaseStatesInsert];
			
			IF OBJECT_ID('Inspector.DriveSpaceInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[DriveSpaceInsert];
			
			IF OBJECT_ID('Inspector.FailedAgentJobsInsert') IS NOT NULL 
			DROP PROCEDURE [Inspector].[FailedAgentJobsInsert];
			
			--Typo Fix 1.0.1
			IF OBJECT_ID('Inspector.LoginAttemptsiInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[LoginAttemptsiInsert];

			--Corrected Typo 1.0.1
			IF OBJECT_ID('Inspector.LoginAttemptsInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[LoginAttemptsInsert];
			
			IF OBJECT_ID('Inspector.JobOwnerInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[JobOwnerInsert];
			
			IF OBJECT_ID('Inspector.TopFiveDatabasesInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[TopFiveDatabasesInsert];
			
			IF OBJECT_ID('Inspector.BackupsCheckInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[BackupsCheckInsert];
			
			IF OBJECT_ID('Inspector.DatabaseGrowthsInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[DatabaseGrowthsInsert];
			
			IF OBJECT_ID('Inspector.DatabaseOwnershipInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[DatabaseOwnershipInsert];
			
			IF OBJECT_ID('Inspector.BackupSizesByDayInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[BackupSizesByDayInsert];
			
			IF OBJECT_ID('Inspector.DatabaseSettingsInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[DatabaseSettingsInsert];

			IF OBJECT_ID('Inspector.ServerSettingsInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[ServerSettingsInsert];

			IF OBJECT_ID('Inspector.InstanceStartInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[InstanceStartInsert];

			IF OBJECT_ID('Inspector.InstanceVersionInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[InstanceVersionInsert];

			IF OBJECT_ID('Inspector.SuspectPagesInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[SuspectPagesInsert];

			IF OBJECT_ID('Inspector.AGDatabasesInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[AGDatabasesInsert];

			IF OBJECT_ID('Inspector.LongRunningTransactionsInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[LongRunningTransactionsInsert];
									
			IF OBJECT_ID('Inspector.SQLUnderCoverInspectorReport') IS NOT NULL 
			DROP PROCEDURE [Inspector].[SQLUnderCoverInspectorReport];

			IF OBJECT_ID('Inspector.InspectorDataCollection') IS NOT NULL 
			DROP PROCEDURE [Inspector].[InspectorDataCollection];

			IF OBJECT_ID('Inspector.PopulateModuleWarningLevel') IS NOT NULL 
			DROP PROCEDURE [Inspector].[PopulateModuleWarningLevel];

			IF OBJECT_ID('Inspector.UnusedLogshipConfigInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[UnusedLogshipConfigInsert];

			IF OBJECT_ID('Inspector.ExecutionLogInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[ExecutionLogInsert];

			IF OBJECT_ID('Inspector.CatalogueMissingLogins') IS NOT NULL
			DROP PROCEDURE [Inspector].[CatalogueMissingLogins];

			IF OBJECT_ID('Inspector.ResetHtmlColors') IS NOT NULL
			DROP PROCEDURE [Inspector].[ResetHtmlColors];

			IF OBJECT_ID('Inspector.PSGetColumns') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetColumns];

			IF OBJECT_ID('Inspector.PSGetInspectorBuild') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetInspectorBuild];

			IF OBJECT_ID('Inspector.PSGetConfig') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetConfig];

			IF OBJECT_ID('Inspector.PSGetServers') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetServers];

			IF OBJECT_ID('Inspector.PSGetADHocDatabaseCreationsStage') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetADHocDatabaseCreationsStage];

			IF OBJECT_ID('Inspector.PSGetAGDatabasesStage') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetAGDatabasesStage];

			IF OBJECT_ID('Inspector.PSGetDatabaseGrowthsStage') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetDatabaseGrowthsStage];

			IF OBJECT_ID('Inspector.PSGetDriveSpaceStage') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetDriveSpaceStage];

			IF OBJECT_ID('Inspector.PSGetSettingsTables') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetSettingsTables];

			IF OBJECT_ID('Inspector.PSGetInstanceVersionHistoryStage') IS NOT NULL
			DROP PROCEDURE [Inspector].[PSGetInstanceVersionHistoryStage];

			
			

SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[ADHocDatabaseCreationsInsert]
AS
BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations]
WHERE Servername = @Servername;


INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations] (Servername,Log_Date,Databasename,Create_Date)
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
			  FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[ADHocDatabaseSupression] 
			  WHERE Servername = @Servername AND Suppress = 1)
ORDER BY create_date ASC;


INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[ADHocDatabaseSupression] (Servername, Log_Date, Databasename, Suppress)
SELECT
@Servername,
GETDATE(),
Databasename,
0
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations] Creations
WHERE Servername = @Servername
AND NOT EXISTS (SELECT Databasename 
			 FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[ADHocDatabaseSupression] SuppressList
			 WHERE SuppressList.Servername = @Servername AND SuppressList.Databasename = Creations.Databasename);


IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations] 
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations] (Servername,Log_Date,Databasename,Create_Date)
			VALUES(@Servername,GETDATE(),''No Ad hoc database creations present'',NULL)
			END

END;'

EXEC (@SQLStatement);

SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[AGCheckInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[AGCheck]
WHERE Servername = @Servername;

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[AGCheck] ([Servername], [Log_Date], [AGname], [State], [ReplicaServername], [Suspended], [SuspendReason])
SELECT DISTINCT
@Servername,
GETDATE(),
Groups.name AS AGNAME,
States.synchronization_health_desc,
Replicas.replica_server_name COLLATE DATABASE_DEFAULT +'' ('' + CAST(States.role_desc AS NCHAR(1)) +'')'',
ReplicaStates.is_suspended,
ISNULL(ReplicaStates.suspend_reason_desc,''N/A'') AS suspend_reason_desc
FROM sys.availability_groups Groups
INNER JOIN sys.dm_hadr_availability_replica_states as States ON States.group_id = Groups.group_id
INNER JOIN sys.availability_replicas as Replicas ON States.replica_id = Replicas.replica_id
INNER JOIN sys.dm_hadr_database_replica_states as ReplicaStates ON Replicas.replica_id = ReplicaStates.replica_id

END 
ELSE 
BEGIN

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[AGCheck] ([Servername], [Log_Date], [AGname], [State])
SELECT
@Servername,
GETDATE(),
''HADR IS NOT ENABLED ON THIS SERVER OR YOU HAVE NO AVAILABILITY GROUPS'',
''N/A''

END
END;'

EXEC(@SQLStatement);



DECLARE @DataDriveWhereClause VARCHAR(255)
DECLARE @LogDriveWhereClause VARCHAR(255)  	

DECLARE @DataDriveLength INT = LEN(REPLACE(@DataDrive,',',''))
DECLARE @RemainingDataWhereClause VARCHAR(MAX) 

  IF @DataDriveLength > 1 
  BEGIN 
	IF @Compatibility = 0 
		BEGIN
			SET @RemainingDataWhereClause = (SELECT ' OR physical_name LIKE '''+[StringElement]+'%''' FROM master.dbo.fn_SplitString(RIGHT(@DataDrive,LEN(@DataDrive)-2),',') RemainingWhereClause FOR XML PATH(''))
		END
			IF @Compatibility = 1
			BEGIN
				SET @RemainingDataWhereClause= (SELECT ' OR physical_name LIKE '''+[value]+'%''' FROM STRING_SPLIT(RIGHT(@DataDrive,LEN(@DataDrive)-2),',') RemainingWhereClause FOR XML PATH(''))
			END

  SET @DataDriveWhereClause =  ''+REPLICATE('(',@DataDriveLength) --Total clauses required
  +'physical_name LIKE '''+SUBSTRING(@DataDrive,1,1)+'%''' 
  + @RemainingDataWhereClause +REPLICATE(')',@DataDriveLength-1) + ' AND physical_name LIKE ''%.ldf'') OR '
  END
  ELSE
  BEGIN
  SET @DataDriveWhereClause = '(physical_name LIKE '''+@DataDrive+'%'' AND physical_name LIKE ''%.ldf'') OR '
  END

DECLARE @LogDriveLength INT = LEN(REPLACE(@LogDrive,',',''))
DECLARE @RemainingLogWhereClause VARCHAR(MAX)

  IF @LogDriveLength > 1 
  BEGIN 
  	IF @Compatibility = 0 
		BEGIN
			SET @RemainingLogWhereClause = (SELECT ' OR physical_name LIKE '''+[StringElement]+'%''' FROM master.dbo.fn_SplitString(RIGHT(@LogDrive,LEN(@DataDrive)-2),',') RemainingWhereClause FOR XML PATH(''))
		END
			IF @Compatibility = 1
			BEGIN
				SET @RemainingLogWhereClause= (SELECT ' OR physical_name LIKE '''+[value]+'%''' FROM STRING_SPLIT(RIGHT(@LogDrive,LEN(@LogDrive)-2),',') RemainingWhereClause FOR XML PATH(''))
			END
							    
  SET @LogDriveWhereClause = ''+REPLICATE('(',@LogDriveLength) --Total clauses required
  +'physical_name LIKE '''+SUBSTRING(@LogDrive,1,1)+'%''' 
  + @RemainingLogWhereClause +REPLICATE(')',@LogDriveLength-1) + ' AND physical_name LIKE ''%.mdf'')'
  END
  ELSE
  BEGIN
  SET @LogDriveWhereClause = '(physical_name LIKE '''+@LogDrive+'%'' AND physical_name LIKE ''%.mdf'')'
  END




SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[DatabaseFilesInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFiles]
WHERE Servername = @Servername;

INSERT INTO  '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFiles] (Servername,Log_Date,Databasename,FileType,FilePath)
SELECT
@Servername,
GETDATE(),
DB_NAME(database_id),
type_desc,
physical_name 
FROM sys.master_files
WHERE 
'+ @DataDriveWhereClause + '
'
+@LogDriveWhereClause +
 '
ORDER BY DB_NAME(Database_ID) ASC

IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFiles]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFiles] (Servername,Log_Date,Databasename,FileType,FilePath)
			VALUES(@Servername,GETDATE(),''No Database File issues present'',NULL,NULL)
			END
			
END;'


EXEC(@SQLStatement);



SET @SQLStatement =  
'CREATE PROCEDURE [Inspector].[DatabaseStatesInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseStates]
WHERE Servername = @Servername;

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseStates] (Servername,Log_Date,DatabaseState,Total,DatabaseNames)
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

END;'

EXEC(@SQLStatement);


SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[DriveSpaceInsert] 
AS
BEGIN

--Revision date: 28/06/2018

DECLARE @Retention INT = (SELECT Value From '+@LinkedServername+'['+@Databasename+'].[Inspector].[Settings] Where Description = ''DriveSpaceRetentionPeriodInDays'')

DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DriveSpace] 
WHERE Log_Date < DATEADD(DAY,-@Retention,DATEADD(DAY,1,CAST(GETDATE() AS DATE)))
AND Servername = @@SERVERNAME;


IF NOT EXISTS (SELECT Log_Date FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DriveSpace] WHERE Servername = @@SERVERNAME AND CAST(Log_Date AS DATE) = CAST(GETDATE() AS DATE))
	BEGIN
		--RECORD THE DRIVE SPACE CAPACITY AND AVAILABLE SPACE PER DAY
		INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DriveSpace] (Servername, Log_Date, Drive, Capacity_GB, AvailableSpace_GB)
		SELECT DISTINCT
		@@SERVERNAME,
		GETDATE(),
		UPPER(volumestats.volume_mount_point) AS Drive,
		CAST((CAST(volumestats.total_bytes AS DECIMAL(20,2)))/1024/1024/1024 AS DECIMAL(10,2)) Capacity_GB,
		CAST((CAST(volumestats.available_bytes AS DECIMAL(20,2)))/1024/1024/1024 AS DECIMAL(10,2)) AS AvailableSpace_GB
		FROM sys.master_files masterfiles
		CROSS APPLY sys.dm_os_volume_stats(masterfiles.database_id, file_id) volumestats
	END

END'


EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PopulateModuleWarningLevel] 
AS 
BEGIN

--Revision date: 08/03/2019

/*
These modules are excluded from warning level control:
BackupsCheck
DriveSpace
TopFiveDatabases
DatabaseGrowthCheck
BackupSizesCheck
*/

	INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[ModuleWarningLevel] ([ModuleConfig_Desc],[Module])
	SELECT [ModuleConfig_Desc],[Module]
	FROM 
	(
	    SELECT	
		ModuleConfig_Desc,						
	    AGCheck,													
	    DatabaseFileCheck,	
	    DatabaseOwnershipCheck,
	    DatabaseStatesCheck,	
	    FailedAgentJobCheck,		
	    JobOwnerCheck,
	    FailedLoginsCheck,	
	    ADHocDatabaseCreationCheck,
	    DatabaseSettings,
	    ServerSettings,
	    SuspectPages,
	    AGDatabases,
	    LongRunningTransactions,
		UnusedLogshipConfig
	    FROM [Inspector].[Modules]
	) Modules
	UNPIVOT
	(ModuleConfig_Desc2 FOR Module IN 
	(AGCheck								
	,DatabaseFileCheck	
	,DatabaseOwnershipCheck
	,DatabaseStatesCheck	
	,FailedAgentJobCheck	
	,JobOwnerCheck
	,FailedLoginsCheck
	,ADHocDatabaseCreationCheck
	,DatabaseSettings
	,ServerSettings
	,SuspectPages
	,AGDatabases
	,LongRunningTransactions
	,UnusedLogshipConfig)
	) AS [ModulesList]
	WHERE NOT EXISTS (SELECT 1 
					FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[ModuleWarningLevel] 
					WHERE [ModulesList].[ModuleConfig_Desc] = [ModuleWarningLevel].[ModuleConfig_Desc]
					AND CAST([ModulesList].[Module] AS VARCHAR(50)) = [ModuleWarningLevel].[Module]
					)
   UNION ALL 
   SELECT 
   [Modules].[ModuleConfig_Desc],
   [CatalogueModulesList].[Module]
   FROM [Inspector].[Modules]
   CROSS JOIN (SELECT [Module] FROM (VALUES(''CatalogueMissingLogins'')) ModuleList(Module)) AS CatalogueModulesList
   WHERE NOT EXISTS (SELECT 1 
					FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[ModuleWarningLevel] 
					WHERE [ModuleConfig_Desc] = [Modules].[ModuleConfig_Desc] 
					AND [Module] = [CatalogueModulesList].[Module]);

END'

EXEC(@SQLStatement);

--Run Proc for the first time to populate the Warning Level table
EXEC [Inspector].[PopulateModuleWarningLevel];

SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[FailedAgentJobsInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[FailedAgentJobs]
WHERE Servername = @Servername;

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[FailedAgentJobs] (Servername,Log_Date,Jobname,LastStepFailed,LastFailedDate,LastError)
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
			FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[FailedAgentJobs]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[FailedAgentJobs] (Servername,Log_Date,Jobname,LastStepFailed,LastFailedDate,LastError)
			VALUES(@Servername,GETDATE(),''No Failed Jobs present'',NULL,NULL,NULL)
			END

END;'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[LoginAttemptsInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[LoginAttempts]
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

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[LoginAttempts] (Servername,Log_Date,Username,Attempts,LastErrorDate,LastError)
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
			FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[LoginAttempts]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[LoginAttempts] (Servername,Log_Date,Username,Attempts,LastErrorDate,LastError)
			VALUES(@Servername,GETDATE(),''No Failed Logins present'',NULL,NULL,NULL)
			END

END;'


EXEC(@SQLStatement);


SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[JobOwnerInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME
DECLARE @AgentjobOwnerExclusions VARCHAR(255) = (SELECT REPLACE([Value],'' '','''') FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[Settings] WHERE [Description] = ''AgentJobOwnerExclusions'')

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[JobOwner]
WHERE Servername = @Servername;

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[JobOwner] (Servername,Log_Date,Job_ID,Jobname)
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
			FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[JobOwner]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[JobOwner] (Servername,Log_Date,Job_ID,Jobname)
			VALUES(@Servername,GETDATE(),NULL,''No Job Owner issues present'')
			END

END;'


EXEC(@SQLStatement);


SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[TopFiveDatabasesInsert]
AS
BEGIN

--Revision date: 28/06/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[TopFiveDatabases]
WHERE Servername = @Servername;

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[TopFiveDatabases] (Servername,Log_Date,Databasename,TotalSize_MB)
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

END ;'

EXEC(@SQLStatement);


SET @SQLStatement =  CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[BackupsCheckInsert]
AS
BEGIN

--Revision date: 11/09/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @FullBackupThreshold INT = (Select [Value] FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[Settings] WHERE Description = ''FullBackupThreshold'')

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[BackupsCheck]
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

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[BackupsCheck] ([Servername],[Log_Date],[Databasename],[AGname],[FULL],[DIFF],[LOG],[IsFullRecovery],[IsSystemDB],[primary_replica],[backup_preference])
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

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[BackupsCheck] ([Servername],[Log_Date],[Databasename],[AGname],[FULL],[DIFF],[LOG],[IsFullRecovery],[IsSystemDB],[primary_replica],[backup_preference])  
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

			
END;'

EXEC(@SQLStatement);

SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[DatabaseGrowthsInsert]
AS

--Revision date: 28/09/2018

     SET NOCOUNT ON;

     BEGIN

        DECLARE @Servername NVARCHAR(128)= @@Servername;
	    DECLARE @LastUpdated DATETIME = GETDATE();
		DECLARE @Retention INT = (SELECT ISNULL(NULLIF([Value],''''),30) From '+@LinkedServername+'['+@Databasename+'].[Inspector].[Settings] Where Description = ''DriveSpaceRetentionPeriodInDays'');
		DECLARE @ScopeIdentity INT

--Insert any databases that are present on the serverbut not present in [Inspector].[DatabaseFileSizes]
         IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
             BEGIN
                 INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes]
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
                           RIGHT([Masterfiles].[physical_name],CHARINDEX(''\'',REVERSE([Masterfiles].[physical_name]))-1) AS [Filename], --Get the Filename
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
                       AND [type_desc] = ''ROWS''
                       AND NOT EXISTS
                 (
                     SELECT [Database_id]
                     FROM   '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [DatabaseFileSizes]
                     WHERE  [Servername] = @Servername
                            AND DB_NAME([Masterfiles].[database_id]) = [DatabaseFileSizes].[Database_name]
                            AND [Masterfiles].[file_id] = [DatabaseFileSizes].[File_id]
                 )
                 ORDER BY DB_NAME([Masterfiles].[database_id]) ASC,
                          [type] ASC;
         END
             ELSE
             BEGIN
                 INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes]
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
                        RIGHT([Masterfiles].[physical_name],CHARINDEX(''\'',REVERSE([Masterfiles].[physical_name]))-1) AS [Filename], 
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
                        AND [type_desc] = ''ROWS''
                        AND NOT EXISTS
                 (
                     SELECT [Database_id]
                     FROM   '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [DatabaseFileSizes]
                     WHERE  [Servername] = @Servername
                            AND DB_NAME([Masterfiles].[database_id]) = [DatabaseFileSizes].[Database_name]
                            AND [Masterfiles].[file_id] = [DatabaseFileSizes].[File_id]
                 )
                 ORDER BY DB_NAME([Masterfiles].[database_id]) ASC,
                          [type] ASC;
         END

--Remove any databases that have been dropped from SQL but still present in [Inspector].[DatabaseFileSizes]
         DELETE [Sizes]
         FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes]
              LEFT JOIN [sys].[databases] [DatabasesList] ON [Sizes].[Database_name] = [DatabasesList].[name] COLLATE DATABASE_DEFAULT
         WHERE  [Sizes].[Servername] = @Servername
                AND [DatabasesList].[database_id] IS NULL;

--Ensure that the Database_Id column is synced in the base table as a database may have been dropped and restored as a new Database_id
         UPDATE [Sizes]
         SET
            [Database_id] = [DatabasesList].[database_id],
			[LastUpdated] = @LastUpdated
         FROM   '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes]
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
                    AND [type_desc] = ''ROWS''
                    AND [DatabasesList].state = 0
         ) [GrowthCheck]
         INNER JOIN '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes] ON [GrowthCheck].[database_id] = [Sizes].[Database_id]
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
                    AND [type_desc] = ''ROWS''
                    AND [DatabasesList].state = 0
         ) [ShrunkDatabases]
         INNER JOIN '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes] ON [ShrunkDatabases].[database_id] = [Sizes].[Database_id]
                                                                                      AND [Sizes].[File_id] = [ShrunkDatabases].[file_id]
         WHERE [ShrunkDatabases].[size] < [PostGrowthSize_MB]
         AND [Servername] = @Servername;


--Log the Database Growth event, using sp_executesql to ensure that SCOPE_IDENTITY() works if using linked server
		INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizeHistory]
         ([Servername],
          [Database_id],
          [Database_name],
          [Log_Date],
          [Type_Desc],
          [File_id],
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
                RIGHT([Masterfiles].[physical_name],CHARINDEX(''\'',REVERSE([Masterfiles].[physical_name]))-1) AS [Filename], --Get the Filename
                [DatabaseFileSizes].[PostGrowthSize_MB],  --PostGrowth size is the Last recorded database size after a growth event
                [DatabaseFileSizes].[GrowthRate],
                (((CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024 - [DatabaseFileSizes].[PostGrowthSize_MB]) / [DatabaseFileSizes].[GrowthRate]) AS [TotalGrowthIncrements],  --IF Growth is in Percent then this will be calculated based on the Current DB size Less Originally logged size , Divided by the Growth percentage based on the original database size
                (CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024 AS [CurrentSize_MB] --Next approx Growth interval in MB
         FROM   '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [DatabaseFileSizes]
                INNER JOIN [sys].[master_files] [Masterfiles] ON [Masterfiles].[database_id] = [DatabaseFileSizes].[Database_id]
                                                                 AND [DatabaseFileSizes].[File_id] = [Masterfiles].[file_id]
         WHERE  [NextGrowth] <= (CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024
                AND [DatabaseFileSizes].[Servername] = @Servername
			 AND NOT EXISTS (
						  SELECT GrowthID
						  FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizeHistory] ExistingRecord
						  WHERE [Servername] = @Servername 
						  AND DB_NAME([Masterfiles].[database_id]) = [Database_name]
						  AND CAST([Log_Date] AS DATE) = CAST(GETDATE() AS DATE)
						  ); --Ensure that there has not been any growths logged for today before recording as this will affect thresholds. 
						     --(this allows the collection to be ran without worrying that the growths will be logged prematurely);
		
		'+CASE WHEN @LinkedServernameParam IS NULL THEN 'SELECT @ScopeIdentity = SCOPE_IDENTITY();'
		ELSE 'SELECT @ScopeIdentity = MAX(GrowthID) FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizeHistory] WHERE Servername = @Servername AND Log_Date = @LastUpdated;' END +'
		


IF (@ScopeIdentity IS NOT NULL) --IF Growths have just been inserted
BEGIN
--Double check the databases sizes in the base table are correct and update as required
         UPDATE [Sizes]
         SET    [PostGrowthSize_MB] = (CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024,
			 [LastUpdated] = @LastUpdated
         FROM   [sys].[master_files] [Masterfiles]
                INNER JOIN '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes] ON [Masterfiles].[database_id] = [Sizes].[Database_id]
                                                                                             AND [Sizes].[File_id] = [Masterfiles].[file_id]
         WHERE  [Masterfiles].[database_id] > 3
                AND ((CAST([Masterfiles].[size] AS BIGINT) * 8) / 1024 != [Sizes].[PostGrowthSize_MB])
                AND [Servername] = @Servername; 

--Set Next growth size for all Databases on this server which have grown
         UPDATE '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizes]
         SET    [NextGrowth] = ([PostGrowthSize_MB] + [GrowthRate]),
			 [LastUpdated] = @LastUpdated
         WHERE  [NextGrowth] <= [PostGrowthSize_MB]
                AND [Servername] = @Servername;
END

--Clean up the history for growths older than @Retention in days
         DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseFileSizeHistory]
         WHERE [Log_Date] < DATEADD(DAY,-@Retention,GETDATE())
         AND [Servername] = @Servername;

     END;'

EXEC(@SQLStatement);



SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[DatabaseOwnershipInsert]
AS
BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @DatabaseOwnerExclusions NVARCHAR(255) = (SELECT REPLACE(Value,'' '','''') from '+@LinkedServername+'['+@Databasename+'].Inspector.Settings WHERE Description = ''DatabaseOwnerExclusions'');

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseOwnership]
WHERE Servername = @Servername;

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 
INSERT INTO '+@LinkedServername+'['+@Databasename+'].Inspector.DatabaseOwnership ([Servername],[Log_Date],[AGname],[Database_name],[Owner])
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
INSERT INTO '+@LinkedServername+'['+@Databasename+'].Inspector.DatabaseOwnership ([Servername],[Log_Date],[AGname],[Database_name],[Owner])
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
			FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseOwnership]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseOwnership] ([Servername],[Log_Date],[AGname],[Database_name],[Owner])
			VALUES(@Servername,GETDATE(),NULL,''No Database Ownership issues present'',NULL)
			END
			
END;'

EXEC(@SQLStatement);


SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[BackupSizesByDayInsert]
AS
BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[BackupSizesByDay]
WHERE Servername = @@Servername;

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[BackupSizesByDay] ([Servername],[Log_Date],[DayOfWeek],[CastedDate],[TotalSizeInBytes])
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
			FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[BackupSizesByDay]
			WHERE Servername = @Servername)
			BEGIN 
			INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[BackupSizesByDay] ([Servername],[Log_Date],[DayOfWeek],[CastedDate],[TotalSizeInBytes])
			VALUES(@Servername,NULL,NULL,NULL,NULL)
			END

END;'


EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[DatabaseSettingsInsert]

AS

BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings]
WHERE Servername = @Servername

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''Collation_name'',
ISNULL(collation_name,''None'')   ,
COUNT(collation_name)  
FROM sys.databases
GROUP BY collation_name


INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_close_on'',
CASE is_auto_close_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
COUNT(is_auto_close_on)  
FROM sys.databases
GROUP BY is_auto_close_on


INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_shrink_on'',
CASE is_auto_shrink_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
COUNT(is_auto_shrink_on)  
FROM sys.databases
GROUP BY is_auto_shrink_on


INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_update_stats_on'',
CASE is_auto_update_stats_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
COUNT(is_auto_update_stats_on)  
FROM sys.databases
GROUP BY is_auto_update_stats_on


INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_read_only'',
CASE is_read_only WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
COUNT(is_read_only)  
FROM sys.databases
GROUP BY is_read_only

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''user_access_desc'', 
user_access_desc, 
COUNT(user_access_desc)  
FROM sys.databases
GROUP BY user_access_desc

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''compatibility_level'',
[compatibility_level],
COUNT([compatibility_level])  
FROM sys.databases
GROUP BY [compatibility_level]


INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''recovery_model_desc'',
recovery_model_desc,
COUNT(recovery_model_desc)  
FROM sys.databases
GROUP BY recovery_model_desc

END;'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[ServerSettingsInsert]

AS

BEGIN

--Revision date: 28/06/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[ServerSettings]
WHERE Servername = @Servername

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[ServerSettings] ([Servername],[Log_Date],[configuration_id],[Setting],[value_in_use])
SELECT 
@Servername,
@LogDate,
[configuration_id],
CAST([name] AS NVARCHAR(128)), 
CAST([value_in_use] AS INT)
FROM sys.configurations
WHERE name IN (''max server memory (MB)'',''cost threshold for parallelism'',''max degree of parallelism'',''optimize for ad hoc workloads'',''automatic soft-NUMA disabled'',''xp_cmdshell'',''Agent XPs'',''Database Mail XPs'',''backup compression default'',''backup checksum default'')
ORDER BY 
[configuration_id] ASC,
[name] ASC



END;'

EXEC(@SQLStatement);

SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[InstanceStartInsert]

AS

BEGIN

--Revision date: 02/07/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[InstanceStart]
WHERE Servername = @Servername

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[InstanceStart] ([Servername],[Log_Date],[InstanceStart])
SELECT 
@Servername,
@LogDate,
[create_date]
FROM sys.databases
WHERE name = ''tempdb''

END;'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[InstanceVersionInsert]

AS

BEGIN

--Revision date: 14/02/2019

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;
DECLARE @PhysicalServername NVARCHAR(128) = CAST(SERVERPROPERTY(''ComputerNamePhysicalNetBIOS'') AS NVARCHAR(128));
DECLARE @Version NVARCHAR(20) =  CAST(SERVERPROPERTY(''ProductVersion'') AS NVARCHAR(20));
DECLARE @Edition NVARCHAR(50) = CAST(SERVERPROPERTY(''Edition'') AS NVARCHAR(50));

--Check for version and/or edition change
IF EXISTS(SELECT 1 FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[InstanceVersion] WHERE Servername = @Servername)
BEGIN 
	--If the major version has changed we only want to advise of that change, if the major version has not changed 
	--then check for a minor version change and advise of the change.

	INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[InstanceVersionHistory] ([Servername], [Log_Date], [CollectionDatetime], [VersionNo], [Edition])
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
			FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[InstanceVersion]
			WHERE Servername = @Servername
		) AS LastLoggedVersionInfo
	) AS VersionCheck
	WHERE ([VersionNo] IS NOT NULL OR [Edition] IS NOT NULL)
	AND NOT EXISTS (SELECT 1 
					FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[InstanceVersionHistory] 
					WHERE Servername = @Servername 
					AND CAST(VersionCheck.[Log_Date] AS DATE) = CAST([InstanceVersionHistory].[Log_Date] AS DATE) 
					AND ([VersionNo] = [VersionCheck].[VersionNo] OR [Edition] = [VersionCheck].[Edition]))

END 

DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[InstanceVersion]
WHERE Servername = @Servername;

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[InstanceVersion] ([Servername], [PhysicalServername], [Log_Date], [VersionInfo])
SELECT @Servername, @PhysicalServername, GETDATE(), @Version + N'' - '' + @Edition
END;
'
EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[SuspectPagesInsert]

AS

BEGIN

--Revision date: 30/07/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[SuspectPages]
WHERE Servername = @Servername

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[SuspectPages] ([Servername],[Log_Date],[Databasename],[file_id],[page_id],[event_type],[error_count],[last_update_date])
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

IF NOT EXISTS (SELECT Servername FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[SuspectPages] WHERE Servername = @Servername)
BEGIN 
	INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[SuspectPages] ([Servername],[Log_Date],[Databasename],[file_id],[page_id],[event_type],[error_count],[last_update_date])
	VALUES(@Servername,GETDATE(),NULL,NULL,NULL,NULL,NULL,NULL)
END


END;'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[AGDatabasesInsert]
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
DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[AGDatabases] 
WHERE AGDatabases.Servername = @Servername
AND (EXISTS (SELECT 1 FROM sys.databases DBs WHERE AGDatabases.Databasename = DBs.name COLLATE DATABASE_DEFAULT AND AGDatabases.Servername = @Servername AND state != 0)
OR NOT EXISTS (SELECT 1 FROM sys.databases DBs WHERE AGDatabases.Databasename = DBs.name COLLATE DATABASE_DEFAULT AND AGDatabases.Servername = @Servername));

--INSERT databases missing from the table and assume they should be joined to an AG.
INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[AGDatabases] ([Servername], [Log_Date], [LastUpdated], [Databasename], [Is_AG], [Is_AGJoined])
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
AND NOT EXISTS (SELECT 1 FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[AGDatabases] WHERE Databasename = DBs.name COLLATE DATABASE_DEFAULT AND Servername = @Servername);


--Update Is_AGJoined 
UPDATE DBs
SET 
[Is_AGJoined] = CASE WHEN [AGReplicas].[replica_server_name] IS NULL THEN 0 ELSE 1 END, 
[LastUpdated] = GETDATE()
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[AGDatabases] DBs
LEFT JOIN (SELECT JoinedDBs.group_id,database_name
		   FROM sys.availability_databases_cluster JoinedDBs 
		   WHERE EXISTS (SELECT 1 FROM sys.availability_groups Groups WHERE JoinedDBs.group_id = Groups.group_id)
		   ) AS AGDBs ON DBs.Databasename COLLATE DATABASE_DEFAULT = AGDBs.database_name
LEFT JOIN sys.availability_replicas AGReplicas ON AGDBs.group_id = AGReplicas.group_id AND AGReplicas.replica_server_name = @Servername
WHERE DBs.Servername = @Servername;
	

END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[LongRunningTransactionsInsert]
AS

BEGIN

--Revision date: 08/08/2018

SET NOCOUNT ON;

DECLARE @TransactionDurationThreshold INT = (SELECT CAST([Value] AS INT) FROM [Inspector].[Settings] WHERE [Description] = ''LongRunningTransactionThreshold'');
DECLARE @Now DATETIME = GETDATE();
DECLARE @Servername NVARCHAR(128) = @@SERVERNAME;

DELETE FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[LongRunningTransactions]
WHERE Servername = @Servername;

--Set a default value of 300 (5 Mins) if NULL
IF @TransactionDurationThreshold IS NULL 
BEGIN 
	SET @TransactionDurationThreshold = 300;
END

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[LongRunningTransactions] ([Servername], [Log_Date], [session_id], [transaction_begin_time], [Duration_DDHHMMSS], [TransactionState], [SessionState], [login_name], [host_name], [program_name], [Databasename])
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
FROM sys.dm_tran_session_transactions SessionTrans
JOIN sys.dm_tran_active_transactions ActiveTrans ON SessionTrans.transaction_id = ActiveTrans.transaction_id
JOIN sys.dm_exec_sessions Sessions ON Sessions.session_id = SessionTrans.session_id
JOIN sys.dm_exec_connections Connections ON Connections.session_id = Sessions.session_id
WHERE ActiveTrans.transaction_begin_time <= DATEADD(SECOND,-@TransactionDurationThreshold,@Now)
ORDER BY ActiveTrans.transaction_begin_time ASC;

IF NOT EXISTS (SELECT 1 FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[LongRunningTransactions] WHERE Servername = @Servername)
BEGIN 
	INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[LongRunningTransactions] ([Servername], [Log_Date], [session_id], [transaction_begin_time], [Duration_DDHHMMSS], [TransactionState], [SessionState], [login_name], [host_name], [program_name], [Databasename])
	VALUES(@Servername,@Now,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
END

END
'
EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[UnusedLogshipConfigInsert]
AS
BEGIN

--Revision date: 30/11/2018

SET NOCOUNT ON;

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[UnusedLogshipConfig]
WHERE Servername = @Servername;

INSERT INTO '+@LinkedServername+'['+@Databasename+'].[Inspector].[UnusedLogshipConfig] (Servername,Log_Date,Databasename,Databasestate)
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

END;
'
EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[ExecutionLogInsert]
(
@RunDatetime DATETIME,
@Servername NVARCHAR(128),
@ModuleConfigDesc VARCHAR(20),
@Procname NVARCHAR(128),
@Duration MONEY,
@PSCollection BIT
)
AS
BEGIN
	INSERT INTO [Inspector].[ExecutionLog] (ExecutionDate,Servername,ModuleConfig_Desc,Procname,Duration,PSCollection)
	VALUES(@RunDatetime,@Servername,@ModuleConfigDesc,@Procname,@Duration,@PSCollection);
END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[ResetHtmlColors]
AS
BEGIN 

	UPDATE [Inspector].[ModuleWarnings]
	SET 
	[HighlightHtmlColor] = CASE 
							WHEN [WarningLevel] IS NULL THEN NULL 
							WHEN [WarningLevel] = 1 THEN ''#F78181'' 
							WHEN [WarningLevel] = 2 THEN ''#FAFCA4''
							WHEN [WarningLevel] = 3 THEN ''#FEFFFF''
						   END,
	[GradientLeftHtmlColor] = CASE 
								WHEN [WarningLevel] IS NULL THEN NULL 
								WHEN [WarningLevel] IN (1,2,3) THEN ''#000000'' 
							 END,
	[GradientRightHtmlColor] = CASE 
								WHEN [WarningLevel] IS NULL THEN NULL 
								WHEN [WarningLevel] = 1 THEN ''#F78181'' 
								WHEN [WarningLevel] = 2 THEN ''#FAFCA4''
								WHEN [WarningLevel] = 3 THEN ''#FEFFFF''
							   END
END'	

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PSGetColumns]
(
@Tablename NVARCHAR(128)
)
AS
BEGIN
SET NOCOUNT ON;

--Revision date: 14/09/2018

SELECT CAST(STUFF(Columnname,1,1,'''') AS VARCHAR(4000)) AS Columnnames
FROM 
(
	SELECT '',''+QUOTENAME(columns.name) 
	FROM sys.tables
	INNER JOIN sys.columns ON tables.object_id = columns.object_id
	WHERE tables.name IN (SELECT Tablename FROM [Inspector].[PSInspectorTables] WHERE Tablename = @Tablename)
	ORDER BY tables.name ASC,columns.column_id ASC
	FOR XML PATH('''')
) AS ColumnList (Columnname)
END'

EXEC(@SQLStatement);

SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PSGetInspectorBuild]
AS
BEGIN 
--Revision date: 14/09/2018

	SELECT 
	@@SERVERNAME AS Servername,
	CAST([Value] AS DECIMAL(4,1)) AS Build
	FROM [Inspector].[Settings]
	WHERE [Description] = ''InspectorBuild''
END'

EXEC(@SQLStatement);

SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PSGetConfig]
(
@Servername NVARCHAR(128),
@ModuleConfig VARCHAR(20) = NULL
)
AS
BEGIN
--Revision date: 14/09/2018
--TableAction: 1 delete, 2 delete with retention, 3 Stage/merge
--InsertAction: 1 ALL, 2 Todays'' data only

DECLARE @DriveSpaceRetentionPeriodInDays VARCHAR(6) = (SELECT ISNULL(NULLIF([Value],''''),''90'') FROM [Inspector].[Settings] WHERE [Description] = ''DriveSpaceRetentionPeriodInDays'')

IF EXISTS (SELECT 1 FROM [Inspector].[CurrentServers] WHERE [Servername] = @Servername)
BEGIN
	SELECT 
	[ActiveServers].[Servername], 
	[ActiveServers].[ModuleConfig_Desc], 
	[PSEnabledModules].[Module], 
	[PSEnabledModules].[Module]+''Insert'' AS Procedurename,
	CASE
		WHEN [PSEnabledModules].[Module] = ''DatabaseGrowths''
		THEN ''DatabaseFileSizes,DatabaseFileSizeHistory''
		WHEN [PSEnabledModules].[Module] = ''ADHocDatabaseCreations''
		THEN ''ADHocDatabaseCreations,ADHocDatabaseSupression''
		ELSE [PSEnabledModules].[Module]
	END AS Tablename,
	CASE
		WHEN [PSEnabledModules].[Module] IN (''AGDatabases'',''DriveSpace'')
		THEN ''PS''+[PSEnabledModules].[Module]+''Stage''
		WHEN [PSEnabledModules].[Module] = ''ADHocDatabaseCreations''
		THEN ''PSADHocDatabaseCreationsStage,PSADHocDatabaseSupressionStage''
		WHEN [PSEnabledModules].[Module] = ''DatabaseGrowths''
		THEN ''PSDatabaseFileSizesStage,PSDatabaseFileSizeHistoryStage''
		ELSE NULL
	END AS StageTablename,
	CASE
		WHEN [PSEnabledModules].[Module] IN (''AGDatabases'', ''DriveSpace'', ''DatabaseGrowths'', ''ADHocDatabaseCreations'')
		THEN ''PSGet''+[PSEnabledModules].[Module]+''Stage''
		ELSE NULL
	END AS StageProcname,
	CASE
		WHEN [PSEnabledModules].[Module] IN (''AGDatabases'',''DriveSpace'')
		THEN ''3''
		WHEN [PSEnabledModules].[Module] IN (''ADHocDatabaseCreations'',''DatabaseGrowths'')
		THEN ''3,3''
		ELSE ''1''
	END AS TableAction, --1 delete, 2 delete with retention, 3 Stage/merge
	CASE
		WHEN [PSEnabledModules].[Module] IN (''AGDatabases'',''BackupSizesByDay'')
		THEN ''1''
		WHEN [PSEnabledModules].[Module] = ''ADHocDatabaseCreations''
		THEN ''1,1''
		WHEN [PSEnabledModules].[Module] = ''DatabaseGrowths''
		THEN ''1,2''
		ELSE ''2''
	END AS InsertAction, --1 ALL, 2 Todays'' data only
	CASE 
		WHEN [PSEnabledModules].[Module] = (''DatabaseGrowths'') THEN @DriveSpaceRetentionPeriodInDays+'',''+@DriveSpaceRetentionPeriodInDays
		WHEN [PSEnabledModules].[Module] = (''DriveSpace'') THEN @DriveSpaceRetentionPeriodInDays
		ELSE NULL 
	END AS RetentionInDays
FROM
(
	SELECT 
	[Servername], 
	COALESCE(@ModuleConfig,[ModuleConfig_Desc], ''Default'') AS [ModuleConfig_Desc]
	FROM [Inspector].[CurrentServers]
	WHERE Servername = @Servername
	AND IsActive = 1
) AS ActiveServers
INNER JOIN [Inspector].[PSEnabledModules] ON [ActiveServers].ModuleConfig_Desc = [PSEnabledModules].[ModuleConfig_Desc]
UNION ALL
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
NULL AS RetentionInDays
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
ORDER BY [PSEnabledModules].[Module] ASC;
END

END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PSGetServers]
AS 
BEGIN 
--Revision date: 14/09/2018

	SELECT 
	[Servername]
	FROM [Inspector].[CurrentServers]
	WHERE [IsActive] = 1
END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PSGetADHocDatabaseCreationsStage]
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


END'

EXEC(@SQLStatement);

SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PSGetAGDatabasesStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN 
--Revision date: 14/09/2018

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

--Update any changes (do not update Is_AG as this should be controlled via the table)
UPDATE AGDatabases
SET [Is_AG] = Stage.[Is_AG],
[Is_AGJoined] = Stage.[Is_AGJoined],
[LastUpdated] = GETDATE()
FROM [Inspector].[PSAGDatabasesStage] Stage
WHERE Stage.Servername = @Servername
AND EXISTS (SELECT 1 
				FROM [Inspector].[AGDatabases] Base
				WHERE Base.Servername = Stage.Servername
				AND Base.Databasename = Stage.Databasename
				AND Base.[Is_AGJoined] = Stage.[Is_AGJoined]
				);


END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+'
CREATE PROCEDURE [Inspector].[PSGetDriveSpaceStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN 

DECLARE @DriveSpaceRetentionPeriodInDays INT = (SELECT ISNULL(NULLIF(CAST([Value] AS INT),''''),90) FROM [Inspector].[Settings] WHERE [Description] = ''DriveSpaceRetentionPeriodInDays'')


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

END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PSGetDatabaseGrowthsStage]
(
@Servername NVARCHAR(128)
)
AS 
BEGIN
--Revision date: 14/09/2018

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
AND (PSStage.LastUpdated > Base.LastUpdated OR PSStage.LastUpdated IS NOT NULL AND Base.LastUpdated IS NULL)

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
INSERT INTO [Inspector].[DatabaseFileSizeHistory] ([Servername], [Database_id], [Database_name], [Log_Date], [Type_Desc], [File_id], [FileName], [PreGrowthSize_MB], [GrowthRate_MB], [GrowthIncrements], [PostGrowthSize_MB])
SELECT [Servername], [Database_id], [Database_name], [Log_Date], [Type_Desc], [File_id], [FileName], [PreGrowthSize_MB], [GrowthRate_MB], [GrowthIncrements], [PostGrowthSize_MB]
FROM [Inspector].[PSDatabaseFileSizeHistoryStage] PSStage
WHERE NOT EXISTS (SELECT 1 
				FROM [DatabaseFileSizeHistory] Base 
				WHERE PSStage.Database_id = Base.Database_id 
				AND PSStage.[File_id] = Base.[File_id]
				AND Base.Servername = @Servername 
				AND PSStage.Log_Date = Base.Log_Date)

END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[PSGetInstanceVersionHistoryStage]
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

END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+'
CREATE PROCEDURE [Inspector].[PSGetSettingsTables]
(
@SortOrder BIT, --0 FOR ORDER BY TableOrder ASC , 1 FOR ORDER BY TableOrder DESC
@PSCollection BIT = 0 --If its a powershell collection ensure that the WarningLevel table is populated
)
AS 
--Revision date: 17/12/2018

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
		FROM (VALUES(1,''Settings'',0,0),(2,''CurrentServers'',0,0), (3,''EmailRecipients'',0,0), (4,''EmailConfig'',0,0),(5,''CatalogueModules'',0,0), (6,''Modules'',0,1),(7,''ModuleWarningLevel'',0,0)) SettingsTables(TableOrder,Tablename,TruncateTable,ReseedTable)
		ORDER BY TableOrder ASC;
	END

	IF @SortOrder = 1 
	BEGIN 
		SELECT Tablename,TruncateTable,ReseedTable 
		FROM (VALUES(1,''Settings'',0,0),(2,''CurrentServers'',0,0), (3,''EmailRecipients'',0,0), (4,''EmailConfig'',0,0),(5,''CatalogueModules'',0,0), (6,''Modules'',0,1),(7,''ModuleWarningLevel'',0,0)) SettingsTables(TableOrder,Tablename,TruncateTable,ReseedTable)
		ORDER BY TableOrder DESC;
	END

END'

EXEC(@SQLStatement);

--Catalogue reporting procs
SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[CatalogueMissingLogins]
(
@Servername NVARCHAR(128),
@TableHeaderColour VARCHAR(7) = NULL,
@WarningLevelFontColour VARCHAR(7) = NULL,
@HtmlOutput VARCHAR(MAX) OUTPUT
)
AS
--Revision date: 08/03/2019
BEGIN

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


END'

EXEC(@SQLStatement);


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[InspectorDataCollection]
(
@ModuleConfig VARCHAR(20)  = NULL,
@PSCollection BIT = 0
)
AS 
BEGIN 

--Revision date: 17/02/2019

SET NOCOUNT ON;

DECLARE @AGCheck	BIT
DECLARE @BackupsCheck	BIT
DECLARE @BackupSizesCheck	BIT
DECLARE @DatabaseGrowthCheck	BIT
DECLARE @DatabaseFileCheck	BIT
DECLARE @DatabaseOwnershipCheck	BIT
DECLARE @DatabaseStatesCheck	BIT
DECLARE @DriveSpaceCheck	BIT
DECLARE @FailedAgentJobCheck	BIT
DECLARE @JobOwnerCheck	BIT
DECLARE @FailedLoginsCheck	BIT
DECLARE @TopFiveDatabaseSizeCheck	BIT
DECLARE @ADHocDatabaseCreationCheck	BIT
DECLARE @DatabaseSettings	BIT
DECLARE @ServerSettings	BIT
DECLARE @SuspectPages	BIT
DECLARE @AGDatabases	BIT
DECLARE @LongRunningTransactions BIT
DECLARE @UnusedLogshipConfig BIT
DECLARE @Servername NVARCHAR(128) = @@SERVERNAME
DECLARE @CollectionStart DATETIME
DECLARE @Duration MONEY
DECLARE @LastTruncate DATE

    IF EXISTS (SELECT ModuleConfig_Desc FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[Modules] WHERE ModuleConfig_Desc = @ModuleConfig) OR @ModuleConfig IS NULL 
    BEGIN
		--Truncate the ExecutionLog daily
		SELECT @LastTruncate = (SELECT TOP 1 CAST([ExecutionDate] AS DATE) FROM [Inspector].[ExecutionLog] ORDER BY [ID] DESC)
 
		--If the most recent log is from yesterday then Truncate the log.
		IF (@LastTruncate < CAST(GETDATE() AS DATE))
		BEGIN 
			TRUNCATE TABLE [Inspector].[ExecutionLog];
		END
		
	   --If @ModuleConfig IS NULL check if specific server has a Moduleconfig set against it and set @ModuleConfig accordingly, if none found then set ''Default''
	   IF @ModuleConfig IS NULL  
	   BEGIN
		  SELECT @ModuleConfig = ISNULL(ModuleConfig_Desc,''Default'')
		  FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[CurrentServers]
		  WHERE IsActive = 1 
		  AND Servername = @Servername;
	   END
	   
	   
	   --Get enabled module list for @ModuleConfig
	   SELECT 							
	   @AGCheck  = ISNULL(AGCheck,0),					
	   @BackupsCheck = ISNULL(BackupsCheck,0),					
	   @BackupSizesCheck = ISNULL(BackupSizesCheck,0),			
	   @DatabaseGrowthCheck	 = ISNULL(DatabaseGrowthCheck,0),			
	   @DatabaseFileCheck	 = ISNULL(DatabaseFileCheck,0),			
	   @DatabaseOwnershipCheck	= ISNULL(DatabaseOwnershipCheck,0),		
	   @DatabaseStatesCheck	 = ISNULL(DatabaseStatesCheck,0),			
	   @DriveSpaceCheck  = ISNULL(DriveSpaceCheck,0),				
	   @FailedAgentJobCheck	 = ISNULL(FailedAgentJobCheck,0),			
	   @JobOwnerCheck	  = ISNULL(JobOwnerCheck,0),				
	   @FailedLoginsCheck	 = ISNULL(FailedLoginsCheck,0),			
	   @TopFiveDatabaseSizeCheck	= ISNULL(TopFiveDatabaseSizeCheck,0),		
	   @ADHocDatabaseCreationCheck   = ISNULL(ADHocDatabaseCreationCheck,0),	
	   @DatabaseSettings = ISNULL(DatabaseSettings,0),
	   @ServerSettings = ISNULL(ServerSettings,0),
	   @SuspectPages	= ISNULL(SuspectPages,0),
	   @AGDatabases	= ISNULL(AGDatabases,0),
	   @LongRunningTransactions	= ISNULL(LongRunningTransactions,0),
	   @UnusedLogshipConfig	= ISNULL(UnusedLogshipConfig,0)
	   FROM '+@LinkedServername+'['+@Databasename+'].[Inspector].[Modules]
	   WHERE ModuleConfig_Desc = @ModuleConfig;
	   
	   
	   RAISERROR(''ModuleConfig selected for server: %s'',0,0,@ModuleConfig) WITH NOWAIT;

	   RAISERROR(''Checking for missing Warning level/module combinations'',0,0) WITH NOWAIT;
	   EXEC [Inspector].[PopulateModuleWarningLevel];

	   IF @AGCheck = 1 
	   BEGIN 
		  SET @CollectionStart = GETDATE();

		  RAISERROR(''Running [AGCheckInsert]'',0,0) WITH NOWAIT;
		  EXEC [Inspector].[AGCheckInsert];

		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''AGCheckInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;
	   END

	   IF @BackupsCheck = 1 
	   BEGIN
		  SET @CollectionStart = GETDATE();

		  RAISERROR(''Running [BackupsCheckInsert]'',0,0) WITH NOWAIT; 
	      EXEC [Inspector].[BackupsCheckInsert];

		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''BackupsCheckInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;
	   END

	   IF @BackupSizesCheck = 1 
	   BEGIN 
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [BackupSizesByDayInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[BackupSizesByDayInsert]; 		
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''BackupSizesByDayInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection; 
	   END

	   IF @DatabaseGrowthCheck = 1 
	   BEGIN
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [DatabaseGrowthsInsert]'',0,0) WITH NOWAIT; 
	      EXEC [Inspector].[DatabaseGrowthsInsert];		
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''DatabaseGrowthsInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;  
	   END

	   IF @DatabaseFileCheck = 1 
	   BEGIN
		SET @CollectionStart = GETDATE();
			    
	      RAISERROR(''Running [DatabaseFilesInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[DatabaseFilesInsert]; 

		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''DatabaseFilesInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;  
	   END

	   IF @DatabaseOwnershipCheck = 1 
	   BEGIN 
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [DatabaseOwnershipInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[DatabaseOwnershipInsert]; 	
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''DatabaseOwnershipInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection; 	 
	   END

	   IF @DatabaseStatesCheck = 1 
	   BEGIN 
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [DatabaseStatesInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[DatabaseStatesInsert]; 

		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''DatabaseStatesInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;	 
	   END

	   IF @DriveSpaceCheck = 1 
	   BEGIN 
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [DriveSpaceInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[DriveSpaceInsert]; 	
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''DriveSpaceInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection; 
	   END

	   IF @FailedAgentJobCheck = 1 
	   BEGIN 
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [FailedAgentJobsInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[FailedAgentJobsInsert]; 	
		 
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''FailedAgentJobsInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection; 
	   END

	   IF @JobOwnerCheck = 1 
	   BEGIN 
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [JobOwnerInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[JobOwnerInsert]; 		
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''JobOwnerInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;  
	   END

	   IF @FailedLoginsCheck = 1 
	   BEGIN 
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [LoginAttemptsInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[LoginAttemptsInsert]; 	
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''LoginAttemptsInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection; 
	   END

	   IF @TopFiveDatabaseSizeCheck = 1 
	   BEGIN
		SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [TopFiveDatabasesInsert]'',0,0) WITH NOWAIT; 
	      EXEC [Inspector].[TopFiveDatabasesInsert]; 		
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''TopFiveDatabasesInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;	 
	   END

	   IF @ADHocDatabaseCreationCheck = 1 
	   BEGIN
	 	SET @CollectionStart = GETDATE(); 

	      RAISERROR(''Running [ADHocDatabaseCreationsInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[ADHocDatabaseCreationsInsert]; 		 

		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''ADHocDatabaseCreationsInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;
	   END

	   IF @DatabaseSettings = 1 
	   BEGIN 
	 	SET @CollectionStart = GETDATE(); 

	      RAISERROR(''Running [DatabaseSettingsInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[DatabaseSettingsInsert]; 	 

		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''DatabaseSettingsInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;
	   END

	   IF @ServerSettings = 1 
	   BEGIN 
	 	SET @CollectionStart = GETDATE(); 

	      RAISERROR(''Running [ServerSettingsInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[ServerSettingsInsert]; 
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''ServerSettingsInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;	    
	   END

	   IF @SuspectPages = 1 
	   BEGIN 
	 	SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [SuspectPagesInsert]'',0,0) WITH NOWAIT;
	      EXEC [Inspector].[SuspectPagesInsert]; 	
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''SuspectPagesInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;  
	   END

	   IF @AGDatabases = 1 
	   BEGIN
	 	SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [AGDatabasesInsert]'',0,0) WITH NOWAIT; 
	      EXEC [Inspector].[AGDatabasesInsert]; 

		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''AGDatabasesInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;      
	   END

	   IF @LongRunningTransactions = 1 
	   BEGIN 
	 	SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [LongRunningTransactionsInsert]'',0,0) WITH NOWAIT;
		  EXEC [Inspector].[LongRunningTransactionsInsert];	
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''LongRunningTransactionsInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;
	   END

	   IF @UnusedLogshipConfig = 1
	   BEGIN 
	 	SET @CollectionStart = GETDATE();

	      RAISERROR(''Running [UnusedLogshipConfigInsert]'',0,0) WITH NOWAIT;
		  EXEC [Inspector].[UnusedLogshipConfigInsert];
		  
		  SET @Duration = CAST(DATEDIFF(MILLISECOND,@CollectionStart,GETDATE()) AS MONEY)/1000;

		  EXEC [Inspector].[ExecutionLogInsert] 
			@RunDatetime = @CollectionStart, 
			@Servername = @Servername, 
			@ModuleConfigDesc = @ModuleConfig,
			@Procname = N''UnusedLogshipConfigInsert'', 
			@Duration = @Duration,
			@PSCollection = @PSCollection;		
	   END

	   RAISERROR(''Running [InstanceStartInsert]'',0,0) WITH NOWAIT;
	   EXEC [Inspector].[InstanceStartInsert]; 	   

	   RAISERROR(''Running [InstanceVersionInsert]'',0,0) WITH NOWAIT;
	   EXEC [Inspector].[InstanceVersionInsert]; 	   

	   IF @PSCollection = 1 
	   BEGIN 
		RAISERROR(''Displaying executed modules list for Powershell collection'',0,0) WITH NOWAIT;
	   	EXEC [Inspector].[PSGetConfig] @Servername = @Servername, @ModuleConfig = @ModuleConfig; 
	   END

    END
    ELSE
    BEGIN
	   RAISERROR(''@ModuleConfig supplied: ''''%s'''' is not a valid module config description, for valid options query [Inspector].[Modules]'',11,0,@ModuleConfig);
    END

END'

EXEC(@SQLStatement);


--Create Main Inspector Report Stored Procedure
SET @SQLStatement = ''

SELECT @SQLStatement = @SQLStatement + CONVERT(VARCHAR(MAX), '')+ 
'/*********************************************
--Author: Adrian Buckman
--Revision date: 07/03/2019
--Description: SQLUnderCoverInspectorReport - Report and email from Central logging tables.
--V1.4


--Example Execute command
--EXEC [Inspector].[SQLUnderCoverInspectorReport] 
--@EmailDistributionGroup = ''DBA'',
--@TestMode = 0,
--@ModuleDesc = NULL,
--@EmailRedWarningsOnly = 0,
--@Theme = ''Dark''

*********************************************/
'
IF @LinkedServername = ''
BEGIN

SELECT @SQLStatement = @SQLStatement + CONVERT(VARCHAR(MAX), '')+ '
CREATE PROCEDURE [Inspector].[SQLUnderCoverInspectorReport] 
(
@EmailDistributionGroup VARCHAR(100),
@TestMode BIT = 0,
@ModuleDesc VARCHAR(20)	= NULL,
@EmailRedWarningsOnly BIT = 0,
@Theme VARCHAR(5) = ''Dark'',
@PSCollection BIT = 0,
@NoClutter BIT = 0
)
AS 
BEGIN
SET NOCOUNT ON;

IF EXISTS (SELECT name FROM sys.databases WHERE name = '''+@Databasename+''' AND state = 0)

'
END
ELSE
BEGIN
SELECT @SQLStatement = @SQLStatement + CONVERT(VARCHAR(MAX), '')+ '
CREATE PROCEDURE [Inspector].[SQLUnderCoverInspectorReport] 
(
@EmailDistributionGroup VARCHAR(100),
@TestMode BIT = 0,
@ModuleDesc VARCHAR(20)	= NULL,
@EmailRedWarningsOnly BIT = 0,
@Theme VARCHAR(5) = ''Dark'',
@PSCollection BIT = 0,
@NoClutter BIT = 0
)
AS 
BEGIN
SET NOCOUNT ON;

IF EXISTS (SELECT data_source FROM sys.servers 
WHERE name ='''+REPLACE(REPLACE(REPLACE(@LinkedServername,'[',''),']',''),'.','')+'''
AND data_source IN (
				SELECT Groups.name
				FROM sys.dm_hadr_availability_group_states States
				INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id
				WHERE primary_replica = @@Servername)
				)
OR @@SERVERNAME = (SELECT data_source FROM sys.servers 
WHERE name ='''+REPLACE(REPLACE(REPLACE(@LinkedServername,'[',''),']',''),'.','')+''')

'
END


SELECT @SQLStatement = @SQLStatement + CONVERT(VARCHAR(MAX), '') + '
BEGIN

IF EXISTS (SELECT [ID] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Modules] WHERE ModuleConfig_Desc = @ModuleDesc)
OR @ModuleDesc IS NULL
BEGIN

IF OBJECT_ID(''tempdb.dbo.#TrafficLightSummary'') IS NOT NULL
DROP TABLE #TrafficLightSummary;

CREATE TABLE #TrafficLightSummary
(
SummaryHeader VARCHAR(1000),
WarningPriority TINYINT
);

DECLARE @ModuleConfig VARCHAR(20) 
DECLARE @FreeSpaceRemainingPercent	INT = (SELECT ISNULL(CAST([Value] AS INT),10) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''FreeSpaceRemainingPercent'')
DECLARE @DaysUntilDriveFullThreshold	INT = (SELECT ISNULL(CAST([Value] AS INT),56) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DaysUntilDriveFullThreshold'')
DECLARE @FullBackupThreshold	INT = (SELECT ISNULL(CAST([Value] AS INT),8) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''FullBackupThreshold'')
DECLARE @DiffBackupThreshold	INT = (SELECT CAST([Value] AS INT) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'')
DECLARE @LogBackupThreshold	INT = (SELECT ISNULL(CAST([Value] AS INT),60) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''LogBackupThreshold'')
DECLARE @DatabaseGrowthsAllowedPerDay	INT = (SELECT ISNULL(CAST([Value] AS INT),1) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DatabaseGrowthsAllowedPerDay'')
DECLARE @MAXDatabaseGrowthsAllowedPerDay	INT = (SELECT ISNULL(CAST([Value] AS INT),10) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''MAXDatabaseGrowthsAllowedPerDay'')
DECLARE @InspectorBuild	VARCHAR(6) = (SELECT ISNULL([Value],'''') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''InspectorBuild'')
DECLARE @ReportStart DATETIME = GETDATE();

DECLARE @AGCheck	BIT 
DECLARE @BackupsCheck	BIT 
DECLARE @BackupSizesCheck	BIT 
DECLARE @DatabaseGrowthCheck	BIT 
DECLARE @DatabaseFileCheck	BIT 
DECLARE @DatabaseOwnershipCheck	BIT 
DECLARE @DatabaseStatesCheck	BIT 
DECLARE @DriveSpaceCheck	BIT 
DECLARE @FailedAgentJobCheck	BIT 
DECLARE @JobOwnerCheck	BIT 
DECLARE @FailedLoginsCheck	BIT 
DECLARE @TopFiveDatabaseSizeCheck	BIT 
DECLARE @ADHocDatabaseCreationCheck	BIT 
DECLARE @BackupSpaceCheck	BIT 
DECLARE @DatabaseSettings	BIT
DECLARE @UseMedian	BIT
DECLARE @ServerSettings	BIT
DECLARE @SuspectPages	BIT
DECLARE @AGDatabases	BIT
DECLARE @LongRunningTransactions BIT
DECLARE @UnusedLogshipConfig BIT
DECLARE @TotalWarningCount INT = 0
DECLARE @TotalAdvisoryCount INT = 0
DECLARE @WarningLevel TINYINT
DECLARE @WarningLevelFontColour VARCHAR(7)
DECLARE @VersionNo VARCHAR(128)
DECLARE @Edition VARCHAR(128)
DECLARE @DatabaseGrowthCheckRunEnabled BIT
DECLARE @Duration MONEY
DECLARE @CatalogueInstalled BIT 
DECLARE @CatalogueBuild	VARCHAR(10)
DECLARE @CatalogueModuleEnabled BIT
DECLARE @CatalogueModulename VARCHAR(20)
DECLARE @CatalogueHtml VARCHAR(MAX)
DECLARE @CountCatalogueWarnings INT 
DECLARE @CatalogueLastExecution DATETIME
DECLARE @CatalogueModuleReport BIT
DECLARE @CPUCount INT
DECLARE @TotalRAM INT
DECLARE @VMType NVARCHAR(60)

DECLARE @Stack VARCHAR(255) = (SELECT [Value] from ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''SQLUndercoverInspectorEmailSubject'') 

DECLARE @EmailHeader VARCHAR(1000) = CASE 
										WHEN @PSCollection = 0 
										THEN ''<img src="''+(SELECT [Value] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''EmailBannerURL'')+''">''
										ELSE ''<img src="''+(SELECT [Value] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''PSEmailBannerURL'')+''">''
									 END
DECLARE @SubjectText VARCHAR(255) 
DECLARE @AlertSubjectText VARCHAR(255) 
DECLARE @Importance VARCHAR(6) = ''Low'';
DECLARE @EmailBody VARCHAR(MAX) = '''';
DECLARE @AlertHeader VARCHAR(MAX) = '''';
DECLARE @AdvisoryHeader VARCHAR(MAX) = '''';
DECLARE @InfoHeader VARCHAR(MAX) = '''';
DECLARE @RecipientsList VARCHAR(1000) = (SELECT Recipients FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[EmailRecipients] WHERE [Description] = @EmailDistributionGroup)
DECLARE @RedHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([HighlightHtmlColor],''''),''#F78181'') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 1);
DECLARE @YellowHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([HighlightHtmlColor],''''),''#FAFCA4'') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 2);
DECLARE @InfoHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([HighlightHtmlColor],''''),''#FEFFFF'') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 3);
DECLARE @GradientLeftRedHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientLeftHtmlColor],''''),CASE WHEN @Theme = ''LIGHT'' THEN ''#FFFFFF'' ELSE ''#000000'' END) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 1);
DECLARE @GradientLeftYellowHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientLeftHtmlColor],''''),CASE WHEN @Theme = ''LIGHT'' THEN ''#FFFFFF'' ELSE ''#000000'' END) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 2);
DECLARE @GradientLeftInfoHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientLeftHtmlColor],''''),CASE WHEN @Theme = ''LIGHT'' THEN ''#FFFFFF'' ELSE ''#000000'' END) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 3);
DECLARE @GradientRightRedHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientRightHtmlColor],''''),@RedHighlight) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 1);
DECLARE @GradientRightYellowHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientRightHtmlColor],''''),@YellowHighlight) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 2);
DECLARE @GradientRightInfoHighlight VARCHAR(7) = (SELECT ISNULL(NULLIF([GradientRightHtmlColor],''''),CASE WHEN @Theme = ''LIGHT'' THEN ''#000000'' ELSE ''#FFFFFF'' END) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ModuleWarnings] WHERE [WarningLevel] = 3);
DECLARE @TableTail VARCHAR(65) = ''</table><p><A HREF = "#Warnings">Back to Top</a><p>'';
DECLARE @TableHeaderColour VARCHAR(7) 
DECLARE @ServerSummaryHeader VARCHAR(MAX) = ''<A NAME = "Warnings"></a><b>SQLUndercover Inspector Build: ''+@InspectorBuild+''<div style="text-align: right;"><b>Report date:</b> ''+CONVERT(VARCHAR(17),GETDATE(),113)+''</div><hr><p>Server Summary:</b><br></br>'';
DECLARE @ServerSummaryFontColour VARCHAR(30)
DECLARE @DriveLetterExcludes VARCHAR(10) = (SELECT REPLACE(REPLACE([Value],'':'',''''),''\'','''') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DriveSpaceDriveLetterExcludes'');
DECLARE @DisabledModules VARCHAR(2000)
DECLARE @InstanceStart DATETIME
DECLARE @InstanceVersionInfo NVARCHAR(128)
DECLARE @InstanceUptime INT
DECLARE @PhysicalServername NVARCHAR(128)
DECLARE @ReportDataRetention INT = (SELECT ISNULL(NULLIF(CAST([Value] AS INT),''''),30) from ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''ReportDataRetention'');
DECLARE @CollectionOutOfDate BIT


IF @ModuleDesc IS NULL 
BEGIN 
	SET @SubjectText = (SELECT [EmailSubject] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[EmailConfig] WHERE [ModuleConfig_Desc] = ''Default''); 
END
ELSE 
BEGIN 
	SET @SubjectText = (SELECT [EmailSubject] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[EmailConfig] WHERE [ModuleConfig_Desc] = @ModuleDesc); 
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

--Check if the Undercover Catalogue is installed
IF OBJECT_ID(''Catalogue.ConfigInstances'') IS NOT NULL 
BEGIN 
	SET @CatalogueInstalled = 1; 
END 

--Get Catalogue build and append to the Server summary header.
IF @CatalogueInstalled = 1 
BEGIN 
	EXEC sp_executesql N''SELECT @CatalogueBuild = [ParameterValue] FROM [Catalogue].[ConfigPoSH] WHERE [ParameterName] = ''''CatalogueVersion'''';'',N''@CatalogueBuild VARCHAR(10) OUTPUT'',@CatalogueBuild = @CatalogueBuild OUTPUT
	EXEC sp_executesql N''SELECT TOP 1 @CatalogueLastExecution = [ExecutionDate] FROM [Catalogue].[ExecutionLog] WHERE [CompletedSuccessfully] = 1 ORDER BY [ID] DESC;'',N''@CatalogueLastExecution DATETIME OUTPUT'',@CatalogueLastExecution = @CatalogueLastExecution OUTPUT
	SET @ServerSummaryHeader = ''<A NAME = "Warnings"></a><b>SQLUndercover Inspector Build: ''+ISNULL(@InspectorBuild,'''')+''<p><b>SQLUndercover Catalogue Build: ''+ISNULL(@CatalogueBuild,'''')+''</b><div style="text-align: right;"><b>Catalogue last executed: ''+ISNULL(CONVERT(VARCHAR(17),NULLIF(@CatalogueLastExecution,''1900-01-01 00:00:00.000''),113),''N/A'')+''</b><p><b>Report date:</b> ''+CONVERT(VARCHAR(17),GETDATE(),113)+''</div><hr><p>Server Summary:</b><br></br>'';
END

--Build beginning of the HTML 
SET @EmailHeader = ''
<html>
<head>
<title>SQLUndercover Inspector</title>
<style>
td 
    {
    color: Black; border: solid black;border-width: 1px;padding-left:10px;padding-right:10px;padding-top:10px;padding-bottom:10px;font: 11px arial;
    }
</style>
</head>
<body style="background-color: ''+CASE WHEN @Theme = ''LIGHT'' THEN ''White'' ELSE ''Black'' END +'';" text="''+CASE WHEN @Theme = ''LIGHT'' THEN ''Black'' ELSE ''White'' END +''">
<div style="text-align: center;">'' +ISNULL(@EmailHeader,'''')+''</div>
<BR>
<BR>
'';
	

DECLARE @Serverlist NVARCHAR(128)
DECLARE ServerCur CURSOR LOCAL FAST_FORWARD
FOR 

SELECT Servername,ModuleConfig_Desc,TableHeaderColour
FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers]
WHERE [IsActive] = 1 
ORDER BY Servername ASC


OPEN ServerCur

FETCH NEXT FROM ServerCur INTO @Serverlist,@ModuleConfig,@TableHeaderColour

WHILE @@FETCH_STATUS = 0 
BEGIN

IF @ModuleConfig IS NULL BEGIN SET @ModuleConfig = ''Default'' END;
IF @TableHeaderColour IS NULL BEGIN SET @TableHeaderColour = ''#E6E6FA'' END;

SET @InstanceStart = NULL;
SET @InstanceUptime = NULL;
SET @InstanceVersionInfo = NULL;
SET @PhysicalServername = NULL;


SELECT 							
@AGCheck = ISNULL(AGCheck,0),					
@BackupsCheck = ISNULL(BackupsCheck,0),					
@BackupSizesCheck = ISNULL(BackupSizesCheck,0),			
@DatabaseGrowthCheck = ISNULL(DatabaseGrowthCheck,0),			
@DatabaseFileCheck = ISNULL(DatabaseFileCheck,0),			
@DatabaseOwnershipCheck	= ISNULL(DatabaseOwnershipCheck,0),		
@DatabaseStatesCheck = ISNULL(DatabaseStatesCheck,0),			
@DriveSpaceCheck = ISNULL(DriveSpaceCheck,0),				
@FailedAgentJobCheck = ISNULL(FailedAgentJobCheck,0),			
@JobOwnerCheck = ISNULL(JobOwnerCheck,0),				
@FailedLoginsCheck = ISNULL(FailedLoginsCheck,0),			
@TopFiveDatabaseSizeCheck = ISNULL(TopFiveDatabaseSizeCheck,0),		
@ADHocDatabaseCreationCheck	= ISNULL(ADHocDatabaseCreationCheck,0),					
@BackupSpaceCheck = ISNULL(BackupSpaceCheck,0),
@DatabaseSettings = ISNULL(DatabaseSettings,0),
@UseMedian = ISNULL(UseMedianCalculationForDriveSpaceCalc,0),
@ServerSettings = ISNULL(ServerSettings,0),
@SuspectPages = ISNULL(SuspectPages,0),
@AGDatabases = ISNULL(AGDatabases,0),
@LongRunningTransactions = ISNULL(LongRunningTransactions,0),
@UnusedLogshipConfig = ISNULL(UnusedLogshipConfig,0)
FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Modules]
WHERE ModuleConfig_Desc = ISNULL(@ModuleDesc,@ModuleConfig)

IF @DatabaseGrowthCheck = 1
BEGIN 
    SET @DatabaseGrowthCheckRunEnabled = 1;
END 

IF ISNULL(@ModuleDesc,@ModuleConfig) != ''PeriodicBackupCheck''
BEGIN 
	--Disabled Modules List
	SELECT @DisabledModules = STUFF(REPLACE(
	ISNULL('' , AGCheck''+NULLIF(CAST(@AGCheck AS CHAR(1)),1),'''') +
	ISNULL('' , BackupsCheck''+NULLIF(CAST(@BackupsCheck AS CHAR(1)),1),'''') +
	ISNULL('' , BackupSizesCheck''+NULLIF(CAST(@BackupSizesCheck AS CHAR(1)),1),'''') +
	ISNULL('' , DatabaseGrowthCheck''+NULLIF(CAST(@DatabaseGrowthCheck AS CHAR(1)),1),'''') +
	ISNULL('' , DatabaseFileCheck''+NULLIF(CAST(@DatabaseFileCheck AS CHAR(1)),1),'''') +
	ISNULL('' , DatabaseOwnershipCheck''+NULLIF(CAST(@DatabaseOwnershipCheck AS CHAR(1)),1),'''') +
	ISNULL('' , DatabaseStatesCheck''+NULLIF(CAST(@DatabaseStatesCheck AS CHAR(1)),1),'''') +
	ISNULL('' , DriveSpaceCheck''+NULLIF(CAST(@DriveSpaceCheck AS CHAR(1)),1),'''') +
	ISNULL('' , FailedAgentJobCheck''+NULLIF(CAST(@FailedAgentJobCheck AS CHAR(1)),1),'''') +
	ISNULL('' , JobOwnerCheck''+NULLIF(CAST(@JobOwnerCheck AS CHAR(1)),1),'''') +
	ISNULL('' , FailedLoginsCheck''+NULLIF(CAST(@FailedLoginsCheck AS CHAR(1)),1),'''') +
	ISNULL('' , TopFiveDatabaseSizeCheck''+NULLIF(CAST(@TopFiveDatabaseSizeCheck AS CHAR(1)),1),'''') +
	ISNULL('' , ADHocDatabaseCreationCheck''+NULLIF(CAST(@ADHocDatabaseCreationCheck AS CHAR(1)),1),'''') +
	ISNULL('' , BackupSpaceCheck''+NULLIF(CAST(@BackupSpaceCheck AS CHAR(1)),1),'''') +
	ISNULL('' , DatabaseSettings''+NULLIF(CAST(@DatabaseSettings AS CHAR(1)),1),'''') +
	ISNULL('' , ServerSettings''+NULLIF(CAST(@ServerSettings AS CHAR(1)),1),'''') +
	ISNULL('' , SuspectPages''+NULLIF(CAST(@SuspectPages AS CHAR(1)),1),'''') +
	ISNULL('' , AGDatabases''+NULLIF(CAST(@AGDatabases AS CHAR(1)),1),'''') +
	ISNULL('' , LongRunningTransactions''+NULLIF(CAST(@LongRunningTransactions AS CHAR(1)),1),'''') +
	ISNULL('' , UnusedLogshipConfig''+NULLIF(CAST(@UnusedLogshipConfig AS CHAR(1)),1),'''')+
	ISNULL('' , UseMedian''+NULLIF(CAST(@UseMedian AS CHAR(1)),1),''''),''0'',''''),1,3,'''')
END 

IF ISNULL(@ModuleDesc,@ModuleConfig) = ''PeriodicBackupCheck''
BEGIN 
	SET @DisabledModules = ''N/A''
END 

IF @DisabledModules IS NULL BEGIN SET @DisabledModules = ''None'' END

SET @InstanceStart = (SELECT [InstanceStart] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[InstanceStart] WHERE Servername = @Serverlist AND Log_Date >= CAST(GETDATE() AS DATE));
SET @InstanceUptime = (SELECT DATEDIFF(DAY,@InstanceStart,GETDATE()));
SELECT @InstanceVersionInfo = [VersionInfo], @PhysicalServername = [PhysicalServername] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[InstanceVersion] WHERE Servername = @Serverlist AND Log_Date >= CAST(GETDATE() AS DATE);

IF @CatalogueInstalled = 1 
BEGIN 
	EXEC sp_executesql N''SELECT @CPUCount = [CPUCount],@TotalRAM = ([PhysicalMemoryMB]/1000) FROM [Catalogue].[Servers] WHERE ServerName = @Serverlist'',N''@Serverlist NVARCHAR(128),@CPUCount INT OUTPUT, @TotalRAM INT OUTPUT'',@Serverlist = @Serverlist, @CPUCount = @CPUCount OUTPUT, @TotalRAM = @TotalRAM OUTPUT;
	EXEC sp_executesql N''SELECT @VMType = CASE WHEN [VMType] = ''''NONE'''' THEN ''''Physical'''' ELSE ''''Virtual'''' END FROM [Catalogue].[Servers] WHERE ServerName = @Serverlist'',N''@Serverlist NVARCHAR(128), @VMType NVARCHAR(60) OUTPUT'',@Serverlist = @Serverlist, @VMType = @VMType OUTPUT;
END

SELECT  @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server <A NAME = "''+REPLACE(@Serverlist,''\'','''')+''Servername''+''"></a>[''+@Serverlist+'']</b><BR></BR>
Instance start: <b>''+ISNULL(CONVERT(VARCHAR(17),@InstanceStart,113),''Not Recorded'')+'' (Uptime: ''+ISNULL(CAST(@InstanceUptime AS VARCHAR(6)),''N/A'')+CASE WHEN @InstanceUptime IS NOT NULL THEN '' Days)'' ELSE '')'' END + ''</b><BR>
Instance Version/Edition: <b>''+ISNULL(@InstanceVersionInfo,''Not Recorded'')+''</b><BR>
Physical Servername: <b>''+ISNULL(@PhysicalServername,''Not Recorded'')+''</b><BR>''
+ISNULL(''CPU Count: <b>''+CAST(@CPUCount AS VARCHAR(4))+''</b><BR>'','''')
+ISNULL(''Total RAM: <b>''+CAST(@TotalRAM AS VARCHAR(10))+'' GB</b><BR>'','''')
+ISNULL(''Machine type: <b>''+CAST(@VMType AS VARCHAR(10))+''</b><BR>'','''')
+''<p></p>''
+''ModuleConfig used: <b>''+ISNULL(@ModuleDesc,@ModuleConfig)+ ''</b><BR> 
Disabled Modules: <b>''+@DisabledModules+''</b><BR></p><p></p><BR></BR>''

IF @DriveSpaceCheck = 1 
BEGIN
--Excluded from Warning level control
    DECLARE @BodyDriveSpace  VARCHAR(MAX) = ''''
	DECLARE @CountDriveSpace INT
    DECLARE @TableHeadDriveSpace VARCHAR(1000) =
    ''<b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''DriveSpace''+''"></a>Drive space Report (Using ''+CASE WHEN @UseMedian = 1 THEN ''Median based Calculation'' ELSE ''Average based Calculation'' END +''):</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Server name</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Drive</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Total GB</b></font></td>	
	<td bgcolor=''+@TableHeaderColour+''><b>Available GB</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>% Free</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Est.Daily Growth GB</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Days Until Disk Full</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Days Recorded</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Usage Trend</b></font></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Usage Trend AVG GB</b></font></td>
	'';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DriveSpace]
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	BEGIN

	WITH TotalDriveEntries AS 
	(
	--GROUP THE DRIVE LETTERS AND COUNT TOTAL LOGGED ENTRIES (1 entry per day)
	SELECT Servername,Drive,COUNT(Drive) AS TotalEntries
	FROM (
	SELECT Servername,Drive,CAST(Log_Date AS DATE) AS Datelogged
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DriveSpace]
	WHERE Servername = @Serverlist
	GROUP BY Servername,Drive,CAST(Log_Date AS DATE)
	) AS X 
	GROUP BY Servername,Drive
	),
	SpaceVariation as (
	--CALCULATE THE DIFFERENCE BETWEEN CURRENT FREESPACE AND LAST RECORDED FREE SPACE FOR ALL ENTRIES PER DRIVE
	SELECT 
	Log_Date,
	DriveSpace.
	Servername,
	DriveSpace.Drive,
	Capacity_GB,
	(Capacity_GB-AvailableSpace_GB) as UsedSpace_GB,
	AvailableSpace_GB,
	LAG(Capacity_GB-AvailableSpace_GB,1,Capacity_GB-AvailableSpace_GB) OVER(PARTITION BY DriveSpace.Servername,DriveSpace.Drive ORDER BY DriveSpace.Servername,DriveSpace.Drive,Log_Date) as laggedUsedSpace,
	TotalEntries
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DriveSpace] AS DriveSpace
	INNER JOIN TotalDriveEntries ON DriveSpace.Drive = TotalDriveEntries.Drive AND DriveSpace.Servername = TotalDriveEntries.Servername
	),
	ApplyMedianRowNum AS (
	SELECT 
	Servername,
	Drive,
	laggedUsedSpace,
	CASE 
		WHEN (UsedSpace_GB-laggedUsedSpace) < 0 THEN 0 
		ELSE (UsedSpace_GB-laggedUsedSpace) 
	END AS VarianceCalc,
	ROW_NUMBER() OVER (PARTITION BY [Drive] ORDER BY [Drive],(SELECT(UsedSpace_GB-laggedUsedSpace)) DESC) AS RowNum,
	TotalEntries
	FROM SpaceVariation
	),
	AverageDailyGrowth AS
	(
	--TAKE THE DIFFERENCES FROM SpaceVariation CTE AND DIVIDE THIS BY TOTAL ENTRIES PER DRIVE LETTER
	SELECT
	Servername, 
	Drive,
	CASE 
		WHEN @UseMedian = 1 THEN (SELECT VarianceCalc FROM ApplyMedianRowNum Median WHERE Median.Drive = SpaceVariation.Drive AND (Median.TotalEntries/2) = Median.RowNum)
		ELSE CAST(SUM((VarianceCalc)/TotalEntries) AS DECIMAL(10,2)) 
	END AS AverageDailyGrowth_GB
	FROM ApplyMedianRowNum SpaceVariation
	GROUP BY
	Servername,
	Drive
	) 
	SELECT @BodyDriveSpace = @BodyDriveSpace +(
	SELECT 
	CASE 
		WHEN AverageDailyGrowth_GB > 0 
		AND CAST(COALESCE((LastRecordedFreeSpace.AvailableSpace_GB)/NULLIF(AverageDailyGrowth_GB,0),0) AS DECIMAL(20,2)) < @DaysUntilDriveFullThreshold
		THEN @RedHighlight 
		WHEN CAST((LastRecordedFreeSpace.AvailableSpace_GB/LastRecordedFreeSpace.Capacity_GB)*100 AS DECIMAL(10,2)) < @FreeSpaceRemainingPercent 
		AND AverageDailyGrowth.Drive COLLATE DATABASE_DEFAULT NOT IN (SELECT '+CASE WHEN @Compatibility = 0 THEN '[StringElement]+'':\''' ELSE '[value]+'':\''' END+ 
		'FROM '+CASE WHEN @Compatibility = 0 THEN '[master].[dbo].fn_SplitString(@DriveLetterExcludes,'','') DriveLetterExcludes'
										ELSE 'STRING_SPLIT(@DriveLetterExcludes,'','') DriveLetterExcludes'
										END+')
		THEN @YellowHighlight
		ELSE ''#FFFFFF'' 
	END AS [@bgcolor], 
	AverageDailyGrowth.Servername AS ''td'','''', + 
	AverageDailyGrowth.Drive AS ''td'','''', + 
	LastRecordedFreeSpace.Capacity_GB AS ''td'','''', + 
	LastRecordedFreeSpace.AvailableSpace_GB AS ''td'','''', + 
	CAST((AvailableSpace_GB/LastRecordedFreeSpace.Capacity_GB)*100 AS DECIMAL(10,2)) AS ''td'','''', + 
	AverageDailyGrowth.AverageDailyGrowth_GB AS ''td'','''', + 
	CASE WHEN AverageDailyGrowth_GB <= 0 
	THEN ''N/A''
	ELSE
	CAST(CAST(COALESCE((LastRecordedFreeSpace.AvailableSpace_GB)/NULLIF(AverageDailyGrowth_GB,0),0) AS DECIMAL(20,2)) AS VARCHAR(10))
	END AS ''td'','''', + 
	TotalDriveEntries.TotalEntries  AS ''td'','''', + 
	STUFF((SELECT TOP 5 '', ['' + DATENAME(WEEKDAY,DATEADD(DAY,-1,SpaceVariation.Log_Date)) + '' '' + CASE WHEN laggedUsedSpace-UsedSpace_GB > 0 THEN ''0''  --DATEADD is used here to display the previous day as the collection date is a day ahead.
	ELSE CAST(ABS(laggedUsedSpace-UsedSpace_GB) AS VARCHAR(10)) END +'' GB]'' FROM SpaceVariation WHERE SpaceVariation.Drive = TotalDriveEntries.Drive AND SpaceVariation.Servername = TotalDriveEntries.Servername ORDER BY SpaceVariation.Log_Date DESC FOR XML PATH('''')),1,1,'''')  AS ''td'','''', +
	FiveDayTotal.SUMFiveDayTotal AS ''td'',''''
	FROM AverageDailyGrowth
	INNER JOIN TotalDriveEntries ON TotalDriveEntries.Drive =  AverageDailyGrowth.Drive AND TotalDriveEntries.Servername =  AverageDailyGrowth.Servername
	CROSS APPLY (SELECT TOP 1 Capacity_GB,AvailableSpace_GB
				FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DriveSpace] DriveSpace
				WHERE DriveSpace.Drive = TotalDriveEntries.Drive
				AND DriveSpace.Servername = TotalDriveEntries.Servername
				ORDER BY Log_Date DESC) as LastRecordedFreeSpace
	CROSS APPLY (SELECT CAST(AVG(CASE WHEN laggedUsedSpace-UsedSpace_GB > 0 THEN 0  
				 ELSE ABS(laggedUsedSpace-UsedSpace_GB) END) AS DECIMAL(20,2)) AS SUMFiveDayTotal 
				 FROM 
					(SELECT TOP 5 Drive, laggedUsedSpace,UsedSpace_GB
						FROM SpaceVariation 
						WHERE SpaceVariation.Drive = TotalDriveEntries.Drive 
						AND SpaceVariation.Servername = TotalDriveEntries.Servername 
						ORDER BY SpaceVariation.Log_Date DESC
					)  AS LastFiveDays 
				 ) AS FiveDayTotal
	WHERE AverageDailyGrowth.Servername = @Serverlist
	ORDER BY AverageDailyGrowth.Drive ASC
	FOR XML PATH(''tr''),Elements)
	
	-- Count Drive space warnings
	SET @CountDriveSpace = (LEN(@BodyDriveSpace) - LEN(REPLACE(@BodyDriveSpace,@RedHighlight, '''')))/LEN(@RedHighlight)
	
	SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDriveSpace, '''') + ISNULL(@BodyDriveSpace, '''') + ''</table><p><b><font style="color: Black; background-color: ''+@YellowHighlight+''">Advisory Highlight</font> - Drive remaining percent below ''+CAST(@FreeSpaceRemainingPercent AS VARCHAR(3))+''%''+ ISNULL('' (Drives being excluded are: ''+ @DriveLetterExcludes +'')'','''') +''<br>
	 <font style="color: Black; background-color: ''+@RedHighlight+''">Warning Highlight</font> - Estimated days remaining until drive is full, is below ''+CAST(@DaysUntilDriveFullThreshold AS VARCHAR(3))+ '' Days </p></b>''
	 + ISNULL(REPLACE(@TableTail,''</table>'',''''),'''') +''<p><BR><p>''
				  
	IF @BodyDriveSpace LIKE ''%''+@RedHighlight+''%''		
	BEGIN 
		SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DriveSpace''+''">''+@Serverlist+''</a><font color= ''+@RedHighlight+''>  - has (''+CAST(@CountDriveSpace AS VARCHAR(5))+'') Drive Space warnings</font><p>''	  
		SET @Importance = ''High'' 
		SET @TotalWarningCount = @TotalWarningCount + @CountDriveSpace
	END
		
	--Count Drive space Yellow Highlights	
	SET @CountDriveSpace = (LEN(@BodyDriveSpace) - LEN(REPLACE(@BodyDriveSpace,@YellowHighlight, '''')))/LEN(@YellowHighlight)
	IF @CountDriveSpace > 0	
	BEGIN 
		SELECT @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DriveSpace''+''">''+@Serverlist+''</a><font color= ''+@YellowHighlight+''>  - has (''+CAST(@CountDriveSpace AS VARCHAR(5))+'') Drive Space warnings where remaining space is below ''+CAST(@FreeSpaceRemainingPercent AS VARCHAR(3))+''% remaining</font><p>''	  
		SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountDriveSpace
	END
		
		
	END
	ELSE
	BEGIN
	SET @BodyDriveSpace = 
	(SELECT 
	@RedHighlight AS [@bgcolor], 
	@Serverlist AS ''td'','''', + 
	''Data Collection out of date'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'',''''
	FOR XML PATH(''tr''),Elements)
	
	SET @CountDriveSpace = (LEN(@BodyDriveSpace) - LEN(REPLACE(@BodyDriveSpace,@RedHighlight, '''')))/LEN(@RedHighlight)

	SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDriveSpace, '''') + ISNULL(@BodyDriveSpace, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	
	IF @BodyDriveSpace LIKE ''%''+@RedHighlight+''%''		
	BEGIN 
		SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DriveSpace''+''">''+@Serverlist+''</a><font color= ''+@RedHighlight+''>  - has (''+CAST(@CountDriveSpace AS VARCHAR(5))+'') Drive Space warnings <b>(Data collection out of Date)</b></font><p>''	  
		SET @Importance = ''High'' 
		SET @TotalWarningCount = @TotalWarningCount + @CountDriveSpace
	END

	END

END


IF @AGCheck = 1 
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''AGCheck'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @RedHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;

	DECLARE @BodyAGCheck VARCHAR(MAX)
	DECLARE @TableHeadAGCheck VARCHAR(1000)
	DECLARE @CountAGCheck INT
	
	SET @TableHeadAGCheck = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''"></a>Availability Group Health Check</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>AG name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>State</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Replica Server Name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Suspended</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Suspend Reason</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[AGCheck]
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyAGCheck = (
		SELECT 
		CASE 
			WHEN @WarningLevel IS NULL AND ([State] != ''HEALTHY'' AND [State] != ''N/A'' ) THEN @RedHighlight
			WHEN @WarningLevel = 1 AND ([State] != ''HEALTHY'' AND [State] != ''N/A'') THEN @RedHighlight
			WHEN @WarningLevel = 2 AND ([State] != ''HEALTHY'' AND [State] != ''N/A'') THEN @YellowHighlight
			WHEN @WarningLevel = 3 AND ([State] != ''HEALTHY'' AND [State] != ''N/A'') THEN @InfoHighlight
			ELSE ''#FFFFFF''
		END AS [@bgcolor],
		Servername  AS ''td'','''', +
		AGname AS ''td'','''', +
		[State] AS ''td'','''', +
		ISNULL([ReplicaServername],''N/A'') AS ''td'','''', +
		CASE WHEN [Suspended] = 1 THEN ''Y'' 
		WHEN [Suspended] = 0 THEN ''N''
		ELSE ''N/A'' END AS ''td'','''', +
		ISNULL([SuspendReason],''N/A'') AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[AGCheck]
		WHERE Servername = @Serverlist
		ORDER BY AGname ASC,ReplicaServername ASC
		FOR XML PATH(''tr''),ELEMENTS);
	END
	ELSE
	BEGIN
		SET @BodyAGCheck = (
		SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @RedHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Serverlist  AS ''td'','''', +
		''Data collection out of date'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[AGCheck]
		WHERE Servername = @Serverlist
		ORDER BY AGname ASC
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1
	END

	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyAGCheck LIKE ''%HADR IS NOT ENABLED ON THIS SERVER OR YOU HAVE NO AVAILABILITY GROUPS%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadAGCheck, '''') + ISNULL(@BodyAGCheck, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	END

	--Populate Alert header (Default Warning Level)
	IF (@WarningLevel = 1 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyAGCheck LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountAGCheck = (LEN(@BodyAGCheck) - LEN(REPLACE(@BodyAGCheck,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGCheck AS VARCHAR(5))+'') AG Warnings</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGCheck AS VARCHAR(5))+'') AG Warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountAGCheck
		END
	END
	
	--Populate Advisory header 
	IF @WarningLevel = 2 
	BEGIN 
		IF @BodyAGCheck LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountAGCheck = (LEN(@BodyAGCheck) - LEN(REPLACE(@BodyAGCheck,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGCheck AS VARCHAR(5))+'') AG Warnings</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGCheck AS VARCHAR(5))+'') AG Warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountAGCheck
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyAGCheck LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountAGCheck = (LEN(@BodyAGCheck) - LEN(REPLACE(@BodyAGCheck,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGCheck AS VARCHAR(5))+'') AG Warnings</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGCheck AS VARCHAR(5))+'') AG Warnings <b>(Data collection out of Date)</b></font><p>''  
			END
		END
	
	END

END 


IF @SuspectPages  = 1
BEGIN 

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''SuspectPages'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @RedHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;

	DECLARE @BodySuspectPages VARCHAR(MAX) = ''''
	DECLARE @TableHeadSuspectPages VARCHAR(1000)
	DECLARE @CountSuspectPages INT
	
	SET @TableHeadSuspectPages = ''
	<b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''SuspectPages''+''"></a>Suspect Pages Check</b>
	<br> <table cellpadding=0 cellspacing=0 border=0> 
	<tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>File ID</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Page ID</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Event type</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Error count</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Last update</b></td>
	'';
		
		IF (SELECT MAX(Log_Date) 
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[SuspectPages] 
		WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)	
		BEGIN
			SELECT @BodySuspectPages = @BodySuspectPages +
			(SELECT 
			CASE 
				WHEN @WarningLevel IS NULL AND [Databasename] IS NOT NULL THEN @RedHighlight
				WHEN @WarningLevel = 1 AND [Databasename] IS NOT NULL THEN @RedHighlight
				WHEN @WarningLevel = 2 AND [Databasename] IS NOT NULL THEN @YellowHighlight
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
			FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[SuspectPages]
			WHERE Servername = @Serverlist
			ORDER BY [last_update_date] ASC
			FOR XML PATH(''tr''),ELEMENTS);
		END
		ELSE
		BEGIN
			SET @BodySuspectPages =
			(SELECT 
			CASE 
				WHEN @WarningLevel IS NULL THEN @RedHighlight
				WHEN @WarningLevel = 1 THEN @RedHighlight
				WHEN @WarningLevel = 2 THEN @YellowHighlight
				WHEN @WarningLevel = 3 THEN @InfoHighlight
			END AS [@bgcolor],
			@Serverlist AS ''td'','''', + 
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
	
	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodySuspectPages LIKE ''%No Suspect pages found%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadSuspectPages,'''') + ISNULL(@BodySuspectPages, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	END

	--Populate Alert header (Default Warning Level)
	IF (@WarningLevel = 1 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodySuspectPages LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountSuspectPages = (LEN(@BodySuspectPages) - LEN(REPLACE(@BodySuspectPages,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''SuspectPages''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountSuspectPages AS VARCHAR(5))+'') Suspect page warnings</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''SuspectPages''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountSuspectPages AS VARCHAR(5))+'') Suspect page warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountSuspectPages
		END
	END
	
	--Populate Advisory header 
	IF @WarningLevel = 2 
	BEGIN 
		IF @BodySuspectPages LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountSuspectPages = (LEN(@BodySuspectPages) - LEN(REPLACE(@BodySuspectPages,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''SuspectPages''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountSuspectPages AS VARCHAR(5))+'') Suspect page warnings</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''SuspectPages''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountSuspectPages AS VARCHAR(5))+'') Suspect page warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountSuspectPages
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodySuspectPages LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountSuspectPages = (LEN(@BodySuspectPages) - LEN(REPLACE(@BodySuspectPages,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''SuspectPages''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountSuspectPages AS VARCHAR(5))+'') Suspect page warnings</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''SuspectPages''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountSuspectPages AS VARCHAR(5))+'') Suspect page warnings <b>(Data collection out of Date)</b></font><p>''  
			END
		END
	
	END
	
END


IF @AGDatabases  = 1
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''AGDatabases'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;

	DECLARE @BodyAGDatabases VARCHAR(MAX)
	DECLARE @TableHeadAGDatabases VARCHAR(1000)
	DECLARE @CountAGDatabases INT
	
	SET @TableHeadAGDatabases = ''
	<b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''AGDatabases''+''"></a>Databases not joined to an Availability group</b>
	<br> <table cellpadding=0 cellspacing=0 border=0> 
	<tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Last Checked</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
	'';

	IF (SELECT MAX(LastUpdated) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[AGDatabases] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyAGDatabases =(
		SELECT
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		[Servername] AS ''td'','''', +
		CONVERT(VARCHAR(17),[LastUpdated],113) AS ''td'','''', +
		[Databasename] AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[AGDatabases]
		WHERE [Is_AG] = 1
		AND [Is_AGJoined] = 0
		AND Servername = @Serverlist
		ORDER BY [Databasename] ASC
		FOR XML PATH(''tr''),ELEMENTS);
		
		IF @BodyAGDatabases IS NULL
		BEGIN
			SET @BodyAGDatabases =(
			SELECT
			''#FFFFFF'' AS [@bgcolor], 
			@Serverlist AS ''td'','''', +
			''No Databases marked as AG and not joined'' AS ''td'','''', +
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE
	BEGIN
		SET @BodyAGDatabases =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor], 
		@Serverlist AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),Elements);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyAGDatabases LIKE ''%No Databases marked as AG and not joined%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadAGDatabases,'''') + ISNULL(@BodyAGDatabases, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	END

	--Populate Alert header
	IF @WarningLevel = 1
	BEGIN 
		IF @BodyAGDatabases LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountAGDatabases = (LEN(@BodyAGDatabases) - LEN(REPLACE(@BodyAGDatabases,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AGDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGDatabases AS VARCHAR(5))+'') Databases not joined to an Availability group</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AGDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGDatabases AS VARCHAR(5))+'') Databases not joined to an Availability group <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountAGDatabases
		END
	END
	
	--Populate Advisory header (Default Warning Level)
	IF (@WarningLevel = 2  OR @WarningLevel IS NULL) 
	BEGIN 
		IF @BodyAGDatabases LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountAGDatabases = (LEN(@BodyAGDatabases) - LEN(REPLACE(@BodyAGDatabases,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AGDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGDatabases AS VARCHAR(5))+'') Databases not joined to an Availability group</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AGDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGDatabases AS VARCHAR(5))+'') Databases not joined to an Availability group <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountAGDatabases
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyAGDatabases LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountAGDatabases = (LEN(@BodyAGDatabases) - LEN(REPLACE(@BodyAGDatabases,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AGDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGDatabases AS VARCHAR(5))+'') Databases not joined to an Availability group</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AGDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAGDatabases AS VARCHAR(5))+'') Databases not joined to an Availability group <b>(Data collection out of Date)</b></font><p>''  
			END
		END
	
	END

END


IF @LongRunningTransactions  = 1
BEGIN
	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''LongRunningTransactions'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;
								
	DECLARE @LongRunningTransactionThreshold VARCHAR(255) = (SELECT CAST([Value] AS INT) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''LongRunningTransactionThreshold'')
	DECLARE @BodyLongRunningTransactions VARCHAR(MAX)
	DECLARE @TableHeadLongRunningTransactions VARCHAR(1000)
	DECLARE @CountLongRunningTransactions INT
	
	--Default value
	IF @LongRunningTransactionThreshold IS NULL 
	BEGIN 
		SET @LongRunningTransactionThreshold = 300
	END

	SET @TableHeadLongRunningTransactions = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''LongRunningTransactions''+''"></a>Transactions that exceed the threshold of ''+CAST(@LongRunningTransactionThreshold AS VARCHAR(8))+'' seconds ''+CASE WHEN @LongRunningTransactionThreshold > 300 THEN ''(''+CAST(CAST(CAST(@LongRunningTransactionThreshold AS MONEY)/60.00 AS MONEY) AS VARCHAR(10))+'' Minutes)'' ELSE '''' END+''</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Session id</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Transaction begin time</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Duration (DDHHMMSS)</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Transaction state</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Session state</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Login name</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Host name</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Program name</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[LongRunningTransactions] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyLongRunningTransactions = (SELECT 
		CASE
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
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
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[LongRunningTransactions]
		WHERE Servername = @Serverlist
		AND [transaction_begin_time] IS NOT NULL
		ORDER BY [transaction_begin_time] ASC
		FOR XML PATH(''tr''),ELEMENTS);

		IF @BodyLongRunningTransactions IS NULL 
		BEGIN 
			SET @BodyLongRunningTransactions = (SELECT 
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
			FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[LongRunningTransactions]
			WHERE Servername = @Serverlist
			AND [transaction_begin_time] IS NULL
			ORDER BY [transaction_begin_time] ASC
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN 
		SET @BodyLongRunningTransactions = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Serverlist AS ''td'','''',+
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

	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyLongRunningTransactions LIKE ''%No Long running transactions%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadLongRunningTransactions, '''') + ISNULL(@BodyLongRunningTransactions, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	END

	--Populate Alert header
	IF @WarningLevel = 1
	BEGIN 
		IF @BodyLongRunningTransactions LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountLongRunningTransactions = (LEN(@BodyLongRunningTransactions) - LEN(REPLACE(@BodyLongRunningTransactions,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''LongRunningTransactions''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLongRunningTransactions AS VARCHAR(5))+'') Transactions that exceed ''+CAST(@LongRunningTransactionThreshold AS VARCHAR(8))+ '' seconds duration</font><p>''   
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''LongRunningTransactions''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLongRunningTransactions AS VARCHAR(5))+'') Long running transactions <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountLongRunningTransactions
		END
	END
	
	--Populate Advisory header (Default Warning Level)
	IF (@WarningLevel = 2 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyLongRunningTransactions LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountLongRunningTransactions = (LEN(@BodyLongRunningTransactions) - LEN(REPLACE(@BodyLongRunningTransactions,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''LongRunningTransactions''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLongRunningTransactions AS VARCHAR(5))+'') Transactions that exceed ''+CAST(@LongRunningTransactionThreshold AS VARCHAR(8))+ '' seconds duration</font><p>''   
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''LongRunningTransactions''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLongRunningTransactions AS VARCHAR(5))+'') Long running transactions <b>(Data collection out of Date)</b></font><p>''  		
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountLongRunningTransactions
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyLongRunningTransactions LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountLongRunningTransactions = (LEN(@BodyLongRunningTransactions) - LEN(REPLACE(@BodyLongRunningTransactions,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''LongRunningTransactions''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLongRunningTransactions AS VARCHAR(5))+'') Transactions that exceed ''+CAST(@LongRunningTransactionThreshold AS VARCHAR(8))+ '' seconds duration</font><p>''   
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''LongRunningTransactions''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLongRunningTransactions AS VARCHAR(5))+'') Long running transactions <b>(Data collection out of Date)</b></font><p>''  		
			END
		END
	
	END

END


IF @DatabaseStatesCheck = 1 
BEGIN
	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''DatabaseStatesCheck'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value 
	--Warning level 1 (Red) only controls states: ''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)''
	IF  @WarningLevel > 3 BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;
								
	DECLARE @BodyDatabaseStates VARCHAR(MAX)
	DECLARE @TableHeadDatabaseStates VARCHAR(1000)
	DECLARE @CountDatabaseStates INT
	DECLARE @SuspectAlertText VARCHAR(65) = NULL

	SET @TableHeadDatabaseStates = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''"></a>Database Count by State</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database state</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database names</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseStates] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyDatabaseStates =(
		SELECT 
		CASE 
			WHEN DatabaseState IN (''RECOVERY_PENDING'',''SUSPECT'',''EMERGENCY'') THEN @RedHighlight --Cannot be overidden using Warning levels
			WHEN @WarningLevel IS NULL AND DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @YellowHighlight
			WHEN @WarningLevel = 1 AND DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @RedHighlight
			WHEN @WarningLevel = 2 AND DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @YellowHighlight
			WHEN @WarningLevel = 3 AND DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @InfoHighlight
		ELSE ''#FFFFFF'' END AS [@bgcolor],
		Servername AS ''td'','''', +
		DatabaseState AS ''td'','''', +
		Total AS ''td'','''', +
		DatabaseNames AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseStates]
		WHERE Servername = @Serverlist
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
	   
		IF (@BodyDatabaseStates LIKE ''%<td>SUSPECT</td>%'' OR @BodyDatabaseStates LIKE ''%<td>RECOVERY_PENDING</td>%'' OR @BodyDatabaseStates LIKE ''%<td>EMERGENCY</td>%'')
		BEGIN 
			SET @SuspectAlertText = '' (SUSPECT , RECOVERY_PENDING OR EMERGENCY DATABASE/S PRESENT!)'' 
		END
	END
	ELSE
	BEGIN
		SET @BodyDatabaseStates =(
		SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight 
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Serverlist AS ''td'','''', +
		''Data collection out of date'' AS ''td'','''', +
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	--Append html table to the report
	SELECT @EmailBody = @EmailBody + ISNULL(@TableHeadDatabaseStates, '''') + ISNULL(@BodyDatabaseStates, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'';

	--Populate Alert header
	--Warning Level 1 handled inside the block as there are two conditions for red higlights
	IF @BodyDatabaseStates LIKE ''%''+@RedHighlight+''%''
	BEGIN
		SET @CountDatabaseStates = (LEN(@BodyDatabaseStates) - LEN(REPLACE(@BodyDatabaseStates,@RedHighlight, '''')))/LEN(@RedHighlight);
		SELECT @AlertHeader = @AlertHeader + 
		CASE --@SuspectAlertText takes precedence over the standard red warning as these states are more critical that the warning level ones.
			WHEN @CollectionOutOfDate = 0 AND @SuspectAlertText IS NOT NULL THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= ''+@RedHighlight+''>  - has (''+CAST(@CountDatabaseStates AS VARCHAR(5))+'') Database State warnings ''+ISNULL(@SuspectAlertText,'''')+''</font></b><p>''
			WHEN @CollectionOutOfDate = 0 AND @SuspectAlertText IS NULL AND @WarningLevel = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseStates AS VARCHAR(5))+'') Database State Advisories including any of the following states: (Restoring, Recovering, Offline, Snapshot (more than 10 days old))</font><p>'' 
			WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseStates AS VARCHAR(5))+'') Database State warnings <b>(Data collection out of Date)</b></font><p>''  
		END
		SET @Importance = ''High'' ;
		SET @TotalWarningCount = @TotalWarningCount + @CountDatabaseStates;
	END
	
	--Populate Advisory header (Default Warning Level)
	IF (@WarningLevel = 2 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyDatabaseStates LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountDatabaseStates = (LEN(@BodyDatabaseStates) - LEN(REPLACE(@BodyDatabaseStates,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseStates AS VARCHAR(5))+'') Database State Advisories including any of the following states: (Restoring, Recovering, Offline, Snapshot (more than 10 days old))</font><p>''        
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseStates AS VARCHAR(5))+'') Database State warnings <b>(Data collection out of Date)</b></font><p>''  		
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountDatabaseStates;
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyDatabaseStates LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountDatabaseStates = (LEN(@BodyDatabaseStates) - LEN(REPLACE(@BodyDatabaseStates,@InfoHighlight, '''')))/LEN(@InfoHighlight);
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseStates AS VARCHAR(5))+'') Database State Advisories including any of the following states: (Restoring, Recovering, Offline, Snapshot (more than 10 days old))</font><p>''        
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseStates AS VARCHAR(5))+'') Database State warnings <b>(Data collection out of Date)</b></font><p>''  		
			END
		END
	
	END

END



IF @FailedAgentJobCheck = 1 
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''FailedAgentJobCheck'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @RedHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;
	
	DECLARE @BodyFailedJobsTotals VARCHAR(MAX)
	DECLARE @TableHeadFailedJobsTotals VARCHAR(1000)
	DECLARE @CountFailedJobsTotals INT

	SET @TableHeadFailedJobsTotals =''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''"></a>Failed Agent Jobs in the last 24hrs</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></font></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Log Date</b></font></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Job name</b></font></td>	
    <td bgcolor=''+@TableHeaderColour+''><b>Last Step Failed</b></font></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Last Failed Date</b></font></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Last Error</b></font></td>
    '';

	IF (SELECT MAX(Log_Date)   
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[FailedAgentJobs]
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE) 
	BEGIN
		SET @BodyFailedJobsTotals = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @RedHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''', + 
		CONVERT(VARCHAR(17),Log_Date,113) AS ''td'','''', + 
		Jobname AS ''td'','''', +  
		LastStepFailed AS ''td'','''', +  
		CONVERT(VARCHAR(17),LastFailedDate,113) AS ''td'','''',+  
		LastError + ''...'' AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[FailedAgentJobs]
		WHERE Servername = @Serverlist
		AND Jobname != ''No Failed Jobs present''
		FOR XML PATH(''tr''),ELEMENTS);

		IF @BodyFailedJobsTotals IS NULL
		BEGIN
			SET @BodyFailedJobsTotals = 
			(SELECT ''#FFFFFF'' AS [@bgcolor],
			@Serverlist AS ''td'','''', + 
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
		SET @BodyFailedJobsTotals = 
		(SELECT
		CASE 
			WHEN @WarningLevel IS NULL THEN @RedHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Serverlist AS ''td'','''', + 
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
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyFailedJobsTotals LIKE ''%No Failed Jobs present%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadFailedJobsTotals,'''') + ISNULL(@BodyFailedJobsTotals, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	END

--Populate Alert header (Default Warning Level)
	IF (@WarningLevel = 1 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyFailedJobsTotals LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountFailedJobsTotals = (LEN(@BodyFailedJobsTotals) - LEN(REPLACE(@BodyFailedJobsTotals,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountFailedJobsTotals AS VARCHAR(5))+'') Failed Job warnings</font><p>''
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountFailedJobsTotals AS VARCHAR(5))+'') Failed Job warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountFailedJobsTotals
		END
	END
	
	--Populate Advisory header 
	IF @WarningLevel = 2 
	BEGIN 
		IF @BodyFailedJobsTotals LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountFailedJobsTotals = (LEN(@BodyFailedJobsTotals) - LEN(REPLACE(@BodyFailedJobsTotals,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountFailedJobsTotals AS VARCHAR(5))+'') Failed Job warnings</font><p>''
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountFailedJobsTotals AS VARCHAR(5))+'') Failed Job warnings <b>(Data collection out of Date)</b></font><p>''  		
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountFailedJobsTotals
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyFailedJobsTotals LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountFailedJobsTotals = (LEN(@BodyFailedJobsTotals) - LEN(REPLACE(@BodyFailedJobsTotals,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountFailedJobsTotals AS VARCHAR(5))+'') Failed Job warnings</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountFailedJobsTotals AS VARCHAR(5))+'') Failed Job warnings <b>(Data collection out of Date)</b></font><p>''  
			END
		END
	
	END

END


IF @FailedLoginsCheck = 1
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''FailedLoginsCheck'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @InfoHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;
	
	DECLARE @BodyLoginAttempts VARCHAR(MAX)
	DECLARE @TableHeadLoginAttempts VARCHAR(1000)
	DECLARE @CountLoginAttempts INT

	SET @TableHeadLoginAttempts = ''
	<b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''FailedLogin''+''"></a>Failed Login Attempts in the last 24hrs</b>
    <br> <table cellpadding=0 cellspacing=0 border=0>
    <tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Username</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Attempts</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Last Failed Attempt</b></td> 
	<td bgcolor=''+@TableHeaderColour+''><b>Last Error</b></td>
	'';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[LoginAttempts]
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyLoginAttempts = 
		(SELECT
		CASE 
			WHEN @WarningLevel IS NULL THEN @InfoHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''',+
		Username AS ''td'','''',+
		Attempts AS ''td'','''',+
		CONVERT(VARCHAR(17),LastErrorDate,113) AS ''td'','''',+
		LastError AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[LoginAttempts]
		WHERE Servername = @Serverlist
		AND Username != ''No Failed Logins present''
		FOR XML PATH(''tr''),ELEMENTS)

		IF @BodyLoginAttempts IS NULL
		BEGIN 
			SET @BodyLoginAttempts = (SELECT
			''#FFFFFF'' AS [@bgcolor],
			@Serverlist AS ''td'','''',+
			''No Failed Logins present'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'','''',+
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS)
		END
	END
	ELSE
	BEGIN 
		SET @BodyLoginAttempts = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @InfoHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Serverlist AS ''td'','''',+
		''Data Collection out of date'' AS ''td'','''',+
		''N/A'' AS ''td'','''',+
		''N/A'' AS ''td'','''',+
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyLoginAttempts LIKE ''%No Failed Logins present%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadLoginAttempts, '''') + ISNULL(@BodyLoginAttempts, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	END

	--Populate Alert header
	IF @WarningLevel = 1
	BEGIN 
		IF @BodyLoginAttempts LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountLoginAttempts = (LEN(@BodyLoginAttempts) - LEN(REPLACE(@BodyLoginAttempts,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedLogin''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLoginAttempts AS VARCHAR(5))+'') Failed Login warnings</font><p>''
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedLogin''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLoginAttempts AS VARCHAR(5))+'') Failed Login warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountLoginAttempts
		END
	END
	
	--Populate Advisory header 
	IF @WarningLevel = 2 
	BEGIN 
		IF @BodyLoginAttempts LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountLoginAttempts = (LEN(@BodyLoginAttempts) - LEN(REPLACE(@BodyLoginAttempts,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedLogin''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLoginAttempts AS VARCHAR(5))+'') Failed Login warnings</font><p>''
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedLogin''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLoginAttempts AS VARCHAR(5))+'') Failed Login warnings <b>(Data collection out of Date)</b></font><p>'' 
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountLoginAttempts
		END
	END
	
	--Populate Info header (Default Warning Level)
	IF (@WarningLevel = 3 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyLoginAttempts LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountLoginAttempts = (LEN(@BodyLoginAttempts) - LEN(REPLACE(@BodyLoginAttempts,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedLogin''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLoginAttempts AS VARCHAR(5))+'') Failed Login warnings</font><p>''
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedLogin''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountLoginAttempts AS VARCHAR(5))+'') Failed Login warnings <b>(Data collection out of Date)</b></font><p>'' 
			END
		END
	
	END

END


--Catalogue Logins Module
IF @CatalogueInstalled = 1 
BEGIN 

	--Check if the Catalogue module is enabled
	SET @CatalogueModulename = ''Logins''

	EXEC sp_executesql N''SELECT @CatalogueModuleEnabled = [Active] FROM [Catalogue].[ConfigModules] WHERE [ModuleName] = @CatalogueModulename'',
	N''@CatalogueModuleEnabled BIT OUTPUT, @CatalogueModulename VARCHAR(20)'',
	@CatalogueModuleEnabled = @CatalogueModuleEnabled OUTPUT,
	@CatalogueModulename = @CatalogueModulename;

	--Check if the Inspector is enabled to report on the Catalogue module
	SET @CatalogueModuleReport = (SELECT [Enabled] FROM [Inspector].[CatalogueModules] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''CatalogueMissingLogins'')

	IF (@CatalogueModuleEnabled = 1 AND @CatalogueModuleReport = 1)
	BEGIN 
		IF @CatalogueLastExecution >= DATEADD(DAY,-1,@ReportStart)
		BEGIN

			SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''CatalogueMissingLogins'')
			
			SET @CatalogueHtml = NULL;
			SET @CountCatalogueWarnings = 0;

			SET @CollectionOutOfDate = 0			
			SET @WarningLevelFontColour = CASE 
											WHEN @WarningLevel IS NULL THEN @InfoHighlight
											WHEN @WarningLevel = 1 THEN @RedHighlight
											WHEN @WarningLevel = 2 THEN @YellowHighlight
											WHEN @WarningLevel = 3 THEN @InfoHighlight 
										 END;
			
			EXEC [Inspector].[CatalogueMissingLogins] 
			@Servername = @Serverlist,
			@TableHeaderColour = @TableHeaderColour,
			@WarningLevelFontColour = @WarningLevelFontColour,
			@HtmlOutput = @CatalogueHtml OUTPUT;
			
			IF @CatalogueHtml IS NOT NULL
			BEGIN 
						
				--Append html table to the report
				SELECT  @EmailBody = @EmailBody + @CatalogueHtml + ''<p><BR><p>'' 
			
				--Populate Alert header
				IF @WarningLevel = 1
				BEGIN 
					IF @CatalogueHtml LIKE ''%''+@RedHighlight+''%''
					BEGIN
						SET @CountCatalogueWarnings = (LEN(@CatalogueHtml) - LEN(REPLACE(@CatalogueHtml,@RedHighlight, '''')))/LEN(@RedHighlight)
						SELECT @AlertHeader = @AlertHeader + 
						CASE 
							WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''MissingLogins''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountCatalogueWarnings AS VARCHAR(5))+'') Missing Logins</font><p>''
							WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''MissingLogins''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountCatalogueWarnings AS VARCHAR(5))+'') Missing Login warnings <b>(Data collection out of Date)</b></font><p>''  
						END
						SET @Importance = ''High'' 
						SET @TotalWarningCount = @TotalWarningCount + @CountCatalogueWarnings
					END
				END
				
				--Populate Advisory header 
				IF @WarningLevel = 2 
				BEGIN 
					IF @CatalogueHtml LIKE ''%''+@YellowHighlight+''%''
					BEGIN
						SET @CountCatalogueWarnings = (LEN(@CatalogueHtml) - LEN(REPLACE(@CatalogueHtml,@YellowHighlight, '''')))/LEN(@YellowHighlight)
						SELECT @AdvisoryHeader = @AdvisoryHeader + 
						CASE 
							WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''MissingLogins''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountCatalogueWarnings AS VARCHAR(5))+'') Missing Logins</font><p>''
							WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''MissingLogins''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountCatalogueWarnings AS VARCHAR(5))+'') Missing Login warnings <b>(Data collection out of Date)</b></font><p>''  
						END
						SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountCatalogueWarnings
					END
				END
				
				--Populate Info header (Default Warning Level)
				IF (@WarningLevel = 3 OR @WarningLevel IS NULL) 
				BEGIN 
					IF @CatalogueHtml LIKE ''%''+@InfoHighlight+''%''
					BEGIN 
						SET @CountCatalogueWarnings = (LEN(@CatalogueHtml) - LEN(REPLACE(@CatalogueHtml,@InfoHighlight, '''')))/LEN(@InfoHighlight)
						SELECT @InfoHeader = @InfoHeader + 
						CASE 
							WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''MissingLogins''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountCatalogueWarnings AS VARCHAR(5))+'') Missing Logins</font><p>''
							WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''MissingLogins''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountCatalogueWarnings AS VARCHAR(5))+'') Missing Login warnings <b>(Data collection out of Date)</b></font><p>''  
						END
					END
				
				END
						
			END 

		END
	END

END


IF @JobOwnerCheck = 1 
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''JobOwnerCheck'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;
	
	DECLARE @AgentJobOwnerExclusions VARCHAR(255) = (SELECT REPLACE([Value],'' '' ,'''') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''AgentJobOwnerExclusions'')
	DECLARE @BodyJobOwner VARCHAR(MAX)
	DECLARE @TableHeadJobOwner VARCHAR(1000)
	DECLARE @CountJobOwner INT
	
	SET @TableHeadJobOwner = ''
	<b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''"></a>Agent Jobs where the owner is not ''+ISNULL(REPLACE(REPLACE(@AgentJobOwnerExclusions,'' '',''''),'','','', ''),''[N/A - No Exclusions Set]'')+''</b>
	<br> <table cellpadding=0 cellspacing=0 border=0> 
	<tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Job ID</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Job name</b></td>
	'';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[JobOwner] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyJobOwner = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''',+
		Job_ID AS ''td'','''', + 
		Jobname AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[JobOwner]
		WHERE Servername = @Serverlist
		AND Jobname != ''No Job Owner issues present''
		FOR XML PATH(''tr''),ELEMENTS);

		IF @BodyJobOwner IS NULL
		BEGIN
			SET @BodyJobOwner = 
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			@Serverlist AS ''td'','''',+
			''N/A'' AS ''td'','''', + 
			''No Job Owner issues present'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
    BEGIN 
		SET @BodyJobOwner = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Serverlist AS ''td'','''',+
		''N/A'' AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
    END

	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyJobOwner LIKE ''%No Job Owner issues present%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadJobOwner, '''') + ISNULL(@BodyJobOwner, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	END

	--Populate Alert header
	IF @WarningLevel = 1 
	BEGIN 
		IF @BodyJobOwner LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountJobOwner = (LEN(@BodyJobOwner) - LEN(REPLACE(@BodyJobOwner,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountJobOwner AS VARCHAR(5))+'') Agent jobs where the Owner is not ''+ISNULL(REPLACE(REPLACE(@AgentJobOwnerExclusions,'' '',''''),'','','', ''),''[N/A - No Exclusions Set]'')+''</font><p>'' 
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountJobOwner AS VARCHAR(5))+'') Agent Job Owner warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountJobOwner
		END
	END
	
	--Populate Advisory header (Default Warning Level) 
	IF (@WarningLevel = 2 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyJobOwner LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountJobOwner = (LEN(@BodyJobOwner) - LEN(REPLACE(@BodyJobOwner,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountJobOwner AS VARCHAR(5))+'') Agent jobs where the Owner is not ''+ISNULL(REPLACE(REPLACE(@AgentJobOwnerExclusions,'' '',''''),'','','', ''),''[N/A - No Exclusions Set]'')+''</font><p>'' 
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountJobOwner AS VARCHAR(5))+'') Agent Job Owner warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountJobOwner
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyJobOwner LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountJobOwner = (LEN(@BodyJobOwner) - LEN(REPLACE(@BodyJobOwner,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountJobOwner AS VARCHAR(5))+'') Agent jobs where the Owner is not ''+ISNULL(REPLACE(REPLACE(@AgentJobOwnerExclusions,'' '',''''),'','','', ''),''[N/A - No Exclusions Set]'')+''</font><p>'' 
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountJobOwner AS VARCHAR(5))+'') Agent Job Owner warnings <b>(Data collection out of Date)</b></font><p>''  
			END
		END
	
	END

END



IF @TopFiveDatabaseSizeCheck = 1 
BEGIN
	--Excluded from Warning level control
	DECLARE @BodyTopFiveDatabases VARCHAR(MAX)
	DECLARE @TableHeadTopFiveDatabases VARCHAR(1000)

	SET @TableHeadTopFiveDatabases = ''
    <b>Top 5 Databases by size</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Total size(MB)</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[TopFiveDatabases] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
	SET @BodyTopFiveDatabases = 
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		Servername AS ''td'','''', + 
		Databasename AS ''td'','''', + 
		TotalSize_MB AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[TopFiveDatabases] 
		WHERE Servername = @Serverlist
		FOR XML PATH(''tr''),ELEMENTS);
	END
	ELSE
	BEGIN
		SET @BodyTopFiveDatabases = 
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		@Serverlist AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);
	END

	--Append html table to the report
	SELECT @EmailBody = @EmailBody + ISNULL(@TableHeadTopFiveDatabases, '''') + ISNULL(@BodyTopFiveDatabases, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

END
	
	
IF @DatabaseFileCheck = 1 
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''DatabaseFileCheck'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @RedHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;

	--Check Data and log files are on the correct drives Variables
	DECLARE @BodyDatabaseFiles VARCHAR(MAX)
	DECLARE @TableHeadDatabaseFiles VARCHAR(1000)
	DECLARE @CountDatabaseFiles INT

	SET @TableHeadDatabaseFiles = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''"></a>Data or Log files on incorrect drives</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>File type</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>File path</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseFiles] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyDatabaseFiles = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @RedHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''', +
		Databasename AS ''td'','''', + 
		FileType AS ''td'','''', +
		FilePath AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseFiles]
		WHERE Servername = @Serverlist
		AND Databasename != ''No Database File issues present''
		FOR XML PATH(''tr''),ELEMENTS);


		IF @BodyDatabaseFiles IS NULL 
		BEGIN
			SET @BodyDatabaseFiles = 
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			@Serverlist AS ''td'','''', +
			''No Database File issues present'' AS ''td'','''', + 
			''N/A'' AS ''td'','''', +
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN 
		SET @BodyDatabaseFiles = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @RedHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Serverlist AS ''td'','''', +
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'','''', +
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyDatabaseFiles LIKE ''%No Database File issues present%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadDatabaseFiles, '''') + ISNULL(@BodyDatabaseFiles, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>''
	END

	--Populate Alert header (Default Warning Level)
	IF (@WarningLevel = 1 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyDatabaseFiles LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountDatabaseFiles = (LEN(@BodyDatabaseFiles) - LEN(REPLACE(@BodyDatabaseFiles,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseFiles AS VARCHAR(5))+'') Data or Log files on incorrect drives</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseFiles AS VARCHAR(5))+'') Data or Log files on incorrect drives <b>(Data collection out of Date)</b></font><p>''   
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountDatabaseFiles
		END
	END
	
	--Populate Advisory header 
	IF @WarningLevel = 2 
	BEGIN 
		IF @BodyDatabaseFiles LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountDatabaseFiles = (LEN(@BodyDatabaseFiles) - LEN(REPLACE(@BodyDatabaseFiles,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseFiles AS VARCHAR(5))+'') Data or Log files on incorrect drives</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseFiles AS VARCHAR(5))+'') Data or Log files on incorrect drives <b>(Data collection out of Date)</b></font><p>''   
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountDatabaseFiles
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyDatabaseFiles LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountDatabaseFiles = (LEN(@BodyDatabaseFiles) - LEN(REPLACE(@BodyDatabaseFiles,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseFiles AS VARCHAR(5))+'') Data or Log files on incorrect drives</font><p>''  
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDatabaseFiles AS VARCHAR(5))+'') Data or Log files on incorrect drives <b>(Data collection out of Date)</b></font><p>''   
			END
		END
	
	END

END


IF @BackupsCheck = 1 
BEGIN
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
	backup_preference NVARCHAR(60)
	);

	DECLARE @BodyBackupsReport VARCHAR(MAX)
	DECLARE @TableHeadBackupsReport VARCHAR(1000)
	DECLARE @CountBackupsReport INT

	SET @TableHeadBackupsReport = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''Backup''+''"></a>The following Databases are missing database backups:</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Servername</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>AG name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Last Full</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Last Diff</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Last Log</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Full Recovery</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>AG Backup Pref</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Preferred Servers</b></td>
    '';


	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupsCheck] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
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
		  
		  
		INSERT INTO #Validations (Databasename,AGname,FullState,DiffState,LogState,IsFullRecovery,Serverlist,primary_replica,backup_preference)
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
					WHEN ([LastDiff] >= ''19000101'' AND [LastDiff] < DATEADD(DAY,-@DiffBackupThreshold,[Log_Date])  OR [LastDiff] IS NULL) AND IsSystemDB = 0 THEN ISNULL(CONVERT(VARCHAR(17),[LastDiff],113),''More then ''+CAST(@DiffBackupThreshold AS VARCHAR(3))+'' days ago'')
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
		backup_preference
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
		  
		  
		SET @BodyBackupsReport = (
		SELECT 
		@RedHighlight [@bgcolor], 
		@Serverlist AS ''td'','''', + 
		Databasename AS ''td'','''', +
		AGname AS ''td'','''', +
		FullState AS ''td'','''', +
		DiffState AS ''td'','''', +
		LogState AS ''td'','''', +
		IsFullRecovery AS ''td'','''', +
		CASE 
			WHEN backup_preference = ''PRIMARY'' THEN ''Primary only''
			WHEN backup_preference = ''SECONDARY'' THEN ''Prefer secondary''
			WHEN backup_preference = ''SECONDARY_ONLY'' THEN ''Secondary only''
			WHEN backup_preference = ''NONE'' THEN ''Any replica''
			WHEN backup_preference = ''NON AG'' THEN ''N/A''
			ELSE backup_preference  
		END AS ''td'','''', +
		CASE 
			WHEN backup_preference = ''SECONDARY_ONLY'' THEN REPLACE(REPLACE(Serverlist,'', ''+@Serverlist,''''),@Serverlist+'', '','''')
			ELSE Serverlist
		END AS ''td'',''''
		FROM #Validations
		WHERE ([FullState] != ''OK'' OR ([DiffState] != ''OK'' AND [DiffState] != ''N/A'') OR ([LogState] != ''OK'' AND [LogState] != ''N/A''))
		AND Serverlist like ''%''+@Serverlist+''%''
		ORDER BY Databasename ASC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		IF @BodyBackupsReport IS NULL
		BEGIN
			SET @BodyBackupsReport = (
			SELECT 
			''#FFFFFF'' [@bgcolor], 
			@Serverlist AS ''td'','''', + 
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

		--Count Backup Warnings
		SET @CountBackupsReport = (LEN(@BodyBackupsReport) - LEN(REPLACE(@BodyBackupsReport,@RedHighlight, '''')))/LEN(@RedHighlight)
		
		--Append html table to the report
		SELECT  @EmailBody = @EmailBody + 
		CASE 
			WHEN @BodyBackupsReport LIKE ''%No backup issues present%'' AND @NoClutter = 1 THEN ''''
			ELSE ISNULL(@TableHeadBackupsReport, '''') + ISNULL(@BodyBackupsReport, '''') +''</table><p><font style="color: Black; background-color: ''+@RedHighlight+''">Warning Highlight Thresholds:</font><br>
		Last FULL backup older than <b>''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Day/s</b><br>
		''+ CASE WHEN @DiffBackupThreshold IS NOT NULL THEN ''Last DIFF backup older than <b>''+ CAST(@DiffBackupThreshold AS VARCHAR(3))+'' Day/s</b><br>'' ELSE ''DIFF backups excluded from check</b><br>'' END +
		''Last Log backup older than <b>''+CAST(@LogBackupThreshold AS VARCHAR(3))+'' Minute/s</b><br>
		Databases Excluded for this server: <b>''+(SELECT CAST(COUNT(Servername) AS VARCHAR(6)) FROM [Inspector].[BackupsCheckExcludes] WHERE Servername = @Serverlist AND ([SuppressUntil] IS NULL OR [SuppressUntil] >= GETDATE()))+''</b></p></b>''
		+ ISNULL(REPLACE(@TableTail,''</table>'',''''),'''') +''<p><BR><p>''
		END


		IF @BodyBackupsReport LIKE ''%''+@RedHighlight+''%''		
		BEGIN 
			SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Backup''+''">''+@Serverlist+''</a><font color= ''+@RedHighlight+''>  - has (''+CAST(@CountBackupsReport AS VARCHAR(5))+'') Database Backup issues</font><p>''   
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountBackupsReport
		END

	END
	ELSE 
	BEGIN
		SET @BodyBackupsReport = (
		SELECT 
		@RedHighlight [@bgcolor],
		@Serverlist AS ''td'','''', +  
		''Data Collection out of date''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'','''', +
		''N/A''  AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS)

		--Count Backup Warnings
		SET @CountBackupsReport = (LEN(@BodyBackupsReport) - LEN(REPLACE(@BodyBackupsReport,@RedHighlight, '''')))/LEN(@RedHighlight)
		
		--Append html table to the report
		SELECT @EmailBody = @EmailBody + ISNULL(@TableHeadBackupsReport, '''') + ISNULL(@BodyBackupsReport, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

		IF @BodyBackupsReport LIKE ''%''+@RedHighlight+''%''		
		BEGIN 
			SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Backup''+''">''+@Serverlist+''</a><font color= ''+@RedHighlight+''>  - has (''+CAST(@CountBackupsReport AS VARCHAR(5))+'') Database Backup issues <b>(Data collection out of Date)</b></font><p>''   
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountBackupsReport
		END
	END

END


IF @DatabaseOwnershipCheck = 1 
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''DatabaseOwnershipCheck'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;
	
	DECLARE @DatabaseOwnerExclusions VARCHAR(255) = (SELECT REPLACE([Value],'' '' ,'''') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DatabaseOwnerExclusions'')
	
	DECLARE @BodyDBOwner VARCHAR(MAX)
	DECLARE @TableHeadDBOwner VARCHAR(1000)
	DECLARE @CountDBOwner INT

	SET @DatabaseOwnerExclusions = REPLACE(REPLACE(@DatabaseOwnerExclusions,'' '',''''),'','','', '')

	SET @TableHeadDBOwner = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''"></a>The following Databases have an owner that is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+'':</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>AG name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Owner</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseOwnership]
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyDBOwner = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		[Servername] AS ''td'','''', + 
		[AGname] AS ''td'','''', + 
		[Database_name] AS ''td'','''', + 
		[Owner] AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseOwnership]
		WHERE [Servername] = @Serverlist
		AND [Database_name] != ''No Database Ownership issues present''
		ORDER BY [Database_name]
		FOR XML PATH(''tr''),ELEMENTS);

		IF @BodyDBOwner IS NULL
		BEGIN
			SET @BodyDBOwner = 
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
		SET @BodyDBOwner = 
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
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

	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyDBOwner LIKE ''%No Database Ownership issues present%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadDBOwner, '''') + ISNULL(@BodyDBOwner, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	END

	--Populate Alert header
	IF @WarningLevel = 1
	BEGIN 
		IF @BodyDBOwner LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountDBOwner = (LEN(@BodyDBOwner) - LEN(REPLACE(@BodyDBOwner,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBOwner AS VARCHAR(5))+'') Databases where the Owner is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+''</font><p>''
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBOwner AS VARCHAR(5))+'') Databases where the Owner is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+'' <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountDBOwner
		END
	END
	
	--Populate Advisory header (Default Warning Level) 
	IF (@WarningLevel = 2 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyDBOwner LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountDBOwner = (LEN(@BodyDBOwner) - LEN(REPLACE(@BodyDBOwner,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBOwner AS VARCHAR(5))+'') Databases where the Owner is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+''</font><p>''
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBOwner AS VARCHAR(5))+'') Databases where the Owner is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+'' <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountDBOwner
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyDBOwner LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountDBOwner = (LEN(@BodyDBOwner) - LEN(REPLACE(@BodyDBOwner,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBOwner AS VARCHAR(5))+'') Databases where the Owner is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+''</font><p>''
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBOwner AS VARCHAR(5))+'') Databases where the Owner is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+'' <b>(Data collection out of Date)</b></font><p>''  
			END
		END
	
	END

END



IF @BackupSizesCheck = 1 
BEGIN
--Excluded from Warning level control
	DECLARE @BodyBackupsByDay VARCHAR(MAX)
	DECLARE @TableHeadBackupsByDay VARCHAR(1000)

	SET @TableHeadBackupsByDay = ''
    <b>Backup Sizes by Day for server:</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Day Of Week</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Total Backup Size GB</b></td>
    '';

	
	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupSizesByDay]
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyBackupsByDay =   
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		[DayOfWeek] AS ''td'','''', + 
		[TotalBackupSize_GB] AS ''td'','''' 
		FROM (
		SELECT 
		[DayOfWeek],
		[CastedDate],
		CAST(SUM(((TotalSizeInBytes)/1024)/1024)/1024 AS DECIMAL (10,1)) AS [TotalBackupSize_GB]
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupSizesByDay]
		WHERE Servername = @Serverlist
		AND Log_Date IS NOT NULL
		GROUP BY [DayOfWeek],[CastedDate]
		) BackupSizesByDay
		ORDER BY CastedDate ASC
		FOR XML PATH(''tr''),ELEMENTS);  	 
	END
	ELSE 
	BEGIN  
		IF EXISTS (SELECT Log_Date FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupSizesByDay] WHERE Servername = @Serverlist AND Log_Date IS NULL) 
		BEGIN
			SET @BodyBackupsByDay =  
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			''No Backups for the past 7 days'' AS ''td'','''', + 
			''N/A'' AS ''td'','''' 
			FOR XML PATH(''tr''),ELEMENTS);
		END
		
		IF @BodyBackupsByDay IS NULL
		BEGIN
			SET @BodyBackupsByDay =  
			(SELECT 
			''#FFFFFF'' AS [@bgcolor],
			''Data collection out of Date'' AS ''td'','''', + 
			''N/A'' AS ''td'','''' 
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END

	--Append html table to the report	  	  
	SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadBackupsByDay, '''') + ISNULL(@BodyBackupsByDay, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
END


IF @ADHocDatabaseCreationCheck = 1 
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''ADHocDatabaseCreationCheck'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;

	DECLARE @BodyAdHocDatabases VARCHAR(MAX)
	DECLARE @TableHeadAdHocDatabases VARCHAR(1000)
	DECLARE @CountAdHocDatabases INT

	SET @TableHeadAdHocDatabases = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''"></a>Potential Ad hoc database creations in the last 7 days</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Create date</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ADHocDatabaseCreations] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyAdHocDatabases =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Databasename AS ''td'','''', + 
		CONVERT(VARCHAR(17),Create_Date,113) AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ADHocDatabaseCreations]
		WHERE Servername = @Serverlist
		AND Databasename != ''No Ad hoc database creations present''
		AND Databasename NOT IN (
				SELECT Databasename 
				FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ADHocDatabaseSupression] Suppressed
				WHERE Servername = @Serverlist 
				AND Suppressed.Suppress = 1)
		ORDER BY Create_Date ASC
		FOR XML PATH(''tr''),ELEMENTS);

		IF @BodyAdHocDatabases IS NULL
		BEGIN 
			SET @BodyAdHocDatabases =
			(SELECT 
			''#FFFFFF''  AS [@bgcolor],
			''No Ad hoc database creations present'' AS ''td'','''', + 
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN
		SET @BodyAdHocDatabases =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyAdHocDatabases LIKE ''%No Ad hoc database creations present%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadAdHocDatabases, '''') +ISNULL(@BodyAdHocDatabases, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>''
	END

	--Populate Alert header
	IF @WarningLevel = 1
	BEGIN 
		IF @BodyAdHocDatabases LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountAdHocDatabases = (LEN(@BodyAdHocDatabases) - LEN(REPLACE(@BodyAdHocDatabases,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAdHocDatabases AS VARCHAR(5))+'') Potential AD Hoc Database creations in the last 7 days</font><p>''     
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAdHocDatabases AS VARCHAR(5))+'') Potential AD Hoc Database creations <b>(Data collection out of Date)</b></font><p>'' 
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountAdHocDatabases
		END
	END
	
	--Populate Advisory header (Default Warning Level)
	IF (@WarningLevel = 2 OR @WarningLevel IS NULL) 
	BEGIN 
		IF @BodyAdHocDatabases LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountAdHocDatabases = (LEN(@BodyAdHocDatabases) - LEN(REPLACE(@BodyAdHocDatabases,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAdHocDatabases AS VARCHAR(5))+'') Potential AD Hoc Database creations in the last 7 days</font><p>''     
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAdHocDatabases AS VARCHAR(5))+'') Potential AD Hoc Database creations <b>(Data collection out of Date)</b></font><p>'' 
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountAdHocDatabases
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyAdHocDatabases LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountAdHocDatabases = (LEN(@BodyAdHocDatabases) - LEN(REPLACE(@BodyAdHocDatabases,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAdHocDatabases AS VARCHAR(5))+'') Potential AD Hoc Database creations in the last 7 days</font><p>''     
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountAdHocDatabases AS VARCHAR(5))+'') Potential AD Hoc Database creations <b>(Data collection out of Date)</b></font><p>'' 
			END
		END
	
	END

END
	     


IF @DatabaseSettings  = 1
BEGIN 

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''DatabaseSettings'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;

	DECLARE @BodyDatabaseSettings VARCHAR(MAX) = ''''
	DECLARE @TableHeadDatabaseSettings VARCHAR(1000)
	DECLARE @CountDBSettings INT
	
	SET @TableHeadDatabaseSettings = ''
    <b>Database Settings</b>
    <br> 
    <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td colspan = "2" align="Center" bgcolor=''+@TableHeaderColour+''><b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''DBSettings''+''"></a>Database Settings</b></td>
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Collation</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Total</b></td></tr>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		WHERE Servername = @Serverlist 
		AND Setting = ''Collation_name''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @BodyDatabaseSettings  = @BodyDatabaseSettings + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Auto Close</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL AND [Description] = ''Enabled'' THEN @YellowHighlight
			WHEN @WarningLevel = 1 AND [Description] = ''Enabled'' THEN @RedHighlight
			WHEN @WarningLevel = 2 AND [Description] = ''Enabled'' THEN @YellowHighlight
			WHEN @WarningLevel = 3 AND [Description] = ''Enabled'' THEN @InfoHighlight
			ELSE ''#FFFFFF''
		END AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		WHERE Servername = @Serverlist 
		AND Setting = ''is_auto_close_on''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @BodyDatabaseSettings  = @BodyDatabaseSettings + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Auto Shrink</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		(SELECT
		CASE 
			WHEN @WarningLevel IS NULL AND [Description] = ''Enabled'' THEN @YellowHighlight
			WHEN @WarningLevel = 1 AND [Description] = ''Enabled'' THEN @RedHighlight
			WHEN @WarningLevel = 2 AND [Description] = ''Enabled'' THEN @YellowHighlight
			WHEN @WarningLevel = 3 AND [Description] = ''Enabled'' THEN @InfoHighlight
			ELSE ''#FFFFFF''
		END AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		WHERE Servername = @Serverlist 
		AND Setting = ''is_auto_shrink_on''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @BodyDatabaseSettings  = @BodyDatabaseSettings + ''
		<tr>
		<td bgcolor=''+@TableHeaderColour+''><b>Auto Update Stats</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL AND [Description] = ''Disabled'' THEN @YellowHighlight
			WHEN @WarningLevel = 1 AND [Description] = ''Disabled'' THEN @RedHighlight
			WHEN @WarningLevel = 2 AND [Description] = ''Disabled'' THEN @YellowHighlight
			WHEN @WarningLevel = 3 AND [Description] = ''Disabled'' THEN @InfoHighlight
			ELSE ''#FFFFFF''
		END AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'','''' 
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		WHERE Servername = @Serverlist 
		AND Setting = ''is_auto_update_stats_on''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @BodyDatabaseSettings  = @BodyDatabaseSettings + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Read Only</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],		  
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		WHERE Servername = @Serverlist 
		AND Setting = ''is_read_only''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @BodyDatabaseSettings  = @BodyDatabaseSettings + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>User Access</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		(SELECT 
		''#FFFFFF'' AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		WHERE Servername = @Serverlist 
		AND Setting = ''user_access_desc''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @BodyDatabaseSettings  = @BodyDatabaseSettings + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Compatibility Level</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		(SELECT  
		''#FFFFFF'' AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		WHERE Servername = @Serverlist 
		AND Setting = ''compatibility_level''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
		  
		SELECT @BodyDatabaseSettings  = @BodyDatabaseSettings + ''
		<tr> 
		<td bgcolor=''+@TableHeaderColour+''><b>Recovery Model</b></td>
		<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td>
		</tr>
		'';
		  
		SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		(SELECT  
		''#FFFFFF'' AS [@bgcolor],
		[Description]  AS ''td'','''', + 
		Total   AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		WHERE Servername = @Serverlist 
		AND Setting = ''recovery_model_desc''
		ORDER BY Total DESC
		FOR XML PATH(''tr''),ELEMENTS);
	END
	ELSE
	BEGIN
		SET @BodyDatabaseSettings =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @RedHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		''Data Collection out of date''  AS ''td'','''', + 
		''N/A''   AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;

	END

	--Append html table to the report
	SELECT @EmailBody = @EmailBody + ISNULL(@TableHeadDatabaseSettings,'''') + ISNULL(@BodyDatabaseSettings, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

	--Populate Alert header (Default Warning Level)
	IF (@WarningLevel = 1 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyDatabaseSettings LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountDBSettings = (LEN(@BodyDatabaseSettings) - LEN(REPLACE(@BodyDatabaseSettings,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBSettings AS VARCHAR(5))+'') Database Auto Close or Auto Shrink settings enabled or Auto Update Stats Disabled</font><p>''	
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBSettings AS VARCHAR(5))+'') Database setting warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountDBSettings
		END
	END
	
	--Populate Advisory header 
	IF @WarningLevel = 2 
	BEGIN 
		IF @BodyDatabaseSettings LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountDBSettings = (LEN(@BodyDatabaseSettings) - LEN(REPLACE(@BodyDatabaseSettings,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBSettings AS VARCHAR(5))+'') Database Auto Close or Auto Shrink settings enabled or Auto Update Stats Disabled</font><p>''	
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBSettings AS VARCHAR(5))+'') Database setting warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountDBSettings
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyDatabaseSettings LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountDBSettings = (LEN(@BodyDatabaseSettings) - LEN(REPLACE(@BodyDatabaseSettings,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBSettings AS VARCHAR(5))+'') Database Auto Close or Auto Shrink settings enabled or Auto Update Stats Disabled</font><p>''	
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountDBSettings AS VARCHAR(5))+'') Database setting warnings <b>(Data collection out of Date)</b></font><p>''  
			END
		END
	
	END

END


IF @ServerSettings  = 1
BEGIN 

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''ServerSettings'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;
	
	DECLARE @BodyServerSettings VARCHAR(MAX) = ''''
	DECLARE @TableHeadServerSettings VARCHAR(1000)
	DECLARE @CountServerSettings INT

	SET @TableHeadServerSettings = ''
    <b>Server Settings</b>
    <br> 
    <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td colspan = "2" align="Center" bgcolor=''+@TableHeaderColour+''><b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''ServerSettings''+''"></a>Server Settings</b></td>
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Collation</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Total</b></td></tr>
    '';
	
	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ServerSettings] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SELECT @BodyServerSettings = @BodyServerSettings +
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL 
			THEN CASE 
					WHEN [Setting] = ''cost threshold for parallelism'' AND [value_in_use] = 5 THEN @YellowHighlight
					WHEN [Setting] = ''max degree of parallelism'' AND [value_in_use] <= 1 THEN @YellowHighlight
					WHEN [Setting] = ''max server memory (MB)'' AND [value_in_use] = 2147483647 THEN @YellowHighlight
					ELSE ''#FFFFFF''
				 END
			WHEN @WarningLevel = 1
			THEN CASE 
					WHEN [Setting] = ''cost threshold for parallelism'' AND [value_in_use] = 5 THEN @RedHighlight
					WHEN [Setting] = ''max degree of parallelism'' AND [value_in_use] <= 1 THEN @RedHighlight
					WHEN [Setting] = ''max server memory (MB)'' AND [value_in_use] = 2147483647 THEN @RedHighlight
					ELSE ''#FFFFFF''
				 END
			WHEN @WarningLevel = 2 
			THEN CASE 
					WHEN [Setting] = ''cost threshold for parallelism'' AND [value_in_use] = 5 THEN @YellowHighlight
					WHEN [Setting] = ''max degree of parallelism'' AND [value_in_use] <= 1 THEN @YellowHighlight
					WHEN [Setting] = ''max server memory (MB)'' AND [value_in_use] = 2147483647 THEN @YellowHighlight
					ELSE ''#FFFFFF''
				 END
			WHEN @WarningLevel = 3 
			THEN CASE 
					WHEN [Setting] = ''cost threshold for parallelism'' AND [value_in_use] = 5 THEN @InfoHighlight
					WHEN [Setting] = ''max degree of parallelism'' AND [value_in_use] <= 1 THEN @InfoHighlight
					WHEN [Setting] = ''max server memory (MB)'' AND [value_in_use] = 2147483647 THEN @InfoHighlight
					ELSE ''#FFFFFF''
				 END
		ELSE ''#FFFFFF''		
		END AS [@bgcolor],
		[Setting]  AS ''td'','''', + 
		[value_in_use]   AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ServerSettings]
		WHERE Servername = @Serverlist
		ORDER BY [configuration_id] ASC
		FOR XML PATH(''tr''),ELEMENTS);
	END
	ELSE
	BEGIN
		SET @BodyServerSettings =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @RedHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		''Data Collection out of date''  AS ''td'','''', + 
		''N/A''   AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	--Append html table to the report
	SELECT @EmailBody = @EmailBody + ISNULL(@TableHeadServerSettings,'''') + ISNULL(@BodyServerSettings, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

	--Populate Alert header
	IF @WarningLevel = 1
	BEGIN 
		IF @BodyServerSettings LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountServerSettings = (LEN(@BodyServerSettings) - LEN(REPLACE(@BodyServerSettings,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ServerSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountServerSettings AS VARCHAR(5))+'') Cost Threshold for parallelism, MAXDOP or Max Server memory set to default values</font><p>''	
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ServerSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountServerSettings AS VARCHAR(5))+'') Server Settings warnings <b>(Data collection out of Date)</b></font><p>''  
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountServerSettings
		END
	END
	
	--Populate Advisory header (Default Warning Level)
	IF (@WarningLevel = 2 OR @WarningLevel IS NULL)
	BEGIN 
		IF @BodyServerSettings LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountServerSettings = (LEN(@BodyServerSettings) - LEN(REPLACE(@BodyServerSettings,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ServerSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountServerSettings AS VARCHAR(5))+'') Cost Threshold for parallelism, MAXDOP or Max Server memory set to default values</font><p>''	
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ServerSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountServerSettings AS VARCHAR(5))+'') Server Settings warnings <b>(Data collection out of Date)</b></font><p>'' 
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountServerSettings
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyServerSettings LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountServerSettings = (LEN(@BodyServerSettings) - LEN(REPLACE(@BodyServerSettings,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ServerSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountServerSettings AS VARCHAR(5))+'') Cost Threshold for parallelism, MAXDOP or Max Server memory set to default values</font><p>''	
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ServerSettings''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountServerSettings AS VARCHAR(5))+'') Server Settings warnings <b>(Data collection out of Date)</b></font><p>'' 
			END
		END
	
	END

END


IF @UnusedLogshipConfig = 1 
BEGIN

	SET @CollectionOutOfDate = 0
	SET @WarningLevel = (SELECT [WarningLevel] FROM [Inspector].[ModuleWarningLevel] WHERE [ModuleConfig_Desc] = ISNULL(@ModuleDesc,@ModuleConfig) AND [Module] = ''UnusedLogshipConfig'')
	
	--If warning level is equal to 0 or greater than 3 set to the Inspector default value
	IF (@WarningLevel = 0 OR @WarningLevel > 3) BEGIN SET @WarningLevel = NULL END 
	
	SET @WarningLevelFontColour = CASE 
									WHEN @WarningLevel IS NULL THEN @YellowHighlight
									WHEN @WarningLevel = 1 THEN @RedHighlight
									WHEN @WarningLevel = 2 THEN @YellowHighlight
									WHEN @WarningLevel = 3 THEN @InfoHighlight 
								 END;

	DECLARE @BodyUnusedLogshipConfig VARCHAR(MAX)
	DECLARE @TableHeadUnusedLogshipConfig VARCHAR(1000)
	DECLARE @CountUnusedLogshipConfig INT

	SET @TableHeadUnusedLogshipConfig = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''UnusedLogshipConfig''+''"></a>Unused secondary log shipping config</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Servername</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>State</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ADHocDatabaseCreations] 
	WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)
	BEGIN
		SET @BodyUnusedLogshipConfig =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		Servername AS ''td'','''', + 
		Databasename AS ''td'','''', +
		Databasestate AS ''td'',''''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[UnusedLogshipConfig]
		WHERE Servername = @Serverlist
		ORDER BY [Databasename] ASC
		FOR XML PATH(''tr''),ELEMENTS);

		IF @BodyUnusedLogshipConfig IS NULL
		BEGIN 
			SET @BodyUnusedLogshipConfig =
			(SELECT 
			''#FFFFFF''  AS [@bgcolor],
			@Serverlist AS ''td'','''', + 
			''No unused log shipping config present'' AS ''td'','''', + 
			''N/A'' AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
	BEGIN
		SET @BodyUnusedLogshipConfig =
		(SELECT 
		CASE 
			WHEN @WarningLevel IS NULL THEN @YellowHighlight
			WHEN @WarningLevel = 1 THEN @RedHighlight
			WHEN @WarningLevel = 2 THEN @YellowHighlight
			WHEN @WarningLevel = 3 THEN @InfoHighlight
		END AS [@bgcolor],
		@Serverlist AS ''td'','''', + 
		''Data Collection out of date'' AS ''td'','''', + 
		''N/A'' AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);

		--Mark Collection as out of date
		SET @CollectionOutOfDate = 1;
	END

	--Append html table to the report
	SELECT  @EmailBody = @EmailBody + 
	CASE 
		WHEN @BodyUnusedLogshipConfig LIKE ''%No unused log shipping config present%'' AND @NoClutter = 1 THEN ''''
		ELSE ISNULL(@TableHeadUnusedLogshipConfig, '''') +ISNULL(@BodyUnusedLogshipConfig, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>''
	END

	--Populate Alert header
	IF @WarningLevel = 1
	BEGIN 
		IF @BodyUnusedLogshipConfig LIKE ''%''+@RedHighlight+''%''
		BEGIN
			SET @CountUnusedLogshipConfig = (LEN(@BodyUnusedLogshipConfig) - LEN(REPLACE(@BodyUnusedLogshipConfig,@RedHighlight, '''')))/LEN(@RedHighlight)
			SELECT @AlertHeader = @AlertHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''UnusedLogshipConfig''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountUnusedLogshipConfig AS VARCHAR(5))+'') Unused secondary log shipping configs present</font><p>''     
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''UnusedLogshipConfig''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountUnusedLogshipConfig AS VARCHAR(5))+'') Unused secondary log shipping config <b>(Data collection out of Date)</b></font><p>'' 
			END
			SET @Importance = ''High'' 
			SET @TotalWarningCount = @TotalWarningCount + @CountUnusedLogshipConfig
		END
	END
	
	--Populate Advisory header (Default Warning Level)
	IF (@WarningLevel = 2 OR @WarningLevel IS NULL) 
	BEGIN 
		IF @BodyUnusedLogshipConfig LIKE ''%''+@YellowHighlight+''%''
		BEGIN
			SET @CountUnusedLogshipConfig = (LEN(@BodyUnusedLogshipConfig) - LEN(REPLACE(@BodyUnusedLogshipConfig,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			SELECT @AdvisoryHeader = @AdvisoryHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''UnusedLogshipConfig''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountUnusedLogshipConfig AS VARCHAR(5))+'') Unused secondary log shipping configs present</font><p>''     
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''UnusedLogshipConfig''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountUnusedLogshipConfig AS VARCHAR(5))+'') Unused secondary log shipping config <b>(Data collection out of Date)</b></font><p>'' 
			END
			SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountUnusedLogshipConfig
		END
	END
	
	--Populate Info header 
	IF @WarningLevel = 3
	BEGIN 
		IF @BodyUnusedLogshipConfig LIKE ''%''+@InfoHighlight+''%''
		BEGIN 
			SET @CountUnusedLogshipConfig = (LEN(@BodyUnusedLogshipConfig) - LEN(REPLACE(@BodyUnusedLogshipConfig,@InfoHighlight, '''')))/LEN(@InfoHighlight)
			SELECT @InfoHeader = @InfoHeader + 
			CASE 
				WHEN @CollectionOutOfDate = 0 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''UnusedLogshipConfig''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountUnusedLogshipConfig AS VARCHAR(5))+'') Unused secondary log shipping configs present</font><p>''     
				WHEN @CollectionOutOfDate = 1 THEN ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''UnusedLogshipConfig''+''">''+@Serverlist+''</a><font color= "''+@WarningLevelFontColour+''">  - has (''+CAST(@CountUnusedLogshipConfig AS VARCHAR(5))+'') Unused secondary log shipping config <b>(Data collection out of Date)</b></font><p>'' 
			END
		END
	
	END

END


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
	SET @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+@Serverlist+''</a><font color=''+@YellowHighlight+''> - SQL ''+@VersionNo+''</font><p>'';
END

--If Edition has changed then create an entry in the advisory header
IF @Edition IS NOT NULL
BEGIN
	SET @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+@Serverlist+''</a><font color=''+@YellowHighlight+''> - SQL ''+@Edition+''</font><p>'';
END



IF @AlertHeader LIKE ''%''+@Serverlist+''%''
BEGIN
   SET @ServerSummaryFontColour = ''<font color= ''+@RedHighlight+''>''
END
ELSE 
IF @AdvisoryHeader LIKE ''%''+@Serverlist+''%''
BEGIN
	SET @ServerSummaryFontColour = ''<font color= ''+@YellowHighlight+''>''
END
ELSE
IF @InfoHeader LIKE ''%''+@Serverlist+''%''
BEGIN
	SET @ServerSummaryFontColour = ''<font color= "''+CASE WHEN @Theme = ''LIGHT'' THEN ''Black'' ELSE ''+@InfoHighlight+'' END+''">''
END
ELSE
BEGIN
   SET @ServerSummaryFontColour = ''<font color= "Green">''
END


--Evaluate server and colour code accordingly  
INSERT INTO #TrafficLightSummary ([SummaryHeader],[WarningPriority])
SELECT 
CASE
WHEN @ServerSummaryFontColour = ''<font color= ''+@RedHighlight+''>'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color=''+@RedHighlight+''>''+@Serverlist+''</font>]</a></b></font> ''
WHEN @ServerSummaryFontColour = ''<font color= ''+@YellowHighlight+''>'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color= ''+@YellowHighlight+''>''+@Serverlist+''</font>]</a></b></font> ''
WHEN @ServerSummaryFontColour = ''<font color= ''+@InfoHighlight+''>'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color="''+CASE WHEN @Theme = ''LIGHT'' THEN ''Black'' ELSE ''+@InfoHighlight+'' END+''">''+@Serverlist+''</font>]</a></b></font> ''
WHEN @ServerSummaryFontColour = ''<font color= "Green">'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color="Green">''+@Serverlist+''</font>]</a></b></font> ''
END,
CASE
WHEN @ServerSummaryFontColour = ''<font color= ''+@RedHighlight+''>'' THEN 1
WHEN @ServerSummaryFontColour = ''<font color= ''+@YellowHighlight+''>'' THEN 2
WHEN @ServerSummaryFontColour = ''<font color= "''+CASE WHEN @Theme = ''LIGHT'' THEN ''Black'' ELSE ''White'' END+''">'' THEN 3
WHEN @ServerSummaryFontColour = ''<font color= "Green">'' THEN 4
END

--Add Break to the end of the Server warning ready for the next
IF @AlertHeader LIKE ''%''+@Serverlist+''%'' BEGIN SET @AlertHeader = @AlertHeader + ''<BR></BR>'' END

--Add Break to the end of the Server Advisory Condition ready for the next
IF @AdvisoryHeader LIKE ''%''+@Serverlist+''%'' BEGIN SET @AdvisoryHeader = @AdvisoryHeader + ''<BR></BR>'' END

--Add Break to the end of the Server Info header ready for the next
IF @InfoHeader LIKE ''%''+@Serverlist+''%'' BEGIN SET @InfoHeader = @InfoHeader + ''<BR></BR>'' END


FETCH NEXT FROM ServerCur INTO @Serverlist,@ModuleConfig,@TableHeaderColour

END
CLOSE ServerCur
DEALLOCATE ServerCur




IF (@DatabaseGrowthCheck = 1 OR @DatabaseGrowthCheckRunEnabled = 1)
BEGIN
--Excluded from Warning level control	

	DECLARE @BodyGrowthCheck VARCHAR(MAX) = ''''
	DECLARE @TableHeadGrowthCheck VARCHAR(1000)
	DECLARE @CountGrowthCheck INT
	
	SET @TableHeadGrowthCheck = ''
    <b><A NAME = "GrowthEvents''+''Growth''+''"></a><p>The following Database files have grown more than ''+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' time/s in the past 24hours:
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Type desc</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>File ID</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Filename</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Pre Growth Size MB</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Growth Rate MB</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Growth Increments</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Post Growth Size MB</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Suggested Growth Rate MB</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Growth Rate trend (Last 5 days)</b></td>
    '';


	SELECT @BodyGrowthCheck = @BodyGrowthCheck + 
	(SELECT  
	CASE   
		WHEN [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay AND [GrowthIncrements] < @MAXDatabaseGrowthsAllowedPerDay THEN @YellowHighlight
		WHEN [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay AND [GrowthIncrements] >= @MAXDatabaseGrowthsAllowedPerDay THEN @RedHighlight
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
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseFileSizeHistory] LatestGrowths
	CROSS APPLY (SELECT STUFF((SELECT TOP 5 '', ['' 
		+ DATENAME(WEEKDAY,DATEADD(DAY,-1,[HistoricGrowths].[Log_Date])) 
		+ '' '' 
		+ CAST([GrowthRate_MB]*[GrowthIncrements] AS VARCHAR(10))
		+'' MB]''
		FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseFileSizeHistory] HistoricGrowths
		WHERE [LatestGrowths].[Servername] = [HistoricGrowths].[Servername]
		AND [LatestGrowths].[Database_id] = [HistoricGrowths].[Database_id]
		AND [LatestGrowths].[File_id] = [HistoricGrowths].[File_id]
		AND [HistoricGrowths].[Log_Date] >= DATEADD(DAY,-5,CAST(GETDATE() AS DATE))
		ORDER BY [HistoricGrowths].[Log_Date] DESC 
		FOR XML PATH('''')),1,1,'''')
		) AS [HistoricGrowths](LastFiveDaysGrowth)
	WHERE [Log_Date] >= CAST(GETDATE() AS DATE)
	AND [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay
	ORDER BY [Servername],[Database_name],[File_id]
	FOR XML PATH(''tr''),Elements);

	--Check for Database Growth Advisory Condition, then for any warnings 
	SELECT  @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server [ALL Servers]<b><p><BR>''+ISNULL(@TableHeadGrowthCheck, '''') + ISNULL(@BodyGrowthCheck, '''') + ''</table><p><font style="color: Black; background-color: ''+@YellowHighlight+''">Advisory Highlight</font> - More than ''+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' growth event/s in the past 24 hours<br>
		<font style="color: Black; background-color: ''+@RedHighlight+''">Warning Highlight</font> - ''+CAST(@MAXDatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' or more growth event/s in the past 24 hours</b></p>'' + ISNULL(REPLACE(@TableTail,''</table>'',''''),'''') + ''<p><BR><p>''
	IF @BodyGrowthCheck LIKE ''%''+@YellowHighlight+''%''	
	BEGIN
		SET @CountGrowthCheck = (LEN(@BodyGrowthCheck) - LEN(REPLACE(@BodyGrowthCheck,@YellowHighlight, '''')))/LEN(@YellowHighlight)
		SET @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+''GrowthEvents''+''Growth''+''">''+''Database Growth''+''</a><font color= ''+@YellowHighlight+''>  - (''+CAST(@CountGrowthCheck AS VARCHAR(5))+'') Database Growth events found which exceed your acceptable threshold of ''+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' Growth/s per 24hrs</font><p>''  
		SET @TotalAdvisoryCount = @TotalAdvisoryCount + @CountGrowthCheck 
	END

	IF @BodyGrowthCheck LIKE ''%''+@RedHighlight+''%''	  
	BEGIN 
		SET @CountGrowthCheck = (LEN(@BodyGrowthCheck) - LEN(REPLACE(@BodyGrowthCheck,@RedHighlight, '''')))/LEN(@RedHighlight)
		SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+''GrowthEvents''+''Growth''+''">''+''Database Growth''+''</a><font color= ''+@RedHighlight+''>  - (''+CAST(@CountGrowthCheck AS VARCHAR(5))+'') Database Growth events found which equal or exceed your Max Threshold of ''+CAST(@MAXDatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' Growths per 24hrs</font><p>''  
		SET @Importance = ''High'' 
		SET @TotalWarningCount = @TotalWarningCount + @CountGrowthCheck
	END

END


IF @BackupSpaceCheck = 1  
BEGIN
--Excluded from Warning level control
	DECLARE @BackupRoot VARCHAR(128)
	SET @BackupRoot = (SELECT NULLIF([Value],'''') From ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] where [Description] = ''BackupsPath'')

	DECLARE @BodyBackupSpace VARCHAR(MAX) = ''''
    DECLARE @TableHeadBackupSpace VARCHAR(1000)

	SET @TableHeadBackupSpace = ''
    <b><A NAME = "BackupStorage''+''BackupStorage''+''"></a><b>Backup space estimate for tonight (entire stack) versus free space checked against  [''+ISNULL(@BackupRoot,''No Server Set, Check Inspector.Settings'')+''] </b>
    <br> <table cellpadding=0 cellspacing=0 border=0>
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Backup Estimate For Tonight GB</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Backup Server FreeSpace GB</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Backup Server Free Space After Backups GB</b></td>
    '';


	IF (Select [value] FROM sys.configurations WHERE name = ''xp_cmdshell'') = 1
	BEGIN
		DECLARE @ErrorEncountered BIT = 0
		DECLARE @ErrorEncounteredText VARCHAR(100)
		DECLARE @BackupSizeForNextWeekday AS DECIMAL(10,1)
		DECLARE @BackupSpaceLessStorageSpace AS DECIMAL(10,1) 
		DECLARE @ExtractedInformation VARCHAR(MAX) = ''''
		DECLARE @FreeSpace_Bytes BIGINT = ''''
		DECLARE @FreeSpace_GB INT = '''' 
		DECLARE @Xpcmd VARCHAR(128)  
		
		IF OBJECT_ID(''tempdb.dbo.#BackupDriveSpace'') IS NOT NULL
		DROP TABLE #BackupDriveSpace;
		   
		CREATE TABLE #BackupDriveSpace
		(
		BytesFree NVARCHAR(MAX) 
		); 
		  

		IF @BackupRoot LIKE ''%\'' 
		BEGIN 
			SET @BackupRoot = LEFT(@BackupRoot,LEN(@BackupRoot)-1);
		END
		  
		SET @Xpcmd =  ''DIR\ ''+@BackupRoot;

		INSERT INTO #BackupDriveSpace (BytesFree)
		EXEC xp_cmdshell @Xpcmd;
		  
		IF EXISTS (SELECT TOP 1 BytesFree
					FROM #BackupDriveSpace
					WHERE BytesFree IS NOT NULL 
					AND BytesFree NOT IN (''The device is not ready.'', ''The system cannot find the path specified.'',''The network path was not found.'',''The specified path is invalid'',''The filename, directory name, or volume label syntax is incorrect.'')
					)
		BEGIN
			--Extract the drive information based on the @BackupRoot value (Start the string at this point ignoring any drives letters prior to it)
			SELECT @ExtractedInformation = @ExtractedInformation + (
			SELECT RIGHT(BytesFree,LEN(BytesFree)-CHARINDEX(@BackupRoot,BytesFree)+1) as DriveidentificationSTART
			FROM (SELECT BytesFree as BytesFree
					FROM #BackupDriveSpace 
					FOR XML PATH('''')
					) IdentifyDriveSpace (BytesFree))
			
			IF @ExtractedInformation LIKE ''%File Not Found%'' 
			BEGIN 
				SET @ErrorEncountered = 1;
				SET @ErrorEncounteredText = ''Invalid Backup Path Specified in [Inspector].[Settings]'';
				SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''BackupStorage''+''</a><font color= ''+@RedHighlight+''>  - Access denied for Backup Path Specified in [Inspector].[Settings]</font><p>'' ;
				SET @Importance = ''High'';
				SET @TotalWarningCount = @TotalWarningCount + 1;
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
					SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''BackupStorage''+''</a><font color= ''+@RedHighlight+''>  - Unable to determine free space for the Backup Path Specified in [Inspector].[Settings]</font><p>'';
					SET @Importance = ''High'';
					SET @TotalWarningCount = @TotalWarningCount + 1;
				END 
				
				SET @FreeSpace_GB = ((@FreeSpace_Bytes/1024)/1024)/1024;
			END
				
		END
		ELSE
		BEGIN
			SET @ErrorEncountered = 1;
			SET @ErrorEncounteredText = ''Invalid Backup Path Specified in [Inspector].[Settings]'';
			SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''BackupStorage''+''</a><font color= ''+@RedHighlight+''>  - Invalid Backup Path Specified in [Inspector].[Settings]</font><p>'';
			SET @Importance = ''High'';
			SET @TotalWarningCount = @TotalWarningCount + 1;
		END
	END
	ELSE
	BEGIN 
		SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''BackupStorage''+''</a><font color= ''+@RedHighlight+''>  - xp_cmdshell must be enabled for module BackupSizesCheck to run</font><p>'';
		SET @Importance = ''High'';
		SET @ErrorEncountered = 1;
		SET @ErrorEncounteredText = ''xp_cmdshell must be enabled'';
		SET @TotalWarningCount = @TotalWarningCount + 1;
	END

	
	SET @BackupSizeForNextWeekday = 
	(SELECT ISNULL(CAST(SUM(((TotalSizeInBytes)/1024)/1024)/1024 AS DECIMAL (10,1)),0) 
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupSizesByDay]
	WHERE [DayOfWeek] = DATENAME(WEEKDAY,DATEADD(DAY,1,Getdate()))
	)

	IF @BackupRoot IS NOT NULL
    BEGIN
		IF @ErrorEncountered = 0 
		BEGIN 
			SET @BackupSpaceLessStorageSpace = CAST(@FreeSpace_GB AS DECIMAL(10,1)) - @BackupSizeForNextWeekday
			SELECT @BodyBackupSpace = @BodyBackupSpace + 
			(SELECT 
			CASE 
			WHEN @FreeSpace_GB < (@BackupSizeForNextWeekday + (@BackupSizeForNextWeekday*10) /100) --Warn when the free space on the backup location is less than the estimated size for the next days backups multiplied by 10%.
			THEN @RedHighlight 
			ELSE ''#FFFFFF'' END AS [@bgcolor],
			@BackupSizeForNextWeekday AS ''td'','''',+
			@FreeSpace_GB  AS ''td'','''',+
			@BackupSpaceLessStorageSpace  AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END 

		IF @ErrorEncountered = 1 
		BEGIN
			SELECT @BodyBackupSpace = @BodyBackupSpace + 
			(SELECT 
			@RedHighlight AS [@bgcolor],
			@BackupSizeForNextWeekday AS ''td'','''',+
			@ErrorEncounteredText  AS ''td'','''',+
			''N/A''  AS ''td'',''''
			FOR XML PATH(''tr''),ELEMENTS);
		END
	END
	ELSE 
    BEGIN 
		SET @BackupSpaceLessStorageSpace = CAST(@FreeSpace_GB AS DECIMAL(10,1)) - @BackupSizeForNextWeekday
		SELECT @BodyBackupSpace = @BodyBackupSpace + 
		(SELECT @RedHighlight AS [@bgcolor],
		@BackupSizeForNextWeekday AS ''td'','''',+
		''BackupPath is Set to NULL, Check Inspector.Settings''  AS ''td'','''',+
		''N/A''  AS ''td'',''''
		FOR XML PATH(''tr''),ELEMENTS);
	END 

	--Append html table to the report
	SELECT @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server [ALL Servers]<b><p><BR>''+ISNULL(@TableHeadBackupSpace, '''') + ISNULL(@BodyBackupSpace, '''') + ISNULL(@TableTail, '''') + ''<p><BR><p>'';

	--If unsufficient space then create and alert.
	IF @FreeSpace_GB < (@BackupSizeForNextWeekday + (@BackupSizeForNextWeekday*10) /100)	
	BEGIN 
		SET @AlertHeader = @AlertHeader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''Backup Storage''+''</a><font color= ''+@RedHighlight+''> - There is insufficient free space on the backup server [''+@BackupRoot+''] for tonight''''s backups, Minimum space required: ''+CAST(@BackupSizeForNextWeekday AS VARCHAR(15))+'' GB , Space Available ''+CAST(@FreeSpace_GB AS VARCHAR(15)) + '' GB <p></font>''; 
		SET @Importance = ''High'';
		SET @TotalWarningCount = @TotalWarningCount + 1;
	END

END


IF @BackupSizesCheck = 1
BEGIN
--Excluded from Warning level control
	DECLARE @BodyBackupSpaceWeekly VARCHAR(MAX) = ''''
	DECLARE @TableHeadBackupSpaceWeekly VARCHAR(1000)
	
	SET @TableHeadBackupSpaceWeekly = ''
    <b>Backup space total by day (entire stack)</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Day Of Week</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Monday</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Tuesday</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Wednesday</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Thursday</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Friday</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Saturday</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Sunday</b></td>
    '';
	
	SELECT @BodyBackupSpaceWeekly = @BodyBackupSpaceWeekly +
	(SELECT ''#FFFFFF'' AS [@bgcolor],
	''Total_GB'' AS ''td'','''',+
	ISNULL(CAST((([Monday]/1024)/1024)/1024 AS DECIMAL (10,1)),0) AS ''td'','''',+
	ISNULL(CAST((([Tuesday]/1024)/1024)/1024 AS DECIMAL (10,1)),0) AS ''td'','''',+
	ISNULL(CAST((([Wednesday]/1024)/1024)/1024 AS DECIMAL (10,1)),0) AS ''td'','''',+
	ISNULL(CAST((([Thursday]/1024)/1024)/1024 AS DECIMAL (10,1)),0) AS ''td'','''',+
	ISNULL(CAST((([Friday]/1024)/1024)/1024 AS DECIMAL (10,1)),0) AS ''td'','''',+
	ISNULL(CAST((([Saturday]/1024)/1024)/1024 AS DECIMAL (10,1)),0) AS ''td'','''',+
	ISNULL(CAST((([Sunday]/1024)/1024)/1024 AS DECIMAL (10,1)),0) AS ''td'',''''
	FROM
	(SELECT [DayOfWeek],TotalSizeInBytes
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupSizesByDay]) AS SourceTable
	PIVOT
	(
	SUM(TotalSizeInBytes)
	FOR [DayOfWeek] IN ([Monday],[Tuesday],[Wednesday],[Thursday],[Friday],[Saturday],[Sunday])
	) AS PivotTable
	FOR XML PATH(''tr''),ELEMENTS);
	
	--Append html table to the report
	SELECT @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server [ALL Servers]<b><p><BR>''+ISNULL(+@TableHeadBackupSpaceWeekly, '''') + ISNULL(@BodyBackupSpaceWeekly, '''') + ISNULL(@TableTail, '''') + ''<p><BR><p>'';

END


																
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
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= ''+@RedHighlight+''>Warnings Present - </font></b><BR></BR>'')
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
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= ''+@YellowHighlight+''>Advisories/No Warnings - </font></b><BR></BR>'')
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


SET @EmailBody = ''
<div style="text-align: center;">''+@ServerSummaryHeader+''</div>'' 
+ ''
<BR></BR>
<HR></HR>
<div style="background:linear-gradient(to right, ''+@GradientLeftRedHighlight+'' 35%, ''+@GradientRightRedHighlight+'' 110%)">
<text>''+@AlertHeader +''<BR></text>
</div>
<div style="background: linear-gradient(to right, ''+@GradientLeftYellowHighlight+'' 35%, ''+@GradientRightYellowHighlight+'' 110%)">
<text>'' + ISNULL(@AdvisoryHeader,'''') + ''</text>
</div>
<div style="background: linear-gradient(to right, ''+@GradientLeftInfoHighlight+'' 35%, ''+@GradientRightInfoHighlight+'' 110%)">
<text>'' + ISNULL(@InfoHeader,'''') + ''</text>
</div>
'' +@EmailBody

SET @EmailBody = @EmailBody + ''
</body>
</html>
''

SET @EmailBody = Replace(Replace(@EmailBody,''&lt;'',''<''),''&gt;'',''>'')

SET @EmailBody = @EmailHeader + @EmailBody 

IF @TestMode = 1 OR (@RecipientsList IS NULL OR @RecipientsList = '''')
BEGIN
INSERT INTO ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ReportData] (ReportDate,ModuleConfig,ReportData,Summary)
SELECT GETDATE(),ISNULL(@ModuleDesc,@ModuleConfig),@EmailBody,''(''+CAST(@TotalWarningCount AS VARCHAR(6))+'') Red warnings, (''+CAST(@TotalAdvisoryCount AS VARCHAR(6))+'') Yellow Advisories'';
END
ELSE
BEGIN

IF @EmailRedWarningsOnly = 1 
	BEGIN
		IF @Importance = ''High''
		BEGIN
			INSERT INTO ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ReportData] (ReportDate,ModuleConfig,ReportData,Summary)
			SELECT GETDATE(),ISNULL(@ModuleDesc,@ModuleConfig),@EmailBody,''(''+CAST(@TotalWarningCount AS VARCHAR(6))+'') Red warnings, (''+CAST(@TotalAdvisoryCount AS VARCHAR(6))+'') Yellow Advisories'';

			EXEC msdb.dbo.sp_send_dbmail 
			@recipients = @RecipientsList,
			@subject = @SubjectText,
			@importance = @Importance,
			@body=@EmailBody ,
			@body_format = ''HTML'' 
		END
	END
	ELSE 
	BEGIN
			INSERT INTO ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ReportData] (ReportDate,ModuleConfig,ReportData,Summary)
			SELECT GETDATE(),ISNULL(@ModuleDesc,@ModuleConfig),@EmailBody,''(''+CAST(@TotalWarningCount AS VARCHAR(6))+'') Red warnings, (''+CAST(@TotalAdvisoryCount AS VARCHAR(6))+'') Yellow Advisories'';

			EXEC msdb.dbo.sp_send_dbmail 
			@recipients = @RecipientsList,
			@subject = @SubjectText,
			@importance = @Importance,
			@body=@EmailBody ,
			@body_format = ''HTML'' 
	END
END

SET @Duration = CAST(DATEDIFF(MILLISECOND,@ReportStart,GETDATE()) AS MONEY)/1000;
IF @ModuleDesc IS NULL BEGIN SET @ModuleDesc = @ModuleConfig END

EXEC [Inspector].[ExecutionLogInsert] 
@RunDatetime = @ReportStart, 
@Servername = @@SERVERNAME, 
@ModuleConfigDesc = @ModuleDesc,
@Procname = N''SQLUnderCoverInspectorReport'', 
@Duration = @Duration,
@PSCollection = @PSCollection;

--Report Data cleanup
DELETE FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ReportData]
WHERE ReportDate < DATEADD(DAY,-@ReportDataRetention,GETDATE());

END
ELSE
BEGIN 
	RAISERROR(''@ModuleDesc supplied does not exist in [Inspector].[Modules]'',15,1) 
END
END
ELSE 
BEGIN
	PRINT ''Not the Source server for the report , Quitting the job''
END

END
'

EXEC(@SQLStatement);


--Agent job creations
SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+'
USE [msdb];

IF NOT EXISTS (SELECT name FROM sysjobs WHERE name LIKE ''%SQLUndercover Inspector Data Collection%'')
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''SQLUndercover Inspector Data Collection'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Collect data and insert into '+@LinkedServername+'['+@Databasename+'].'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Collect and record data'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ['+@Databasename+'].[Inspector].[InspectorDataCollection] @ModuleConfig = NULL;'', 
		@database_name=N''master'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
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


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'USE [msdb];

IF NOT EXISTS (Select name from msdb..sysjobs where name LIKE ''%SQLUndercover Inspector Report%'')
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''SQLUndercover Inspector Report'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Produce SQLUndercover Inspector HTML report from the collected data in ['+@Databasename+']'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Report'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ['+@Databasename+'].[Inspector].[SQLUnderCoverInspectorReport]
@EmailDistributionGroup = ''''DBA'''',
@TestMode = 0, 
@ModuleDesc = NULL,
@EmailRedWarningsOnly = 0, 
@Theme = ''''Dark'''';

/*
@TestMode : 0 = Log to Inspector.ReportData, 1 = Email report.
@EmailRedWarningsOnly 0 = show all backup info, 1 = show threshold breaches only.
*/
'', 
		@database_name=N''master'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
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


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'USE [msdb];

IF NOT EXISTS (SELECT name FROM sysjobs WHERE name LIKE ''%SQLUndercover Periodic Backups Collection%'')
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''SQLUndercover Periodic Backups Collection'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''SQLUndercover Periodic Backups Collection , Collect Backup information and insert into: '+@LinkedServername+'['+@Databasename+']'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Collect backup information'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ['+@Databasename+'].[Inspector].[InspectorDataCollection] @ModuleConfig = ''''PeriodicBackupCheck'''';'', 
		@database_name=N''master'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
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


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'USE [msdb];

IF NOT EXISTS (SELECT name FROM sysjobs WHERE name LIKE ''%SQLUndercover Periodic Backups Report%'')
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''SQLUndercover Periodic Backups Report'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''SQLUndercover Periodic Backup Report, check Backup information inserted into: '+@LinkedServername+'['+@Databasename+'] and report.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Collate information and send email report'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''USE ['+@Databasename+'];

--SQLUndercover Periodic Backup Report
EXEC ['+@Databasename+'].[Inspector].[SQLUnderCoverInspectorReport] 
@EmailDistributionGroup = ''''DBA'''',
@TestMode = 0,
@ModuleDesc = ''''PeriodicBackupCheck'''',
@EmailRedWarningsOnly = 1, 
@Theme = ''''Dark'''' 

/*
@TestMode : 0 = Log to Inspector.ReportData, 1 = Email report.
@EmailRedWarningsOnly 0 = show all backup info, 1 = show threshold breaches only.
*/
'',
		@database_name=N''master'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
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
SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+'
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
    EXEC msdb.dbo.sp_update_job @job_id = @JobID, @description=N''SQLUndercover Periodic Backup Report, check Backup information inserted into: '+@LinkedServername+'['+@Databasename+'] and report.''
END'

EXEC (@SQLStatement);


--Update Inspector Build 
UPDATE [Inspector].[Settings]
SET [Value] = @Build
WHERE [Description] = 'InspectorBuild'
AND ([Value] != @Build OR [Value] IS NULL);

--Log Upgrade/Installation in Upgrade history table 
INSERT INTO [Inspector].[InspectorUpgradeHistory] ([Log_Date], [PreserveData], [CurrentBuild], [TargetBuild], [SetupCommand])
VALUES (GETDATE(),CASE WHEN @InitialSetup = 0 THEN 1 ELSE 0 END,CAST(@CurrentBuild AS DECIMAL(4,1)),CAST(@Build AS DECIMAL(4,1)),
'EXEC [Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = '''+@Databasename+''',	
@DataDrive = '''+@DataDrive+''',	
@LogDrive = '''+@LogDrive+''',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = '+ISNULL(''''+@BackupsPath+'''','NULL')+',
@LinkedServername = '+ISNULL(''''+@LinkedServernameParam+'''','NULL')+',  
@StackNameForEmailSubject = '+ISNULL(''''+@StackNameForEmailSubject+'''','SQLUndercover')+',	
@EmailRecipientList = '+ISNULL(''''+@EmailRecipientList+'''','NULL')+',	  
@DriveSpaceHistoryRetentionInDays = '+CAST(ISNULL(@DriveSpaceHistoryRetentionInDays,90) AS VARCHAR(6))+', 
@DaysUntilDriveFullThreshold = '+CAST(ISNULL(@DaysUntilDriveFullThreshold,56) AS VARCHAR(6))+', 
@FreeSpaceRemainingPercent = '+CAST(ISNULL(@FreeSpaceRemainingPercent,10) AS VARCHAR(6))+',
@DriveLetterExcludes = '+ISNULL(''''+@DriveLetterExcludes+'''','NULL')+', 
@DatabaseGrowthsAllowedPerDay = '+CAST(ISNULL(@DatabaseGrowthsAllowedPerDay,1) AS VARCHAR(6))+',  
@MAXDatabaseGrowthsAllowedPerDay = '+CAST(ISNULL(@MAXDatabaseGrowthsAllowedPerDay,10) AS VARCHAR(6))+', 
@AgentJobOwnerExclusions = '''+ISNULL(''''+@AgentJobOwnerExclusions+'''','sa')+''', 
@FullBackupThreshold = '+CAST(ISNULL(@FullBackupThreshold,8) AS VARCHAR(6))+',		
@DiffBackupThreshold = '+CAST(ISNULL(@DiffBackupThreshold,2) AS VARCHAR(6))+',		
@LogBackupThreshold = '+CAST(ISNULL(@LogBackupThreshold,20) AS VARCHAR(6))+',		
@DatabaseOwnerExclusions = '''+ISNULL(''''+@DatabaseOwnerExclusions+'''','sa')+''',  
@LongRunningTransactionThreshold = '+CAST(ISNULL(@LongRunningTransactionThreshold,300) AS VARCHAR(6))+',	
@InitialSetup = '+CAST(ISNULL(@InitialSetup,0) AS VARCHAR(1))+',
@Help = '+CAST(ISNULL(@Help,'NULL') AS VARCHAR(1))+'; 
'
);



--Inspector Information

IF @Compatibility = 0 
	SET @SQLStatement = 
'IF EXISTS(SELECT [StringElement] 
			FROM master.dbo.fn_SplitString('''+@DataDrive+''','','')
			WHERE [StringElement] IN (SELECT [StringElement] 
					FROM master.dbo.fn_SplitString('''+@LogDrive+''','','')
					) )'

IF @Compatibility = 1
	SET @SQLStatement =
'IF EXISTS(SELECT [value] 
			FROM STRING_SPLIT('''+@DataDrive+''','','')
			WHERE [value] IN (SELECT [value] 
					FROM STRING_SPLIT('''+@LogDrive+''','','')
					) )'

SET @SQLStatement = @SQLStatement + CHAR(13)+CHAR(10) +
'BEGIN 
PRINT 
''
=========================================
=============== WARNING!! ===============
=========================================

@DataDrive AND @LogDrive Contain one or more Drive letters that are the same, this will cause uneccesary Alerts it is recommended that you Disable Module ''''DatabaseFileCheck''''
To Disable - Update ['+@Databasename+'].[Inspector].[Modules] setting DatabaseFileCheck to 0
_______________________________________________________________________________________________________________________________________________________________________________

''
END
'
EXEC(@SQLStatement);


PRINT '
===================================================================================================================================
Our Getting started guide can be found here: https://sqlundercover.com/2018/02/19/getting-started-with-the-sqlundercover-inspector/
===================================================================================================================================


=====================================
SET Schedules for the following jobs:
=====================================

[SQLUndercover Inspector Report]
[SQLUndercover Inspector Data Collection]
[SQLUndercover Periodic Backups Report]
[SQLUndercover Periodic Backups Collection]

Set the Data Collection jobs to run a couple of minutes before the corresponding Report e.g. [SQLUndercover Inspector Data Collection] @ 8.55am , [SQLUndercover Inspector Report] @ 9:00am

___________________________________________________________________________________________________________________________________________________________________________________________

'
PRINT '
====================================================================
Be sure to check the following settings prior to using the solution:
====================================================================
 
[Inspector].[CurrentServers]  - Ensure that ALL servers that you want to report on are here (If you are using Linked Servers to report to a central Database) and the IsActive flag set to 1 or 0 accordingly

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
RAISERROR('Linked Server name is incorrect - Please correct the name and try again',11,0) WITH NOWAIT;
END
END

ELSE 
BEGIN 
RAISERROR('Please double check your database context, this script needs to be executed against the database [%s]',11,0,@Databasename) WITH NOWAIT;
END

END
ELSE
BEGIN
RAISERROR('@DataDrive And/Or @LogDrive cannot have more than 4 drive letters specified',11,1)
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

EXEC [Inspector].[InspectorSetup]
--Required Parameters (No defaults)							     
@Databasename = ''%s'',	
@DataDrive = ''S,U'',	
@LogDrive = ''T,V'',	
--Optional Parameters (Defaults Specified), ignored when @InitialSetup = 0
@BackupsPath = ''F:\Backups'',
@LinkedServername = NULL,  
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
@DiffBackupThreshold = 2,		
@LogBackupThreshold = 20,		
@DatabaseOwnerExclusions = ''sa'',  
@LongRunningTransactionThreshold = 300,	
@InitialSetup = 0; 
',0,0,@DBname) WITH NOWAIT;