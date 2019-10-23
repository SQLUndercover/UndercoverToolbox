BEGIN


SELECT 
@@SERVERNAME AS ServerName, 
SERVERPROPERTY('collation') AS Collation,
SERVERPROPERTY('Edition') AS Edition, 
SERVERPROPERTY('ProductVersion') AS VersionNo,
sqlserver_start_time AS ServerStartTime,
[cost threshold for parallelism] AS CostThreshold,
[max worker threads] AS MaxWorkerThreads,
[max degree of parallelism] AS [MaxDOP],
cpu_count AS CPUCount,
NULL AS NUMACount, --not implemented, needs a version check
physical_memory_kb / 1024 AS PhysicalMemoryMB,
[max server memory (MB)] AS MaxMemoryMB,
[min server memory (MB)] AS MinMemoryMB,
NULL AS MemoryModel,  --not implemented, needs a version check
SERVERPROPERTY('IsClustered') AS IsClustered,
virtual_machine_type_desc AS VMType
FROM sys.dm_os_sys_info,
(
	SELECT [max worker threads],[cost threshold for parallelism],[max degree of parallelism],[min server memory (MB)],[max server memory (MB)]
	FROM 
	(SELECT name, value_in_use
	FROM sys.configurations
	WHERE name in ('max worker threads','cost threshold for parallelism','max degree of parallelism','min server memory (MB)','max server memory (MB)')) AS Source
	PIVOT
	(
	MAX(value_in_use)
	FOR name IN ([max worker threads],[cost threshold for parallelism],[max degree of parallelism],[min server memory (MB)],[max server memory (MB)])
	)AS PivotTable
) AS config
END
