--Undercover Catalogue
--David Fowler
--Version 0.4.1 - 14 January 2020
--Module: Services
--Script: Get

SELECT	@@SERVERNAME AS ServerName, 
		servicename AS ServiceName, 
		startup_type_desc AS StartupType, 
		status_desc AS StatusDesc, 
		service_account AS ServiceAccount, 
		NULL AS InstantFileInit
FROM sys.dm_server_services
