/******************************************************************

Author: David Fowler
Revision date: 07/02/2018
Version: 1
Description: Display details on all open transaction on the instance

© www.sqlundercover.com 

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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