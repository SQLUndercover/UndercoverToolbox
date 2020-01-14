--Undercover Catalogue
--David Fowler
--Version 0.4.1 - 14 January 2020
--Module: ServerConfig
--Script: Get

BEGIN
--get server configuration settings

SELECT	@@SERVERNAME AS ServerName,
		[name] AS SettingName, 
		CAST([value] AS INT) AS SettingValue, 
		CAST(value_in_use AS int) AS SettingValueInUse
FROM sys.configurations

END