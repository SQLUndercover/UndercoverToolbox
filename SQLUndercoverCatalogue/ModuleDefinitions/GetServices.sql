--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 10 December 2019
--Module: Services
--Script: Get

SELECT	@@SERVERNAME AS ServerName, 
		servicename AS ServiceName, 
		startup_type_desc AS StartupType, 
		status_desc AS StatusDesc, 
		service_account AS ServiceAccount, 
		instant_file_initialization_enabled AS InstantFileInit
FROM sys.dm_server_services
