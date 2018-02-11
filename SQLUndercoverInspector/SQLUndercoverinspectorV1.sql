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
Revision date: 31/01/2018
Version: 1
Description: SQLUndercover Inspector setup script

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


--=======================================================
/******  Scroll down for Quick Setup instructions ******/
--=======================================================


--OBJECT LIST:
---------------------------------------------
-- 1 x FUNCTION  - fn_Splitstring is required if SPLIT_STRING is not compatible with your system
--				   fn_Splitstring can be found here https://sqlundercover.com/2017/06/01/undercover-toolbox-fn_splitstring-its-like-string_split-but-for-luddites-or-those-who-havent-moved-to-sql-2016-yet/
---------------------------------------------
-- 1 x SCHEMA: [Inspector] 
---------------------------------------------
-- 22 x TABLES: 	
---------------------------------------------
-- [Inspector].[ADHocDatabaseCreations]
-- [Inspector].[ADHocDatabaseSupression]
-- [Inspector].[AGCheck]
-- [Inspector].[BackupsCheck]
-- [Inspector].[BackupSizesByDay]
-- [Inspector].[CurrentServers]
-- [Inspector].[DatabaseFiles]
-- [Inspector].[DatabaseFileSizeHistory]
-- [Inspector].[DatabaseFileSizes]
-- [Inspector].[DatabaseOwnership]
-- [Inspector].[DatabaseSettings]
-- [Inspector].[DatabaseStates]
-- [Inspector].[DriveSpace]
-- [Inspector].[EmailRecipients]
-- [Inspector].[FailedAgentJobs]
-- [Inspector].[JobOwner]
-- [Inspector].[LoginAttempts]
-- [Inspector].[Modules]
-- [Inspector].[ReportData]
-- [Inspector].[Settings]
-- [Inspector].[TopFiveDatabases]
-- [Inspector].[EmailConfig]



-- 15 x STORED PROCEDURES: 
---------------------------------------------
-- [Inspector].[ADHocDatabaseCreationsInsert]
-- [Inspector].[AGCheckInsert]
-- [Inspector].[BackupsCheckInsert]
-- [Inspector].[BackupSizesByDayInsert]
-- [Inspector].[DatabaseFilesInsert]
-- [Inspector].[DatabaseGrowthsInsert]
-- [Inspector].[DatabaseOwnershipInsert]
-- [Inspector].[DatabaseSettingsInsert]
-- [Inspector].[DatabaseStatesInsert]
-- [Inspector].[DriveSpaceInsert]
-- [Inspector].[FailedAgentJobsInsert]
-- [Inspector].[JobOwnerInsert]
-- [Inspector].[LoginAttemptsiInsert]
-- [Inspector].[TopFiveDatabasesInsert]
-- [Inspector].[SQLUnderCoverInspectorReport]
--===========================================

-- 4 x AGENT JOBS: 
---------------------------------------------
-- [SQLUndercover Inspector Report]
-- [SQLUndercover Inspector Data Collection]
-- [SQLUndercover Periodic Backups Report]
-- [SQLUndercover Periodic Backups Collection]
--===========================================


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--===========================================
--============  QUICK SETUP  ================
--===========================================
 
-- 1) Ensure you have created your Logging Database

-- 2) Scroll down to 'STEP 1' Ensure the @Databasename Variable Value matches your Logging Database name, If you are using Linked servers
--    to point at one central logging database then you will need to SET @LinkedServerName with the linked server name, otherwise SET this to NULL. Run against the Target of the linked server First!!
--    SET the Remaining values for the variables in this step accordingly, If this is the initial setup then leave @InitialSetup set to 1 

-- 3) Scroll down to 'STEP 2' SET the variables accordingly in this step for initial setup, otherwise if preserving Data or Settings (@InitialSetup = 0) then you can skip this step.

-- 4) Run the script in the context of your Logging database. If using Linked servers that point to one central database then run on the target Database first then the remaining servers.

-- 5) The script should complete with no errors and provide some additional imformation on how to fine tune the solution.

--===========================================


--======================================================================================
--===============================  STEP 1  =============================================
--======================================================================================


DECLARE @LinkedServerName NVARCHAR(128) = NULL  --Name of the Linked Server , SET to NULL if you are not using Linked Servers for this solution
									   --Run against the Target of the linked server First!! then the remaining servers you want to monitor.

DECLARE @Databasename NVARCHAR(128) = 'SQLUndercoverDB'	--Name of the Logging Database

DECLARE @DataDrive VARCHAR(7) = 'S,U'	--List Data Drives here (Maximum of 4 - comma delimited e.g 'P,Q,R,S')
DECLARE @LogDrive VARCHAR(7) = 'T,V'	--List Log Drives here (Maximum of 4 - comma delimited e.g 'T,U,V,W')
									

--============================= IMPORTANT!! ============================================
--================ LEAVE @InitialSetup = 1 FOR INITIAL SETUP ===========================

DECLARE @InitialSetup BIT = 1	 --Set to 1 for intial setup, 0 to Upgrade or re deploy to preserve previously logged data and settings config.


--======================================================================================
													 
												
--===============================  STEP 2  =============================================												
--The Parameters in the following block will be ignored if @InitialSetup (From Step 1) is set to 0
--SKIP SETTING THESE IF YOU SET @InitialSetup = 0 IN STEP 1
--======================================================================================

DECLARE @StackNameForEmailSubject VARCHAR(255) = 'SQLUndercover'	  --Specify the name for this stack that you want to show in the email subject

DECLARE @EmailRecipientList VARCHAR(1000) = NULL	  -- This will populate the EmailRecipients table for 'DBA'

DECLARE @BackupsPath VARCHAR(255) = 'F:\Backups'	  -- Backup Drive and path

DECLARE @DriveSpaceHistoryRetentionInDays TINYINT = 90
DECLARE @DaysUntilDriveFullThreshold	  TINYINT = 56 -- Estimated days until drive is full - Specify the threshold for when you will start to receive alerts (Red highlight and Alert header entry)
DECLARE @FreeSpaceRemainingPercent		  TINYINT = 10 -- Specify the percentage of drive space remaining where you want to start seeing a yellow highlight against the drive
DECLARE @DriveLetterExcludes			  VARCHAR(10) -- Exclude Drive letters from showing Yellow Advisory warnings when @FreeSpaceRemainingPercent has been reached/exceeded e.g C,D (Comma Delimited)

DECLARE @DatabaseGrowthsAllowedPerDay	  TINYINT = 1  -- Total Database Growths acceptable for a 24hour period If exceeded a Yellow Advisory condition will be shown
DECLARE @MAXDatabaseGrowthsAllowedPerDay  TINYINT = 10 -- MAX Database Growths for a 24 hour period If equal or exceeded a Red Warning condition will be shown

DECLARE @AgentJobOwnerExclusions VARCHAR(50) = 'SA'  --Exclude agent jobs with these owners (Comma delimited)

DECLARE @FullBackupThreshold TINYINT = 8		-- X Days older than Getdate()
DECLARE @DiffBackupThreshold TINYINT = 2		-- X Days older than Getdate() 
DECLARE @LogBackupThreshold  TINYINT  = 60		-- X Minutes older than Getdate()

DECLARE @DatabaseOwnerExclusions VARCHAR(255) = 'SA'  --Exclude databases with these owners (Comma delimited)

--======================================================================================
--============================= STEP 3: RUN THE CODE ===================================
--======================================================================================



DECLARE @Compatibility BIT
--SET compatibility to 1 if server version includes STRING_SPLIT
SELECT	@Compatibility = CASE
			WHEN SERVERPROPERTY ('productversion') >= '13.0.4001.0' AND Compatibility_Level >= 130 THEN 1
			ELSE 0
		END
FROM sys.databases
WHERE name = DB_NAME()



IF @Compatibility = 1 OR (@Compatibility = 0 AND OBJECT_ID('Master.dbo.Fn_SplitString') IS NOT NULL) 
BEGIN

IF (@DataDrive IS NOT NULL AND @LogDrive IS NOT NULL) 
	BEGIN
	SET  @DataDrive = REPLACE(@DataDrive,' ','')
	SET  @LogDrive  = REPLACE(@LogDrive,' ','')

	IF LEN(@DataDrive) <= 7 AND LEN(@LogDrive) <= 7
	BEGIN
		IF DB_NAME() = @Databasename
		BEGIN
			IF @LinkedServerName IS NULL OR EXISTS (SELECT NAME FROM SYS.SERVERS WHERE NAME = @LinkedServerName)
			BEGIN

			DECLARE @SQLStatement VARCHAR(MAX) 
			DECLARE @DatabaseFileSizesResult INT
			DECLARE @Build VARCHAR(3) ='1'
			 
			
			IF RIGHT(@BackupsPath,1) != '\' BEGIN SET @BackupsPath = @BackupsPath +'\' END
			
			IF @LinkedServerName IS NOT NULL BEGIN SET @LinkedServerName = QUOTENAME(@LinkedServerName)+'.' END
			IF @LinkedServerName IS NULL BEGIN SET @LinkedServerName = '' END


			SET NOCOUNT ON;
			
			--Check for the Inspector Schema in the reporting database and create the schema if it does not exist
			IF SCHEMA_ID('Inspector') IS NULL
			BEGIN
			EXEC sp_executesql N'CREATE SCHEMA [Inspector]'
			END



			IF @InitialSetup = 0
			
			BEGIN
			 --Copy previously recorded data from Inspector data tables into Temporary tables for re insertion
			 IF OBJECT_ID('Inspector.ADHocDatabaseCreations_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[ADHocDatabaseCreations_Copy];

			 IF OBJECT_ID('Inspector.ADHocDatabaseSupression_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[ADHocDatabaseSupression_Copy];
			
			 IF OBJECT_ID('Inspector.AGCheck_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[AGCheck_Copy];
			
			 IF OBJECT_ID('Inspector.BackupsCheck_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[BackupsCheck_Copy];
			
			 IF OBJECT_ID('Inspector.BackupSizesByDay_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[BackupSizesByDay_Copy];
			
			 IF OBJECT_ID('Inspector.DatabaseFiles_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[DatabaseFiles_Copy];
			
			 IF OBJECT_ID('Inspector.DatabaseFileSizeHistory_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[DatabaseFileSizeHistory_Copy];
			
			 IF OBJECT_ID('Inspector.DatabaseFileSizes_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[DatabaseFileSizes_Copy];
			
			 IF OBJECT_ID('Inspector.DatabaseOwnership_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[DatabaseOwnership_Copy];
			
			 IF OBJECT_ID('Inspector.DatabaseSettings_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[DatabaseSettings_Copy];
			
			 IF OBJECT_ID('Inspector.DatabaseStates_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[DatabaseStates_Copy];
			
			 IF OBJECT_ID('Inspector.DriveSpace_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[DriveSpace_Copy];
			
			 IF OBJECT_ID('Inspector.FailedAgentJobs_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[FailedAgentJobs_Copy];
			
			 IF OBJECT_ID('Inspector.JobOwner_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[JobOwner_Copy];
			
			 IF OBJECT_ID('Inspector.LoginAttempts_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[LoginAttempts_Copy];
			
			 IF OBJECT_ID('Inspector.ReportData_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[ReportData_Copy];
			
			 IF OBJECT_ID('Inspector.TopFiveDatabases_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[TopFiveDatabases_Copy];
			
			
			IF OBJECT_ID('Inspector.ADHocDatabaseCreations') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[ADHocDatabaseCreations_Copy]  FROM [Inspector].[ADHocDatabaseCreations] END
			IF OBJECT_ID('Inspector.ADHocDatabaseSupression') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[ADHocDatabaseSupression_Copy]  FROM [Inspector].[ADHocDatabaseSupression] END
			IF OBJECT_ID('Inspector.AGCheck') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[AGCheck_Copy]  FROM [Inspector].[AGCheck] END
			IF OBJECT_ID('Inspector.BackupsCheck') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[BackupsCheck_Copy]  FROM [Inspector].[BackupsCheck] END
			IF OBJECT_ID('Inspector.BackupSizesByDay') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[BackupSizesByDay_Copy]  FROM [Inspector].[BackupSizesByDay] END
			IF OBJECT_ID('Inspector.DatabaseFiles') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[DatabaseFiles_Copy]  FROM [Inspector].[DatabaseFiles] END
			IF OBJECT_ID('Inspector.DatabaseFileSizeHistory') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[DatabaseFileSizeHistory_Copy]  FROM [Inspector].[DatabaseFileSizeHistory] END
			IF OBJECT_ID('Inspector.DatabaseFileSizes') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[DatabaseFileSizes_Copy]  FROM [Inspector].[DatabaseFileSizes] END
			IF OBJECT_ID('Inspector.DatabaseOwnership') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[DatabaseOwnership_Copy]  FROM [Inspector].[DatabaseOwnership] END
			IF OBJECT_ID('Inspector.DatabaseSettings') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[DatabaseSettings_Copy]  FROM [Inspector].[DatabaseSettings] END
			IF OBJECT_ID('Inspector.DatabaseStates') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[DatabaseStates_Copy]  FROM [Inspector].[DatabaseStates] END
			IF OBJECT_ID('Inspector.DriveSpace') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[DriveSpace_Copy]  FROM [Inspector].[DriveSpace] END
			IF OBJECT_ID('Inspector.FailedAgentJobs') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[FailedAgentJobs_Copy]  FROM [Inspector].[FailedAgentJobs] END
			IF OBJECT_ID('Inspector.JobOwner') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[JobOwner_Copy]  FROM [Inspector].[JobOwner] END
			IF OBJECT_ID('Inspector.LoginAttempts') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[LoginAttempts_Copy]  FROM [Inspector].[LoginAttempts] END
			IF OBJECT_ID('Inspector.ReportData') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[ReportData_Copy]  FROM [Inspector].[ReportData] END
			IF OBJECT_ID('Inspector.TopFiveDatabases') IS NOT NULL 
			 BEGIN SELECT * INTO [Inspector].[TopFiveDatabases_Copy]  FROM [Inspector].[TopFiveDatabases] END
			
			
			END


IF @InitialSetup = 0 
BEGIN
			
			--Copy existing settings from Inspector Settings tables into Temporary tables for re insertion
			 IF OBJECT_ID('Inspector.CurrentServers_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[CurrentServers_Copy];
			
			 IF OBJECT_ID('Inspector.EmailRecipients_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[EmailRecipients_Copy];
			
			 IF OBJECT_ID('Inspector.Modules_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[Modules_Copy];
			
			 IF OBJECT_ID('Inspector.Settings_Copy') IS NOT NULL 
			 DROP TABLE [Inspector].[Settings_Copy];
			
			 IF OBJECT_ID('Inspector.EmailConfig_Copy') IS NOT NULL
			 DROP TABLE [Inspector].[EmailConfig_Copy];
			
			
			IF OBJECT_ID('Inspector.Settings') IS NOT NULL 
			 BEGIN 
			 SELECT * 
			 INTO [Inspector].[Settings_Copy]  
			 FROM [Inspector].[Settings] 
			 END
			 IF OBJECT_ID('Inspector.EmailRecipients') IS NOT NULL 
			 BEGIN 
			 SELECT * 
			 INTO [Inspector].[EmailRecipients_Copy]  
			 FROM [Inspector].[EmailRecipients] 
			 END
			IF OBJECT_ID('Inspector.CurrentServers') IS NOT NULL 
			 BEGIN 
			 SELECT * 
			 INTO [Inspector].[CurrentServers_Copy]  
			 FROM [Inspector].[CurrentServers] 
			 END
			IF OBJECT_ID('Inspector.Modules') IS NOT NULL 
			 BEGIN 
			 SELECT * 
			 INTO [Inspector].[Modules_Copy]  
			 FROM [Inspector].[Modules] 
			 END
			
			IF OBJECT_ID('Inspector.EmailConfig') IS NOT NULL
			 BEGIN 
			 SELECT * 
			 INTO [Inspector].[EmailConfig_Copy] 
			 FROM [Inspector].[EmailConfig] 
			 END
			
			END


			--Drop Constraints
			IF OBJECT_ID('Inspector.FK_ModuleConfig_Email') IS NOT NULL
			ALTER TABLE [Inspector].[EmailConfig] DROP CONSTRAINT FK_ModuleConfig_Email;
			
			IF OBJECT_ID('Inspector.FK_ModuleConfig_Desc') IS NOT NULL
			ALTER TABLE [Inspector].[CurrentServers] DROP CONSTRAINT FK_ModuleConfig_Desc;
			
			IF OBJECT_ID('Inspector.PK_ModuleConfig_Desc') IS NOT NULL
			ALTER TABLE [Inspector].[Modules] DROP CONSTRAINT PK_ModuleConfig_Desc;




			--Drop and recreate all Settings tables
			IF OBJECT_ID('Inspector.ReportData') IS NOT NULL 
			DROP TABLE [Inspector].[ReportData];
			
			CREATE TABLE [Inspector].[ReportData](
				[ID] INT IDENTITY(1,1),
				[ReportDate] DATETIME NOT NULL,
				[ModuleConfig] VARCHAR(20),
				[ReportData] VARCHAR(MAX) NULL
			);
			
			IF OBJECT_ID('Inspector.Settings') IS NOT NULL 
			DROP TABLE [Inspector].[Settings];
			
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
			
			IF OBJECT_ID('Inspector.Modules') IS NOT NULL
			DROP TABLE [Inspector].[Modules];
			
			
			CREATE TABLE [Inspector].[Modules]
			(
			ID INT IDENTITY(1,1),
			ModuleConfig_Desc						VARCHAR(20) NOT NULL,
			EnableAGCheck							BIT,
			EnableBackupsCheck						BIT,
			EnableBackupSizesCheck					BIT,
			EnableDatabaseGrowthCheck				BIT,
			EnableDatabaseFileCheck					BIT,
			EnableDatabaseOwnershipCheck			     BIT,
			EnableDatabaseStatesCheck				BIT,
			EnableDriveSpaceCheck					BIT,
			EnableFailedAgentJobCheck				BIT,
			EnableJobOwnerCheck						BIT,
			EnableFailedLoginsCheck					BIT,
			EnableTopFiveDatabaseSizeCheck			BIT,
			EnableADHocDatabaseCreationCheck		     BIT,
			EnableBackupSpaceCheck					BIT,
			EnableDatabaseSettings					BIT,
			UseMedianCalculationForDriveSpaceCalc	     BIT
			CONSTRAINT PK_ModuleConfig_Desc PRIMARY KEY (ModuleConfig_Desc)
			);
			
			
			IF OBJECT_ID('Inspector.EmailRecipients') IS NOT NULL
			DROP TABLE [Inspector].[EmailRecipients];
			
			CREATE TABLE [Inspector].[EmailRecipients]
			(
			ID INT IDENTITY(1,1),
			Description VARCHAR(50) NOT NULL,
			Recipients VARCHAR(1000) DEFAULT NULL
			CONSTRAINT UC_EmailDescription UNIQUE (Description)
			); 
			
			
			IF OBJECT_ID('Inspector.CurrentServers') IS NOT NULL 
			DROP TABLE [Inspector].[CurrentServers];
			
			 
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
			
			
			IF OBJECT_ID('Inspector.EmailConfig') IS NOT NULL
			DROP TABLE [Inspector].[EmailConfig];
			
			CREATE TABLE [Inspector].[EmailConfig]
			(
			ModuleConfig_Desc VARCHAR(20),
			EmailSubject VARCHAR(100) DEFAULT NULL,
			CONSTRAINT FK_ModuleConfig_Email FOREIGN KEY (ModuleConfig_Desc) REFERENCES Inspector.Modules(ModuleConfig_Desc)
			);
			
			
			
			
			
			IF @InitialSetup = 0 
			BEGIN
			--Insert Preserved Settings from Temporary tables into Inspector Base tables  
			IF OBJECT_ID('Inspector.Settings_Copy') IS NOT NULL 
			BEGIN
			
				SET IDENTITY_INSERT [Inspector].[Settings] ON
				INSERT INTO [Inspector].[Settings] ([ID], [Description], [Value]) 
				SELECT [ID], [Description], [Value]
				FROM [Inspector].[Settings_Copy] AS PreservedSettings 
				SET IDENTITY_INSERT [Inspector].[Settings] OFF;

			END

			IF OBJECT_ID('Inspector.Modules_Copy') IS NOT NULL
			BEGIN
			
				UPDATE Config
				SET 
				[EnableADHocDatabaseCreationCheck]		= PreservedSettings.[EnableADHocDatabaseCreationCheck],
				[EnableAGCheck]					= PreservedSettings.[EnableAGCheck],
				[EnableBackupsCheck]				= PreservedSettings.[EnableBackupsCheck],
				[EnableBackupSizesCheck]				= PreservedSettings.[EnableBackupSizesCheck],
				[EnableBackupSpaceCheck]				= PreservedSettings.[EnableBackupSpaceCheck],
				[EnableDatabaseFileCheck]			= PreservedSettings.[EnableDatabaseFileCheck],
				[EnableDatabaseGrowthCheck]			= PreservedSettings.[EnableDatabaseGrowthCheck],
				[EnableDatabaseOwnershipCheck]		= PreservedSettings.[EnableDatabaseOwnershipCheck],
				[EnableDatabaseSettings]				= PreservedSettings.[EnableDatabaseSettings],
				[EnableDatabaseStatesCheck]			= PreservedSettings.[EnableDatabaseStatesCheck],
				[EnableDriveSpaceCheck]				= PreservedSettings.[EnableDriveSpaceCheck],
				[EnableFailedAgentJobCheck]			= PreservedSettings.[EnableFailedAgentJobCheck],
				[EnableFailedLoginsCheck]			= PreservedSettings.[EnableFailedLoginsCheck],
				[EnableJobOwnerCheck]				= PreservedSettings.[EnableJobOwnerCheck],
				[EnableTopFiveDatabaseSizeCheck]		= PreservedSettings.[EnableTopFiveDatabaseSizeCheck],
				[ModuleConfig_Desc]					= PreservedSettings.[ModuleConfig_Desc] ,
				[UseMedianCalculationForDriveSpaceCalc]	= PreservedSettings.[UseMedianCalculationForDriveSpaceCalc]
				FROM [Inspector].[Modules] AS Config
				INNER JOIN [Inspector].[Modules_Copy] AS PreservedSettings ON Config.ModuleConfig_Desc = PreservedSettings.ModuleConfig_Desc;
			
			
				INSERT INTO [Inspector].[Modules] 
				(
				[EnableADHocDatabaseCreationCheck],
				[EnableAGCheck],
				[EnableBackupsCheck],
				[EnableBackupSizesCheck],
				[EnableBackupSpaceCheck],
				[EnableDatabaseFileCheck],
				[EnableDatabaseGrowthCheck],
				[EnableDatabaseOwnershipCheck],
				[EnableDatabaseSettings],
				[EnableDatabaseStatesCheck],
				[EnableDriveSpaceCheck],
				[EnableFailedAgentJobCheck],
				[EnableFailedLoginsCheck],
				[EnableJobOwnerCheck],
				[EnableTopFiveDatabaseSizeCheck],
				[ModuleConfig_Desc] ,
				[UseMedianCalculationForDriveSpaceCalc]
				)
				SELECT 
				PreservedSettings.[EnableADHocDatabaseCreationCheck],
				PreservedSettings.[EnableAGCheck],
				PreservedSettings.[EnableBackupsCheck],
				PreservedSettings.[EnableBackupSizesCheck],
				PreservedSettings.[EnableBackupSpaceCheck],
				PreservedSettings.[EnableDatabaseFileCheck],
				PreservedSettings.[EnableDatabaseGrowthCheck],
				PreservedSettings.[EnableDatabaseOwnershipCheck],
				PreservedSettings.[EnableDatabaseSettings],
				PreservedSettings.[EnableDatabaseStatesCheck],
				PreservedSettings.[EnableDriveSpaceCheck],
				PreservedSettings.[EnableFailedAgentJobCheck],
				PreservedSettings.[EnableFailedLoginsCheck],
				PreservedSettings.[EnableJobOwnerCheck],
				PreservedSettings.[EnableTopFiveDatabaseSizeCheck],
				PreservedSettings.[ModuleConfig_Desc] ,
				PreservedSettings.[UseMedianCalculationForDriveSpaceCalc]
				FROM [Inspector].[Modules_Copy] AS PreservedSettings 
				LEFT JOIN [Inspector].[Modules] AS Config ON Config.ModuleConfig_Desc = PreservedSettings.ModuleConfig_Desc
				WHERE Config.ModuleConfig_Desc IS NULL;
			
			END
			
			IF OBJECT_ID('Inspector.CurrentServers_Copy') IS NOT NULL
			BEGIN
			
				INSERT INTO [Inspector].[CurrentServers] (Servername,Isactive,ModuleConfig_Desc) 
				SELECT PreservedSettings.Servername,PreservedSettings.Isactive,PreservedSettings.ModuleConfig_Desc
				FROM [Inspector].[CurrentServers_Copy] AS PreservedSettings 
				WHERE NOT EXISTS (SELECT Servername
									FROM [Inspector].[CurrentServers] AS Config
									WHERE Config.Servername = PreservedSettings.Servername);
			
			END
			
			IF OBJECT_ID('Inspector.EmailRecipients_Copy') IS NOT NULL
			BEGIN
			
				UPDATE  Config
				SET Config.Recipients = PreservedSettings.Recipients
				FROM [Inspector].[EmailRecipients]  AS Config
				INNER JOIN [Inspector].[EmailRecipients_Copy] AS PreservedSettings ON Config.Description = PreservedSettings.Description;
				
				INSERT INTO [Inspector].[EmailRecipients] (Description,Recipients) 
				SELECT PreservedSettings.Description,PreservedSettings.Recipients
				FROM [Inspector].[EmailRecipients_Copy] AS PreservedSettings 
				LEFT JOIN [Inspector].[EmailRecipients]  AS Config ON Config.Description = PreservedSettings.Description
				WHERE Config.Description IS NULL;
			
			END
			
			
			IF OBJECT_ID('Inspector.EmailConfig_Copy') IS NOT NULL
			BEGIN
			
				INSERT INTO [Inspector].[EmailConfig] (ModuleConfig_Desc,EmailSubject)
				SELECT [ModuleConfig_Desc],[EmailSubject]
				FROM [Inspector].[EmailConfig_Copy]
			
			END
			
			END

IF @InitialSetup = 1 
BEGIN
--Insert Settings into Inspector Base tables  
SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+'
INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES  (''SQLUndercoverInspectorEmailSubject'','''+@StackNameForEmailSubject+''')

		
INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES	(''DriveSpaceRetentionPeriodInDays'','+CAST(@DriveSpaceHistoryRetentionInDays AS VARCHAR(6))+'),
		'+CASE 
			WHEN @EmailRecipientList IS NULL 
			THEN 
			'(''DriveSpaceDriveLetterExcludes'',NULL),
			'
			ELSE
			'(''DriveSpaceDriveLetterExcludes'','''+@DriveLetterExcludes+'''),
			'
			END+
		'(''FullBackupThreshold'','+CAST(@FullBackupThreshold AS VARCHAR(3))+'),
		(''DiffBackupThreshold'','+CAST(@DiffBackupThreshold AS VARCHAR(3))+'),
		(''LogBackupThreshold'' ,'+CAST(@LogBackupThreshold AS VARCHAR(6))+'),
		(''DaysUntilDriveFullThreshold'' ,'+CAST(@DaysUntilDriveFullThreshold AS VARCHAR(4))+'),
		(''FreeSpaceRemainingPercent'','+CAST(@FreeSpaceRemainingPercent AS VARCHAR(3))+'),
		(''DatabaseGrowthsAllowedPerDay'','+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'),
		(''MAXDatabaseGrowthsAllowedPerDay'','+CAST(@MAXDatabaseGrowthsAllowedPerDay AS VARCHAR(5))+')


INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES	(''BackupsPath'','''+@BackupsPath+'''),
		(''EmailBannerURL'',''https://i2.wp.com/sqlundercover.files.wordpress.com/2017/11/inspector_whitehandle.png?ssl=1&w=450''),
		(''DatabaseOwnerExclusions'','''+@DatabaseOwnerExclusions+'''),
		(''AgentJobOwnerExclusions'','''+@AgentJobOwnerExclusions+''')

INSERT INTO [Inspector].[Settings] ([Description],[Value])
VALUES	(''InspectorBuild'','''+@Build+''')
		


INSERT INTO [Inspector].[Modules] (ModuleConfig_Desc,EnableAGCheck,EnableBackupsCheck,EnableBackupSizesCheck,EnableDatabaseGrowthCheck,EnableDatabaseFileCheck,EnableDatabaseOwnershipCheck,
					   EnableDatabaseStatesCheck,EnableDriveSpaceCheck,EnableFailedAgentJobCheck,EnableJobOwnerCheck,EnableFailedLoginsCheck,EnableTopFiveDatabaseSizeCheck,
					   EnableADHocDatabaseCreationCheck,EnableBackupSpaceCheck,EnableDatabaseSettings,UseMedianCalculationForDriveSpaceCalc)
VALUES	(''Default'',1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0),(''PeriodicBackupCheck'',0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        
INSERT INTO Inspector.EmailConfig (ModuleConfig_Desc,EmailSubject)
VALUES (''Default'',''SQLUndercover Inspector check ''),(''PeriodicBackupCheck'',''SQLUndercover Backups Report'')

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 
INSERT INTO '+CAST(@LinkedServerName AS VARCHAR(128))+'['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers] (Servername,Isactive,ModuleConfig_Desc)
SELECT DISTINCT Replica_server_name,1,NULL
FROM sys.dm_hadr_availability_replica_cluster_nodes AGServers
WHERE NOT EXISTS (SELECT Servername FROM '+CAST(@LinkedServerName AS VARCHAR(128))+'['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers] WHERE Servername = AGServers.Replica_server_name)
END 
ELSE 
BEGIN 

INSERT INTO '+CAST(@LinkedServerName AS VARCHAR(128))+'['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers] (Servername,Isactive,ModuleConfig_Desc)
SELECT @@SERVERNAME,1,NULL
WHERE NOT EXISTS (SELECT Servername FROM '+CAST(@LinkedServerName AS VARCHAR(128))+'['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers] WHERE Servername = @@Servername)
END
'
+
CASE 
WHEN @EmailRecipientList IS NULL 
THEN 
'INSERT INTO [Inspector].[EmailRecipients] (Description)
VALUES (''DBA'')
'
ELSE
'
INSERT INTO [Inspector].[EmailRecipients] (Description,Recipients)
VALUES (''DBA'','''+@EmailRecipientList+''')

'
END

EXEC (@SQLStatement)

END


			--Drop and create all Inspector Data Tables and Stored Procedures
			IF OBJECT_ID('Inspector.ADHocDatabaseCreations') IS NOT NULL
			DROP TABLE [Inspector].[ADHocDatabaseCreations];
			
			CREATE TABLE [Inspector].[ADHocDatabaseCreations]
			(
			[Servername] NVARCHAR(128) NOT NULL,
			[Log_date] DATETIME NULL,
			[Databasename] NVARCHAR(128) NOT NULL,
			[Create_Date] DATETIME NULL
			);

			
			IF OBJECT_ID('Inspector.ADHocDatabaseSupression') IS NOT NULL
			DROP TABLE [Inspector].[ADHocDatabaseSupression];
			
			CREATE TABLE [Inspector].[ADHocDatabaseSupression]
			(
			[Servername] NVARCHAR(128),
			[Log_Date] DATETIME,
			[Databasename] NVARCHAR(128),
			[Suppress] BIT
			);		
				
			
			IF OBJECT_ID('Inspector.AGCheck') IS NOT NULL
			DROP TABLE [Inspector].[AGCheck];
			
			CREATE TABLE [Inspector].[AGCheck]
			(
				[ServerName] NVARCHAR(128) NOT NULL,
				[Log_Date] DATETIME NOT NULL,
				[AGname] NVARCHAR(128) NULL,
				[State] VARCHAR(50) NULL,
				[ReplicaServerName] NVARCHAR(256) NULL,
				[Suspended] BIT NULL,
				[SuspendReason] VARCHAR(50) NULL
			); 
			
			 
			
			IF OBJECT_ID('Inspector.DatabaseFiles') IS NOT NULL
			DROP TABLE [Inspector].[DatabaseFiles];
			
			CREATE TABLE [Inspector].[DatabaseFiles]
			(
			[ServerName] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Databasename] NVARCHAR(128), 
			[FileType] VARCHAR(8),
			[FilePath] NVARCHAR(260)
			);
			
			
			
			IF OBJECT_ID('Inspector.DatabaseStates') IS NOT NULL
			DROP TABLE [Inspector].[DatabaseStates];
			
			CREATE TABLE [Inspector].[DatabaseStates]
			(
			[ServerName] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[DatabaseState] VARCHAR(40)  NULL,
			[Total] INT,
			[DatabaseNames] VARCHAR(MAX) NULL
			); 
			
			
			
			
			IF OBJECT_ID('Inspector.DriveSpace') IS NOT NULL
			DROP TABLE [Inspector].[DriveSpace];
			
			CREATE TABLE [Inspector].[DriveSpace] 
			(
			[Servername] NVARCHAR(128),
			[Log_Date] DATETIME,
			[Drive] NVARCHAR(3),
			[Capacity_GB] DECIMAL(10,2),
			[AvailableSpace_GB] DECIMAL(10,2)
			);
			
			
			IF OBJECT_ID('Inspector.FailedAgentJobs') IS NOT NULL
			DROP TABLE [Inspector].[FailedAgentJobs]
			
			CREATE TABLE [Inspector].[FailedAgentJobs]
			(
			[ServerName] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[JobName] VARCHAR(128)  NULL,
			[LastStepFailed] TINYINT NULL,
			[LastFailedDate] DATETIME NULL,
			[LastError] VARCHAR(260) NULL
			);
			
			
			IF OBJECT_ID('Inspector.LoginAttempts') IS NOT NULL
			DROP TABLE [Inspector].[LoginAttempts];
			
			CREATE TABLE [Inspector].[LoginAttempts]
			(
			[ServerName] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Username] VARCHAR(50)  NULL,
			[Attempts] INT NULL,
			[LastErrorDate] DATETIME NULL,
			[LastError] VARCHAR(260) NULL
			); 
			
			
			
			IF OBJECT_ID('Inspector.JobOwner') IS NOT NULL
			DROP TABLE [Inspector].[JobOwner];
			
			CREATE TABLE [Inspector].[JobOwner]
			(
			[ServerName] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Job_ID]  UNIQUEIDENTIFIER  NULL,
			[JobName] VARCHAR(100) NOT NULL
			); 
			
			
			
			IF OBJECT_ID('Inspector.TopFiveDatabases') IS NOT NULL
			DROP TABLE [Inspector].[TopFiveDatabases];
			
			CREATE TABLE [Inspector].[TopFiveDatabases]
			(
			[ServerName] NVARCHAR(128)  NOT NULL,
			[Log_Date] DATETIME  NOT NULL,
			[Databasename] NVARCHAR(128)  NULL,
			[TotalSize_MB] BIGINT
			); 
			
			
			
			IF OBJECT_ID('Inspector.BackupsCheck') IS NOT NULL
			DROP TABLE [Inspector].[BackupsCheck];
			
			CREATE TABLE [Inspector].[BackupsCheck](
				[ServerName] NVARCHAR (128) NOT NULL,
				[Log_Date] [datetime] NOT NULL,
				[Databasename] [nvarchar](128) NULL,
				[AGname] Nvarchar (128) NULL,
				[FULL] [datetime] NULL,
				[DIFF] [datetime] NULL,
				[LOG] [datetime] NULL,
				[IsFullRecovery] [bit] NULL,
				[IsSystemDB] [bit] NULL
				);
			
			
			
			
			IF OBJECT_ID('Inspector.DatabaseFileSizes') IS NOT NULL
			DROP TABLE [Inspector].[DatabaseFileSizes];
			
			CREATE TABLE [Inspector].[DatabaseFileSizes](
				[ServerName] NVARCHAR(128)  NOT NULL,
				[Database_id] INT NOT NULL,
				[Database_name] [nvarchar](128) NULL,
				[OriginalDateLogged] [datetime] NOT NULL,
				[OriginalSize_MB] BIGINT NULL,
				[Type_desc] [nvarchar](60) NULL,
				[File_id] TINYINT NOT NULL,
				[Filename] [nvarchar](260) NULL,
				[PostGrowthSize_MB] BIGINT NULL,
				[GrowthRate] [int] NULL,
				[Is_percent_growth] [bit] NOT NULL,
				[NextGrowth] BIGINT  NULL
			); 
			
			IF OBJECT_ID('Inspector.DatabaseFileSizeHistory') IS NOT NULL
			DROP TABLE [Inspector].[DatabaseFileSizeHistory];
			
			
			CREATE TABLE [Inspector].DatabaseFileSizeHistory
			(
			[GrowthID] BIGINT IDENTITY(1,1),
			[ServerName] NVARCHAR(128)  NOT NULL,
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
			
			
			IF OBJECT_ID('Inspector.DatabaseOwnership') IS NOT NULL
			DROP TABLE [Inspector].[DatabaseOwnership];
			
			CREATE TABLE [Inspector].[DatabaseOwnership]
			    (
				[ServerName] [nvarchar](128) NOT NULL,
				[Log_Date] DATETIME NULL,
				[AGName] [nvarchar](128) NULL,
				[Database_name] [nvarchar](128) NOT NULL,
				[Owner] [nvarchar](100) NULL
				) ;
			
			
			IF OBJECT_ID('Inspector.BackupSizesByDay') IS NOT NULL
			DROP TABLE [Inspector].[BackupSizesByDay];
			
			CREATE TABLE [Inspector].[BackupSizesByDay]
				(
				[ServerName] [nvarchar](128) NOT NULL,
				[Log_Date] DATETIME NULL,
				[DayOfWeek] [VARCHAR](10) NULL,
				[CastedDate] [DATE] NULL,
				[TotalSizeInBytes] [BIGINT] NULL
				);
			
			IF OBJECT_ID('Inspector.DatabaseSettings') IS NOT NULL
			DROP TABLE [Inspector].[DatabaseSettings]
			
			CREATE TABLE [Inspector].[DatabaseSettings](
				[Servername] [nvarchar](128) NULL,
				[Log_Date] [datetime] NULL,
				[Setting] [varchar](50) NULL,
				[Description] [varchar](100) NULL,
				[Total] [int] NULL
			);
			
			
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
			
			IF OBJECT_ID('Inspector.LoginAttemptsiInsert') IS NOT NULL
			DROP PROCEDURE [Inspector].[LoginAttemptsiInsert];
			
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
			
			IF OBJECT_ID('Inspector.SQLUnderCoverInspectorReport') IS NOT NULL 
			DROP PROCEDURE [Inspector].[SQLUnderCoverInspectorReport];




SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[ADHocDatabaseCreationsInsert]
AS
BEGIN

--Revision date: 31/01/2018

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME;

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations]
WHERE Servername = @ServerName;


INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations] (Servername,Log_date,Databasename,Create_Date)
SELECT
@ServerName,
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
			  FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[ADHocDatabaseSupression] 
			  WHERE Servername = @ServerName AND Suppress = 1)
ORDER BY create_date ASC;


INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[ADHocDatabaseSupression] (Servername, Log_Date, Databasename, Suppress)
SELECT
@ServerName,
GETDATE(),
Databasename,
0
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations] Creations
WHERE Servername = @ServerName
AND NOT EXISTS (SELECT Databasename 
			 FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[ADHocDatabaseSupression] SuppressList
			 WHERE SuppressList.Servername = @ServerName AND SuppressList.Databasename = Creations.Databasename);


IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations] 
			WHERE Servername = @ServerName)
			BEGIN 
			INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[ADHocDatabaseCreations] (Servername,Log_date,Databasename,Create_Date)
			VALUES(@ServerName,GETDATE(),''No Ad hoc database creations present'',NULL)
			END

END;'

EXEC (@SQLStatement);

SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[AGCheckInsert]
AS
BEGIN

--Revision date: 31/01/2018

SET NOCOUNT ON;

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[AGCheck]
WHERE Servername = @ServerName;

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[AGCheck] ([ServerName], [Log_Date], [AGname], [State], [ReplicaServerName], [Suspended], [SuspendReason])
SELECT DISTINCT
@ServerName,
Getdate(),
Groups.NAME AS AGNAME,
States.synchronization_health_desc,
Replicas.replica_server_name +'' ('' + CAST(States.role_desc AS NCHAR(1)) +'')'',
ReplicaStates.is_suspended,
ISNULL(ReplicaStates.suspend_reason_desc,''N/A'') AS suspend_reason_desc
FROM sys.availability_groups Groups
INNER JOIN sys.dm_hadr_availability_replica_states as States ON States.group_id = Groups.group_id
INNER JOIN sys.availability_replicas as Replicas ON States.replica_id = Replicas.replica_id
INNER JOIN sys.dm_hadr_database_replica_states as ReplicaStates ON Replicas.replica_id = ReplicaStates.replica_id

END 
ELSE 
BEGIN

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[AGCheck] ([ServerName], [Log_Date], [AGname], [State])
SELECT
@ServerName,
Getdate(),
''HADR IS NOT ENABLED ON THIS SERVER OR YOU HAVE NO AVAILABILITY GROUPS'',
''N/A''

END
END;'

EXEC(@SQLStatement)



DECLARE @DataDriveWhereClause VARCHAR(255)
DECLARE @LogDriveWhereClause VARCHAR(255)  	

DECLARE @DataDriveLength INT = LEN(REPLACE(@DataDrive,',',''))
DECLARE @RemainingDataWhereClause VARCHAR(MAX) 

  IF @DataDriveLength > 1 
  BEGIN 
	IF @Compatibility = 0 
		BEGIN
			SET @RemainingDataWhereClause = (SELECT ' OR physical_name LIKE '''+[StringElement]+'%''' FROM Master.dbo.fn_SplitString(RIGHT(@DataDrive,LEN(@DataDrive)-2),',') RemainingWhereClause FOR XML PATH(''))
		END
			IF @Compatibility = 1
			BEGIN
				SET @RemainingDataWhereClause= (SELECT ' OR physical_name LIKE '''+[Value]+'%''' FROM STRING_SPLIT(RIGHT(@DataDrive,LEN(@DataDrive)-2),',') RemainingWhereClause FOR XML PATH(''))
			END

  SET @DataDriveWhereClause =  ''+REPLICATE('(',@DataDriveLength) --Total clauses required
  +'Physical_name LIKE '''+SUBSTRING(@DataDrive,1,1)+'%''' 
  + @RemainingDataWhereClause +REPLICATE(')',@DataDriveLength-1) + ' AND physical_name LIKE ''%.ldf'') OR '
  END
  ELSE
  BEGIN
  SET @DataDriveWhereClause = '(Physical_name LIKE '''+@DataDrive+'%'' AND physical_name LIKE ''%.ldf'') OR '
  END

DECLARE @LogDriveLength INT = LEN(REPLACE(@LogDrive,',',''))
DECLARE @RemainingLogWhereClause VARCHAR(MAX)

  IF @LogDriveLength > 1 
  BEGIN 
  	IF @Compatibility = 0 
		BEGIN
			SET @RemainingLogWhereClause = (SELECT ' OR physical_name LIKE '''+[StringElement]+'%''' FROM Master.dbo.fn_SplitString(RIGHT(@LogDrive,LEN(@DataDrive)-2),',') RemainingWhereClause FOR XML PATH(''))
		END
			IF @Compatibility = 1
			BEGIN
				SET @RemainingLogWhereClause= (SELECT ' OR physical_name LIKE '''+[Value]+'%''' FROM STRING_SPLIT(RIGHT(@LogDrive,LEN(@LogDrive)-2),',') RemainingWhereClause FOR XML PATH(''))
			END
							    
  SET @LogDriveWhereClause = ''+REPLICATE('(',@LogDriveLength) --Total clauses required
  +'Physical_name LIKE '''+SUBSTRING(@LogDrive,1,1)+'%''' 
  + @RemainingLogWhereClause +REPLICATE(')',@LogDriveLength-1) + ' AND physical_name LIKE ''%.mdf'')'
  END
  ELSE
  BEGIN
  SET @LogDriveWhereClause = '(Physical_name LIKE '''+@LogDrive+'%'' AND physical_name LIKE ''%.mdf'')'
  END




SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[DatabaseFilesInsert]
AS
BEGIN

--Revision date: 31/01/2018

SET NOCOUNT ON;

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFiles]
WHERE Servername = @ServerName;

INSERT INTO  '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFiles] (ServerName,Log_Date,Databasename,FileType,FilePath)
SELECT
@ServerName,
GetDate(),
DB_NAME(Database_ID),
Type_Desc,
Physical_Name 
FROM sys.master_files
WHERE 
'+ @DataDriveWhereClause + '
'
+@LogDriveWhereClause +
 '
ORDER BY DB_NAME(Database_ID) ASC

IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFiles]
			WHERE Servername = @ServerName)
			BEGIN 
			INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFiles] (ServerName,Log_Date,Databasename,FileType,FilePath)
			VALUES(@ServerName,GETDATE(),''No Database File issues present'',NULL,NULL)
			END
			
END;'


EXEC(@SQLStatement)



SET @SQLStatement =  
'CREATE PROCEDURE [Inspector].[DatabaseStatesInsert]
AS
BEGIN

--Revision date: 31/01/2018

SET NOCOUNT ON;

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseStates]
WHERE Servername = @ServerName;

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseStates] (ServerName,Log_Date,DatabaseState,Total,DatabaseNames)
SELECT 
@ServerName,
GetDate(),
State_desc,
COUNT(State_desc),
CASE WHEN State_desc IN (''ONLINE'',''SNAPSHOT (less than 10 days old)'') THEN ''-'' ELSE DBName END
FROM (Select CASE WHEN source_database_id IS NOT NULL AND create_date < DATEADD(DAY,-10,GetDate()) THEN ''SNAPSHOT (more than 10 days old)''
WHEN source_database_id IS NOT NULL AND create_date > DATEADD(DAY,-10,GetDate()) THEN ''SNAPSHOT (less than 10 days old)'' 
ELSE State_Desc END AS State_desc,
STUFF(COALESCE(NonOnlineDBs.DatabaseName,OldSnapshotDBs.DatabaseName,''''),1,2,'''') As DBName
From sys.databases Databases
CROSS APPLY (SELECT '' , '' + QUOTENAME(NAME) 
			 FROM SYS.DATABASES NonOnlineDBs
			 WHERE Databases.State_desc = NonOnlineDBs.State_desc
			 AND (NonOnlineDBs.State_desc != ''Online'' AND source_database_id IS NULL)
			 FOR XML PATH('''')) NonOnlineDBs (Databasename)
CROSS APPLY (SELECT '' , '' + QUOTENAME(NAME) 
			 FROM SYS.DATABASES OldSnapshotDBs
			 WHERE Databases.State_desc = OldSnapshotDBs.State_desc
			 AND source_database_id IS NOT NULL 
			 AND create_date < DATEADD(DAY,-10,GetDate())
			 FOR XML PATH('''')) OldSnapshotDBs (Databasename)
) DatabaseStates
GROUP BY State_desc,DBName
ORDER BY COUNT(State_desc) DESC

END;'

EXEC(@SQLStatement)


SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[DriveSpaceInsert] 
AS
BEGIN

--Revision date: 31/01/2018

DECLARE @Retention INT = (SELECT Value From '+@LinkedServerName+'['+@Databasename+'].[Inspector].[Settings] Where Description = ''DriveSpaceRetentionPeriodInDays'')

DELETE FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DriveSpace] 
WHERE Log_Date < DATEADD(DAY,-@Retention,DATEADD(DAY,1,CAST(GETDATE() AS DATE)))
AND Servername = @@SERVERNAME;


IF NOT EXISTS (SELECT Log_Date FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DriveSpace] WHERE Servername = @@SERVERNAME AND CAST(Log_Date AS DATE) = CAST(GETDATE() AS DATE))
	BEGIN
		--RECORD THE DRIVE SPACE CAPACITY AND AVAILABLE SPACE PER DAY
		INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DriveSpace] (Servername, Log_Date, Drive, Capacity_GB, AvailableSpace_GB)
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


EXEC(@SQLStatement)


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[FailedAgentJobsInsert]
AS
BEGIN

--Revision date: 31/01/2018

SET NOCOUNT ON;

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[FailedAgentJobs]
WHERE Servername = @ServerName;

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[FailedAgentJobs] (ServerName,Log_Date,JobName,LastStepFailed,LastFailedDate,LastError)
SELECT 
@ServerName,
GETDATE(),
Jobs.name,
JobHistory.step_id,
JobHistory.FailedRunDate,
CAST(JobHistory.LastError AS VARCHAR(250))
FROM msdb.dbo.sysjobs Jobs
--Get the most recent Failure Datetime for each failed job within @FromDate and @ToDate
CROSS APPLY (SELECT TOP 1 JobHistory.step_id,JobHistory.run_date,
					CASE JobHistory.run_date WHEN 0 THEN NULL ELSE
					CONVERT(DATETIME, 
								STUFF(STUFF(CAST(JobHistory.run_date AS NCHAR(8)), 7, 0, ''-''), 5, 0, ''-'') + N'' '' + 
								STUFF(STUFF(SUBSTRING(CAST(1000000 + JobHistory.run_time AS NCHAR(7)), 2, 6), 5, 0, '':''), 3, 0, '':''), 
								120) END AS [FailedRunDate] ,
								[Message] AS LastError
					FROM msdb.dbo.sysjobhistory JobHistory
					WHERE 	Run_status = 0 
					AND  Jobs.job_id = JobHistory.job_id
					ORDER BY 
					[FailedRunDate] DESC,
					step_id DESC) JobHistory
								
WHERE Jobs.enabled = 1
AND JobHistory.FailedRunDate > CAST(DATEADD(DAY,-1,CAST(GETDATE() AS DATE)) AS DATETIME)
--Check that each job has not succeeded since the last failure
AND NOT EXISTS (SELECT [LastSuccessfulrunDate] 
				FROM(
				SELECT CASE JobHistory.run_date WHEN 0 THEN NULL ELSE
				CONVERT(DATETIME, 
				STUFF(STUFF(CAST(JobHistory.run_date AS NCHAR(8)), 7, 0, ''-''), 5, 0, ''-'') + N'' '' + 
				STUFF(STUFF(SUBSTRING(CAST(1000000 + JobHistory.run_time AS NCHAR(7)), 2, 6), 5, 0, '':''), 3, 0, '':''), 
					120) END AS [LastSuccessfulrunDate] 
				FROM msdb.dbo.sysjobhistory JobHistory
				WHERE 	Run_status = 1
				AND  Jobs.job_id = JobHistory.job_id
						) LastSuccessfulJobrun
WHERE LastSuccessfulJobrun.[LastSuccessfulrunDate] > JobHistory.[FailedRunDate])
--Ensure that the job is not currently running
AND NOT EXISTS (SELECT NAME
				FROM msdb.dbo.sysjobactivity JobActivity
				WHERE Jobs.job_id = JobActivity.job_id 
				AND start_execution_date > DATEADD(MINUTE,-30,GETDATE())
				AND stop_execution_date is null
					) 
--Only show failed jobs where the Failed step is NOT configured to quit reporting success on error
AND NOT EXISTS (SELECT 1
				FROM msdb..sysjobsteps ReportingSuccessSteps
				WHERE Jobs.job_id = ReportingSuccessSteps.job_id
				AND JobHistory.step_id = ReportingSuccessSteps.step_id
				AND on_fail_action = 1 -- quit job reporting success
				)
				
ORDER BY NAME ASC

IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[FailedAgentJobs]
			WHERE Servername = @ServerName)
			BEGIN 
			INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[FailedAgentJobs] (ServerName,Log_Date,JobName,LastStepFailed,LastFailedDate,LastError)
			VALUES(@ServerName,GETDATE(),''No Failed Jobs present'',NULL,NULL,NULL)
			END

END;'

EXEC(@SQLStatement)


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[LoginAttemptsiInsert]
AS
BEGIN

--Revision date: 31/01/2018

SET NOCOUNT ON;

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[LoginAttempts]
WHERE Servername = @ServerName;
 
IF OBJECT_ID(''Tempdb..#Errors'') IS NOT NULL
DROP TABLE #Errors; 

CREATE TABLE #Errors  
(
Logdate Datetime,
Processinfo Varchar(30),
Text Varchar (255)
);

DECLARE @StartTime DATETIME = DATEADD(DAY,-1,GETDATE())

INSERT INTO #Errors ([Logdate],[Processinfo],[Text])
EXEC xp_ReadErrorLog 0, 1, N''FAILED'',N''login'',@StartTime,NULL;

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[LoginAttempts] (ServerName,Log_Date,Username,Attempts,LastErrorDate,LastError)
SELECT 
@ServerName,
GetDate(), 
REPLACE(LoginErrors.Username,'''''''',''''),
CAST(LoginErrors.Attempts AS NVARCHAR(6)),
LatestDate.Logdate,
Latestdate.LastError
FROM (
SELECT SUBSTRING(text,PATINDEX(''%''''%''''%'',Text),CHARINDEX(''.'',Text)-(PATINDEX(''%''''%''''%'',Text))) as Username,Count(*) Attempts
FROM #Errors Errors
GROUP BY SUBSTRING(text,PATINDEX(''%''''%''''%'',Text),CHARINDEX(''.'',Text)-(PATINDEX(''%''''%''''%'',Text)))
) LoginErrors
CROSS APPLY (SELECT TOP 1 Logdate,text as LastError
		  FROM #Errors LatestDate
		  WHERE  LoginErrors.Username = SUBSTRING(text,Patindex(''%''''%''''%'',Text),charindex(''.'',Text)-(Patindex(''%''''%''''%'',Text)))
		  ORDER by Logdate DESC) LatestDate

ORDER BY Attempts DESC

IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[LoginAttempts]
			WHERE Servername = @ServerName)
			BEGIN 
			INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[LoginAttempts] (ServerName,Log_Date,Username,Attempts,LastErrorDate,LastError)
			VALUES(@ServerName,GETDATE(),''No Failed Logins present'',NULL,NULL,NULL)
			END

END;'


EXEC(@SQLStatement)


SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[JobOwnerInsert]
AS
BEGIN

--Revision date: 31/01/2018

SET NOCOUNT ON;

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME
DECLARE @AgentjobOwnerExclusions VARCHAR(255) = (SELECT REPLACE([Value],'' '','''') FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[Settings] WHERE [Description] = ''AgentJobOwnerExclusions'')

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[JobOwner]
WHERE Servername = @ServerName;

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[JobOwner] (ServerName,Log_Date,Job_ID,JobName)
SELECT 
@ServerName,
GetDate(),
jobs.Job_ID,
jobs.[name] 
FROM msdb.dbo.sysjobs jobs
INNER join master.sys.syslogins logins ON jobs.owner_sid = logins.sid
WHERE logins.name NOT IN ('+CASE WHEN @Compatibility = 0 
					   THEN 'SELECT [StringElement]  
						   FROM Master.dbo.fn_SplitString(@AgentjobOwnerExclusions,'','')'
					   ELSE 'SELECT [Value]  
						   FROM STRING_SPLIT(@AgentjobOwnerExclusions,'','')'
					   END +
						  ')
AND jobs.enabled = 1

IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[JobOwner]
			WHERE Servername = @ServerName)
			BEGIN 
			INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[JobOwner] (ServerName,Log_Date,Job_ID,JobName)
			VALUES(@ServerName,GETDATE(),NULL,''No Job Owner issues present'')
			END

END;'


EXEC(@SQLStatement)


SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[TopFiveDatabasesInsert]
AS
BEGIN

--Revision date: 31/01/2018

SET NOCOUNT ON;

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[TopFiveDatabases]
WHERE Servername = @ServerName;

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[TopFiveDatabases] (ServerName,Log_Date,Databasename,TotalSize_MB)
SELECT TOP 5 
@ServerName,
GetDate(),
Databasename,
[TotalSize(MB)]
FROM 
(
    SELECT DBs.name AS Databasename,
    SUM((CAST(DBFiles.size AS BIGINT)*8)/1024 ) [TotalSize(MB)] 
    FROM [sys].[master_files] DBFiles
    INNER JOIN sys.databases DBs ON DBFiles.database_id = DBs.database_id
    GROUP BY DBs.name
) Sizes
ORDER BY [TotalSize(MB)] DESC

END ;'

EXEC(@SQLStatement)


SET @SQLStatement =  CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[BackupsCheckInsert]
AS
BEGIN

--Revision date: 31/01/2018

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME;
DECLARE @FullBackupThreshold INT = (Select [Value] FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[Settings] WHERE Description = ''FullBackupThreshold'')

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[BackupsCheck]
WHERE Servername = @ServerName;

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 


IF OBJECT_ID(''Tempdb..#DatabaseList'') IS NOT NULL
DROP TABLE #DatabaseList;

CREATE TABLE #DatabaseList
(
Database_id INT,
ServerName NVARCHAR(128),
Log_Date DATETIME,
Databasename NVARCHAR(128),
AGName NVARCHAR(128),
[State] TINYINT,
Source_database_id INT,
IsFullRecovery BIT,
IsSystemDB BIT
);

IF OBJECT_ID(''Tempdb..#BackupAggregation'') IS NOT NULL
DROP TABLE #BackupAggregation;


CREATE TABLE #BackupAggregation
(
Database_id INT,
Databasename NVARCHAR(128),
[Full] DATETIME,
[Diff] DATETIME,
[Log] DATETIME
);

INSERT INTO #DatabaseList ([Database_id],[ServerName],[Log_Date],[Databasename],[AGName],[State],[Source_database_id],[IsFullRecovery],[IsSystemDB])
SELECT DISTINCT
Database_id,
@ServerName AS Servername,
Getdate() AS Log_Date,
sys.databases.NAME AS Databasename,
AG.NAME AS AGName,
[State],
Source_database_id,
CASE WHEN recovery_model_desc = ''FULL'' THEN 1 WHEN recovery_model_desc IS NULL THEN 1 ELSE 0 END AS IsFullRecovery,
CASE WHEN database_id <= 4 THEN 1 ELSE 0 END AS IsSystemDB
FROM sys.databases 
INNER JOIN sys.availability_replicas ar ON sys.databases.replica_id = ar.replica_id
INNER JOIN sys.availability_groups ag ON ar.group_id = AG.group_id 
WHERE database_id != 2
AND [State] = 0 
AND source_database_id IS NULL

UNION ALL 

SELECT
Database_id,
@ServerName AS Servername,
Getdate() AS Log_Date,
sys.databases.NAME AS Databasename,
NULL AS AGName,
[State],
Source_database_id,
CASE WHEN recovery_model_desc = ''FULL'' THEN 1 WHEN recovery_model_desc IS NULL THEN 1 ELSE 0 END AS IsFullRecovery,
CASE WHEN database_id <= 4 THEN 1 ELSE 0 END AS IsSystemDB
FROM sys.databases 
WHERE database_id != 2
AND [State] = 0 
AND source_database_id IS NULL
and replica_id is NULL
ORDER BY Database_id


INSERT INTO #BackupAggregation ([Database_id],[Databasename],[Full],[Diff],[Log])
SELECT Database_id,database_name AS Dbname, [D], [I], [L]    
FROM 
(SELECT Database_ID,backuplog.database_name,backuplog.Type,MAX(backuplog.Backup_finish_date) AS Backup_Finish_Date                                   
FROM msdb..backupset backuplog
INNER JOIN #DatabaseList ON #DatabaseList.Databasename = backuplog.database_name  
WHERE 
backup_finish_date > DATEADD(DAY,-@FullBackupThreshold,CAST(GetDate() AS DATE))
GROUP BY Database_ID,backuplog.database_name,backuplog.Type ) p
PIVOT( MAX(Backup_finish_date) FOR Type IN ([D],[I],[L])) d
ORDER BY Database_id ASC

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[BackupsCheck] ([ServerName],[Log_Date],[Databasename],[AGname],[FULL],[DIFF],[LOG],[IsFullRecovery],[IsSystemDB])
SELECT 
[ServerName],
[Log_Date],
#DatabaseList.[Databasename],
COALESCE(#DatabaseList.AGName,''Not in an AG'') AS AGname,
ISNULL([FULL],''19000101'') AS [FULL],
ISNULL([DIFF],''19000101'') AS [DIFF],
ISNULL([LOG],''19000101'') AS [LOG],
[IsFullRecovery],
[IsSystemDB]
FROM #DatabaseList
LEFT JOIN #BackupAggregation ON #DatabaseList.Database_ID = #BackupAggregation.Database_ID
WHERE ([State] = 0 AND source_database_id IS NULL) 

END 
ELSE 
BEGIN 

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[BackupsCheck] ([ServerName],[Log_Date],[Databasename],[AGname],[FULL],[DIFF],[LOG],[IsFullRecovery],[IsSystemDB])  
SELECT DISTINCT @ServerName,Getdate(),dbs.name,@ServerName +''(Non AG)'' AS AGname,ISNULL([D],''19000101''),ISNULL([I],''19000101''),ISNULL([L],''19000101''),
CASE WHEN dbs.recovery_model_desc = ''FULL'' THEN 1 ELSE 0 END,
CASE WHEN dbs.database_id <= 4 THEN 1 ELSE 0 END AS IsSystemDB
FROM (SELECT backuplog.database_name,backuplog.Type,MAX(backuplog.Backup_finish_date) AS Backup_Finish_Date                                     
       FROM msdb..backupset backuplog                         
WHERE 
backup_finish_date > DATEADD(DAY,-@FullBackupThreshold,CAST(GetDate() AS DATE))
GROUP BY backuplog.database_name,backuplog.Type ) p
PIVOT( MAX(Backup_finish_date) FOR Type IN ([D],[I],[L])) d
RIGHT JOIN sys.databases dbs ON d.database_name = dbs.name
WHERE database_id != 2
AND [State] = 0 
AND source_database_id IS NULL
END

			
END;'

EXEC(@SQLStatement)

SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[DatabaseGrowthsInsert]
AS

--Revision date: 31/01/2018

     SET NOCOUNT ON;

     BEGIN

         DECLARE @Servername NVARCHAR(128)= @@Servername;

--Insert any databases that are present on the serverbut not present in [Inspector].[DatabaseFileSizes]
         IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
             BEGIN
                 INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes]
                 ([Servername],
                  [Database_id],
                  [Database_name],
                  [OriginalDateLogged],
                  [OriginalSize_MB],
                  [type_desc],
                  [File_id],
                  [Filename],
                  [PostGrowthSize_MB],
                  [GrowthRate],
                  [Is_percent_growth],
                  [NextGrowth]
                 )

                 SELECT    @Servername,
                           [MasterFiles].[Database_id],
                           DB_NAME([Masterfiles].[Database_id]) AS [Database_name],
                           GETDATE() AS [OriginalDateLogged],
                           CAST([Masterfiles].[Size] AS BIGINT) * 8 / 1024 AS [OriginalSize_MB],
                           [Masterfiles].[type_desc],
                           [MasterFiles].[File_id],
                           RIGHT([Masterfiles].[Physical_name],CHARINDEX(''\'',REVERSE([Masterfiles].[Physical_name]))-1) AS [Filename], --Get the Filename
                           CAST([Masterfiles].[Size] AS BIGINT) * 8 / 1024 AS [PostGrowthSize_MB],
                           CASE [Masterfiles].[is_percent_Growth]
                               WHEN 0
                               THEN([Masterfiles].[Growth] * 8) / 1024
                               WHEN 1
                               THEN(((CAST([Size] AS BIGINT) * 8) / 1024) * [Growth]) / 100
                           END AS [GrowthRate_MB],			
                           [Masterfiles].[Is_percent_growth],
                           CASE [Masterfiles].[is_percent_growth]
                               WHEN 0
                               THEN((CAST([Size] AS BIGINT) * 8) / 1024) + ([Growth] * 8) / 1024
                               WHEN 1
                               THEN((CAST([Size] AS BIGINT) * 8) / 1024) + (((CAST([Size] AS BIGINT) * 8) / 1024) * [Growth]) / 100
                           END [NextGrowth]													
                 FROM      [sys].[master_files] [Masterfiles]
                           LEFT JOIN
                 (
                     SELECT DB_ID([ADC].[database_name]) AS [Database_ID]
                     FROM   [sys].[dm_hadr_availability_group_states] [st]
                            INNER JOIN [Sys].[availability_databases_cluster] [ADC] ON [ST].[group_id] = [ADC].[group_id]
                     WHERE  [primary_replica] = @@Servername
                 ) [DatabaseList] ON [DatabaseList].[Database_ID] = [Masterfiles].[Database_ID]
                 WHERE [Masterfiles].[Database_ID] > 3
                       AND [type_desc] = ''ROWS''
                       AND NOT EXISTS
                 (
                     SELECT [Database_id]
                     FROM   '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [DatabaseFileSizes]
                     WHERE  [Servername] = @Servername
                            AND DB_NAME([Masterfiles].[database_id]) = [DatabaseFileSizes].[Database_name]
                            AND [Masterfiles].[file_id] = [DatabaseFileSizes].[file_id]
                 )
                 ORDER BY DB_NAME([Masterfiles].[Database_id]) ASC,
                          [Type] ASC;
         END
             ELSE
             BEGIN
                 INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes]
                 ([Servername],
                  [Database_id],
                  [Database_name],
                  [OriginalDateLogged],
                  [OriginalSize_MB],
                  [type_desc],
                  [File_id],
                  [Filename],
                  [PostGrowthSize_MB],
                  [GrowthRate],
                  [Is_percent_growth],
                  [NextGrowth]
                 )

                 SELECT @@SERVERNAME,
                        [MasterFiles].[Database_id],
                        DB_NAME([Masterfiles].[Database_id]) AS [Database_name],
                        GETDATE() AS [OriginalDateLogged],
                        CAST([Masterfiles].[Size] AS BIGINT) * 8 / 1024 AS [OriginalSize_MB],
                        [Masterfiles].[type_desc],
                        [MasterFiles].[File_id],
                        RIGHT([Masterfiles].[Physical_name],CHARINDEX(''\'',REVERSE([Masterfiles].[Physical_name]))-1) AS [Filename], 
                        CAST([Masterfiles].[Size] AS BIGINT) * 8 / 1024 AS [PostGrowthSize_MB],
                        CASE [Masterfiles].[is_percent_Growth]
                            WHEN 0
                            THEN([Masterfiles].[Growth] * 8) / 1024
                            WHEN 1
                            THEN(((CAST([Size] AS BIGINT) * 8) / 1024) * [Growth]) / 100
                        END AS [GrowthRate_MB],			
                        [Masterfiles].[Is_percent_growth],
                        CASE [Masterfiles].[is_percent_growth]
                            WHEN 0
                            THEN((CAST([Size] AS BIGINT) * 8) / 1024) + ([Growth] * 8) / 1024
                            WHEN 1
                            THEN((CAST([Size] AS BIGINT) * 8) / 1024) + (((CAST([Size] AS BIGINT) * 8) / 1024) * [Growth]) / 100
                        END [NextGrowth]													
                 FROM   [sys].[master_files] [Masterfiles]
                 WHERE  [Masterfiles].[Database_ID] > 3
                        AND [type_desc] = ''ROWS''
                        AND NOT EXISTS
                 (
                     SELECT [Database_id]
                     FROM   '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [DatabaseFileSizes]
                     WHERE  [Servername] = @Servername
                            AND DB_NAME([Masterfiles].[database_id]) = [DatabaseFileSizes].[Database_name]
                            AND [Masterfiles].[file_id] = [DatabaseFileSizes].[file_id]
                 )
                 ORDER BY DB_NAME([Masterfiles].[Database_id]) ASC,
                          [Type] ASC;
         END

--Remove any databases that have been dropped from SQL but still present in [Inspector].[DatabaseFileSizes]
         DELETE [Sizes]
         FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes]
              LEFT JOIN [sys].[databases] [DatabasesList] ON [Sizes].[database_name] = [DatabasesList].[name] COLLATE DATABASE_DEFAULT
         WHERE  [Sizes].[Servername] = @Servername
                AND [DatabasesList].[database_id] IS NULL;

--Ensure that the Database_Id column is synced in the base table as a database may have been dropped and restored as a new Database_id
         UPDATE [Sizes]
         SET
               [database_id] = [DatabasesList].[database_id]
         FROM   '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes]
                INNER JOIN [sys].[databases] [DatabasesList] ON [Sizes].[database_name] = [DatabasesList].[name] COLLATE DATABASE_DEFAULT
         WHERE  [Sizes].[Servername] = @Servername
                AND [DatabasesList].[database_id] != [Sizes].[Database_id];

--Keep the base table in sync by checking if the growth rates have changed - if they have then update the base table
         UPDATE    [Sizes]
         SET
               [GrowthRate] = [GrowthCheck].[GrowthRate_MB],
               [Is_percent_growth] = [GrowthCheck].[Is_percent_growth]
         FROM
         (
             SELECT [MasterFiles].[Database_id],
                    [MasterFiles].[File_id],
                    CASE [Masterfiles].[is_percent_Growth]
                        WHEN 0
                        THEN([Masterfiles].[Growth] * 8) / 1024
                        WHEN 1
                        THEN(((CAST([Size] AS BIGINT) * 8) / 1024) * [Growth]) / 100
                    END AS [GrowthRate_MB],			--IN MB , The physical value expressed as a number
                    [Masterfiles].[Is_percent_growth]
             FROM   [sys].[master_files] [Masterfiles]
                    INNER JOIN [sys].[databases] [DatabasesList] ON [Masterfiles].[database_id] = [DatabasesList].[database_id]
             WHERE  [Masterfiles].[Database_ID] > 3
                    AND [Type_desc] = ''ROWS''
                    AND [DatabasesList].State = 0
         ) [GrowthCheck]
         INNER JOIN '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes] ON [GrowthCheck].[Database_id] = [Sizes].[Database_id]
                                                                                      AND [Sizes].[File_id] = [GrowthCheck].[File_id]
         WHERE(([GrowthCheck].[GrowthRate_MB] != [Sizes].[GrowthRate])
               OR ([Growthcheck].[is_Percent_Growth] != [Sizes].[Is_percent_growth]))
              AND [ServerName] = @Servername;

--Log the Database Growth event
         INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizeHistory]
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

         SELECT [DatabaseFileSizes].[ServerName],
                [MasterFiles].[Database_id],
                DB_NAME([Masterfiles].[Database_id]) AS [Database_name],
                GETDATE() AS [Log_Date],
                [Masterfiles].[type_desc],
                [MasterFiles].[File_id],
                RIGHT([Masterfiles].[Physical_name],CHARINDEX(''\'',REVERSE([Masterfiles].[Physical_name]))-1) AS [Filename], --Get the Filename
                [DatabaseFileSizes].[PostGrowthSize_MB],  --PostGrowth size is the Last recorded database size after a growth event
                [DatabaseFileSizes].[Growthrate],
                (((CAST([Masterfiles].[Size] AS BIGINT) * 8) / 1024 - [DatabaseFileSizes].[PostGrowthSize_MB]) / [DatabaseFileSizes].[GrowthRate]) AS [TotalGrowthIncrements],  --IF Growth is in Percent then this will be calculated based on the Current DB size Less Originally logged size , Divided by the Growth percentage based on the original database size
                (CAST([Masterfiles].[Size] AS BIGINT) * 8) / 1024 AS [CurrentSize_MB] --Next approx Growth interval in MB
         FROM   '+@LinkedServerName+'['+@Databasename+'].[Inspector].[databasefilesizes] [DatabaseFileSizes]
                INNER JOIN [sys].[master_files] [Masterfiles] ON [Masterfiles].[Database_id] = [DatabaseFileSizes].[Database_id]
                                                                 AND [DatabaseFileSizes].[File_id] = [Masterfiles].[file_id]
         WHERE  [NextGrowth] < (CAST([Masterfiles].[Size] AS BIGINT) * 8) / 1024
                AND [DatabaseFileSizes].[ServerName] = @Servername
			 AND NOT EXISTS (
						  SELECT GrowthID
						  FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizeHistory] ExistingRecord
						  WHERE [Servername] = @Servername 
						  AND DB_NAME([Masterfiles].[Database_id]) = [Database_name]
						  AND CAST([Log_Date] AS DATE) = CAST(GETDATE() AS DATE)
						  ); --Ensure that there has not been any growths logged for today before recording as this will affect thresholds. 
						     --(this allows the collection to be ran without worrying that the growths will be logged prematurely)

 
--Double check the databases sizes in the base table are correct and update as required
         UPDATE [Sizes]
         SET    [PostGrowthSize_MB] = (CAST([Masterfiles].[Size] AS BIGINT) * 8) / 1024
         FROM   [sys].[master_files] [Masterfiles]
                INNER JOIN '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes] [Sizes] ON [Masterfiles].[database_id] = [Sizes].[database_id]
                                                                                             AND [Sizes].[File_id] = [Masterfiles].[File_id]
         WHERE  [Masterfiles].[Database_ID] > 3
                AND ((CAST([Masterfiles].[Size] AS BIGINT) * 8) / 1024 != [Sizes].[PostGrowthSize_MB])
                AND [Servername] = @Servername;

--Set Next growth size for all Databases on this server which have grown
         UPDATE '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizes]
         SET    [NextGrowth] = ([PostGrowthSize_MB] + [GrowthRate])
         WHERE  [NextGrowth] <= [PostGrowthSize_MB]
                AND [ServerName] = @Servername;


--Clean up the history for growths older than 90 days
         DELETE FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseFileSizeHistory]
         WHERE [Log_Date] < DATEADD(DAY,-90,GETDATE())
         AND [Servername] = @Servername;

     END;'

EXEC(@SQLStatement)



SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[DatabaseOwnershipInsert]
AS
BEGIN

--Revision date: 31/01/2018

DECLARE @ServerName NVARCHAR(128) = @@SERVERNAME;
DECLARE @DatabaseOwnerExclusions NVARCHAR(255) = (SELECT REPLACE(Value,'' '','''') from '+@LinkedServerName+'['+@Databasename+'].Inspector.Settings where Description = ''DatabaseOwnerExclusions'');

DELETE 
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseOwnership]
WHERE Servername = @ServerName;

IF SERVERPROPERTY(''IsHadrEnabled'') = 1 AND EXISTS (SELECT name FROM sys.availability_groups)
BEGIN 
INSERT INTO '+@LinkedServerName+'['+@Databasename+'].Inspector.DatabaseOwnership ([ServerName],[Log_Date],[AGname],[Database_name],[Owner])
SELECT 
@ServerName,
GETDATE(),
AG.Name as AGName,
Databases.[Name],
COALESCE(SUSER_SNAME(Databases.[Owner_sid]),''Blank'')
FROM sys.dm_hadr_availability_group_states st
INNER JOIN master.sys.availability_groups ag ON ST.group_id = AG.group_id
INNER JOIN Sys.availability_databases_cluster ADC ON AG.group_id = ADC.group_id
INNER JOIN Sys.Databases Databases ON Databases.Name = ADC.database_name
WHERE primary_replica = @@Servername
AND Databases.OWNER_SID NOT IN ('+CASE WHEN @Compatibility = 0 
						    THEN 'SELECT SUSER_SID([StringElement])  
								FROM Master.dbo.fn_SplitString(@DatabaseOwnerExclusions,'','')'
						    ELSE 'SELECT SUSER_SID([Value])  
								FROM STRING_SPLIT(@DatabaseOwnerExclusions,'','')'
						    END+
						  ')
AND Databases.State = 0 
UNION ALL 
SELECT 
@ServerName,
GETDATE(),
''Not in an AG'' as AGName,
Databases.[Name],
COALESCE(SUSER_SNAME(Databases.[Owner_sid]),''Blank'')
FROM sys.Databases 
WHERE replica_id IS NULL
AND Databases.OWNER_SID NOT IN ('+CASE WHEN @Compatibility = 0
						    THEN 'SELECT SUSER_SID([StringElement])  
								FROM Master.dbo.fn_SplitString(@DatabaseOwnerExclusions,'','')'
						    ELSE 'SELECT SUSER_SID([Value])  
								FROM STRING_SPLIT(@DatabaseOwnerExclusions,'','')'
						    END+
						  ')
AND Databases.State = 0 
AND Source_database_id IS NULL
ORDER BY Databases.Name ASC
END
ELSE 
BEGIN 
INSERT INTO '+@LinkedServerName+'['+@Databasename+'].Inspector.DatabaseOwnership ([ServerName],[Log_Date],[AGname],[Database_name],[Owner])
SELECT 
@ServerName,
GETDATE(),
''N/A'' as AGName,
Databases.[Name],
COALESCE(SUSER_SNAME(Databases.[Owner_sid]),''Blank'')
FROM sys.Databases 
WHERE replica_id IS NULL
AND Databases.OWNER_SID NOT IN ('+CASE WHEN @Compatibility = 0
						    THEN 'SELECT SUSER_SID([StringElement])  
								FROM Master.dbo.fn_SplitString(@DatabaseOwnerExclusions,'','')'
						    ELSE 'SELECT SUSER_SID([Value])  
								FROM STRING_SPLIT(@DatabaseOwnerExclusions,'','')'
						    END+
						  ')
AND Databases.State = 0 
AND Source_database_id IS NULL
ORDER BY Databases.Name ASC
END

IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseOwnership]
			WHERE Servername = @ServerName)
			BEGIN 
			INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseOwnership] ([ServerName],[Log_Date],[AGname],[Database_name],[Owner])
			VALUES(@ServerName,GETDATE(),NULL,''No Database Ownership issues present'',NULL)
			END
			
END;'

EXEC(@SQLStatement)


SET @SQLStatement = 
'CREATE PROCEDURE [Inspector].[BackupSizesByDayInsert]
AS
BEGIN

--Revision date: 31/01/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME

DELETE FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[BackupSizesByDay]
WHERE Servername = @@Servername;

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[BackupSizesByDay] ([ServerName],[Log_Date],[DayOfWeek],[CastedDate],[TotalSizeInBytes])
SELECT 
@SERVERNAME,
GETDATE(),
[DayOfWeek] ,
[CastedDate],
[TotalSizeInBytes]
FROM (
SELECT 
DATENAME(WEEKDAY,Backup_start_date) AS [DayOfWeek],
CAST(Backup_Start_date AS DATE) AS [CastedDate] ,
SUM(COALESCE(Compressed_Backup_Size,Backup_Size)) AS [TotalSizeInBytes]
FROM Msdb..BackupSet 
WHERE Backup_Start_Date >= DATEADD(DAY,-7,CAST(GETDATE() AS DATE))
GROUP BY DATENAME(WEEKDAY,Backup_start_date) ,CAST(Backup_Start_date AS DATE)
) as BackupSizesbyDay;


IF NOT EXISTS (SELECT Servername
			FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[BackupSizesByDay]
			WHERE Servername = @ServerName)
			BEGIN 
			INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[BackupSizesByDay] ([ServerName],[Log_Date],[DayOfWeek],[CastedDate],[TotalSizeInBytes])
			VALUES(@ServerName,NULL,NULL,NULL,NULL)
			END

END;'


EXEC(@SQLStatement)


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'CREATE PROCEDURE [Inspector].[DatabaseSettingsInsert]

AS

BEGIN

--Revision date: 31/01/2018

DECLARE @Servername NVARCHAR(128) = @@SERVERNAME 
DECLARE @LogDate DATETIME = GETDATE()

DELETE FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings]
WHERE Servername = @Servername

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''Collation_name'',
ISNULL(Collation_name,''None'')   ,
Count(Collation_Name)  
FROM sys.databases
GROUP BY Collation_name


INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_close_on'',
CASE is_auto_close_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
Count(is_auto_close_on)  
FROM sys.databases
GROUP BY is_auto_close_on


INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_shrink_on'',
CASE is_auto_shrink_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
Count(is_auto_shrink_on)  
FROM sys.databases
GROUP BY is_auto_shrink_on


INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_auto_update_stats_on'',
CASE is_auto_update_stats_on WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
Count(is_auto_update_stats_on)  
FROM sys.databases
GROUP BY is_auto_update_stats_on


INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''is_read_only'',
CASE is_read_only WHEN 1 THEN ''Enabled'' ELSE ''Disabled'' END   ,
Count(is_read_only)  
FROM sys.databases
GROUP BY is_read_only

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''user_access_desc'', 
user_access_desc, 
Count(user_access_desc)  
FROM sys.databases
GROUP BY user_access_desc

INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''compatibility_level'',
[compatibility_level],
Count([compatibility_level])  
FROM sys.databases
GROUP BY [compatibility_level]


INSERT INTO '+@LinkedServerName+'['+@Databasename+'].[Inspector].[DatabaseSettings] (Servername,Log_Date,Setting,Description,Total)
SELECT 
@Servername,
@LogDate,
''recovery_model_desc'',
recovery_model_desc,
Count(recovery_model_desc)  
FROM sys.databases
GROUP BY recovery_model_desc

END;'

EXEC(@SQLStatement)


IF @InitialSetup = 0
BEGIN
--Insert Preserved data into Inspector Data Base tables
	IF OBJECT_ID('Inspector.ADHocDatabaseCreations_Copy') IS NOT NULL
	INSERT INTO [Inspector].[ADHocDatabaseCreations] 
	SELECT * FROM [Inspector].[ADHocDatabaseCreations_Copy]

	IF OBJECT_ID('Inspector.ADHocDatabaseSupression_Copy') IS NOT NULL
	INSERT INTO [Inspector].[ADHocDatabaseSupression] 
	SELECT * FROM [Inspector].[ADHocDatabaseSupression_Copy]
	
	IF OBJECT_ID('Inspector.AGCheck_Copy') IS NOT NULL
	INSERT INTO [Inspector].[AGCheck] 
	SELECT * FROM [Inspector].[AGCheck_Copy]
	
	IF OBJECT_ID('Inspector.BackupsCheck_Copy') IS NOT NULL
	INSERT INTO [Inspector].[BackupsCheck] 
	SELECT * FROM [Inspector].[BackupsCheck_Copy]
	
	IF OBJECT_ID('Inspector.BackupSizesByDay_Copy') IS NOT NULL
	INSERT INTO [Inspector].[BackupSizesByDay] 
	SELECT * FROM [Inspector].[BackupSizesByDay_Copy]
	
	IF OBJECT_ID('Inspector.DatabaseFiles_Copy') IS NOT NULL
	INSERT INTO [Inspector].[DatabaseFiles] 
	SELECT * FROM [Inspector].[DatabaseFiles_Copy]
	
	IF OBJECT_ID('Inspector.DatabaseFileSizes_Copy') IS NOT NULL
	INSERT INTO [Inspector].[DatabaseFileSizes] 
	SELECT * FROM [Inspector].[DatabaseFileSizes_Copy]
	
	IF OBJECT_ID('Inspector.DatabaseOwnership_Copy') IS NOT NULL
	INSERT INTO [Inspector].[DatabaseOwnership] 
	SELECT * FROM [Inspector].[DatabaseOwnership_Copy]
	
	IF OBJECT_ID('Inspector.DatabaseSettings_Copy') IS NOT NULL
	INSERT INTO [Inspector].[DatabaseSettings] 
	SELECT * FROM [Inspector].[DatabaseSettings_Copy]
	
	IF OBJECT_ID('Inspector.DatabaseStates_Copy') IS NOT NULL
	INSERT INTO [Inspector].[DatabaseStates] 
	SELECT * FROM [Inspector].[DatabaseStates_Copy]
	
	IF OBJECT_ID('Inspector.DriveSpace_Copy') IS NOT NULL
	INSERT INTO [Inspector].[DriveSpace] 
	SELECT * FROM [Inspector].[DriveSpace_Copy]
	
	IF OBJECT_ID('Inspector.FailedAgentJobs_Copy') IS NOT NULL
	INSERT INTO [Inspector].[FailedAgentJobs] 
	SELECT * FROM [Inspector].[FailedAgentJobs_Copy]
	
	IF OBJECT_ID('Inspector.JobOwner_Copy') IS NOT NULL
	INSERT INTO [Inspector].[JobOwner] 
	SELECT * FROM [Inspector].[JobOwner_Copy]
	
	IF OBJECT_ID('Inspector.LoginAttempts_Copy') IS NOT NULL
	INSERT INTO [Inspector].[LoginAttempts] 
	SELECT * FROM [Inspector].[LoginAttempts_Copy]
	
	IF OBJECT_ID('Inspector.ReportData_Copy') IS NOT NULL
	BEGIN
	INSERT INTO [Inspector].[ReportData] ([ReportDate],[ModuleConfig],[ReportData])
	SELECT [ReportDate],[ModuleConfig],[ReportData] FROM [Inspector].[ReportData_Copy]
	END
	
	IF OBJECT_ID('Inspector.TopFiveDatabases_Copy') IS NOT NULL
	INSERT INTO [Inspector].[TopFiveDatabases] 
	SELECT * FROM [Inspector].[TopFiveDatabases_Copy]
	
	
	IF OBJECT_ID('Inspector.DatabaseFileSizeHistory_Copy') IS NOT NULL
	BEGIN
	SET IDENTITY_INSERT [Inspector].[DatabaseFileSizeHistory] ON 
	INSERT INTO [Inspector].[DatabaseFileSizeHistory] ([GrowthID],[Database_id],[Database_name],[File_id],[FileName],[GrowthIncrements],[GrowthRate_MB],[Log_Date],[PostGrowthSize_MB],[PreGrowthSize_MB],[ServerName],[Type_Desc]) 
	SELECT [GrowthID],[Database_id],[Database_name],[File_id],[FileName],[GrowthIncrements],[GrowthRate_MB],[Log_Date],[PostGrowthSize_MB],[PreGrowthSize_MB],[ServerName],[Type_Desc] 
	FROM [Inspector].[DatabaseFileSizeHistory_Copy] 
	SET IDENTITY_INSERT [Inspector].[DatabaseFileSizeHistory] OFF
	END

END


--Drop Preserved Data/Settings Tables
 IF OBJECT_ID('Inspector.ADHocDatabaseCreations_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[ADHocDatabaseCreations_Copy];

 IF OBJECT_ID('Inspector.ADHocDatabaseSupression_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[ADHocDatabaseSupression_Copy];

 IF OBJECT_ID('Inspector.AGCheck_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[AGCheck_Copy];

 IF OBJECT_ID('Inspector.BackupsCheck_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[BackupsCheck_Copy];

 IF OBJECT_ID('Inspector.BackupSizesByDay_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[BackupSizesByDay_Copy];

 IF OBJECT_ID('Inspector.CurrentServers_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[CurrentServers_Copy];

 IF OBJECT_ID('Inspector.DatabaseFiles_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[DatabaseFiles_Copy];

 IF OBJECT_ID('Inspector.DatabaseFileSizeHistory_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[DatabaseFileSizeHistory_Copy];

 IF OBJECT_ID('Inspector.DatabaseFileSizes_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[DatabaseFileSizes_Copy];

 IF OBJECT_ID('Inspector.DatabaseOwnership_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[DatabaseOwnership_Copy];

 IF OBJECT_ID('Inspector.DatabaseSettings_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[DatabaseSettings_Copy];

 IF OBJECT_ID('Inspector.DatabaseStates_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[DatabaseStates_Copy];

 IF OBJECT_ID('Inspector.DriveSpace_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[DriveSpace_Copy];

 IF OBJECT_ID('Inspector.EmailConfig_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[EmailConfig_Copy];

 IF OBJECT_ID('Inspector.EmailRecipients_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[EmailRecipients_Copy];

 IF OBJECT_ID('Inspector.FailedAgentJobs_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[FailedAgentJobs_Copy];

 IF OBJECT_ID('Inspector.JobOwner_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[JobOwner_Copy];

 IF OBJECT_ID('Inspector.LoginAttempts_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[LoginAttempts_Copy];

 IF OBJECT_ID('Inspector.Modules_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[Modules_Copy];

 IF OBJECT_ID('Inspector.ReportData_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[ReportData_Copy];

 IF OBJECT_ID('Inspector.Settings_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[Settings_Copy];

 IF OBJECT_ID('Inspector.TopFiveDatabases_Copy') IS NOT NULL 
 DROP TABLE [Inspector].[TopFiveDatabases_Copy];


--Create Main Inspector Report Stored Procedure
SET @SQLStatement = ''

SELECT @SQLStatement = @SQLStatement + CONVERT(VARCHAR(MAX), '')+ 
'/*********************************************
--Author: Adrian Buckman
--Revision date: 31/01/2018 
--Description: SQLUnderCoverInspectorReport - Report and email from Central logging tables.
--V1


--Example Execute command
--EXEC [Inspector].[SQLUnderCoverInspectorReport] 
--@EmailDistributionGroup = ''DBA'',
--@TestMode = 0,
--@ModuleDesc = NULL,
--@EmailRedWarningsOnly = 0,
--@Theme = ''Dark''

*********************************************/
'
IF @LinkedServerName = ''
	BEGIN

	SELECT @SQLStatement = @SQLStatement + CONVERT(VARCHAR(MAX), '')+ '
CREATE PROCEDURE [Inspector].[SQLUnderCoverInspectorReport] 
(
@EmailDistributionGroup VARCHAR(100),
@TestMode BIT = 0,
@ModuleDesc VARCHAR(20)	= NULL,
@EmailRedWarningsOnly BIT = 0,
@Theme VARCHAR(5) = ''Dark''
)
AS 
BEGIN
SET NOCOUNT ON;

IF EXISTS (SELECT name FROM sys.databases WHERE name = '''+@Databasename+''' AND State = 0)

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
@Theme VARCHAR(5) = ''Dark''
)
AS 
BEGIN
SET NOCOUNT ON;

IF EXISTS (SELECT DATA_SOURCE FROM SYS.SERVERS 
WHERE NAME ='''+REPLACE(REPLACE(REPLACE(@LinkedServerName,'[',''),']',''),'.','')+'''
AND DATA_SOURCE IN (
					SELECT AG.NAME AS AGname
					FROM sys.dm_hadr_availability_group_states st
					INNER JOIN master.sys.availability_groups ag ON ST.group_id = AG.group_id
					WHERE primary_replica = @@Servername)
					 )
OR @@SERVERNAME = (SELECT DATA_SOURCE FROM SYS.SERVERS 
WHERE NAME ='''+REPLACE(REPLACE(REPLACE(@LinkedServerName,'[',''),']',''),'.','')+''')

'

		END


SELECT @SQLStatement = @SQLStatement + CONVERT(VARCHAR(MAX), '') + '

BEGIN 

 IF EXISTS (SELECT [ID] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Modules] WHERE ModuleConfig_Desc = @ModuleDesc)
 OR @ModuleDesc IS NULL

	BEGIN	
		
DECLARE @ModuleConfig VARCHAR(20) 

DECLARE @FreeSpaceRemainingPercent			INT = (SELECT ISNULL(CAST([Value] AS INT),10) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''FreeSpaceRemainingPercent'')
DECLARE @DaysUntilDriveFullThreshold		INT = (SELECT ISNULL(CAST([Value] AS INT),56) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DaysUntilDriveFullThreshold'')
DECLARE @FullBackupThreshold				INT = (SELECT ISNULL(CAST([Value] AS INT),8) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''FullBackupThreshold'')
DECLARE @DiffBackupThreshold				INT = (SELECT ISNULL(CAST([Value] AS INT),2) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DiffBackupThreshold'')
DECLARE @LogBackupThreshold				INT = (SELECT ISNULL(CAST([Value] AS INT),60) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''LogBackupThreshold'')
DECLARE @DatabaseGrowthsAllowedPerDay	     INT = (SELECT ISNULL(CAST([Value] AS INT),1) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DatabaseGrowthsAllowedPerDay'')
DECLARE @MAXDatabaseGrowthsAllowedPerDay     INT = (SELECT ISNULL(CAST([Value] AS INT),10) FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''MAXDatabaseGrowthsAllowedPerDay'')

DECLARE @EnableAGCheck						BIT 
DECLARE @EnableBackupsCheck					BIT 
DECLARE @EnableBackupSizesCheck				BIT 
DECLARE @EnableDatabaseGrowthCheck				BIT 
DECLARE @EnableDatabaseFileCheck				BIT 
DECLARE @EnableDatabaseOwnershipCheck			BIT 
DECLARE @EnableDatabaseStatesCheck				BIT 
DECLARE @EnableDriveSpaceCheck				BIT 
DECLARE @EnableFailedAgentJobCheck				BIT 
DECLARE @EnableJobOwnerCheck					BIT 
DECLARE @EnableFailedLoginsCheck				BIT 
DECLARE @EnableTopFiveDatabaseSizeCheck			BIT 
DECLARE @EnableADHocDatabaseCreationCheck		BIT 
DECLARE @EnableBackupSpaceCheck				BIT 
DECLARE @EnableDatabaseSettings				BIT
DECLARE @UseMedian							BIT



IF OBJECT_ID(''TempDB..#TrafficLightSummary'') IS NOT NULL
DROP TABLE #TrafficLightSummary;

CREATE TABLE #TrafficLightSummary
(
SummaryHeader VARCHAR(1000),
WarningPriority TINYINT
);


DECLARE @Stack VARCHAR(255) = (SELECT [Value] from ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''SQLUndercoverInspectorEmailSubject'') 

DECLARE @EmailHeader VARCHAR(1000) = ''<img src="''+(SELECT [Value] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''EmailBannerURL'')+''">''
DECLARE @SubjectText VARCHAR(255) 
DECLARE @AlertSubjectText VARCHAR(255) 
DECLARE @Importance VARCHAR(6) = ''Low''
DECLARE @EmailBody VARCHAR(MAX) = ''''
DECLARE @Alertheader VARCHAR(MAX) = ''''
DECLARE @AdvisoryHeader VARCHAR(MAX) = ''''
DECLARE @RecipientsList VARCHAR(1000) = (SELECT Recipients FROM ['+CAST(REPLACE(@Databasename,',',';') AS VARCHAR(128))+'].[Inspector].[EmailRecipients] WHERE [Description] = @EmailDistributionGroup)
DECLARE @RedHighlight VARCHAR(7)  = ''#F78181'' 
DECLARE @YellowHighlight VARCHAR(7) = ''#FAFCA4''
DECLARE @TableTail VARCHAR(65) = ''</table><p><A HREF = "#Warnings">Back to Top</a><p>''
DECLARE @TableHeaderColour VARCHAR(7) 
DECLARE @ServerSummaryHeader VARCHAR(MAX) = ''<A NAME = "Warnings"></a><b>Server Summary:</b><br></br>''
DECLARE @ServerSummaryFontColour VARCHAR(30)
DECLARE @DriveLetterExcludes VARCHAR(10) = (SELECT REPLACE(REPLACE([Value],'':'',''''),''\'','''') from ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DriveSpaceDriveLetterExcludes'')
DECLARE @DisabledModules VARCHAR(450)

IF @ModuleDesc IS NULL 
	BEGIN SET @SubjectText = (SELECT [EmailSubject] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[EmailConfig] WHERE [ModuleConfig_Desc] = ''Default'') END
		ELSE BEGIN SET @SubjectText = (SELECT [EmailSubject] FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[EmailConfig] WHERE [ModuleConfig_Desc] = @ModuleDesc) END

IF @SubjectText IS NULL BEGIN SET @SubjectText = ''SQLUndercover Inspector check'' END

SET @SubjectText= @SubjectText +'' for [''+ISNULL(@Stack,'''')+'']''
SET @AlertSubjectText = @SubjectText +'' - WARNINGS FOUND! ''

IF @Theme IS NULL BEGIN SET @Theme = ''Dark'' END
IF @Theme NOT IN (''Light'',''Dark'') BEGIN SET @Theme = ''Dark'' END


--Build beginning of the HTML 
SET @EmailHeader = ''
<html>
<head>
<style>
td 
    {
    color: Black; border: solid black;border-width: 1px;padding-left:10px;padding-right:10px;padding-top:10px;padding-bottom:10px;font: 11px arial;
    }
</style>
</head>
<body style="background-color: ''+CASE WHEN @Theme = ''Light'' THEN ''White'' ELSE ''Black'' END +'';" text="''+CASE WHEN @Theme = ''Light'' THEN ''Black'' ELSE ''White'' END +''">
<div style="text-align: center;">'' +ISNULL(@EmailHeader,'''')+''</div>
<BR>
<BR>''
	

DECLARE @Serverlist NVARCHAR(128)
DECLARE ServerCur CURSOR FORWARD_ONLY
FOR 

SELECT Servername,ModuleConfig_Desc,TableHeaderColour
FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[CurrentServers]
WHERE isactive = 1 
ORDER BY Servername ASC


OPEN ServerCur

FETCH NEXT FROM ServerCur INTO @Serverlist,@ModuleConfig,@TableHeaderColour

WHILE @@FETCH_STATUS = 0 
BEGIN

IF @ModuleConfig IS NULL BEGIN SET @ModuleConfig = ''Default'' END;
IF @TableHeaderColour IS NULL BEGIN SET @TableHeaderColour = ''#E6E6FA'' END;


SELECT 							
@EnableAGCheck					= ISNULL(EnableAGCheck,0),					
@EnableBackupsCheck				= ISNULL(EnableBackupsCheck,0),					
@EnableBackupSizesCheck			= ISNULL(EnableBackupSizesCheck,0),			
@EnableDatabaseGrowthCheck		= ISNULL(EnableDatabaseGrowthCheck,0),			
@EnableDatabaseFileCheck			= ISNULL(EnableDatabaseFileCheck,0),			
@EnableDatabaseOwnershipCheck		= ISNULL(EnableDatabaseOwnershipCheck,0),		
@EnableDatabaseStatesCheck		= ISNULL(EnableDatabaseStatesCheck,0),			
@EnableDriveSpaceCheck			= ISNULL(EnableDriveSpaceCheck,0),				
@EnableFailedAgentJobCheck		= ISNULL(EnableFailedAgentJobCheck,0),			
@EnableJobOwnerCheck			= ISNULL(EnableJobOwnerCheck,0),				
@EnableFailedLoginsCheck			= ISNULL(EnableFailedLoginsCheck,0),			
@EnableTopFiveDatabaseSizeCheck	= ISNULL(EnableTopFiveDatabaseSizeCheck,0),		
@EnableADHocDatabaseCreationCheck	= ISNULL(EnableADHocDatabaseCreationCheck,0),					
@EnableBackupSpaceCheck			= ISNULL(EnableBackupSpaceCheck,0),
@EnableDatabaseSettings			= ISNULL(EnableDatabaseSettings,0),
@UseMedian					= ISNULL(UseMedianCalculationForDriveSpaceCalc,0)
FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Modules]
WHERE ModuleConfig_Desc = ISNULL(@ModuleDesc,@ModuleConfig)



--Disabled Modules List
SELECT @DisabledModules = STUFF(REPLACE(
ISNULL('' , EnableAGCheck''+NULLIF(CAST(@EnableAGCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableBackupsCheck''+NULLIF(CAST(@EnableBackupsCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableBackupSizesCheck''+NULLIF(CAST(@EnableBackupSizesCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableDatabaseGrowthCheck''+NULLIF(CAST(@EnableDatabaseGrowthCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableDatabaseFileCheck''+NULLIF(CAST(@EnableDatabaseFileCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableDatabaseOwnershipCheck''+NULLIF(CAST(@EnableDatabaseOwnershipCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableDatabaseStatesCheck''+NULLIF(CAST(@EnableDatabaseStatesCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableDriveSpaceCheck''+NULLIF(CAST(@EnableDriveSpaceCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableFailedAgentJobCheck''+NULLIF(CAST(@EnableFailedAgentJobCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableJobOwnerCheck''+NULLIF(CAST(@EnableJobOwnerCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableFailedLoginsCheck''+NULLIF(CAST(@EnableFailedLoginsCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableTopFiveDatabaseSizeCheck''+NULLIF(CAST(@EnableTopFiveDatabaseSizeCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableADHocDatabaseCreationCheck''+NULLIF(CAST(@EnableADHocDatabaseCreationCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableBackupSpaceCheck''+NULLIF(CAST(@EnableBackupSpaceCheck AS CHAR(1)),1),'''') +
ISNULL('' , EnableDatabaseSettings''+NULLIF(CAST(@EnableDatabaseSettings AS CHAR(1)),1),'''') +
ISNULL('' , UseMedian''+NULLIF(CAST(@UseMedian AS CHAR(1)),1),''''),''0'',''''),1,3,'''')

IF @DisabledModules IS NULL BEGIN SET @DisabledModules = ''None'' END

SELECT  @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server <A NAME = "''+REPLACE(@Serverlist,''\'','''')+''Servername''+''"></a>[''+@Serverlist+'']</b><BR></BR>
ModuleConfig used: <b>''+ISNULL(@ModuleDesc,@ModuleConfig)+ ''</b><BR> Disabled Modules: <b>''+@DisabledModules+''</b><BR></p><p></p><BR></BR>''

IF @EnableDriveSpaceCheck = 1 
	BEGIN

    DECLARE @BodyDriveSpace  VARCHAR(MAX) = '''',
	@CountDriveSpace VARCHAR(5),
     @TableHeadDriveSpace VARCHAR(1000) =
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
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.DriveSpace 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN

WITH TotalDriveEntries AS 
(
--GROUP THE DRIVE LETTERS AND COUNT TOTAL LOGGED ENTRIES (1 entry per day)
SELECT Servername,Drive,COUNT(Drive) AS TotalEntries
FROM (
SELECT Servername,Drive,CAST(Log_Date AS DATE) AS DATELOGGED
FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.DriveSpace DriveSpace
WHERE Servername = @Serverlist
GROUP BY Servername,Drive,CAST(Log_Date AS DATE)
) AS X 
GROUP BY Servername,Drive
),
SpaceVariation as (
--CALCULATE THE DIFFERENCE BETWEEN CURRENT FREESPACE AND LAST RECORDED FREE SPACE FOR ALL ENTRIES PER DRIVE
SELECT Log_Date,DriveSpace.Servername,DriveSpace.Drive,Capacity_GB,(Capacity_GB-AvailableSpace_GB) as UsedSpace_GB,AvailableSpace_GB,
LAG(Capacity_GB-AvailableSpace_GB,1,Capacity_GB-AvailableSpace_GB) OVER(PARTITION BY DriveSpace.Servername,DriveSpace.Drive ORDER BY DriveSpace.Servername,DriveSpace.Drive,Log_Date) as laggedUsedSpace,
TotalEntries
FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.DriveSpace DriveSpace
INNER JOIN TotalDriveEntries ON DriveSpace.Drive = TotalDriveEntries.Drive AND DriveSpace.Servername = TotalDriveEntries.Servername
),
ApplyMedianRowNum AS (
SELECT Log_Date,Servername,Drive,Capacity_GB,(Capacity_GB-AvailableSpace_GB) as UsedSpace_GB,AvailableSpace_GB,
laggedUsedSpace,ROW_NUMBER() OVER (PARTITION BY [Drive] ORDER BY [Drive],(SELECT(UsedSpace_GB-laggedUsedSpace)) DESC) AS RowNum,
TotalEntries
FROM SpaceVariation
),
AverageDailyGrowth AS
(
--TAKE THE DIFFERENCES FROM SpaceVariation CTE AND DIVIDE THIS BY TOTAL ENTRIES PER DRIVE LETTER
SELECT
Servername, 
Drive,
CASE WHEN SUM(UsedSpace_GB-laggedUsedSpace) <= 0 THEN 0 
WHEN @UseMedian = 1 THEN (SELECT UsedSpace_GB-laggedUsedSpace FROM ApplyMedianRowNum Median WHERE Median.Drive = SpaceVariation.Drive AND (Median.TotalEntries/2) = Median.RowNum)
ELSE CAST(SUM((UsedSpace_GB-laggedUsedSpace)/TotalEntries) AS DECIMAL(10,2)) END AS AverageDailyGrowth_GB
FROM SpaceVariation
GROUP BY
Servername,
Drive
) 
SELECT @BodyDriveSpace = @BodyDriveSpace +(
SELECT CASE 
WHEN AverageDailyGrowth_GB > 0 
AND CAST(COALESCE((LastRecordedFreeSpace.AvailableSpace_GB)/NULLIF(AverageDailyGrowth_GB,0),0) AS DECIMAL(20,2)) < @DaysUntilDriveFullThreshold
THEN @RedHighlight 
WHEN CAST((LastRecordedFreeSpace.AvailableSpace_GB/LastRecordedFreeSpace.Capacity_GB)*100 AS DECIMAL(10,2)) < @FreeSpaceRemainingPercent 
AND AverageDailyGrowth.Drive COLLATE DATABASE_DEFAULT NOT IN (SELECT '+CASE WHEN @Compatibility = 0 THEN '[StringElement]+'':\''' ELSE '[Value]+'':\''' END+ 
'FROM '+CASE WHEN @Compatibility = 0 THEN '[Master].[dbo].fn_SplitString(@DriveLetterExcludes,'','') DriveLetterExcludes'
										ELSE 'STRING_SPLIT(@DriveLetterExcludes,'','') DriveLetterExcludes'
										END+')
THEN @YellowHighlight
ELSE ''#FFFFFF'' END AS [@bgcolor], 
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
			FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.DriveSpace DriveSpace
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

			SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDriveSpace, '''') + ISNULL(@BodyDriveSpace, '''') + ''</table><p><b><font style="color: Black; background-color: #FAFCA4">Yellow Highlight</font> - Drive remaining percent below ''+CAST(@FreeSpaceRemainingPercent AS VARCHAR(3))+''%''+ ISNULL('' (Drives being excluded are: ''+ @DriveLetterExcludes +'')'','''') +''<br>
			 <font style="color: Black; background-color: Red">Red Highlight</font> - Estimated days remaining until drive is full, is below ''+CAST(@DaysUntilDriveFullThreshold AS VARCHAR(3))+ '' Days </p></b>''
			 + ISNULL(REPLACE(@TableTail,''</table>'',''''),'''') +''<p><BR><p>''
			  
			 IF @BodyDriveSpace LIKE ''%''+@RedHighlight+''%''		
			 BEGIN 
			 SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DriveSpace''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountDriveSpace+'') Drive Space warnings</font><p>''	  
			 SET @Importance = ''High'' 
			 END

--Count Drive space Yellow Highlights

		SET @CountDriveSpace = (LEN(@BodyDriveSpace) - LEN(REPLACE(@BodyDriveSpace,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			IF @CountDriveSpace > 0	
				BEGIN 
					SELECT @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DriveSpace''+''">''+@Serverlist+''</a><font color= "#e68a00">  - has (''+@CountDriveSpace+'') Drive Space warnings where remaining space is below ''+CAST(@FreeSpaceRemainingPercent AS VARCHAR(3))+''% remaining</font><p>''	  
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
	   ''N/A'' AS ''td'',''''
	   FOR XML PATH(''tr''),Elements)

	   SET @CountDriveSpace = (LEN(@BodyDriveSpace) - LEN(REPLACE(@BodyDriveSpace,@RedHighlight, '''')))/LEN(@RedHighlight)

			 SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDriveSpace, '''') + ISNULL(@BodyDriveSpace, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
			 IF @BodyDriveSpace LIKE ''%''+@RedHighlight+''%''		
			 BEGIN 
			 SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DriveSpace''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountDriveSpace+'') Drive Space warnings <b>(Data collection out of Date)</b></font><p>''	  
			 SET @Importance = ''High'' 
			 END
	   END
	END

IF @EnableAGCheck = 1 
	BEGIN
--AVAILABILITY GROUP HEALTH CHECK VARIABLES
DECLARE @BodyAGCheck VARCHAR(MAX),
    @TableHeadAGCheck VARCHAR(1000),
	@CountAGCheck VARCHAR(5)

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
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.AGCheck 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN

--AVAILABILITY GROUP HEALTH CHECK SCRIPT
SET @BodyAGCheck = (
SELECT 
CASE WHEN [State] != ''HEALTHY'' AND [State] != ''N/A'' THEN @RedHighlight ELSE ''#FFFFFF'' END AS [@bgcolor],
ServerName  AS ''td'','''', +
AGname AS ''td'','''', +
[State] AS ''td'','''', +
ISNULL([ReplicaServerName],''N/A'') AS ''td'','''', +
CASE WHEN [Suspended] = 1 THEN ''Y'' 
WHEN [Suspended] = 0 THEN ''N''
ELSE ''N/A'' END AS ''td'','''', +
ISNULL([SuspendReason],''N/A'') AS ''td'',''''
FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[AGCheck]
WHERE servername = @Serverlist
ORDER BY AGname ASC,ReplicaServerName ASC
FOR XML PATH(''tr''),ELEMENTS);

--Count AG Check Warnings
    SET @CountAGCheck = (LEN(@BodyAGCheck) - LEN(REPLACE(@BodyAGCheck,@RedHighlight, '''')))/LEN(@RedHighlight)

			SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadAGCheck, '''') + ISNULL(@BodyAGCheck, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
				  IF @BodyAGCheck LIKE ''%''+@RedHighlight+''%''			
				  BEGIN 
				  SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountAGCheck+'') AG Warnings</font><p>''  
				  SET @Importance = ''High'' 
				  END   
			

	   END
	   ELSE
	   BEGIN
	   SET @BodyAGCheck = (
	   SELECT 
	   @RedHighlight AS [@bgcolor],
	   @Serverlist  AS ''td'','''', +
	   ''Data collection out of date'' AS ''td'','''', +
	   ''N/A'' AS ''td'',''''
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[AGCheck]
	   WHERE servername = @Serverlist
	   ORDER BY AGname ASC
	   FOR XML PATH(''tr''),ELEMENTS);

	   SET @CountAGCheck = (LEN(@BodyAGCheck) - LEN(REPLACE(@BodyAGCheck,@RedHighlight, '''')))/LEN(@RedHighlight)

	   			SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadAGCheck, '''') + ISNULL(@BodyAGCheck, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
				  IF @BodyAGCheck LIKE ''%''+@RedHighlight+''%''			
				  BEGIN 
				    SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''AgWarnings''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountAGCheck+'') AG Warnings <b>(Data collection out of Date)</b></font><p>''  
				    SET @Importance = ''High'' 
				  END   
		END

	   END


IF @EnableDatabaseStatesCheck = 1 
	BEGIN
-- DATABASE STATE CHECK AND COUNT (INCLUDES LIST OF OFFLINE DBs) VARIABLES
DECLARE @BodyDatabaseStates VARCHAR(MAX),
    @TableHeadDatabaseStates VARCHAR(1000),
    @CountDatabaseStates VARCHAR(5),
	@SuspectAlertText VARCHAR(65) = NULL

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
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.DatabaseStates 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN

	   SET @BodyDatabaseStates =(
	   SELECT 
	   CASE 
	   --WHEN DatabaseState != ''ONLINE'' AND DatabaseState != ''SNAPSHOT (less than 10 days old)'' THEN @RedHighlight ELSE ''#FFFFFF'' END AS [@bgcolor],
	   WHEN DatabaseState IN (''Restoring'',''RECOVERING'',''OFFLINE'',''SNAPSHOT (more than 10 days old)'') THEN @YellowHighlight 
	   WHEN DatabaseState IN (''RECOVERY_PENDING'',''SUSPECT'',''EMERGENCY'') THEN @RedHighlight
	   ELSE ''#FFFFFF'' END AS [@bgcolor],
	   Servername AS ''td'','''', +
	   DatabaseState AS ''td'','''', +
	   Total AS ''td'','''', +
	   DatabaseNames AS ''td'',''''
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseStates]
	   WHERE servername = @Serverlist
	   ORDER BY Total DESC
	   FOR XML PATH(''tr''),ELEMENTS);
	   
	   IF (@BodyDatabaseStates LIKE ''%<td>SUSPECT</td>%'' OR @BodyDatabaseStates LIKE ''%<td>RECOVERY_PENDING</td>%'' OR @BodyDatabaseStates LIKE ''%<td>EMERGENCY</td>%'')
	   BEGIN 
	   SET @SuspectAlertText = '' (SUSPECT , RECOVERY_PENDING OR EMERGENCY DATABASE/S PRESENT!)'' 
	   END
	   
	   --Count Database States Warnings
	   SET @CountDatabaseStates = (LEN(@BodyDatabaseStates) - LEN(REPLACE(@BodyDatabaseStates,@RedHighlight, '''')))/LEN(@RedHighlight)
	   
	    
	   SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDatabaseStates, '''') + ISNULL(@BodyDatabaseStates, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	   	  IF @BodyDatabaseStates LIKE ''%''+@RedHighlight+''%''		
	   	  BEGIN 
	   		 SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "Red">  - <b>has (''+@CountDatabaseStates+'') Database State warnings ''+ISNULL(@SuspectAlertText,'''')+''</font></b><p>''	  
	   		 SET @Importance = ''High'' 
	   	  END
		  IF @BodyDatabaseStates LIKE ''%''+@YellowHighlight+''%''
		  BEGIN
			 SET @CountDatabaseStates = (LEN(@BodyDatabaseStates) - LEN(REPLACE(@BodyDatabaseStates,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			 SELECT @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "#e68a00">  - has (''+@CountDatabaseStates+'') Database State Advisories including any of the following states: (Restoring, Recovering, Offline, Snapshot (more than 10 days old))</font><p>''        
		  END

	   END
	   ELSE
	   BEGIN

	   SET @BodyDatabaseStates =(
	   SELECT 
	   @RedHighlight AS [@bgcolor],
	   @Serverlist AS ''td'','''', +
	   ''Data collection out of date'' AS ''td'','''', +
	   ''N/A'' AS ''td'','''', +
	   ''N/A'' AS ''td'',''''
	   FOR XML PATH(''tr''),ELEMENTS);

	   SET @CountDatabaseStates = (LEN(@BodyDatabaseStates) - LEN(REPLACE(@BodyDatabaseStates,@RedHighlight, '''')))/LEN(@RedHighlight)
	   
	   SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDatabaseStates, '''') + ISNULL(@BodyDatabaseStates, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	   IF @BodyDatabaseStates LIKE ''%''+@RedHighlight+''%''		
	   BEGIN 
	   SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DatabaseState''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountDatabaseStates+'') Database State warnings <b>(Data collection out of Date)</b></font><p>''	  
	   SET @Importance = ''High'' 
	   END

	   END
END

IF @EnableFailedAgentJobCheck = 1 
BEGIN

DECLARE @BodyFailedJobsTotals  VARCHAR(MAX) ,
    @CountFailedJobsTotals VARCHAR(5),
    @TableHeadFailedJobsTotals VARCHAR(1000) =''
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
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.FailedAgentJobs 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE) 

	   BEGIN

    SET @BodyFailedJobsTotals = 
     (SELECT @RedHighlight AS [@bgcolor],
	ServerName AS ''td'','''', + 
	CONVERT(VARCHAR(17),Log_Date,113) AS ''td'','''', + 
	JobName AS ''td'','''', +  
	LastStepFailed AS ''td'','''', +  
	CONVERT(VARCHAR(17),LastFailedDate,113) AS ''td'','''',+  
	LastError + ''...'' AS ''td'',''''
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[FailedAgentJobs]
	WHERE servername = @Serverlist
	AND JobName != ''No Failed Jobs present''
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

	   --Count Failed Job Warnings	
SET @CountFailedJobsTotals =  (LEN(@BodyFailedJobsTotals) - LEN(REPLACE(@BodyFailedJobsTotals,@RedHighlight, '''')))/LEN(@RedHighlight)

 SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadFailedJobsTotals,'''') + ISNULL(@BodyFailedJobsTotals, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
				  IF @BodyFailedJobsTotals LIKE ''%''+@RedHighlight+''%''	
				  BEGIN 
				  SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountFailedJobsTotals+'') Failed Job warnings</font><p>''  
				  SET @Importance = ''High'' 
				  END
	   END
	ELSE 
	BEGIN 

	SET @BodyFailedJobsTotals = 
     (SELECT @RedHighlight AS [@bgcolor],
	@Serverlist AS ''td'','''', + 
	''N/A'' AS ''td'','''', + 
	''Data Collection out of date'' AS ''td'','''', +  
	''N/A'' AS ''td'','''', + 
	''N/A'' AS ''td'','''', +   
	''N/A'' AS ''td'',''''
	FOR XML PATH(''tr''),ELEMENTS);

	SET @CountFailedJobsTotals =  (LEN(@BodyFailedJobsTotals) - LEN(REPLACE(@BodyFailedJobsTotals,@RedHighlight, '''')))/LEN(@RedHighlight)

		     SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadFailedJobsTotals,'''') + ISNULL(@BodyFailedJobsTotals, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
				  IF @BodyFailedJobsTotals LIKE ''%''+@RedHighlight+''%''	
				  BEGIN 
				  SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''FailedJob''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountFailedJobsTotals+'') Failed Job warnings  <b>(Data collection out of Date)</b></font><p>''  
				  SET @Importance = ''High'' 
				  END
	END
END

IF @EnableFailedLoginsCheck = 1
BEGIN

	DECLARE @BodyLoginAttempts VARCHAR(MAX),
		   @TableHeadLoginAttempts VARCHAR(1000)

	SET @TableHeadLoginAttempts = ''
	<b>Failed Login Attempts in the last 24hrs</b>
     <br> <table cellpadding=0 cellspacing=0 border=0>
     <tr> 
	<td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
     <td bgcolor=''+@TableHeaderColour+''><b>Username</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Attempts</b></td>
	<td bgcolor=''+@TableHeaderColour+''><b>Last Failed Attempt</b></td> 
	<td bgcolor=''+@TableHeaderColour+''><b>Last Error</b></td>
	'';

	   IF (SELECT MAX(Log_Date) 
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.AGCheck 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	BEGIN
		  BEGIN


SET @BodyLoginAttempts = (SELECT
					''#FFFFFF'' AS [@bgcolor],
					ServerName AS ''td'','''',+
					Username AS ''td'','''',+
					Attempts AS ''td'','''',+
					CONVERT(VARCHAR(17),LastErrorDate,113) AS ''td'','''',+
					LastError AS ''td'',''''
					FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[LoginAttempts]
					WHERE servername = @Serverlist
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

SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadLoginAttempts, '''') + ISNULL(@BodyLoginAttempts, '''') + ISNULL(@TableTail,'''') +    ''<p><BR><p>'' 


END
ELSE
BEGIN 
SET @BodyLoginAttempts = (SELECT 
					''#FFFFFF'' AS [@bgcolor],
					@Serverlist AS ''td'','''',+
					''Data Collection out of date'' AS ''td'','''',+
					''N/A'' AS ''td'','''',+
					''N/A'' AS ''td'','''',+
					''N/A'' AS ''td'',''''
					FOR XML PATH(''tr''),ELEMENTS)

SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadLoginAttempts, '''') + ISNULL(@BodyLoginAttempts, '''') + ISNULL(@TableTail,'''') +    ''<p><BR><p>'' 

END
END


IF @EnableJobOwnerCheck = 1 

BEGIN

--JOB OWNERSHIP 
DECLARE @AgentJobOwnerExclusions VARCHAR(255) = (SELECT REPLACE([Value],'' '' ,'''') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''AgentJobOwnerExclusions'')

DECLARE @BodyJobOwner VARCHAR(MAX),
	   @TableHeadJobOwner VARCHAR(1000),
	   @CountJobOwner VARCHAR(5)

SET @TableHeadJobOwner = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''"></a>Agent Jobs where the owner is not ''+ISNULL(REPLACE(REPLACE(@AgentJobOwnerExclusions,'' '',''''),'','','', ''),''[N/A - No Exclusions Set]'')+''</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Job ID</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Job name</b></td>
    '';

    	IF (SELECT MAX(Log_Date) 
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.JobOwner 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN

--JOB OWNER SCRIPT
SET @BodyJobOwner = (SELECT 
				@YellowHighlight AS [@bgcolor],
				ServerName AS ''td'','''',+
				job_id AS ''td'','''', + 
				JobName AS ''td'',''''
				FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[JobOwner]
				WHERE servername = @Serverlist
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

SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadJobOwner, '''') + ISNULL(@BodyJobOwner, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

		  IF @BodyJobOwner LIKE ''%''+@YellowHighlight+''%''
		  BEGIN
			 --Count Database States Warnings
			 SET @CountJobOwner = (LEN(@BodyJobOwner) - LEN(REPLACE(@BodyJobOwner,@YellowHighlight, '''')))/LEN(@YellowHighlight)
			 SELECT @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''JobOwner''+''">''+@Serverlist+''</a><font color= "#e68a00">  - has (''+@CountJobOwner+'') Agent jobs where the Owner is not ''+ISNULL(REPLACE(REPLACE(@AgentJobOwnerExclusions,'' '',''''),'','','', ''),''[N/A - No Exclusions Set]'')+''</font><p>''        
		  END

END
ELSE 
    BEGIN 
    
	   SET @BodyJobOwner = 
	   (SELECT 
	   ''#FFFFFF'' AS [@bgcolor],
	   @Serverlist AS ''td'','''',+
	   ''N/A'' AS ''td'','''', + 
	   ''Data Collection out of date'' AS ''td'',''''
	   FOR XML PATH(''tr''),ELEMENTS);
	
	   SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadJobOwner, '''') + ISNULL(@BodyJobOwner, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
    
    END

END

IF @EnableTopFiveDatabaseSizeCheck = 1 

BEGIN

--TOP 5 DATABASES BY SIZE VARIABLES
DECLARE @BodyTopFiveDatabases VARCHAR(MAX),
	   @TableHeadTopFiveDatabases VARCHAR(1000)

SET @TableHeadTopFiveDatabases = ''
    <b>Top 5 Databases by size</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Total size(MB)</b></td>
    '';

	IF (SELECT MAX(Log_Date) 
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.TopFiveDatabases 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN

--TOP 5 DATABASES BY SIZE SCRIPT
SET @BodyTopFiveDatabases = (SELECT 
					   ''#FFFFFF'' AS [@bgcolor],
					   ServerName AS ''td'','''', + 
					   DatabaseName AS ''td'','''', + 
					   TotalSize_MB AS ''td'',''''
					   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[TopFiveDatabases] 
					   WHERE servername = @Serverlist
					   FOR XML PATH(''tr''),ELEMENTS);

	   
	   END
	   ELSE
	   BEGIN
	   SET @BodyTopFiveDatabases = (SELECT 
							  ''#FFFFFF'' AS [@bgcolor],
							  @Serverlist AS ''td'','''', + 
							  ''Data Collection out of date'' AS ''td'','''', + 
							  ''N/A'' AS ''td'',''''
							  FOR XML PATH(''tr''),ELEMENTS);
	   END

SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadTopFiveDatabases, '''') + ISNULL(@BodyTopFiveDatabases, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

END
	 
IF @EnableDatabaseFileCheck = 1 
BEGIN
--Check Data and log files are on the correct drives Variables
DECLARE @BodyDatabaseFiles VARCHAR(MAX),
	   @TableHeadDatabaseFiles VARCHAR(1000),
	   @CountDatabaseFiles VARCHAR(5)


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
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.DatabaseFiles 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN


--Check Data and log files are on the correct drives Script

SET @BodyDatabaseFiles = (SELECT 
					@RedHighlight AS [@bgcolor],
					ServerName AS ''td'','''', +
					Databasename AS ''td'','''', + 
					FileType AS ''td'','''', +
					FilePath AS ''td'',''''
					FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseFiles]
					WHERE ServerName = @Serverlist
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
--Count Database File Warnings
SET @CountDatabaseFiles = (LEN(@BodyDatabaseFiles) - LEN(REPLACE(@BodyDatabaseFiles,@RedHighlight, '''')))/LEN(@RedHighlight)	
 
SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDatabaseFiles, '''') + ISNULL(@BodyDatabaseFiles, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
IF @BodyDatabaseFiles LIKE ''%''+@RedHighlight+''%''		
BEGIN 
SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountDatabaseFiles+'') Data or Log files on incorrect drives</font><p>''  
SET @Importance = ''High'' 
END

	END
	ELSE 
	BEGIN 
	   SET @BodyDatabaseFiles = 
	   (SELECT 
	   @RedHighlight AS [@bgcolor],
	   @Serverlist AS ''td'','''', +
	   ''Data Collection out of date'' AS ''td'','''', + 
	   ''N/A'' AS ''td'','''', +
	   ''N/A'' AS ''td'',''''
	   FOR XML PATH(''tr''),ELEMENTS);

	   --Count Database File Warnings
	   SET @CountDatabaseFiles = (LEN(@BodyDatabaseFiles) - LEN(REPLACE(@BodyDatabaseFiles,@RedHighlight, '''')))/LEN(@RedHighlight)	
 
	   SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDatabaseFiles, '''') + ISNULL(@BodyDatabaseFiles, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	   IF @BodyDatabaseFiles LIKE ''%''+@RedHighlight+''%''		
	   BEGIN 
	   SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DataLogFiles''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountDatabaseFiles+'') Data or Log files on incorrect drives <b>(Data collection out of Date)</b></font><p>''  
	   SET @Importance = ''High'' 
	   END
	END


END

IF @EnableBackupsCheck = 1 
BEGIN

	IF OBJECT_ID(''Tempdb..#RawData'') IS NOT NULL 
	DROP TABLE #RawData;

	CREATE TABLE #RawData
	(
	Databasename NVARCHAR(128),
	LastFull DATETIME,
	LastDiff DATETIME,
	LastLog DATETIME,
	AGName NVARCHAR(128),
	GroupingMethod NVARCHAR(128), 
	Servername NVARCHAR(128),
	IsFullRecovery BIT,
	IsSystemDB BIT
	);

	IF OBJECT_ID(''Tempdb..#Aggregates'') IS NOT NULL
	DROP TABLE #Aggregates;

	CREATE TABLE #Aggregates
	(
	Databasename NVARCHAR(128),
	LastFull DATETIME,
	LastDiff DATETIME,
	LastLog DATETIME,
	AGName NVARCHAR(128),
	GroupingMethod NVARCHAR(128), 
	IsFullRecovery BIT,
	IsSystemDB BIT
	);

	IF OBJECT_ID(''Tempdb..#Validations'') IS NOT NULL 
	DROP TABLE #Validations; 

	CREATE TABLE #Validations
	(
	Databasename NVARCHAR(128),
     AGName NVARCHAR(128),
	FullState VARCHAR(25),
	DiffState VARCHAR(25),
	LogState VARCHAR(25),
	IsFullRecovery CHAR(1),
	Serverlist VARCHAR(1000)
	);

DECLARE @BodyBackupsReport VARCHAR(MAX),
	   @TableHeadBackupsReport VARCHAR(1000),
	   @CountBackupsReport VARCHAR(5)

SET @TableHeadBackupsReport = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''Backup''+''"></a>The following Databases are missing database backups:</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>AG name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Last Full</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Last Diff</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Last Log</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Full Recovery</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Server name</b></td>
    '';


	   IF (SELECT MAX(Log_Date) 
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.BackupsCheck 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN

		  INSERT INTO #RawData (Databasename,LastFull,LastDiff,LastLog,AGName,GroupingMethod,Servername,IsFullRecovery,IsSystemDB)
		  SELECT 
		  LTRIM(RTRIM(BackupSet.Databasename)), --Added trim as Leading and trailing spaces can cause misreporting
		  [FULL] AS LastFull,
		  [DIFF] AS LastDiff,
		  [LOG] AS LastLog,
		  BackupSet.AGName,
		  CASE WHEN BackupSet.AGName = ''Not in an AG'' THEN SERVERNAME
		  ELSE BackupSet.AGName END AS GroupingMethod,  
		  Servername,
		  BackupSet.IsFullRecovery,
		  BackupSet.IsSystemDB
		  FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupsCheck] BackupSet
		  
		  
		  
		  INSERT INTO #Aggregates (Databasename,LastFull,LastDiff,LastLog,AGName,GroupingMethod,IsFullRecovery,IsSystemDB)
		  SELECT 
		  RawData.Databasename,
		  MAX(LastFull) AS LastFull,
		  MAX(LastDiff) AS LastDiff,
		  MAX(LastLog) AS LastLog,
		  AGname,
		  GroupingMethod,
		  IsFullRecovery,
		  IsSystemDB
		  FROM #RawData RawData
		  GROUP BY Databasename,AGName,GroupingMethod,IsFullRecovery,IsSystemDB;
		  
		  
		  INSERT INTO #Validations (Databasename,AGName,FullState,DiffState,LogState,IsFullRecovery,Serverlist)
		  SELECT 
		  Databasename,
		  AGname,
		  CASE
		  	WHEN [LastFull] = ''19000101'' THEN ''More than ''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Days Ago''
		  	WHEN ([LastFull] >= ''19000101'' AND [LastFull] < DATEADD(DAY,-@FullBackupThreshold,GetDate()) OR [LastFull] IS NULL) THEN ISNULL(CONVERT(VARCHAR(17),[LastFull],113),''More then ''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' days ago'')
		  	ELSE ''OK'' END AS [FullState], 
		  	CASE 
		  	WHEN [LastDIFF] = ''19000101'' AND IsSystemDB = 0 THEN ''More than ''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Days Ago''
		  	WHEN ([LastDIFF] >= ''19000101'' AND LastDIFF < DATEADD(DAY,-@DiffBackupThreshold,GetDate())  OR [lastdiff] IS NULL) AND IsSystemDB = 0 THEN ISNULL(CONVERT(VARCHAR(17),LastDIFF,113),''More then ''+CAST(@DiffBackupThreshold AS VARCHAR(3))+'' days ago'')
		  	WHEN IsSystemDB = 1 THEN ''N/A''
		  	ELSE ''OK'' END AS [DiffState], 
		  	CASE 
		  	WHEN  LastLOG = ''19000101'' AND IsSystemDB = 0 AND Aggregates.IsFullRecovery = 1 THEN ''More than ''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Days Ago''
		  	WHEN (([LastLOG] >= ''19000101'' AND [LastLOG] < DATEADD(MINUTE,-@LogBackupThreshold,GetDate()) OR lastlog IS NULL) AND IsSystemDB = 0 AND (Aggregates.IsFullRecovery = 1 OR CAST(Aggregates.IsFullRecovery AS VARCHAR(3)) = ''N/A'')) THEN ISNULL(CONVERT(VARCHAR(17),[LastLOG] ,113),''More than ''+CAST(@LogBackupThreshold AS VARCHAR(3))+'' Minutes ago'')
		  	WHEN Aggregates.IsFullRecovery = 0  OR IsSystemDB = 1 THEN ''N/A''
		  	ELSE ''OK'' END AS [LogState],
		  CASE IsFullRecovery WHEN 1 THEN ''Y'' ELSE ''N'' END AS IsFullRecovery,
		  STUFF(Serverlist.Serverlist,1,1,'''') AS Serverlist
		  FROM #Aggregates Aggregates
		  CROSS APPLY (SELECT '', '' + Servername 
		  			FROM #RawData RawData
		  			WHERE Aggregates.GroupingMethod = RawData.GroupingMethod
		  			AND Aggregates.Databasename = RawData.Databasename 
		  			AND Aggregates.IsFullRecovery = RawData.IsFullRecovery
		  			AND Aggregates.IsSystemDB = RawData.IsSystemDB
		  			AND Aggregates.AGname = RawData.AGname
		  			FOR XML PATH('''')
		  			) AS Serverlist (Serverlist) 
		  
		  
		  
		  SET @BodyBackupsReport = (
		  SELECT 
		  @RedHighlight [@bgcolor], 
		  Databasename  AS ''td'','''', +
		  AGname  AS ''td'','''', +
		  FullState  AS ''td'','''', +
		  DiffState  AS ''td'','''', +
		  LogState  AS ''td'','''', +
		  IsFullRecovery AS ''td'','''', +
		  Serverlist  AS ''td'',''''
		  FROM #Validations
		  WHERE ([FullState] != ''OK'' OR ([DiffState] != ''OK'' AND [DiffState] != ''N/A'') OR ([LogState] != ''OK'' AND [LogState] != ''N/A''))
		  AND Serverlist like ''%''+@Serverlist+''%''
		  ORDER BY Databasename ASC
		  FOR XML PATH(''tr''),ELEMENTS)
		  
		  IF @BodyBackupsReport IS NULL
			 BEGIN

				SET @BodyBackupsReport = (
				SELECT 
				''#FFFFFF'' [@bgcolor], 
				''No backup issues present''  AS ''td'','''', +
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
		  
		  SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadBackupsReport, '''') + ISNULL(@BodyBackupsReport, '''') +''</table><p><font style="color: Black; background-color: #F78181">Red Highlight Thresholds:</font><br>
		  Last FULL backup older than <b>''+CAST(@FullBackupThreshold AS VARCHAR(3))+'' Day/s</b><br>
		  Last DIFF backup older than <b>''+CAST(@DiffBackupThreshold AS VARCHAR(3))+'' Day/s</b><br>
		  Last Log backup older than <b>''+CAST(@LogBackupThreshold AS VARCHAR(3))+'' Minute/s</b></p></b>''+ ISNULL(REPLACE(@TableTail,''</table>'',''''),'''') +''<p><BR><p>''

		  
		  
		  	

		  	  IF @BodyBackupsReport LIKE ''%''+@RedHighlight+''%''		
		  	  BEGIN 
		  	  SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Backup''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountBackupsReport+'') Database Backup issues</font><p>''   
		  	  SET @Importance = ''High'' 
		  	  END

		  END
		  ELSE 
			 BEGIN

				SET @BodyBackupsReport = (
				SELECT 
				@RedHighlight [@bgcolor], 
				''Data Collection out of date''  AS ''td'','''', +
				''N/A''  AS ''td'','''', +
				''N/A''  AS ''td'','''', +
				''N/A''  AS ''td'','''', +
				''N/A''  AS ''td'','''', +
				''N/A''  AS ''td'','''', +
				''N/A''  AS ''td'',''''
				FOR XML PATH(''tr''),ELEMENTS)

			  --Count Backup Warnings
			  SET @CountBackupsReport = (LEN(@BodyBackupsReport) - LEN(REPLACE(@BodyBackupsReport,@RedHighlight, '''')))/LEN(@RedHighlight)
		  
			  SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadBackupsReport, '''') + ISNULL(@BodyBackupsReport, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
		  	  IF @BodyBackupsReport LIKE ''%''+@RedHighlight+''%''		
		  	  BEGIN 
		  	  SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Backup''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountBackupsReport+'') Database Backup issues <b>(Data collection out of Date)</b></font><p>''   
		  	  SET @Importance = ''High'' 
		  	  END

			  END

END


IF @EnableDatabaseOwnershipCheck = 1 
BEGIN

DECLARE @DatabaseOwnerExclusions VARCHAR(255) = (SELECT REPLACE([Value],'' '' ,'''') FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] WHERE [Description] = ''DatabaseOwnerExclusions'')

DECLARE @BodyDBOwner VARCHAR(MAX),
	   @TableHeadDBOwner VARCHAR(1000),
	   @CountDBOwner VARCHAR(5)

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
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.DatabaseOwnership 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN


		  SET @BodyDBOwner = 
		  (SELECT 
		  @YellowHighlight AS [@bgcolor],
		  [ServerName] AS ''td'','''', + 
		  [AGName] AS ''td'','''', + 
		  [Database_Name] AS ''td'','''', + 
		  [Owner] AS ''td'',''''
		  FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseOwnership]
		  WHERE [ServerName] = @Serverlist
		  AND [Database_Name] != ''No Database Ownership issues present''
		  ORDER BY [Database_Name]
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

	   --Count DB Owner Warnings
	   SET @CountDBOwner = (LEN(@BodyDBOwner) - LEN(REPLACE(@BodyDBOwner,@YellowHighlight, '''')))/LEN(@YellowHighlight)
	   
	   SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDBOwner, '''') + ISNULL(@BodyDBOwner, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

	   IF @BodyDBOwner LIKE ''%''+@YellowHighlight+''%''    
	   BEGIN 
	   SET @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''">''+@Serverlist+''</a><font color= "#e68a00">  - has (''+@CountDBOwner+'') Databases where the Owner is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+''</font><p>''   
	   END


	   END
	   ELSE
	   BEGIN

	   SET @BodyDBOwner = 
			 (SELECT 
			 @RedHighlight AS [@bgcolor],
			 ''N/A'' AS ''td'','''', + 
			 ''N/A'' AS ''td'','''', + 
			 ''Data Collection out of date'' AS ''td'','''', + 
			 ''N/A'' AS ''td'',''''
			 FOR XML PATH(''tr''),ELEMENTS);

	   --Count DB Owner Warnings
	   SET @CountDBOwner = (LEN(@BodyDBOwner) - LEN(REPLACE(@BodyDBOwner,@RedHighlight, '''')))/LEN(@RedHighlight)
	  
	   SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDBOwner, '''') + ISNULL(@BodyDBOwner, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	   IF @BodyDBOwner LIKE ''%''+@RedHighlight+''%''			
	   BEGIN 
	   SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBowner''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountDBOwner+'') Databases where the Owner is not ''+ISNULL(@DatabaseOwnerExclusions,''[N/A - No Exclusions Set]'')+'' <b>(Data collection out of Date)</b></font><p>''   
	   SET @Importance = ''High'' 
	   END

	   END



END

IF @EnableBackupSizesCheck = 1 
BEGIN

DECLARE @BodyBackupsByDay VARCHAR(MAX),
    @TableHeadBackupsByDay VARCHAR(1000)

SET @TableHeadBackupsByDay = ''
    <b>Backup Sizes by Day for server:</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Day Of Week</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Total Backup Size GB</b></td>
    '';

	
	   IF (SELECT MAX(Log_Date) 
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.BackupSizesByDay 
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
				IF EXISTS (SELECT Log_Date 
						   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.BackupSizesByDay 
						   WHERE Servername = @Serverlist
						   AND Log_Date IS NULL) 
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

		  	  
SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadBackupsByDay, '''') + ISNULL(@BodyBackupsByDay, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

END

IF @EnableADHocDatabaseCreationCheck = 1 
BEGIN

DECLARE @BodyAdHocDatabases VARCHAR(MAX),
	   @TableHeadAdHocDatabases VARCHAR(1000),
	   @CountAdHocDatabases VARCHAR(5)

SET @TableHeadAdHocDatabases = ''
    <b><A NAME = "''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''"></a>Potential Ad hoc database creations in the last 7 days</b>
    <br> <table cellpadding=0 cellspacing=0 border=0> 
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Database name</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Create date</b></td>
    '';

	   IF (SELECT MAX(Log_Date) 
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.ADHocDatabaseCreations 
	   WHERE Servername = @Serverlist) >= CAST(GETDATE() AS DATE)

	   BEGIN

		  SET @BodyAdHocDatabases =
		  (SELECT 
		  @YellowHighlight  AS [@bgcolor],
		  Databasename AS ''td'','''', + 
		  CONVERT(VARCHAR(17),create_date,113) AS ''td'',''''
		  FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ADHocDatabaseCreations]
		  WHERE Servername = @Serverlist
		  AND Databasename != ''No Ad hoc database creations present''
		  AND NOT EXISTS (SELECT Databasename 
				FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[ADHocDatabaseSupression] Suppressed
				WHERE Servername = @Serverlist 
				AND Suppressed.Databasename = Databasename
				AND Suppressed.Suppress = 1)
		  ORDER BY create_date ASC
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

	   --Count Ad Hoc Database Creations
	   SET @CountAdHocDatabases = (LEN(@BodyAdHocDatabases) - LEN(REPLACE(@BodyAdHocDatabases,@YellowHighlight, '''')))/LEN(@YellowHighlight)
	   
	   SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadAdHocDatabases, '''') +ISNULL(@BodyAdHocDatabases, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
	   IF @BodyAdHocDatabases LIKE ''%''+@YellowHighlight+''%''    
	   BEGIN 
	   SELECT @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''">''+@Serverlist+''</a><font color= "#e68a00">  - has (''+@CountAdHocDatabases+'') Potential AD Hoc Database creations in the last 7 days</font><p>''        
	   END

	   END
	   ELSE 
		  BEGIN

		  SET @BodyAdHocDatabases =
		  (SELECT 
		  @RedHighlight  AS [@bgcolor],
		  ''Data Collection out of date'' AS ''td'','''', + 
		  ''N/A'' AS ''td'',''''
		  FOR XML PATH(''tr''),ELEMENTS);

		  --Count Ad Hoc Database Creations
		  SET @CountAdHocDatabases = (LEN(@BodyAdHocDatabases) - LEN(REPLACE(@BodyAdHocDatabases,@RedHighlight, '''')))/LEN(@RedHighlight)
		  
		  SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadAdHocDatabases, '''') +ISNULL(@BodyAdHocDatabases, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 
		  IF @BodyAdHocDatabases LIKE ''%''+@RedHighlight+''%''    
		  BEGIN 
		  SET @Alertheader = @Alertheader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''ADHocDatabases''+''">''+@Serverlist+''</a><font color= "Red">  - has (''+@CountAdHocDatabases+'') Potential AD Hoc Database creations <b>(Data collection out of Date)</b></font><p>''   
		  SET @Importance = ''High'' 
		  END

		  END



END
	     


IF @EnableDatabaseSettings  = 1

BEGIN 
--Database Settings 

DECLARE @BodyDatabaseSettings VARCHAR(MAX) = '''',
    @TableHeadDatabaseSettings VARCHAR(1000),
    @CountDBSettings VARCHAR(5)

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
	   FROM ['+CAST(@Databasename AS VARCHAR(128))+'].Inspector.DatabaseSettings 
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
		  CASE WHEN [Description] = ''Enabled'' THEN @YellowHighlight ELSE ''#FFFFFF'' END AS [@bgcolor],
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
		  CASE WHEN [Description] = ''Enabled'' THEN @YellowHighlight ELSE ''#FFFFFF'' END AS [@bgcolor],
		  [Description]  AS ''td'','''', + 
		  Total   AS ''td'',''''
		  FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseSettings]
		  WHERE Servername = @Serverlist 
		  AND Setting = ''is_auto_shrink_on''
		  ORDER BY Total DESC
		  FOR XML PATH(''tr''),ELEMENTS);
		  
		  SELECT @BodyDatabaseSettings  = @BodyDatabaseSettings + ''<tr> <td bgcolor=''+@TableHeaderColour+''><b>Auto Update Stats</b></td>''+''<td bgcolor=''+@TableHeaderColour+''><b>Total</b></td></tr>''
		  
		  SELECT @BodyDatabaseSettings = @BodyDatabaseSettings +
		  (SELECT 
		  CASE WHEN [Description] = ''Disabled'' THEN @YellowHighlight ELSE ''#FFFFFF'' END AS [@bgcolor],
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

		  IF @BodyDatabaseSettings LIKE ''%''+@YellowHighlight+''%''
			 BEGIN
				SET @CountDBSettings = (LEN(@BodyDatabaseSettings) - LEN(REPLACE(@BodyDatabaseSettings,@YellowHighlight, '''')))/LEN(@YellowHighlight)
				SELECT @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''DBSettings''+''">''+@Serverlist+''</a><font color= "#e68a00">  - has (''+@CountDBSettings+'') Database Auto Close or Auto Shrink settings enabled or Auto Update Stats Disabled</font><p>''	  
			 END
	   END
	   ELSE
	   BEGIN

	   	  SET @BodyDatabaseSettings =
		  (SELECT 
		  ''#FFFFFF'' AS [@bgcolor],
		  ''Data Collection out of date''  AS ''td'','''', + 
		  ''N/A''   AS ''td'',''''
		  FOR XML PATH(''tr''),ELEMENTS);

	   END

SELECT  @EmailBody = @EmailBody + ISNULL(@TableHeadDatabaseSettings,'''') + ISNULL(@BodyDatabaseSettings, '''') + ISNULL(@TableTail,'''') + ''<p><BR><p>'' 

END


IF @AlertHeader LIKE ''%''+@Serverlist+''%''
BEGIN
   SET @ServerSummaryFontColour = ''<font color= "Red">''
END
    ELSE 
    IF @AdvisoryHeader LIKE ''%''+@Serverlist+''%''
	   BEGIN
	   	SET @ServerSummaryFontColour = ''<font color= "#e68a00">''
	   END
	   ELSE
		  BEGIN
		     SET @ServerSummaryFontColour = ''<font color= "Green">''
		  END


--Evaluate server and colour code accordingly  
INSERT INTO #TrafficLightSummary ([SummaryHeader],[WarningPriority])
SELECT 
CASE
WHEN @ServerSummaryFontColour = ''<font color= "Red">'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color="red">''+@Serverlist+''</font>]</a></b></font> ''
WHEN @ServerSummaryFontColour = ''<font color= "#e68a00">'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color="#e68a00">''+@Serverlist+''</font>]</a></b></font> ''
WHEN @ServerSummaryFontColour = ''<font color= "Green">'' THEN ''<b>''+ @ServerSummaryFontColour+''<A HREF = "#''+REPLACE(@Serverlist,''\'','''')+''Servername''+''">''+''[''+''<font color="Green">''+@Serverlist+''</font>]</a></b></font> ''
END,
CASE
WHEN @ServerSummaryFontColour = ''<font color= "Red">'' THEN 1
WHEN @ServerSummaryFontColour = ''<font color= "#e68a00">'' THEN 2
WHEN @ServerSummaryFontColour = ''<font color= "Green">'' THEN 3
END

--Add Break to the end of the Server warning ready for the next
IF @Alertheader LIKE ''%''+@Serverlist+''%'' BEGIN SET @Alertheader = @Alertheader + ''<BR></BR>'' END

--Add Break to the end of the Server Advisory Condition ready for the next
IF @AdvisoryHeader LIKE ''%''+@Serverlist+''%'' BEGIN SET @AdvisoryHeader = @AdvisoryHeader + ''<BR></BR>'' END


					 FETCH NEXT FROM ServerCur INTO @Serverlist,@ModuleConfig,@TableHeaderColour

END
CLOSE ServerCur
DEALLOCATE ServerCur




IF @EnableDatabaseGrowthCheck = 1 
	BEGIN
	

DECLARE @BodyGrowthCheck VARCHAR(MAX) = '''',
	   @TableHeadGrowthCheck VARCHAR(1000),
	   @CountGrowthCheck VARCHAR(5)

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
    '';


SELECT @BodyGrowthCheck = @BodyGrowthCheck + 
(SELECT  
CASE   
WHEN [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay AND [GrowthIncrements] < @MAXDatabaseGrowthsAllowedPerDay 
THEN @YellowHighlight
WHEN [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay AND [GrowthIncrements] >= @MAXDatabaseGrowthsAllowedPerDay 
THEN @RedHighlight
END AS [@bgcolor], 
[ServerName] AS ''td'','''', + 
[Database_name] AS ''td'','''', +
[Type_Desc] AS ''td'','''', +
[File_id] AS ''td'','''', +
[FileName] AS ''td'','''', +
[PreGrowthSize_MB] AS ''td'','''', +
[GrowthRate_MB] AS ''td'','''', +
[GrowthIncrements] AS ''td'','''', +
[PostGrowthSize_MB] AS ''td'','''',+
CASE WHEN [GrowthRate_MB] < 100 
THEN 100  -- if current growth rate is less than 100MB then suggest a minimum of 100MB
ELSE
[GrowthRate_MB] * [GrowthIncrements] END AS ''td'',''''
  FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[DatabaseFileSizeHistory]
  WHERE [Log_Date] >= CAST(GETDATE() AS DATE)
  AND [GrowthIncrements] > @DatabaseGrowthsAllowedPerDay
  ORDER BY Servername,Database_name,[File_id]
  for xml path(''tr''),Elements);


  --CHECK FOR Database Growth Advisory Condition, then for any warnings 

SELECT  @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server [ALL Servers]<b><p><BR>''+ISNULL(@TableHeadGrowthCheck, '''') + ISNULL(@BodyGrowthCheck, '''') + ''</table><p><font style="color: Black; background-color: #FAFCA4">Yellow Highlight</font> - More than ''+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' growth event/s in the past 24 hours<br>
	<font style="color: Black; background-color: Red">Red Highlight</font> - ''+CAST(@MAXDatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' or more growth event/s in the past 24 hours</b></p>'' + ISNULL(REPLACE(@TableTail,''</table>'',''''),'''') + ''<p><BR><p>''
IF @BodyGrowthCheck LIKE ''%''+@YellowHighlight+''%''	
	   BEGIN

		SET @CountGrowthCheck = (LEN(@BodyGrowthCheck) - LEN(REPLACE(@BodyGrowthCheck,@YellowHighlight, '''')))/LEN(@YellowHighlight)
		SELECT @AdvisoryHeader = @AdvisoryHeader + ''<A HREF = "#''+''GrowthEvents''+''Growth''+''">''+''Database Growth''+''</a><font color= "#e68a00">  - (''+@CountGrowthCheck+'') Database Growth events found which exceed your acceptable threshold of ''+CAST(@DatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' Growth/s per 24hrs</font><p>''  
		  
	   END

IF @BodyGrowthCheck LIKE ''%''+@RedHighlight+''%''	
		  
	   BEGIN 
		    SET @CountGrowthCheck = (LEN(@BodyGrowthCheck) - LEN(REPLACE(@BodyGrowthCheck,@RedHighlight, '''')))/LEN(@RedHighlight)
		    SET @Alertheader = @Alertheader + ''<A HREF = "#''+''GrowthEvents''+''Growth''+''">''+''Database Growth''+''</a><font color= "Red">  - (''+@CountGrowthCheck+'') Database Growth events found which equal or exceed your Max Threshold of ''+CAST(@MAXDatabaseGrowthsAllowedPerDay AS VARCHAR(5))+'' Growths per 24hrs</font><p>''  
		    SET @Importance = ''High'' 
	   END

  END


IF @EnableBackupSpaceCheck = 1  
BEGIN

DECLARE @BackupRoot VARCHAR(128)
SET @BackupRoot = (SELECT Value From ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[Settings] where [Description] = ''BackupsPath'')

DECLARE @BodyBackupSpace VARCHAR(MAX) = '''',
    @TableHeadBackupSpace VARCHAR(1000)

SET @TableHeadBackupSpace = ''
    <b><A NAME = "BackupStorage''+''BackupStorage''+''"></a><b>Backup space estimate for tonight (entire stack) versus free space checked against  [''+ISNULL(@BackupRoot,''No Server Set, Check Inspector.Settings'')+''] </b>
    <br> <table cellpadding=0 cellspacing=0 border=0>
    <tr> 
    <td bgcolor=''+@TableHeaderColour+''><b>Backup Estimate For Tonight GB</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Backup Server FreeSpace GB</b></td>
    <td bgcolor=''+@TableHeaderColour+''><b>Backup Server Free Space After Backups GB</b></td>
    '';


IF (Select [Value]
	From sys.configurations
	WHERE Name = ''xp_cmdshell'') = 1

		BEGIN

		  DECLARE @ErrorEncountered BIT = 0
		  DECLARE @ErrorEncounteredText VARCHAR(100)
		  DECLARE @BackupSizeForNextWeekday AS DECIMAL(10,1)
		  DECLARE @BackupSpaceLessStorageSpace AS DECIMAL(10,1) 
		  DECLARE @ExtractedInformation VARCHAR(MAX) = ''''
		  DECLARE @FreeSpace_Bytes BIGINT = ''''
		  DECLARE @FreeSpace_GB INT = '''' 
		  DECLARE @Xpcmd VARCHAR(128)   
		  IF OBJECT_ID(''Tempdb..#BackupDriveSpace'') IS NOT NULL
		  DROP TABLE #BackupDriveSpace
		     
		  CREATE TABLE #BackupDriveSpace
		  (
		  BytesFree nvarchar(max) 
		  ); 
		  

		  
		  IF @BackupRoot LIKE ''%\'' SET @BackupRoot = LEFT(@BackupRoot,LEN(@BackupRoot)-1)
		  
		  SET @Xpcmd =  ''DIR\ ''+@BackupRoot
		  INSERT INTO #BackupDriveSpace (BytesFree)
		  EXEC XP_CMDSHELL @Xpcmd
		  
		  IF EXISTS (SELECT TOP 1 BytesFree
					FROM #BackupDriveSpace
					WHERE BytesFree IS NOT NULL 
					AND BytesFree NOT IN (''The device is not ready.'', ''The system cannot find the path specified.'',''The network path was not found.'',''The specified path is invalid'',''The filename, directory name, or volume label syntax is incorrect.'')
					)

					BEGIN
						
						
						--Extract the drive information based on the @BackupRoot value (Start the string at this point ignoring any drives letters prior to it)
						SELECT @ExtractedInformation = @ExtractedInformation + (
						SELECT RIGHT(BytesFree,LEN(BytesFree)-CHARINDEX(@BackupRoot,BytesFree)+1) as DriveidentificationSTART
						FROM (
						SELECT BytesFree as BytesFree
						FROM #BackupDriveSpace 
						FOR XML PATH('''')
						) IdentifyDriveSpace (BytesFree)
						)
						
						IF @ExtractedInformation LIKE ''%File Not Found%'' 
						  BEGIN 

							 SET @ErrorEncountered = 1
							 SET @ErrorEncounteredText = ''Invalid Backup Path Specified in [Inspector].[Settings]''
							 
							 SET @Alertheader = @Alertheader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''BackupStorage''+''</a><font color= "Red">  - Access denied for Backup Path Specified in [Inspector].[Settings]</font><p>'' 
							 SET @Importance = ''High''

						  END
						ELSE
						BEGIN
						SELECT @FreeSpace_Bytes = 
						REPLACE(RIGHT(LEFT(@ExtractedInformation,CHARINDEX(''bytes free'',@ExtractedInformation)-1),
						LEN(LEFT(@ExtractedInformation,CHARINDEX(''bytes free'',@ExtractedInformation)-1))-
						CHARINDEX(''Dir(S)'',LEFT(@ExtractedInformation,CHARINDEX(''bytes free'',@ExtractedInformation)-1))-6),'','','''')
						
						SET @FreeSpace_GB = ((@FreeSpace_Bytes/1024)/1024)/1024
						END
				
					END

						ELSE

					BEGIN

						SET @ErrorEncountered = 1
						SET @ErrorEncounteredText = ''Invalid Backup Path Specified in [Inspector].[Settings]''
						
						SET @Alertheader = @Alertheader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''BackupStorage''+''</a><font color= "Red">  - Invalid Backup Path Specified in [Inspector].[Settings]</font><p>'' 
						SET @Importance = ''High''

					
					END


		END
		ELSE
		BEGIN 
		SET @Alertheader = @Alertheader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''BackupStorage''+''</a><font color= "Red">  - xp_cmdshell must be enabled for module BackupSizesCheck to run</font><p>'' 
		SET @Importance = ''High'' 
		SET @ErrorEncountered = 1
		SET @ErrorEncounteredText = ''xp_cmdshell must be enabled''
		END
	
	


SET @BackupSizeForNextWeekday = 
(SELECT ISNULL(CAST(SUM(((TotalSizeInBytes)/1024)/1024)/1024 AS DECIMAL (10,1)),0) 
FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupSizesByDay]
WHERE [DayofWeek] = DATENAME(WEEKDAY,DATEADD(DAY,1,Getdate()))
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



	SELECT  @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server [ALL Servers]<b><p><BR>''+ISNULL(@TableHeadBackupSpace, '''') + ISNULL(@BodyBackupSpace, '''') + ISNULL(@TableTail, '''') + ''<p><BR><p>''

	--If unsufficient space then create and alert.
	IF @FreeSpace_GB < (@BackupSizeForNextWeekday + (@BackupSizeForNextWeekday*10) /100)	
	BEGIN SET @Alertheader = @Alertheader + ''<A HREF = "#''+''BackupStorage''+''BackupStorage''+''">''+''Backup Storage''+''</a><font color= "Red"> - There is insufficient free space on the backup server [''+@BackupRoot+''] for tonight''''s backups, Minimum space required: ''+CAST(@BackupSizeForNextWeekday AS VARCHAR(15))+'' GB , Space Available ''+CAST(@FreeSpace_GB AS VARCHAR(15)) + '' GB <p></font>'' SET @Importance = ''High'' END

END


IF @EnableBackupSizesCheck = 1
BEGIN

	DECLARE @BodyBackupSpaceWeekly VARCHAR(MAX) = '''',
		   @TableHeadBackupSpaceWeekly VARCHAR(1000)
	
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
	(SELECT [DayofWeek],TotalSizeInBytes
	FROM ['+CAST(@Databasename AS VARCHAR(128))+'].[Inspector].[BackupSizesByDay]) AS SourceTable
	PIVOT
	(
	SUM(TotalSizeInBytes)
	FOR [DayOfWeek] IN ([Monday],[Tuesday],[Wednesday],[Thursday],[Friday],[Saturday],[Sunday])
	) AS PivotTable
	FOR XML PATH(''tr''),ELEMENTS);
	
	
	SELECT  @EmailBody = @EmailBody + ''<hr><BR><p> <b>Server [ALL Servers]<b><p><BR>''+ISNULL(+@TableHeadBackupSpaceWeekly, '''') + ISNULL(@BodyBackupSpaceWeekly, '''') + ISNULL(@TableTail, '''') + ''<p><BR><p>'' 

END


																
IF @Importance = ''High'' SET @SubjectText = @AlertSubjectText


IF @Alertheader != '''' 
BEGIN

SET @Alertheader = ''
<BR></BR>
<B>Warnings Conditions:</b>
<p>''
+@Alertheader

END 
ELSE
BEGIN 

SET @Alertheader = ''
<BR></BR>
<B>NO Warnings are present</B>
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



--Red 

IF EXISTS (SELECT SummaryHeader FROM #TrafficLightSummary WHERE WarningPriority = 1 )
BEGIN
SELECT @ServerSummaryHeader = @ServerSummaryHeader +
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= "Red">Warnings Present - </font></b><BR></BR>'')
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
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= "#e68a00">Advisories/No Warnings - </font></b><BR></BR>'')
FROM
(
SELECT SummaryHeader + '' '' 
FROM #TrafficLightSummary
WHERE WarningPriority = 2
FOR XML PATH('''')
) AS SummaryHeader(SummaryHeader)
)
END

--Green
IF EXISTS (SELECT SummaryHeader FROM #TrafficLightSummary WHERE WarningPriority = 3 )
BEGIN
SELECT @ServerSummaryHeader = @ServerSummaryHeader + ''<BR></BR>'' + 
(SELECT STUFF(SummaryHeader,1,0,''<b><font color= "Green">OK - </font></b><BR></BR>'')
FROM
(
SELECT SummaryHeader + '' '' 
FROM #TrafficLightSummary
WHERE WarningPriority = 3
FOR XML PATH('''')
) AS SummaryHeader(SummaryHeader)
)
END


SET @EmailBody = ''
<div style="text-align: center;">''+@ServerSummaryHeader+''</div>'' 
+ ''
<BR></BR>
<HR></HR>
<div style="background:linear-gradient(to right, ''+CASE WHEN @Theme = ''Light'' THEN ''#FFFFFF'' ELSE ''#000000'' END+'' 35%, #F78181 110%)">
<text>''+@Alertheader +''<BR></text>
</div>
<div style="background: linear-gradient(to right, ''+CASE WHEN @Theme = ''Light'' THEN ''#FFFFFF'' ELSE ''#000000'' END+'' 35%, #FAFCA4 110%)">
<text>'' + ISNULL(@AdvisoryHeader,'''') + ''</text>
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
INSERT INTO '+CAST(@Databasename AS VARCHAR(128))+'.Inspector.ReportData (ReportDate,ModuleConfig,ReportData)
SELECT GETDATE(),ISNULL(@ModuleDesc,@ModuleConfig),@EmailBody
END
ELSE
BEGIN

IF @EmailRedWarningsOnly = 1 
	BEGIN
		IF @Importance = ''High''
		BEGIN
			EXEC MSDB..sp_send_dbmail 
			@recipients = @RecipientsList,
			@subject = @SubjectText,
			@Importance = @Importance,
			@body=@EmailBody ,
			@body_format = ''HTML'' 
		END
	END
	ELSE 
	BEGIN
			EXEC MSDB..sp_send_dbmail 
			@recipients = @RecipientsList,
			@subject = @SubjectText,
			@Importance = @Importance,
			@body=@EmailBody ,
			@body_format = ''HTML'' 
	END
END
END
ELSE
BEGIN RAISERROR(''@ModuleDesc supplied does not exist in [Inspector].[Modules]'',15,1) END
END
ELSE 
BEGIN
PRINT ''Not the Source server for the report , Quitting the job''
END

END'

EXEC(@SQLStatement)


--Agent job creations
SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+'
USE [msdb];

IF NOT EXISTS (SELECT Name FROM sysjobs WHERE Name = ''SQLUndercover Inspector Data Collection'')
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
		@description=N''Collect data and insert into  
		'+@LinkedServerName+'['+@Databasename+'] and email the results.'', 
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
		@command=N''--AGENT JOB COMMANDS 

--Data Collection Code , use this code within an Agent job to collect data used by the report

DECLARE @EnableAGCheck						BIT 
DECLARE @EnableBackupsCheck					BIT 
DECLARE @EnableBackupSizesCheck				BIT 
DECLARE @EnableDatabaseGrowthCheck				BIT 
DECLARE @EnableDatabaseFileCheck				BIT 
DECLARE @EnableDatabaseOwnershipCheck			BIT 
DECLARE @EnableDatabaseStatesCheck				BIT 
DECLARE @EnableDriveSpaceCheck				BIT 
DECLARE @EnableFailedAgentJobCheck				BIT 
DECLARE @EnableJobOwnerCheck					BIT 
DECLARE @EnableFailedLoginsCheck				BIT 
DECLARE @EnableTopFiveDatabaseSizeCheck			BIT 
DECLARE @EnableADHocDatabaseCreationCheck		BIT 
DECLARE @EnableDatabaseSettings				BIT
DECLARE @ModuleConfig VARCHAR(20)

SELECT @ModuleConfig = ModuleConfig_Desc
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[CurrentServers]
WHERE isactive = 1 
AND Servername = @@SERVERNAME

IF @ModuleConfig IS NULL BEGIN SET @ModuleConfig = ''''Default'''' END;

SELECT 							
@EnableAGCheck						= ISNULL(EnableAGCheck,0),					
@EnableBackupsCheck					= ISNULL(EnableBackupsCheck,0),					
@EnableBackupSizesCheck				= ISNULL(EnableBackupSizesCheck,0),			
@EnableDatabaseGrowthCheck			= ISNULL(EnableDatabaseGrowthCheck,0),			
@EnableDatabaseFileCheck				= ISNULL(EnableDatabaseFileCheck,0),			
@EnableDatabaseOwnershipCheck			= ISNULL(EnableDatabaseOwnershipCheck,0),		
@EnableDatabaseStatesCheck			= ISNULL(EnableDatabaseStatesCheck,0),			
@EnableDriveSpaceCheck				= ISNULL(EnableDriveSpaceCheck,0),				
@EnableFailedAgentJobCheck			= ISNULL(EnableFailedAgentJobCheck,0),			
@EnableJobOwnerCheck				= ISNULL(EnableJobOwnerCheck,0),				
@EnableFailedLoginsCheck				= ISNULL(EnableFailedLoginsCheck,0),			
@EnableTopFiveDatabaseSizeCheck		= ISNULL(EnableTopFiveDatabaseSizeCheck,0),		
@EnableADHocDatabaseCreationCheck		= ISNULL(EnableADHocDatabaseCreationCheck,0),	
@EnableDatabaseSettings				= ISNULL(EnableDatabaseSettings,0)
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[Modules]
WHERE ModuleConfig_Desc = @ModuleConfig


IF @EnableAGCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[AGCheckInsert] END
IF @EnableBackupsCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[BackupsCheckInsert] END
IF @EnableBackupSizesCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[BackupSizesByDayInsert] END
IF @EnableDatabaseGrowthCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[DatabaseGrowthsInsert] END
IF @EnableDatabaseFileCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[DatabaseFilesInsert] END
IF @EnableDatabaseOwnershipCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[DatabaseOwnershipInsert] END
IF @EnableDatabaseStatesCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[DatabaseStatesInsert] END
IF @EnableDriveSpaceCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[DriveSpaceInsert] END
IF @EnableFailedAgentJobCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[FailedAgentJobsInsert] END
IF @EnableJobOwnerCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[JobOwnerInsert] END
IF @EnableFailedLoginsCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[LoginAttemptsiInsert] END
IF @EnableTopFiveDatabaseSizeCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[TopFiveDatabasesInsert] END
IF @EnableADHocDatabaseCreationCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[ADHocDatabaseCreationsInsert] END
IF @EnableDatabaseSettings = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[DatabaseSettingsInsert] END''
, 
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

EXEC (@SQLStatement)


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'USE [msdb];

IF NOT EXISTS (Select name from msdb..sysjobs where name = ''SQLUndercover Inspector Report'')
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
		@description=N''Create a report from the collected data in 
		['+@Databasename+'] and email the results.'', 
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
@Theme = ''''Dark''''
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

EXEC (@SQLStatement)


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'USE [msdb];

IF NOT EXISTS (SELECT Name FROM sysjobs WHERE Name = ''SQLUndercover Periodic Backups Collection'')
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
		@description=N''--SQLUndercover Periodic Backups Collection
Collect Backup information and insert into: 
'+@LinkedServerName+'['+@Databasename+']'', 
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
		@command=N''USE ['+@Databasename+'];

--SQLUndercover Periodic Backups Collection

--Periodic Backup Checks using SQLUndercover Inspector Report Module ''''BackupsCheck''''

DECLARE @EnableBackupsCheck		BIT 
DECLARE @ModuleConfig			VARCHAR(20)

SELECT @ModuleConfig = ISNULL(ModuleConfig_Desc,''''Default'''')
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[CurrentServers]
WHERE isactive = 1 
AND Servername = @@SERVERNAME


SELECT 											
@EnableBackupsCheck	= ISNULL(EnableBackupsCheck,0)
FROM '+@LinkedServerName+'['+@Databasename+'].[Inspector].[Modules]
WHERE ModuleConfig_Desc = @ModuleConfig



IF @EnableBackupsCheck = 1 BEGIN EXEC ['+@Databasename+'].[Inspector].[BackupsCheckInsert] END'', 
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

EXEC (@SQLStatement)


SET @SQLStatement = CONVERT(VARCHAR(MAX), '')+
'USE [msdb];

IF NOT EXISTS (SELECT Name FROM sysjobs WHERE Name = ''SQLUndercover Periodic Backups Report'')
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
		@description=N''--SQLUndercover Periodic Backup Report

Check Backup information inserted into: 
'+@LinkedServerName+'['+@Databasename+'] 
and email if any issues are found.'', 
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

EXEC (@SQLStatement)


--Inspector Information

IF @Compatibility = 0 
	SET @SQLStatement = 
'IF EXISTS(SELECT [StringElement] 
			FROM Master.dbo.Fn_Splitstring('''+@DataDrive+''','','')
			WHERE [StringElement] IN (SELECT [StringElement] 
					FROM Master.dbo.Fn_Splitstring('''+@LogDrive+''','','')
					) )'

IF @Compatibility = 1
	SET @SQLStatement =
'IF EXISTS(SELECT [Value] 
			FROM STRING_SPLIT('''+@DataDrive+''','','')
			WHERE [Value] IN (SELECT [Value] 
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
To Disable - Update ['+@Databasename+'].[Inspector].[Modules] setting EnableDatabaseFileCheck to 0
_______________________________________________________________________________________________________________________________________________________________________________

''
END
'
EXEC(@SQLStatement)


PRINT '
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
PRINT 'Linked Server name is incorrect - Please correct the name and try again'
END
END

ELSE 
BEGIN 
PRINT 'Please double check your database context, this script needs to be executed against the database ['+@Databasename+']'
END

END
ELSE
BEGIN
RAISERROR('@DataDrive And/Or @LogDrive cannot have more than 4 drive letters specified',15,1)
END

END
ELSE
BEGIN 
PRINT '@Datadrive and @LogDrive cannot be NULL or Blank'
END


END
ELSE
BEGIN
RAISERROR('Fn_SplitString does not exist, SQLUndercover Inspector requires Fn_Splitstring because your system is not compatible with STRING_SPLIT.
Download Fn_SplitString here - https://sqlundercover.com/2017/06/01/undercover-toolbox-fn_splitstring-its-like-string_split-but-for-luddites-or-those-who-havent-moved-to-sql-2016-yet/
and create the Function in the Master Database',0,0)
END


