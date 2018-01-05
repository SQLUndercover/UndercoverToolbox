/******************************************************************

Author: David Fowler
Revision date: 01/09/2017
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


--variable to hold directory to check
DECLARE @Path VARCHAR(50) = 'O:\SQLUndercover\Backups'
 
IF OBJECT_ID('tempdb..#xp_fileexist_Results') IS NOT NULL DROP TABLE #xp_fileexist_Results
 
CREATE TABLE #xp_fileexist_Results (
File_Exists int,
File_is_a_Directory int,
Parent_Directory_Exists int
)
 
--check if directory exists
INSERT INTO #xp_fileexist_Results
(File_Exists, file_is_a_directory, parent_directory_exists)
EXEC Master.dbo.xp_fileexist @Path
 
IF EXISTS (SELECT 1 FROM #xp_fileexist_Results WHERE File_is_a_Directory = 1) --if exists PRINT 'Directory Exists'
    PRINT 'Directory Exists'
ELSE  --if directory doesn't exist, attempt to create it
BEGIN
    EXEC xp_create_subdir @FullPath
 
    --perform another existance check to make sure that the directory was actually created
    TRUNCATE TABLE #xp_fileexist_Results
 
    INSERT INTO #xp_fileexist_Results
    (File_Exists, file_is_a_directory, parent_directory_exists)
    EXEC Master.dbo.xp_fileexist @FullPath
 
    IF EXISTS (SELECT 1 FROM #xp_fileexist_Results WHERE File_is_a_Directory = 1) --if new directory exists PRINT 'Directory Created'
        PRINT 'Directory Created'
    ELSE
        PRINT 'Error Creating Folder' --if new directory doesn't exist then there must have been a problem creating it
END