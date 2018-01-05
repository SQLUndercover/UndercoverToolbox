/******************************************************************

Author: Adrian Buckman
Revision date: 22/10/201
Version: 1

Description: Show Untrusted Foreign key information including Foreign key name, FK table, FK Columns, PK Table , PK Columns reference
Produce SQL Statements to Re enable Untrusted Foreign Keys using @EnableForeignKey = 1 and if these fail to re enable then statements to check the data will be produced.

© www.sqlundercover.com 


This script is for personal, educational, and internal 
corporate purposes, provided that this header is preserved. Redistribution or sale 
of this script,in whole or in part, is prohibited without the author's express 
written consent. 

The software is provided "as is", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. in no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in the
software.

******************************************************************/


 
DECLARE @EnableForeignKey BIT = 1   -- 1: Produce Enable Foreign key scripts, 0: Produce a script to identify if any Orphaned foreign keys exist
DECLARE @SortBy TINYINT = 3   --Order by Column number specify a value from 1-5
 
DECLARE @ColumnName NVARCHAR(128)
DECLARE @FKObjectID INT
DECLARE @PKFKCRels NVARCHAR(1000)
 
SET NOCOUNT ON;
 
SET @ColumnName = CHOOSE(@SortBy,'Orphaned_ForeignKeys_Script','ForeignKey','PK_Tablename','PK_Columns','FK_Columns')
IF @ColumnName IS NOT NULL
BEGIN
 
    IF OBJECT_ID('TempDB..#OutputList') IS NOT NULL
    DROP TABLE #OutputList;
 
    CREATE TABLE #OutputList
    (
    ID INT IDENTITY(1,1),
    Orphaned_ForeignKeys_Script NVARCHAR(4000),
    ForeignKey NVARCHAR(1000),
    PK_Tablename NVARCHAR(256),
    PK_Columns NVARCHAR(1000),
    FK_Columns NVARCHAR(1000)
    );
 
    --Cursor through all non trusted Foreign keys
    DECLARE FK_Cur CURSOR STATIC FORWARD_ONLY LOCAL
    FOR
 
    SELECT
    [Object_id]
    FROM [sys].[foreign_keys] [FKeys]
    WHERE [FKeys].[is_not_trusted] = 1
 
    OPEN FK_Cur
 
    FETCH NEXT FROM FK_Cur INTO @FKObjectID
 
    WHILE @@FETCH_STATUS = 0 
 
           BEGIN
 
           DECLARE @PKFKCRelCols NVARCHAR(1000) = ''
 
                           --For each non trusted Foreign key Match each Foreign key column with it's Referenced PK counterpart
                           DECLARE Column_Cur CURSOR FORWARD_ONLY LOCAL
                           FOR
                           SELECT
                                          (
                                              SELECT
                                         'PK.'+ QUOTENAME(COL_NAME([FKCols].[referenced_object_id],[FKCols].[referenced_column_id])) +
                                         '= FK.'+ QUOTENAME(COL_NAME([FKCols].[parent_object_id],[FKCols].[parent_column_id])) + ' AND '
                                              FROM   [sys].[foreign_key_columns] AS [FKCols]
                                              WHERE  [FKCols].[constraint_object_id] = [FKeys].[object_id]
                                         AND [FKCols].[referenced_column_id] = [ReferenceCols].[column_id] FOR XML PATH('')
                                        ) AS [PK_FK_Columns_By_Position]
 
                              FROM [sys].[foreign_keys] [FKeys]
                                   LEFT JOIN [sys].[foreign_key_columns] [FKCols] ON [FKeys].[object_id] = [FKCols].[constraint_object_id]
                                   LEFT JOIN [sys].[all_columns] [ReferenceCols] ON [FKCols].[referenced_object_id] = [ReferenceCols].[object_id]
                                                                                    AND [FKCols].[referenced_column_id] = [ReferenceCols].[column_id]
                              WHERE [FKeys].[object_id] = @FKObjectID
 
                    OPEN Column_Cur
 
                    FETCH NEXT FROM Column_Cur INTO @PKFKCRels
 
                    WHILE @@FETCH_STATUS = 0 
 
                        BEGIN 
 
                            --Build a list of columns including Aliases and 'AND' clauses to be used in the joins in the scripted output
                           SET @PKFKCRelCols = @PKFKCRelCols + @PKFKCRels 
 
                           FETCH NEXT FROM Column_Cur INTO @PKFKCRels
 
                        END
 
                    CLOSE Column_Cur
                    DEALLOCATE Column_Cur
 
              --Strip additional AND added from the cursor above
              SET @PKFKCRelCols = LEFT(@PKFKCRelCols,LEN(@PKFKCRelCols)-4)
 
              --Build the Orphaned Foreign keys script output and include additional columns that show the Foreign key name, the PK table name, PK columns and FK columns
              INSERT INTO #OutputList (Orphaned_ForeignKeys_Script, ForeignKey, PK_Tablename, PK_Columns,FK_Columns)
              SELECT DISTINCT
              CASE
              WHEN @EnableForeignKey = 0
              THEN
    'SELECT FK.'+REPLACE(FK_Columns,',',' ,FK.')+'
    FROM '+PK_Tablename+' PK
    RIGHT JOIN '+QUOTENAME(PARSENAME(ForeignKey,3))+'.'+QUOTENAME(PARSENAME(ForeignKey,2))+' FK ON '+@PKFKCRelCols+'
    WHERE PK.'+REPLACE(PK_Columns,',',' IS NULL AND PK.')+' IS NULL AND FK.'+REPLACE(FK_Columns,',',' IS NOT NULL AND FK.')+ ' IS NOT NULL
    '
              ELSE
    'BEGIN TRY
        RAISERROR(''Enabling Foreign key '+[ForeignKey]+' WITH CHECK...'',0,0) WITH NOWAIT
        ALTER TABLE '+QUOTENAME(PARSENAME(ForeignKey,3))+'.'+QUOTENAME(PARSENAME(ForeignKey,2))+' WITH CHECK CHECK CONSTRAINT '+QUOTENAME(PARSENAME(ForeignKey,1)) +'
    END TRY
    BEGIN CATCH
        RAISERROR(''FAILED: Orphaned FK Data exists for FK - '+[ForeignKey]+ ' , see output for a script to identify the data'',0,0) WITH NOWAIT'+
        '
        SELECT '''+[ForeignKey]+''' AS Failed_ForeignKey,''SELECT FK.'+REPLACE(FK_Columns,',',' ,FK.')+'
        FROM '+PK_Tablename+' PK
        RIGHT JOIN '+QUOTENAME(PARSENAME(ForeignKey,3))+'.'+QUOTENAME(PARSENAME(ForeignKey,2))+' FK ON '+@PKFKCRelCols+'
        WHERE PK.'+REPLACE(PK_Columns,',',' IS NULL AND PK.')+' IS NULL AND FK.'+REPLACE(FK_Columns,',',' IS NOT NULL AND FK.')+ ' IS NOT NULL'' AS Identify_Orphaned_ForeignKeys_Script
    END CATCH   
 
    '
              END AS Orphaned_ForeignKeys_Script,
              [ForeignKey],
              [PK_Tablename],
              [PK_Columns],
              [FK_Columns]
              FROM
              (
              SELECT
                     QUOTENAME([PKSchema].[name])+'.'+QUOTENAME((OBJECT_NAME([FKeys].[referenced_object_id]))) AS [PK_Tablename],
                     STUFF(
                          (
                              SELECT ','+QUOTENAME(COL_NAME([PKCols].[referenced_object_id],[PKCols].[referenced_column_id]))
                              FROM    [sys].[foreign_key_columns] [PKCols]
                              WHERE  [PKCols].[constraint_object_id] = [FKeys].[object_id] FOR XML PATH('')
                          ),1,1,'') AS [PK_Columns],
                     QUOTENAME(SCHEMA_NAME([FKeys].[Schema_id]))+'.'+QUOTENAME(OBJECT_NAME([FKeys].[Parent_object_id]))+'.'+QUOTENAME([FKeys].[name]) AS [ForeignKey],
                     STUFF(
                          (
                              SELECT ','+QUOTENAME(COL_NAME([FKCols].[parent_object_id],[FKCols].[parent_column_id]))
                              FROM   [sys].[foreign_key_columns] AS [FKCols]
                              WHERE  [FKCols].[constraint_object_id] = [FKeys].object_id FOR XML PATH('')
                          ),1,1,'') AS [FK_Columns]
              FROM [sys].[foreign_keys] [FKeys]
                   LEFT JOIN [sys].[foreign_key_columns] [FKCols] ON [FKeys].[object_id] = [FKCols].[constraint_object_id]
                   LEFT JOIN [sys].[objects] [PKObject] ON [PKObject].[object_id] = [FKeys].[referenced_object_id]
                   LEFT JOIN [sys].[schemas] [PKSchema] ON [PKObject].[schema_id] = [PKSchema].[schema_id]
              WHERE [FKeys].[object_id] = @FKObjectID
              ) DERIVED;
 
           FETCH NEXT FROM FK_Cur INTO @FKObjectID
 
           END
 
    CLOSE FK_Cur
    DEALLOCATE FK_Cur
 
    EXEC (
    N'SELECT
    Orphaned_ForeignKeys_Script,
    ForeignKey,
    PK_Tablename,
    PK_Columns,
    FK_Columns
    FROM #OutputList
    ORDER BY '+@ColumnName+' ASC')
 
END
    ELSE
    BEGIN
        RAISERROR('Invalid @Sortby Value set , only enter values ranging from 1 - 5 inclusive',11,0)
    END