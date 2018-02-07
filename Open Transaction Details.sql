/******************************************************************

Author: David Fowler
Revision date: 07/02/2018
Version: 1
Description: Display details on all open transaction on the instance

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

SELECT	SessionTrans.session_id
		,ActiveTrans.transaction_begin_time
		,DATEDIFF(SECOND,ActiveTrans.transaction_begin_time,GETDATE()) AS Duration_Seconds

		,CASE ActiveTrans.transaction_state
			WHEN 0 THEN 'Uninitialised'
			WHEN 1 THEN 'Not Started'
			WHEN 2 THEN 'Active'
			WHEN 3 THEN 'Ended'
			WHEN 4 THEN 'Commit Initiated'
			WHEN 5 THEN 'Prepared'
			WHEN 6 THEN 'Commited'
			WHEN 7 THEN 'Rolling Back'
			WHEN 8 THEN 'Rolled Back'
			ELSE CAST(ActiveTrans.transaction_state AS VARCHAR)
		END AS TransactionState
		,sessions.login_name
		,sessions.host_name
		,sessions.program_name
		,DB_NAME(sessions.database_id) AS DBName
		,SQLText.text AS LastCommand
FROM sys.dm_tran_session_transactions SessionTrans
JOIN sys.dm_tran_active_transactions ActiveTrans ON SessionTrans.transaction_id = ActiveTrans.transaction_id
JOIN sys.dm_exec_sessions Sessions ON Sessions.session_id = SessionTrans.session_id
JOIN sys.dm_exec_connections connections ON Connections.session_id = Sessions.session_id
CROSS APPLY sys.dm_exec_sql_text(Connections.most_recent_sql_handle) SQLText