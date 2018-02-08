USE [master]
GO

 
IF OBJECT_ID('dbo.sp_AGreconfigure') IS NOT NULL
DROP PROCEDURE sp_AGreconfigure;


/**********************************************
Procedure Name: sp_AGreconfigure
Author: Adrian Buckman
Revision date: 07/01/2018
Version: 1.1

URL: https://sqlundercover.com/2017/12/08/undercover-toolbox-sp_agreconfigure-manage-always-on-sync-failover-settings-from-a-single-stored-procedure/


Description: Produce statements to ALTER Synchronisation mode ,Auto Failover Mode and Readable Secondary modes

06 Jan 2018 - Added @Readable parameter to allow for Readable Secondary scripts to be produced 
	NULL - Default: Ignore Readable secondary check (acts as though you are using V1)
	0 - Produce a statement to switch readable secondary off if switched on 
	1 - Produce a statement to switch readable on if set to off or Read intent
	2 - Produce a statement to switch read intent on if set to off or Readable

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

*********************************************/

CREATE PROCEDURE [dbo].[sp_AGreconfigure]
(
@ServerName NVARCHAR(128) = NULL,
@AGName NVARCHAR(128) = NULL,
@SyncCommit BIT = 0,
@AutoFailover BIT = 0,
@Readable TINYINT = NULL,
@CheckOnly BIT = 0
)
AS

BEGIN
SET NOCOUNT ON;

DECLARE @ErrorText NVARCHAR(256)

IF OBJECT_ID('tempdb.dbo.#AutoFailoverReplicaCount') IS NOT NULL
DROP TABLE #AutoFailoverReplicaCount;

CREATE TABLE #AutoFailoverReplicaCount
(
AGname NVARCHAR(128),
Total INT
);

IF @CheckOnly = 1
BEGIN
	WITH AGStatus AS
	(
	SELECT
	name as AGname,
	replica_server_name,
	CASE WHEN  (primary_replica  = replica_server_name) THEN  1
	ELSE  '' END AS IsPrimaryServer,
	secondary_role_allow_connections_desc AS ReadableSecondary,
	[availability_mode] AS [Synchronous],
	failover_mode_desc 
	FROM master.sys.availability_groups Groups
	INNER JOIN master.sys.availability_replicas Replicas ON Groups.group_id = Replicas.group_id
	INNER JOIN master.sys.dm_hadr_availability_group_states States ON Groups.group_id = States.group_id
	)

	Select
	AGname,
	Replica_server_name,
	IsPrimaryServer,
	Synchronous,
	ReadableSecondary,
	Failover_mode_desc
	FROM AGStatus
	WHERE Replica_server_name = ISNULL(@ServerName,Replica_server_name)
	ORDER BY
	AGname ASC,
	IsPrimaryServer DESC,
	Synchronous DESC;
END
ELSE

--Check that the current server is currently a Primary (ALTER Statements can only be made on the Primary)
IF EXISTS (
			SELECT TOP 1 primary_replica
			FROM sys.dm_hadr_availability_group_states States
			INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id
			WHERE primary_replica = @@SERVERNAME
		  )
BEGIN


IF @SyncCommit = 0 AND @AutoFailover = 1
BEGIN
	RAISERROR('Incompatible options set, When @SyncCommit = 0 then @AutoFailover must be 0',0,0)
END
ELSE 
	IF @Readable > 2 
	BEGIN
		RAISERROR('Incompatible option set, @Readable must be one of the following values "NULL 0, 1, 2"',0,0)
	END
	ELSE
	BEGIN
		--Count total AutoFailover replicas per AG or for @AGname if not null
		IF @AutoFailover = 1
			BEGIN
				INSERT INTO #AutoFailoverReplicaCount (AGname,Total)
				SELECT
				Groups.name,
				COUNT(Groups.name)
				FROM sys.dm_hadr_availability_group_states AGStates
				INNER JOIN master.sys.availability_groups Groups ON AGStates.group_id = Groups.group_id
				INNER JOIN master.sys.availability_replicas AGReplicas ON Groups.group_id = AGReplicas.group_id
				WHERE failover_mode_desc = 'AUTOMATIC'
				AND primary_replica = @@SERVERNAME
				AND Groups.name IN (ISNULL(@AGName,Groups.name))
				GROUP BY
				Groups.name
			END

		IF OBJECT_ID('Tempdb..#AGReplicaInfo') IS NOT NULL
		DROP TABLE #AGReplicaInfo;

		CREATE TABLE #AGReplicaInfo
		(
		[AGName] NVARCHAR(128),
		[Primary_Replica] NVARCHAR(128),
		[Replica_Server_Name] NVARCHAR(128),
		[IsPrimary] BIT,
		[ReadableSecondary] NVARCHAR(128),
		[IsSynchronous] BIT,
		[Failover_Mode_Desc] NVARCHAR(128),
		[Availability_Mode] BIT
		);

		IF OBJECT_ID('TempDB..#Statements') IS NOT NULL
		DROP TABLE #Statements;

		CREATE TABLE #Statements
		(
		ID INT IDENTITY(1,1),
		AGName NVARCHAR(128),
		Replica_Server_Name NVARCHAR(128),
		IsPrimary BIT,
		ReadableSecondary NVARCHAR(128),
		IsSynchronous BIT,
		Failover_mode_desc NVARCHAR(128),
		AlterStatement NVARCHAR(400)
		);

		INSERT INTO #AGReplicaInfo ([AGName],[Primary_Replica],[Replica_Server_Name],[IsPrimary],[ReadableSecondary],[IsSynchronous],[Failover_Mode_Desc])
		SELECT
		[Groups].[name],
		[primary_replica],
		[AGReplicas].[replica_server_Name],
		CASE
		WHEN [primary_replica] = [AGReplicas].[replica_server_Name] THEN 1 ELSE 0
		END AS IsPrimary,
		[secondary_role_allow_connections_desc] AS ReadableSecondary,
		[availability_mode] AS IsSynchronous,
		[failover_mode_desc]
		FROM sys.dm_hadr_availability_group_states AGStates
		INNER JOIN master.sys.availability_groups Groups ON AGStates.group_id = Groups.group_id
		INNER JOIN master.sys.availability_replicas AGReplicas ON Groups.group_id = AGReplicas.group_id
		WHERE
		primary_replica = @@ServerName --Only Show AG's where this server is the Primary Server

		INSERT INTO #Statements ([AGName],[Replica_Server_Name],[IsPrimary],[ReadableSecondary],[IsSynchronous],[Failover_Mode_Desc],[AlterStatement])
		SELECT
		AGName,
		replica_server_name,
		IsPrimary,
		ReadableSecondary,
		IsSynchronous,
		failover_mode_desc,
		NULLIF(CASE
			--Ensure that the Primary is set to Synchronous Commit if @SyncCommit = 1
			WHEN AGname IN (ISNULL(@AGName,AGname)) AND @SyncCommit = 1 AND IsSynchronous = 0
			THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+primary_replica+''' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
'
			ELSE ''
		END +
		CASE
			--Ensure that the Primary is set to Auto Failover if @AutoFailover = 1
			WHEN AGname IN (ISNULL(@AGName,AGname)) AND @AutoFailover = 1 AND [failover_mode_desc] = 'MANUAL'
			THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+primary_replica+''' WITH (FAILOVER_MODE = AUTOMATIC);
'
			ELSE ''
		END,'')
		FROM #AGReplicaInfo
		WHERE primary_replica = replica_server_name;

		INSERT INTO #Statements ([AGName],[Replica_Server_Name],[IsPrimary],[ReadableSecondary],[IsSynchronous],[Failover_Mode_Desc],[AlterStatement])
		SELECT
		AGName,
		replica_server_Name,
		IsPrimary,
		ReadableSecondary,
		IsSynchronous,
		failover_mode_desc,
		--If the Secondary/s are set to Sync and you are setting to Async then produce a statement
		NULLIF(
		CASE
		WHEN replica_server_Name IN (ISNULL(@ServerName,replica_server_Name))
		AND replica_server_name != primary_replica
		AND AGname IN (ISNULL(@AGName,AGname)) AND IsSynchronous = 1 AND @SyncCommit = 0
		THEN	 CASE
					 WHEN @AutoFailover = 0 AND failover_mode_desc = 'AUTOMATIC'
					 THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+replica_server_Name+''' WITH (FAILOVER_MODE = MANUAL);
'
					 ELSE ''
					 END +'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+replica_server_Name+''' WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT);
'
		--If the Secondary/s are set to Async and you are setting to Sync then produce a statement
		WHEN replica_server_Name IN (ISNULL(@ServerName,replica_server_Name))
		AND replica_server_name != primary_replica
		AND AGname IN (ISNULL(@AGName,AGname)) AND @SyncCommit = 1
		THEN CASE
			 WHEN IsSynchronous = 0
			 THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+replica_server_Name+''' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
'			 ELSE ''
			 END +
				 CASE
				 WHEN @AutoFailover = 1 AND [Failover_Mode_Desc] = 'MANUAL'
				 THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+replica_server_Name+''' WITH (FAILOVER_MODE = AUTOMATIC);
'				 
				 WHEN @AutoFailover = 0 AND [Failover_Mode_Desc] = 'AUTOMATIC'
				 THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+replica_server_Name+''' WITH (FAILOVER_MODE = MANUAL);
'				 ELSE ''
				 END
		ELSE ''		  
		END +
			CASE 
			WHEN replica_server_Name IN (ISNULL(@ServerName,replica_server_Name))
			AND replica_server_name != primary_replica
			AND AGname IN (ISNULL(@AGName,AGname)) AND @Readable IN (NULL,0,1,2)
			THEN 
				CASE
				--Readable Secondary statements
				WHEN AGname IN (ISNULL(@AGName,AGname)) AND @Readable = 0 AND [ReadableSecondary] IN ('READ_ONLY','ALL')
				THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+replica_server_Name+''' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = NO));			
' 
				WHEN AGname IN (ISNULL(@AGName,AGname)) AND @Readable = 1 AND [ReadableSecondary] != 'ALL'
				THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+replica_server_Name+''' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
			
'				WHEN AGname IN (ISNULL(@AGName,AGname)) AND @Readable = 2 AND [ReadableSecondary] != 'READ_ONLY'
				THEN 'ALTER AVAILABILITY GROUP ['+AGname+'] MODIFY REPLICA ON N'''+replica_server_Name+''' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = READ_ONLY));
			
'				WHEN @Readable IS NULL 
				THEN ''
				ELSE ''
				END
			ELSE ''
		END,'')
		AS AlterStatement
		FROM #AGReplicaInfo
		WHERE replica_server_Name IN (ISNULL(@ServerName,replica_server_Name))
		AND AGName IN (ISNULL(@AGName,AGName)) 
		ORDER BY
		AGName,
		replica_server_Name;

		SELECT
		AGName,
		Replica_Server_Name,
		IsPrimary,
		ReadableSecondary,
		IsSynchronous,
		Failover_mode_desc,
		AlterStatement
		FROM #Statements
		WHERE AlterStatement IS NOT NULL
		ORDER BY
		ID ASC

--If total Autofailover replicas for any AG or @AGname if it is not null is equal to 3 then RAISERROR
IF (SELECT ISNULL(MAX(Total),0) FROM #AutoFailoverReplicaCount WHERE AGname IN (ISNULL(@AGName,AGname))) = 3
		BEGIN
			IF @AGName IS NOT NULL
				BEGIN
					SELECT AGName, Total AS Total_AutoFailover_Replicas FROM #AutoFailoverReplicaCount WHERE AGName = @AGName ORDER BY AGname ASC
					SET @ErrorText = N'There are already 3 Automatic failover replicas for ['+@AGName+'] some statements may fail'
					RAISERROR(@ErrorText,11,0)
				END

			IF @AGName IS NULL
				BEGIN
					SELECT AGName, Total AS Total_AutoFailover_Replicas FROM #AutoFailoverReplicaCount ORDER BY AGname ASC
					SET @ErrorText = N'There are already 3 Automatic failover replicas for one or more Availability groups some statements may fail'
					RAISERROR(@ErrorText,11,0)
				END

		END

END

END
ELSE
	BEGIN
		RAISERROR('This server is not acting as a Primary server, Please connect to a Primary server and re-run the stored procedure',0,0)
	END
END


