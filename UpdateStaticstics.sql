/******************************************************************
Author: David Fowler
Revision date: 04/09/2019
Version: 1.4

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


CREATE PROC UpdateStatistics (@Threshold INT = 5000) --number of row changes before stats update  
AS  
  
BEGIN  
  
IF OBJECT_ID('tempdb.dbo.##StatsUpdate') IS NOT NULL  
DROP TABLE ##StatsUpdate  
  
CREATE TABLE ##StatsUpdate  
(UpdateCmd VARCHAR(8000))  
  
  
DECLARE @DBName SYSNAME  
DECLARE @SQL VARCHAR(MAX)  
DECLARE @UpdateCmd VARCHAR(8000)  
  
--get databases that are primary on the current node into cursor  
DECLARE DatabasesCur CURSOR STATIC FORWARD_ONLY FOR  
SELECT databases.name AS DBName  
FROM sys.databases
WHERE database_id > 4
AND state = 0
  
OPEN DatabasesCur  
  
FETCH NEXT FROM DatabasesCur INTO @DBName  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  
 SET @SQL =   
 'USE ' + QUOTENAME(@DBName) + ';  
 INSERT INTO ##StatsUpdate  
 SELECT  ''USE '' + QUOTENAME(DB_NAME()) + ''; UPDATE STATISTICS '' + QUOTENAME(SCHEMA_NAME(tables.schema_id)) + ''.'' + QUOTENAME(objects.name) + '' '' + QUOTENAME(stats.name) + '';''  
 FROM sys.stats stats  
 CROSS APPLY sys.dm_db_stats_properties(stats.object_id, stats.stats_id) properties  
 JOIN sys.tables tables ON stats.object_id = tables.object_id  
 JOIN sys.objects objects ON objects.object_id = stats.object_id  
 WHERE properties.modification_counter >= ' + CAST(@Threshold AS VARCHAR(10)) + '  
 AND objects.type = ''U'''  
  
 EXEC (@SQL)  
  
 FETCH NEXT FROM DatabasesCur INTO @DBName  
  
END   
  
CLOSE DatabasesCur  
DEALLOCATE DatabasesCur  
  
--cursor through and run all stats updates  
  
RAISERROR ('Starting Stats Update',0,1) WITH NOWAIT  
  
DECLARE UpdateStatsCmds CURSOR STATIC FORWARD_ONLY FOR  
SELECT DISTINCT UpdateCmd  
FROM ##StatsUpdate  
  
OPEN UpdateStatsCmds  
  
FETCH NEXT FROM UpdateStatsCmds INTO @UpdateCmd  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
 RAISERROR (@UpdateCmd,0,1) WITH NOWAIT  
 EXEC (@UpdateCmd)  
 FETCH NEXT FROM UpdateStatsCmds INTO @UpdateCmd  
END  
  
CLOSE UpdateStatsCmds  
DEALLOCATE UpdateStatsCmds  
  
END  
  