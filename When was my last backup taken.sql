/******************************************************************

Author: David Fowler
Revision date: 19/07/2017
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


SELECT name, [FULL], [DIFF], [LOG]
FROM
  (SELECT databases.name, backup_start_date,
   CASE type
      WHEN 'D' THEN 'FULL'
      WHEN 'I' THEN 'DIFF'
      WHEN 'L' THEN 'LOG'
   END AS type
   FROM msdb..backupset backupset
   RIGHT OUTER JOIN sys.databases databases ON databases.name = backupset.database_name) rawtab
PIVOT
(MAX(backup_start_date)
FOR type IN ([FULL],[DIFF],[LOG])) pivottab