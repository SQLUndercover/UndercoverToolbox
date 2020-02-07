--Undercover Catalogue
--David Fowler
--Version 0.4.2 - 6 February 2020
--Module: Databases
--Script: Update


BEGIN

--update trace flags where they are known to the catalogue
UPDATE	Catalogue.TraceFlags
SET		ServerName = TraceFlags_Stage.ServerName,
		TraceFlag = TraceFlags_Stage.TraceFlag,
		LastRecorded = GETDATE()
FROM	Catalogue.TraceFlags_Stage
WHERE	TraceFlags_Stage.ServerName = TraceFlags.ServerName
		AND TraceFlags_Stage.TraceFlag = TraceFlags.TraceFlag

--insert trace flags that are unknown to the catlogue
INSERT INTO Catalogue.TraceFlags (ServerName, TraceFlag, FirstRecorded, LastRecorded)
SELECT	ServerName,
		TraceFlag,
		GETDATE(),
		GETDATE()
FROM	Catalogue.TraceFlags_Stage
WHERE NOT EXISTS
(SELECT 1 FROM Catalogue.TraceFlags
		WHERE	TraceFlags_Stage.ServerName = TraceFlags.ServerName
		AND TraceFlags_Stage.TraceFlag = TraceFlags.TraceFlag)

END
