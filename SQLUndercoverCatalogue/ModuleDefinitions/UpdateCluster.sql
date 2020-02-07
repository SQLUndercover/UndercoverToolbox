--Undercover Catalogue
--David Fowler
--Version 0.4.2 - 7 February 2020
--Module: Cluster
--Script: Update


BEGIN

--update cluster flags where they are known to the catalogue
UPDATE	Catalogue.Cluster
SET		ClusterName = Cluster_Stage.ClusterName,
		QuorumType = Cluster_Stage.QuorumType,
		QuorumState = Cluster_Stage.QuorumState,
		MemberName = Cluster_Stage.MemberName,
		MemberType = Cluster_Stage.MemberType,
		QuorumVotes = Cluster_Stage.QuorumVotes,
		LastRecorded = GETDATE()
FROM	Catalogue.Cluster_Stage
WHERE	Cluster_Stage.ClusterName = Cluster.ClusterName
		AND Cluster_Stage.MemberName = Cluster.MemberName


--insert cluster flags that are unknown to the catlogue
INSERT INTO Catalogue.Cluster (ClusterName,QuorumType,QuorumState,MemberName,MemberType,QuorumVotes,FirstRecorded,LastRecorded)
SELECT	ClusterName,
		QuorumType,
		QuorumState,
		MemberName,
		MemberType,
		QuorumVotes,
		GETDATE(),
		GETDATE()
FROM	Catalogue.Cluster_Stage
WHERE NOT EXISTS
(SELECT 1 FROM Catalogue.Cluster
		WHERE	Cluster_Stage.ClusterName = Cluster.ClusterName
		AND Cluster_Stage.MemberName = Cluster.MemberName)

END
