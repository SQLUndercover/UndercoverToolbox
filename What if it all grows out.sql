/*

Author: Adrian Buckman
Created Date: 02/03/2018
Revision date: 
Version: 1
Description: What if it all grows out?!
		   Simulate database growths for all databases and see remaining drive space

URL: https://github.com/SQLUndercover/UndercoverToolbox/blob/master/What%20if%20it%20all%20grows%20out.sql

© www.sqlundercover.com 


MIT License
------------

Copyright 2018 Sql Undercover

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

*/

SET NOCOUNT ON;
    
DECLARE @GrowthsPerDB TINYINT = 1
    
    
    
IF OBJECT_ID('tempdb.dbo.#PercentageGrowths') IS NOT NULL
DROP TABLE #PercentageGrowths;
    
CREATE TABLE #PercentageGrowths
(
[Database_id] INT,
[File_id] INT,
[Physical_Name] NVARCHAR(260),
[Size] BIGINT,
[PostGrowthSize] BIGINT,
[Growth] INT
);
    
DECLARE @Counter INT
    
SET @Counter = 0
    
    
    
--Get base data for Percentage growths only.
INSERT INTO #PercentageGrowths ([Database_id],[File_id],[Physical_Name],[Size],[PostGrowthSize],[Growth])
SELECT
[Masterfiles].[database_id],
[Masterfiles].[file_id],
[Masterfiles].[physical_name],
[size],
[size],
[growth]
FROM [sys].[master_files] [Masterfiles]
WHERE [Masterfiles].[database_id] > 4
AND [Masterfiles].[is_percent_growth] = 1
AND EXISTS (SELECT 1 FROM sys.databases WHERE [Masterfiles].database_id = databases.database_id AND databases.state = 0)
    
    
IF EXISTS (SELECT 1 FROM #PercentageGrowths)
BEGIN
 
WHILE @Counter < @GrowthsPerDB
    
    BEGIN
        
        --Add Percentage based growth based on the File size prior to the last growth
        UPDATE #PercentageGrowths
        SET
        [PostGrowthSize] = [PostGrowthSize] + (CAST([PostGrowthSize] AS BIGINT) * CAST([Growth] AS BIGINT) / 100)
            
        --Increment the counter
        SET @Counter = @Counter +1
        
        
        
    END
    
END
    
    
    
--Calculate the growths for Fixed growths and then aggregate with the percent based growths
SELECT
Drive,
CurrentCapacity_MB,
CurrentlyAvailable_MB,
SUM([PostGrowthSize])-SUM([DatabaseFileSize_MB]) AS TotalGrowth_MB,
CurrentlyAvailable_MB - (SUM([PostGrowthSize])-SUM([DatabaseFileSize_MB])) AS PostGrowthAvailable_MB
FROM
(
SELECT
CAST(LEFT([physical_name],CHARINDEX('\',[physical_name])) AS CHAR(3)) AS Drive,
((CAST([size] AS BIGINT) * 8) / 1024) AS [DatabaseFileSize_MB],
((CAST([size] AS BIGINT) * 8) / 1024) + ([growth] * 8) / 1024 * @GrowthsPerDB AS [PostGrowthSize],
((VolumeInfo.total_bytes)/1024)/1024 AS CurrentCapacity_MB,
((VolumeInfo.available_bytes)/1024)/1024 AS CurrentlyAvailable_MB
FROM [sys].[master_files] [Masterfiles]
INNER JOIN [sys].[databases] [DatabasesList] ON [Masterfiles].[database_id] = [DatabasesList].[database_id]
CROSS APPLY [sys].[dm_os_volume_stats]([Masterfiles].[database_id],[Masterfiles].[file_id]) as VolumeInfo
WHERE [Masterfiles].[database_id] > 4 --Ignore System databases
AND [Masterfiles].[is_percent_growth] = 0 --Fixed growths only
AND EXISTS (SELECT 1 FROM sys.databases WHERE [Masterfiles].database_id = databases.database_id AND databases.state = 0)
UNION ALL
SELECT
CAST(LEFT([Physical_Name],CHARINDEX('\',[Physical_Name])) AS CHAR(3)),
((CAST([Size] AS BIGINT) * 8) / 1024),
((CAST([PostGrowthSize] AS BIGINT) * 8) / 1024),
(([PercentVolumeInfo].total_bytes)/1024)/1024,
(([PercentVolumeInfo].available_bytes)/1024)/1024
FROM #PercentageGrowths
CROSS APPLY [sys].[dm_os_volume_stats]([#PercentageGrowths].[Database_id],[#PercentageGrowths].[File_id]) as PercentVolumeInfo
    
) [GrowthCheck]
GROUP BY
Drive,
CurrentCapacity_MB,
CurrentlyAvailable_MB
ORDER BY
Drive ASC