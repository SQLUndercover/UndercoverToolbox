/******************************************************************

Author: David Fowler
Revision date: 05/10/2017
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


DECLARE @SPID INT = 54
 
SELECT COUNT(*)--fn_dblog.*
FROM fn_dblog(null,null)
WHERE
operation IN ('LOP_MODIFY_ROW', 'LOP_INSERT_ROWS','LOP_DELETE_ROWS') AND
context IN ('LCX_HEAP', 'LCX_CLUSTERED') AND
[Transaction ID] =
                    (SELECT fn_dblog.[Transaction ID]
                    FROM sys.dm_tran_session_transactions session_trans
                    JOIN fn_dblog(null,null) ON fn_dblog.[Xact ID] = session_trans.transaction_id
                    WHERE session_id = @SPID)