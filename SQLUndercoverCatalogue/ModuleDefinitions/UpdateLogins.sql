--Undercover Catalogue
--David Fowler
--Version 0.4.0 - 25 November 2019
--Module: Logins
--Script: Update


BEGIN

--update logins where they are known
UPDATE	Catalogue.Logins 
SET		ServerName = [Logins_Stage].ServerName,
		LoginName = [Logins_Stage].LoginName,
		SID = [Logins_Stage].SID,
		RoleName = [Logins_Stage].RoleName,
		PasswordHash = [Logins_Stage].PasswordHash,
		LastRecorded = GETDATE(),
		IsDisabled = [Logins_Stage].IsDisabled,
		LoginType = [Logins_Stage].LoginType
FROM	[Catalogue].[Logins_Stage]
WHERE	Logins.ServerName = [Logins_Stage].ServerName
		AND Logins.LoginName = [Logins_Stage].LoginName
		AND Logins.RoleName = [Logins_Stage].RoleName

--insert logins that are unknown to the catlogue
INSERT INTO Catalogue.Logins
(ServerName,LoginName,SID,RoleName,FirstRecorded,LastRecorded, IsDisabled, PasswordHash,LoginType)
SELECT ServerName,
		LoginName,
		SID,
		RoleName,
		GETDATE(),
		GETDATE(),
		IsDisabled,
		PasswordHash,
		LoginType
FROM [Catalogue].[Logins_Stage]
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Logins
		WHERE Logins.ServerName = [Logins_Stage].ServerName
		AND Logins.LoginName = [Logins_Stage].LoginName
		AND Logins.RoleName = [Logins_Stage].RoleName)

END
