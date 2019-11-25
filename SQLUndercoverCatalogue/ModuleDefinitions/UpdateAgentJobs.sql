--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: AgentJobs
--Script: Update


BEGIN

--update jobs where they are known
UPDATE Catalogue.AgentJobs 
SET JobName = AgentJobs_Stage.JobName,
	Enabled = AgentJobs_Stage.Enabled,
	Description = AgentJobs_Stage.Description,
	Category = AgentJobs_Stage.Category,
	DateCreated = AgentJobs_Stage.DateCreated,
	DateModified = AgentJobs_Stage.DateModified,
	ScheduleEnabled = AgentJobs_Stage.ScheduleEnabled,
	ScheduleName = AgentJobs_Stage.ScheduleName,
	ScheduleFrequency = AgentJobs_Stage.ScheduleFrequency,
	StepID = AgentJobs_Stage.StepID,
	StepName = AgentJobs_Stage.StepName,
	SubSystem = AgentJobs_Stage.SubSystem,
	Command = AgentJobs_Stage.Command,
	DatabaseName = AgentJobs_Stage.DatabaseName,
	LastRecorded = GETDATE()
FROM Catalogue.AgentJobs_Stage
WHERE	AgentJobs.ServerName = AgentJobs_Stage.ServerName
		AND AgentJobs.JobID = AgentJobs_Stage.JobID
		AND AgentJobs.StepID = AgentJobs_Stage.StepID

--insert jobs that are unknown to the catlogue
INSERT INTO Catalogue.AgentJobs 
(ServerName,JobID,JobName,Enabled,Description,Category,DateCreated,DateModified,
ScheduleEnabled,ScheduleName,ScheduleFrequency,StepID, StepName,SubSystem,Command,DatabaseName,
FirstRecorded, LastRecorded)
SELECT	ServerName,
		JobID,
		JobName,
		Enabled,
		Description,
		Category,
		DateCreated,
		DateModified,
		ScheduleEnabled,
		ScheduleName,
		ScheduleFrequency,
		StepID,
		StepName,
		SubSystem,
		Command,
		DatabaseName,
		GETDATE(),
		GETDATE()
FROM Catalogue.AgentJobs_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.AgentJobs 
		WHERE JobID = AgentJobs_Stage.JobID 
		AND StepID = AgentJobs_Stage.StepID
		AND ServerName = AgentJobs_Stage.ServerName)

END
