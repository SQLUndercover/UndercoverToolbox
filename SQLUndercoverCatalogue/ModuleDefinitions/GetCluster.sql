--Undercover Catalogue
--David Fowler
--Version 0.4.2 - 07 February 2020
--Module: Cluster
--Script: Get

SELECT	cluster_name AS ClusterName, 
		quorum_type_desc AS QuorumType,  
		quorum_state_desc AS QuorumState,
		member_name AS MemberName, 
		member_type_desc AS MemberType, 
		number_of_quorum_votes AS QuorumVotes
FROM	sys.dm_hadr_cluster
		,sys.dm_hadr_cluster_members
