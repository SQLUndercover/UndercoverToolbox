USE [master]
go
 
 
 /******************************************************************

Author: Adrian Buckman
Revision date: 17/08/2017
Version: 1

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
 
SELECT DISTINCT
sys.databases.Name AS Databasename,
COALESCE(SUSER_SNAME(sys.Databases.owner_sid),'') AS CurrentOwner,
'ALTER AUTHORIZATION ON DATABASE::['+sys.Databases.Name +'] TO ['+@DBOwner+'];' AS ChangeToNewOwner,
'ALTER AUTHORIZATION ON DATABASE::['+sys.Databases.Name +'] TO ['+COALESCE(SUSER_SNAME(sys.Databases.owner_sid),'')+'];' AS RevertToOriginalOwner
FROM
sys.databases
LEFT JOIN Sys.availability_databases_cluster ADC ON sys.databases.name = ADC.database_name
LEFT JOIN sys.dm_hadr_availability_group_states st ON ST.group_id = ADC.group_id
LEFT JOIN master.sys.availability_groups ag ON ST.group_id = AG.group_id
WHERE (primary_replica = @@Servername
AND sys.Databases.owner_sid != @UserSid)
OR (sys.Databases.owner_sid != @UserSid
AND sys.Databases.State = 0
AND sys.Databases.Source_Database_id IS NULL
AND sys.databases.Replica_id IS NULL)
 
END
ELSE
BEGIN
RAISERROR('No SID found for the owner name you have provided - please check the owner name and try again',11,1)
END
 
END