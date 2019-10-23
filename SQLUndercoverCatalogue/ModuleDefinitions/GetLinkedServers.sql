BEGIN

SELECT	@@SERVERNAME AS Server, 
		servers.name AS LinkedServerName, 
		servers.data_source AS DataSource,
		servers.provider AS Provider, 
		servers.product AS Product, 
		servers.location AS Location,
		servers.provider_string AS ProviderString,
		servers.catalog AS Catalog,
		server_principals.name AS LocalUser,
		linked_logins.uses_self_credential AS Impersonate,
		linked_logins.remote_name AS RemoteUser
FROM sys.servers
JOIN sys.linked_logins ON servers.server_id = linked_logins.server_id
LEFT OUTER JOIN sys.server_principals ON linked_logins.local_principal_id = server_principals.principal_id
WHERE is_linked = 1

END
