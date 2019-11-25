--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Logins
--Script: Get

BEGIN

--get all logins on server
SELECT	@@SERVERNAME AS ServerName,
		principals_logins.name AS LoginName, 
		principals_logins.sid AS SID, 
		principals_roles.name AS RoleName,
		principals_logins.is_disabled AS IsDisabled,
		LOGINPROPERTY(principals_logins.name, 'PasswordHash') AS PasswordHash,  -- **the varbinary of password hash is erroring in powershell, something to be looked at
		principals_logins.type_desc AS LoginType
FROM sys.server_role_members
RIGHT OUTER JOIN sys.server_principals principals_roles 
	ON server_role_members.role_principal_id = principals_roles.principal_id
RIGHT OUTER JOIN sys.server_principals principals_logins 
	ON server_role_members.member_principal_id = principals_logins.principal_id
WHERE principals_logins.type IN ('G','S','U') --include only windows groups, windows logins and SQL logins
ORDER BY principals_logins.name

END
