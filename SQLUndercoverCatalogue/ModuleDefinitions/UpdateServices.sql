--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 10 December 2019
--Module: Services
--Script: Update

--update where known to catalogue
UPDATE Catalogue.Services
SET		ServerName = Services_Stage.ServerName,
		ServiceName = Services_Stage.ServiceName,
		StartupType = Services_Stage.StartupType,
		StatusDesc = Services_Stage.StatusDesc,
		ServiceAccount = Services_Stage.ServiceAccount,
		InstantFileInit = Services_Stage.InstantFileInit,
		LastRecorded = GETDATE()
FROM	Catalogue.Services_Stage
WHERE	Services.ServerName = Services_Stage.ServerName
AND		Services.ServiceName = Services_Stage.ServiceName

--insert where not known to catalogue
INSERT INTO Catalogue.Services 
(ServerName, ServiceName, StartupType,StatusDesc, ServiceAccount, InstantFileInit, FirstRecorded, LastRecorded)
SELECT	ServerName,
		ServiceName,
		StartupType,
		StatusDesc,
		ServiceAccount, 
		InstantFileInit, 
		GETDATE(),
		GETDATE()
FROM	Catalogue.Services_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Services
WHERE	Services.ServerName = Services_Stage.ServerName
AND		Services.ServiceName = Services_Stage.ServiceName)

