/******************************************************************

Author: Adrian Buckman
Revision date: 06/09/2017
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



SELECT    [Database_name],
[DataFilename],
[PhysicalFile_name],
[File_id],
[DatabaseFileSize_MB],
[GrowthRate_MB],
[Is_Percent_Growth],
CASE [GrowthCheck].[is_percent_Growth]
WHEN 1
THEN [Growth]
ELSE 0
END AS [GrowthPercentage%],
[NextGrowth]
FROM
(
SELECT DB_NAME([Masterfiles].[Database_id]) AS [Database_name],
[Masterfiles].[Name] AS [DataFilename],
[MasterFiles].[physical_name] AS [PhysicalFile_name],
[MasterFiles].[File_id],
((CAST([Size] AS BIGINT) * 8) / 1024) AS [DatabaseFileSize_MB],
CASE [Masterfiles].[is_percent_Growth]
WHEN 0
THEN([Masterfiles].[Growth] * 8) / 1024
WHEN 1
THEN(((CAST([Size] AS BIGINT) * 8) / 1024) * [Growth]) / 100
END AS [GrowthRate_MB],
[Masterfiles].[is_percent_growth],
[Masterfiles].[growth],
CASE [Masterfiles].[is_percent_growth]
WHEN 0
THEN((CAST([Size] AS BIGINT) * 8) / 1024) + ([Growth] * 8) / 1024
WHEN 1
THEN((CAST([Size] AS BIGINT) * 8) / 1024) + (((CAST([Size] AS BIGINT) * 8) / 1024) * [Growth]) / 100
END [NextGrowth]
FROM   [SYS].[master_files] [Masterfiles]
INNER JOIN [sys].[databases] [DatabasesList] ON [Masterfiles].[database_id] = [DatabasesList].[database_id]
WHERE  [Masterfiles].[Database_ID] > 4       --Ignore System databases
--AND [Type_desc] = 'ROWS'          --Data Files only
AND [DatabasesList].State = 0       --Online Databases only
) [GrowthCheck]
ORDER BY [Database_name] ASC,
[File_ID] ASC;