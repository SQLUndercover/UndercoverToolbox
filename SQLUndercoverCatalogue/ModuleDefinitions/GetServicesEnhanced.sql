--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 11 December 2019
--Module: ServicesEnhanced
--Script: Get

IF (OBJECT_ID('tempdb.dbo.#RawServices') IS NOT NULL)
DROP TABLE #RawServices

IF (OBJECT_ID('tempdb.dbo.#Services') IS NOT NULL)
DROP TABLE #Services

DECLARE @ServiceName VARCHAR(256)
DECLARE @cmd NVARCHAR(500)

CREATE TABLE #RawServices
(	ServiceName VARCHAR(256) NULL,
	RowNo INT IDENTITY(1,1))

CREATE TABLE #Services
(
    ServerName SYSNAME NULL,
    ServiceName NVARCHAR(256) NULL,
    StartupType NVARCHAR(256) NULL,
    StatusDesc NVARCHAR(256) NULL,
    ServiceAccount NVARCHAR(256) NULL,
    InstantFileInit INT NULL
)


--populate #RawServices with SQL related services

INSERT INTO #RawServices(ServiceName)
EXEC xp_cmdshell 'sc query type= service state= all'-- |find "MSOLAP"'-- |find /V "DISPLAY_NAME"'


--sanitise data
DELETE FROM #RawServices 
WHERE	ServiceName IS NULL
	OR	(ServiceName NOT LIKE 'SERVICE_NAME:%' AND ServiceName NOT LIKE '%STATE%:%')

UPDATE #RawServices
SET ServiceName = CASE	WHEN CHARINDEX('RUNNING', ServiceName) > 0 THEN 'Running'
						WHEN CHARINDEX('STOPPED', ServiceName) > 0 THEN 'Stopped'
						ELSE 'Other' 
				END
WHERE ServiceName NOT LIKE 'SERVICE_NAME:%'

UPDATE #RawServices
SET ServiceName = REPLACE(ServiceName, 'SERVICE_NAME: ','')

--Get running state
INSERT INTO #Services(ServerName,ServiceName,StatusDesc)
SELECT @@SERVERNAME, ServiceName, State
FROM
	(SELECT ServiceName, ROW_NUMBER() OVER (ORDER BY RowNo) AS ServiceID 
	FROM #RawServices
	WHERE ServiceName NOT IN ('RUNNING','STOPPED','START_PENDING','STOP_PENDING','UNKNOWN')) AS ServicesNames
JOIN
	(SELECT ServiceName AS State, ROW_NUMBER() OVER (ORDER BY RowNo) AS ServiceID 
	FROM #RawServices
	WHERE ServiceName IN ('RUNNING','STOPPED','START_PENDING','STOP_PENDING','UNKNOWN')) AS States ON States.ServiceID = ServicesNames.ServiceID

--remove the services that we're no worried about

DELETE FROM #Services
WHERE   ServiceName NOT LIKE 'MSOLAP%'
    AND  ServiceName NOT LIKE 'MsDtsServer%'
    AND  ServiceName != 'SQLServerReportingServices' 
    AND  ServiceName NOT LIKE 'ReportServer%'
    AND  ServiceName != 'SQL Server Distributed Replay Client'
    AND  ServiceName != 'SQL Server Distributed Replay Controller'



DECLARE ServicesCur CURSOR STATIC FORWARD_ONLY FOR
SELECT ServiceName
FROM #Services

--EXEC xp_cmdshell 'sc qc BrokerInfrastructure'

OPEN ServicesCur

--fetch service details
FETCH NEXT FROM ServicesCur INTO @ServiceName

WHILE @@FETCH_STATUS = 0
BEGIN

    TRUNCATE TABLE #RawServices

	SET @cmd = 'sc qc "' + @ServiceName + '"'

    INSERT #RawServices(ServiceName)
	EXEC xp_cmdshell @cmd

    --Update with Startup Type
    UPDATE #Services
    SET StartupType = CASE  WHEN CHARINDEX('DISABLED', RawServices.ServiceName) > 0 THEN 'Disabled'
                            WHEN CHARINDEX('AUTO_START', RawServices.ServiceName) > 0 THEN 'Automatic'
                            WHEN CHARINDEX('DEMAND_START', RawServices.ServiceName) > 0 THEN 'Manual'
                            ELSE 'Other'
                        END
    FROM #RawServices RawServices
    WHERE RawServices.ServiceName LIKE '%START_TYPE%'
    AND #Services.ServiceName = @ServiceName

    --Update with Service Account
    UPDATE #Services
    SET ServiceAccount = REPLACE(RawServices.ServiceName,'        SERVICE_START_NAME : ', '')
    FROM #RawServices RawServices
    WHERE RawServices.ServiceName LIKE '%SERVICE_START_NAME%'
    AND #Services.ServiceName = @ServiceName


    --Update with service display name
    UPDATE #Services
    SET ServiceName = REPLACE(RawServices.ServiceName, '        DISPLAY_NAME       : ','')
    FROM #RawServices RawServices
    WHERE RawServices.ServiceName LIKE '%DISPLAY_NAME%:%'
    AND #Services.ServiceName = @ServiceName


FETCH NEXT FROM ServicesCur INTO @ServiceName

END

CLOSE ServicesCur
DEALLOCATE ServicesCur

SELECT  ServerName,
        ServiceName,
        StartupType,
        StatusDesc,
        ServiceAccount,
        'N'
FROM #Services

