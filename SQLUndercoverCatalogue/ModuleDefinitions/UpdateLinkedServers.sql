--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Linked Server
--Script: Update


BEGIN

--temp table used to prevent duplicate entries from the denormalised stage table
IF OBJECT_ID('tempdb.dbo.#LinkedServers') IS NOT NULL
DROP TABLE #LinkedServers

CREATE TABLE #LinkedServers(
				Server nvarchar(128) NOT NULL
				,LinkedServerName nvarchar(128) NOT NULL
				,DataSource nvarchar(4000) NULL
				,Provider nvarchar(128) NULL
				,Product nvarchar(128) NULL
				,Location nvarchar(4000) NULL
				,ProviderString nvarchar(4000) NULL
				,Catalog nvarchar(128) NULL)

--populate #LinkedServers 
INSERT INTO #LinkedServers
SELECT DISTINCT Server, 
				LinkedServerName, 
				DataSource, 
				Provider, 
				Product, 
				Location, 
				ProviderString, 
				Catalog
FROM Catalogue.LinkedServers_Stage

--update servers table where servers are known to the catalogue

UPDATE Catalogue.LinkedServers_Server 
	SET	Server = LinkedServers.Server
	,LinkedServerName = LinkedServers.LinkedServerName
	,DataSource = LinkedServers.DataSource
	,Provider = LinkedServers.Provider
	,Product = LinkedServers.Product
	,Location = LinkedServers.Location
	,ProviderString = LinkedServers.ProviderString
	,Catalog = LinkedServers.Catalog
	,LastRecorded = GETDATE()
FROM #LinkedServers LinkedServers
WHERE LinkedServers_Server.Server = LinkedServers.Server
	AND LinkedServers_Server.LinkedServerName = LinkedServers.LinkedServerName

--insert into servers table where servers are not known to the catalogue

INSERT INTO Catalogue.LinkedServers_Server(Server ,LinkedServerName,DataSource,Provider,Product,Location,ProviderString,Catalog,FirstRecorded,LastRecorded,Notes)
SELECT	Server 
		,LinkedServerName
		,DataSource
		,Provider
		,Product
		,Location
		,ProviderString
		,Catalog
		,GETDATE()
		,GETDATE()
		,NULL
FROM #LinkedServers LinkedServers
WHERE NOT EXISTS
	(SELECT 1
	FROM Catalogue.LinkedServers_Server
	WHERE LinkedServers_Server.Server = LinkedServers.Server
	AND LinkedServers_Server.LinkedServerName = LinkedServers.LinkedServerName)

--update users table where users are known to the catalogue

UPDATE Catalogue.LinkedServers_Users
SET 	Server = LinkedServers_Stage.Server
		,LinkedServerName = LinkedServers_Stage.LinkedServerName
		,LocalUser = LinkedServers_Stage.LocalUser
		,Impersonate = LinkedServers_Stage.Impersonate
		,RemoteUser = LinkedServers_Stage.RemoteUser
		,LastRecorded = GETDATE()
FROM Catalogue.LinkedServers_Stage
WHERE LinkedServers_Users.Server = LinkedServers_Stage.Server
	AND LinkedServers_Users.LinkedServerName = LinkedServers_Stage.LinkedServerName
	AND ISNULL(LinkedServers_Users.LocalUser, '') = ISNULL(LinkedServers_Stage.LocalUser,'')

--insert into users table where users are unkown to the catalogue

INSERT INTO Catalogue.LinkedServers_Users (Server,LinkedServerName,LocalUser,Impersonate,RemoteUser,FirstRecorded,LastRecorded,Notes)
SELECT	Server
		,LinkedServerName
		,LocalUser
		,Impersonate
		,RemoteUser
		,GETDATE()
		,GETDATE()
		,NULL
FROM Catalogue.LinkedServers_Stage
WHERE NOT EXISTS
	(SELECT 1
	FROM Catalogue.LinkedServers_Users
	WHERE LinkedServers_Users.Server = LinkedServers_Stage.Server
	AND LinkedServers_Users.LinkedServerName = LinkedServers_Stage.LinkedServerName
	AND ISNULL(LinkedServers_Users.LocalUser,'') = ISNULL(LinkedServers_Stage.LocalUser,''))

END

