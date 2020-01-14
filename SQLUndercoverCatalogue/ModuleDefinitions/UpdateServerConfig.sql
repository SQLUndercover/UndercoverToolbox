--Undercover Catalogue
--David Fowler
--Version 0.4.1 - 14 January 2020
--Module: ServerConfig
--Script: Update


BEGIN

--update settings where known to the catalogue
UPDATE Catalogue.ServerConfig
SET ServerName = ServerConfig_Stage.ServerName,
	SettingName = ServerConfig_Stage.SettingName,
	SettingValue = ServerConfig_Stage.SettingValue,
	SettingValueInUse = ServerConfig_Stage.SettingValueInUse,
	LastRecorded = GETDATE()
FROM Catalogue.ServerConfig_Stage
WHERE ServerConfig.ServerName = ServerConfig_Stage.ServerName
	AND ServerConfig.SettingName = ServerConfig_Stage.SettingName

--insert settings where unknown to the catalogue
INSERT INTO Catalogue.ServerConfig
(ServerName, SettingName, SettingValue, SettingValueInUse, FirstRecorded, LastRecorded)
SELECT	ServerName, 
		SettingName, 
		SettingValue, 
		SettingValueInUse,
		GETDATE(),
		GETDATE()
FROM	Catalogue.ServerConfig_Stage
WHERE NOT EXISTS (SELECT 1
					FROM Catalogue.ServerConfig
					WHERE ServerConfig.ServerName = ServerConfig_Stage.ServerName
					AND ServerConfig.SettingName = ServerConfig_Stage.SettingName)

END