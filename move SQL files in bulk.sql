/******************************************************************
 
Author: David Fowler
Revision date: 22/04/2020
Version: 1.1
 
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
 
--config variables
DECLARE @logpath NVARCHAR(260) = 'G:\SQLLogs'
DECLARE @datapath NVARCHAR(260) = 'E:\SQLData'
DECLARE @movelogs BIT = 1
DECLARE @movedata BIT = 0
 
--runtime variables
DECLARE @STMT NVARCHAR(4000)
 
--uncomment the predicates to include and exclude databases as required
DECLARE Files CURSOR STATIC FORWARD_ONLY
FOR
SELECT DB_NAME(database_id)
    ,type
    ,name
    ,REVERSE(SUBSTRING(REVERSE(physical_name), 0, CHARINDEX('\', REVERSE(physical_name))))
FROM sys.master_files
WHERE type IN (0,1)
--AND DB_NAME(database_id) IN ('sqlundercover')                         --uncomment to include databases
--AND DB_NAME(database_id) NOT IN ('master','tempdb','msdb','model')    --uncomment to exclude databases
 
DECLARE @DBName SYSNAME
DECLARE @type TINYINT
DECLARE @logicalname SYSNAME
DECLARE @physicalname NVARCHAR(260)
 
--check filepaths finish with a \ and add if they don't
IF (SUBSTRING(@datapath, LEN(@datapath), 1) != '\')
    SET @datapath += N'\'
 
IF (SUBSTRING(@logpath, LEN(@logpath), 1) != '\')
    SET @logpath += N'\'
 
OPEN Files
 
FETCH NEXT
FROM Files
INTO @DBName
    ,@type
    ,@logicalname
    ,@physicalname
 
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @STMT = N'ALTER DATABASE ' + QUOTENAME(@DBName) + N' MODIFY FILE (NAME = ' +  QUOTENAME(@logicalname) + N', FILENAME = '''
    SET @STMT += CASE
            WHEN @type = 0 AND @movedata = 1
                THEN @datapath + @physicalname + ''')'
            WHEN @type = 1 AND @movelogs = 1
                THEN @logpath + @physicalname + ''')'
            END
 
    PRINT @STMT
 
    FETCH NEXT
    FROM Files
    INTO @DBName
        ,@type
        ,@logicalname
        ,@physicalname
END
 
CLOSE Files
 
DEALLOCATE Files