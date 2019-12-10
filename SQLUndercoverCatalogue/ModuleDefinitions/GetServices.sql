--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 10 December 2019
--Module: Services
--Script: Get

SELECT @@SERVERNAME, servicename, startup_type_desc, status_desc, service_account, instant_file_initialization_enabled
FROM sys.dm_server_services
