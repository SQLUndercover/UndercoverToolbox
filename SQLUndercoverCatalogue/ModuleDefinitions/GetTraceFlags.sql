--Undercover Catalogue
--David Fowler
--Version 0.4.2 - 06 February 2020
--Module: TraceFlags
--Script: Get

CREATE TABLE #TraceFlags
(
TraceFlag INT,
Status BIT,
Global BIT,
Session BIT
)

INSERT INTO #TraceFlags
EXEC sp_executesql N'DBCC tracestatus'

SELECT @@SERVERNAME AS ServerName, TraceFlag
FROM #TraceFlags