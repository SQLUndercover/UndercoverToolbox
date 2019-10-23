BEGIN
--update servers where they are known to the catalogue
UPDATE Catalogue.Servers 
SET		ServerName = Servers_Stage.ServerName,
		Collation = Servers_Stage.Collation,
		Edition = Servers_Stage.Edition,
		VersionNo = Servers_Stage.VersionNo,
		LastRecorded = GETDATE(),
		ServerStartTime = Servers_Stage.ServerStartTime,
		CostThreshold = Servers_Stage.CostThreshold,
		MaxWorkerThreads = Servers_Stage.MaxWorkerThreads,
		[MaxDOP] = Servers_Stage.[MaxDOP],
		CPUCount = Servers_Stage.CPUCount,
		NUMACount = Servers_Stage.NUMACount,
		PhysicalMemoryMB = Servers_Stage.PhysicalMemoryMB,
		MaxMemoryMB = Servers_Stage.MaxMemoryMB,
		MinMemoryMB = Servers_Stage.MinMemoryMB,
		MemoryModel = Servers_Stage.MemoryModel,
		IsClustered = Servers_Stage.IsClustered,
		VMType = Servers_Stage.VMType
FROM Catalogue.Servers_Stage
WHERE	Servers.ServerName = Servers_Stage.ServerName

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.Servers
			([ServerName], 
			[Collation], 
			[Edition], 
			[VersionNo],
			FirstRecorded,
			LastRecorded,
			ServerStartTime,
			CostThreshold,
			MaxWorkerThreads,
			[MaxDOP],
			CPUCount,
			NUMACount,
			PhysicalMemoryMB,
			MaxMemoryMB,
			MinMemoryMB,
			MemoryModel,
			IsClustered,
			VMType)
SELECT	[ServerName], 
		[Collation], 
		[Edition], 
		[VersionNo],
		GETDATE(),
		GETDATE(),
		ServerStartTime,
		CostThreshold,
		MaxWorkerThreads,
		[MaxDOP],
		CPUCount,
		NUMACount,
		PhysicalMemoryMB,
		MaxMemoryMB,
		MinMemoryMB,
		MemoryModel,
		IsClustered,
		VMType
FROM Catalogue.Servers_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Servers
		WHERE Servers.ServerName = Servers_Stage.ServerName)
END
