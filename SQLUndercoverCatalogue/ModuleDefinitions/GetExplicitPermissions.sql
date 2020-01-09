--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: ExplicitPermissions
--Script: Get

BEGIN

DECLARE @DBName SYSNAME
DECLARE @cmd NVARCHAR(4000)

IF OBJECT_ID('tempdb.dbo.#ExplicitPermissions_tmp') IS NOT NULL
DROP TABLE #ExplicitPermissions_tmp

--create temp table to bulid up result set
CREATE TABLE #ExplicitPermissions_tmp(
	[Name] [sysname] NOT NULL,
	[PermissionName] [nvarchar](128) NULL,
	[StateDesc] [nvarchar](60) NULL,
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[MajorObject] [nvarchar](128) NULL,
	[MinorObject] [nvarchar](128) NULL)


--cursor to cycle through all databases on the server
DECLARE DBCur CURSOR FOR
SELECT [name]
FROM sys.databases

OPEN DBCur

FETCH NEXT FROM DBCur INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

--get all permissions for the selected database
BEGIN TRY
SET @cmd = 
'USE ' + QUOTENAME(@DBName) + '

SELECT	database_principals.name,
		database_permissions.permission_name,
		database_permissions.state_desc,
		@@SERVERNAME AS ServerName,
		DB_Name() AS DBName,
		OBJECT_NAME(database_permissions.major_id) AS MajorObject,
		OBJECT_NAME(database_permissions.minor_id) AS MinorObject
FROM sys.database_principals
JOIN sys.database_permissions ON database_principals.principal_id = database_permissions.grantee_principal_id
WHERE database_principals.name != ''public'''

INSERT INTO #ExplicitPermissions_tmp(Name,PermissionName,StateDesc,ServerName,DBName,MajorObject,MinorObject) 
EXEC sp_executesql @stmt = @cmd
END TRY
BEGIN CATCH
--if database in in accessible do nothing and move on to next database
END CATCH

FETCH NEXT FROM DBCur INTO @DBName

END

CLOSE DBCur
DEALLOCATE DBCur

SELECT * FROM #ExplicitPermissions_tmp

END
