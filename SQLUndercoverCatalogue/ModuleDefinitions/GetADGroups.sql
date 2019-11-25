--David Fowler
--v0.4.0

BEGIN

DECLARE @GroupName SYSNAME

--create temp table to hold results from xp_logininfo
IF OBJECT_ID('tempdb.dbo.#LoginInfo') IS NOT NULL
DROP TABLE #LoginInfo

CREATE TABLE #LoginInfo
(accountname SYSNAME NULL,
 type CHAR(8) NULL,
 privilege CHAR(9) NULL,
 mappedloginname SYSNAME NULL,
 permissionpath SYSNAME NULL)

--create temp table to hold final results
IF OBJECT_ID('tempdb.dbo.#FinalResults') IS NOT NULL
DROP TABLE #FinalResults

CREATE TABLE #FinalResults(
	GroupName SYSNAME NOT NULL,
	AccountName SYSNAME NOT NULL,
	AccountType CHAR(8) NOT NULL)
 

--cursor to hold all windows groups

DECLARE GroupsCur CURSOR FAST_FORWARD LOCAL FOR
	SELECT name
	FROM sys.server_principals
	WHERE type_desc = 'WINDOWS_GROUP'

OPEN GroupsCur

FETCH NEXT FROM GroupsCur INTO @GroupName

WHILE @@FETCH_STATUS = 0
BEGIN
	TRUNCATE TABLE #LoginInfo  --truncate work table to prevent data from previous loop being carried through

	DECLARE @SQL VARCHAR(100)
	SET @SQL = 'EXEC xp_logininfo ''' + @GroupName + ''', ''members'''
	
	--populate #LoginInfo
	BEGIN TRY
		INSERT INTO #LoginInfo
		EXEC (@SQL)
	END TRY
	BEGIN CATCH --catch if there's an issue evaluating the group for some reason
		INSERT INTO #LoginInfo (accountname, type)
		VALUES (@GroupName, '*ERROR*')
	END CATCH

	--append to final results temp table
	INSERT INTO #FinalResults (GroupName,AccountName,AccountType)
	SELECT @GroupName, accountname, type
	FROM #LoginInfo

	FETCH NEXT FROM GroupsCur INTO @GroupName
END

SELECT GroupName,AccountName,AccountType
FROM #FinalResults

END
