/*
SQL Undercover Academy
https://sqlundercover.com

SQL Server Backup and Recovery

Module 1: Taking and Restoring a Backup
David Fowler
*/


--Taking a full backup
BACKUP DATABASE SQLUndercover 
TO DISK = 'C:\SQLBackups\SQLUndercover.bak' 
WITH STATS, CHECKSUM, COMPRESSION




--Restoring a backup to the same database
RESTORE DATABASE SQLUndercover
FROM DISK = 'C:\SQLBackups\SQLUndercover.bak' 
WITH STATS, REPLACE



--Taking a differential backup
BACKUP DATABASE SQLUndercover
TO DISK = 'C:\SQLBackups\SQLUndercover.dif'
WITH DIFFERENTIAL



--Restoring a differential backup
--first we need to restore the last full backup

RESTORE DATABASE SQLUndercover
FROM DISK = 'C:\SQLBackups\SQLUndercover.bak'
WITH STATS, REPLACE

RESTORE DATABASE SQLUndercover
FROM DISK = 'C:\SQLBackups\SQLUndercover.dif'
WITH STATS






--we need to remember to restore using NORECOVERY
RESTORE DATABASE SQLUndercover
FROM DISK = 'C:\SQLBackups\SQLUndercover.bak'
WITH STATS, REPLACE, NORECOVERY

RESTORE DATABASE SQLUndercover
FROM DISK = 'C:\SQLBackups\SQLUndercover.dif'
WITH STATS