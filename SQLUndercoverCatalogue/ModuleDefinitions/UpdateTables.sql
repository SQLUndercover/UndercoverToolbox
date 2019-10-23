BEGIN
	
	IF OBJECT_ID('tempdb.dbo.#Tables') IS NOT NULL
	DROP TABLE #Tables

	CREATE TABLE #Tables
		(ServerName NVARCHAR(128) NOT NULL,
		DatabaseName NVARCHAR(128) NOT NULL,
		SchemaName SYSNAME NOT NULL,
		TableName SYSNAME NOT NULL,
		Columns XML
		)

	DECLARE @DBName SYSNAME

	--cursor to hold database
	DECLARE DBCur CURSOR FAST_FORWARD LOCAL FOR
	SELECT name 
	FROM sys.databases

	DECLARE @cmd NVARCHAR(2000)

	OPEN DBCur

	FETCH NEXT FROM DBCur INTO @DBName

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @cmd = N'USE ' + QUOTENAME(@DBName) + N';
			SELECT	@@SERVERNAME AS NameServer,
			DB_NAME() AS DatabaseName, 
			schemas.name AS SchemaName, 
			tables.name AS TableName,
			CAST((
				SELECT columns.name AS ColName,
				types.name AS DataType, 
				CASE 
					WHEN columns.max_length = -1 THEN ''MAX''
					WHEN types.name IN (''nchar'',''nvarchar'') THEN CAST(columns.max_length/2 AS VARCHAR)
					ELSE CAST(columns.max_length AS VARCHAR)
				END AS Length, 
				columns.is_nullable AS IsNullable,
				columns.is_identity AS IsIdentity,
				columns.is_computed AS IsComputed
				FROM sys.columns
				JOIN sys.types ON columns.user_type_id = types.user_type_id
				WHERE columns.object_id = tables.object_id		
				FOR XML RAW
			) AS XML) Cols
			FROM sys.tables
			JOIN sys.schemas ON tables.schema_id = schemas.schema_id'
	
	BEGIN TRY
		INSERT INTO #Tables
		EXEC sp_executesql @cmd
	END TRY
	BEGIN CATCH
		--if database in in accessible do nothing and move on to next database
	END CATCH

	FETCH NEXT FROM DBCur INTO @DBName

	END

	SELECT	ServerName
			,DatabaseName
			,SchemaName
			,TableName
			,Columns
	FROM #Tables

END
