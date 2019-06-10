USE [master]
go
 
 
 /******************************************************************

Author: Adrian Buckman
Revision date: 05/04/2019

Description: Produce a script that will provide ALTER statements to change the database
ownership to the new owner and also ALTER statements to revert back to the old owner

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


 
CREATE PROCEDURE sp_ChangeDatabaseOwnerShip
(
@DBOwner NVARCHAR(128) = NULL,
@Help BIT = 0
)
AS
 
IF @Help = 1
BEGIN
PRINT 'Parameters:
@DBOwner NVARCHAR(128) - Set the new owner name here'
END
 
IF @Help = 0
BEGIN
DECLARE @UserSid VARBINARY = SUSER_SID(@DBOwner)
 
IF @UserSid IS NOT NULL
BEGIN
 
SELECT DIstINCT
sys.databases.name AS Databasename,
COALESCE(SUSER_SNAME(sys.databases.owner_sid),'') AS CurrentOwner,
'ALTER AUTHORIZATION ON DATABASE::['+sys.databases.name +'] TO ['+@DBOwner+'];' AS ChangeToNewOwner,
'ALTER AUTHORIZATION ON DATABASE::['+sys.databases.name +'] TO ['+COALESCE(SUSER_SNAME(sys.databases.owner_sid),'')+'];' AS RevertToOriginalOwner
FROM
sys.databases
LEFT JOIN sys.availability_databases_cluster ADC ON sys.databases.name = ADC.database_name
LEFT JOIN sys.dm_hadr_availability_group_states st ON st.group_id = ADC.group_id
LEFT JOIN master.sys.availability_groups ag ON st.group_id = ag.group_id
WHERE (primary_replica = @@Servername
AND sys.databases.owner_sid != @UserSid)
OR (sys.databases.owner_sid != @UserSid
AND sys.databases.state = 0
AND sys.databases.source_database_id IS NULL
AND sys.databases.replica_id IS NULL)
 
END
ELSE
BEGIN
RAISERROR('No SID found for the owner name you have provided - please check the owner name and try again',11,1)
END
 
END