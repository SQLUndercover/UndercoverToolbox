BEGIN

DECLARE @DBName SYSNAME
DECLARE @cmd NVARCHAR(4000)

IF OBJECT_ID('tempdb.dbo.#Users_Tmp') IS NOT NULL
DROP TABLE #Users_Tmp

--create temp table to bulid up result set
CREATE TABLE #Users_Tmp(
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[UserName] [sysname] NOT NULL,
	[SID] [varbinary](85) NULL,
	[RoleName] [sysname] NULL,
	[MappedLoginName] [sysname] NOT NULL)


--cursor to cycle through all databases on the server
DECLARE DBCur CURSOR FOR
SELECT [name]
FROM sys.databases

OPEN DBCur

FETCH NEXT FROM DBCur INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

--get all users for the selected database

BEGIN TRY
	SET @cmd = 
	'USE ' + QUOTENAME(@DBName) + '

	SELECT	@@SERVERNAME AS ServerName,
			DB_NAME() AS DBName,
			principals_logins.name AS UserName, 
			principals_logins.sid AS SID, 
			principals_roles.name AS RoleName,
			ISNULL(server_principals.name, ''***ORPHANED USER***'') AS MappedLoginName
	FROM sys.database_role_members
	RIGHT OUTER JOIN sys.database_principals principals_roles 
		ON database_role_members.role_principal_id = principals_roles.principal_id
	RIGHT OUTER JOIN sys.database_principals principals_logins 
		ON database_role_members.member_principal_id = principals_logins.principal_id
	LEFT OUTER JOIN sys.server_principals 
		ON server_principals.sid = principals_logins.sid
	WHERE principals_logins.type IN (''G'',''S'',''U'') --include only windows groups, windows logins and SQL logins
		AND principals_logins.sid IS NOT NULL 
	ORDER BY principals_logins.name'

	INSERT INTO #Users_Tmp(ServerName,DBName,UserName,SID,RoleName,MappedLoginName) 
	EXEC sp_executesql @stmt = @cmd
END TRY
BEGIN CATCH
--if the database is inaccessable, do nothing and move on to the next one
END CATCH
FETCH NEXT FROM DBCur INTO @DBName

END

CLOSE DBCur
DEALLOCATE DBCur

SELECT * FROM #Users_Tmp

END
