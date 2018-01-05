/******************************************************************

Author: David Fowler
Revision date: 21/08/2017
Version: 1

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

SET NOCOUNT ON
 
DECLARE @Query VARCHAR(MAX) = 'select * from sys.databases'
DECLARE @TempTableName VARCHAR(128) = '#temptable'
DECLARE @ColumnList VARCHAR(MAX)
 
SELECT @ColumnList = STUFF((SELECT ',' + name + ' ' + system_type_name + ' ' +
CASE is_nullable WHEN 0 THEN 'NOT NULL' ELSE 'NULL' END
+ CHAR(10)
FROM sys.dm_exec_describe_first_result_set(@Query, NULL, 0)
FOR XML PATH('')) ,1,1,'') 
 
PRINT 'CREATE TABLE ' + @TempTableName + '('
PRINT @ColumnList
PRINT(')')