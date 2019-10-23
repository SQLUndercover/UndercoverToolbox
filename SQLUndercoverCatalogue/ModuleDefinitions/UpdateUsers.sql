BEGIN

--update users where they are known
UPDATE	Catalogue.Users 
SET		ServerName = Users_Stage.ServerName,
		DBName = Users_Stage.DBName,
		UserName = Users_Stage.UserName,
		SID = Users_Stage.SID,
		LastRecorded = GETDATE(),
		MappedLoginName = Users_Stage.MappedLoginName
FROM Catalogue.Users_Stage
WHERE	Users.UserName = Users_Stage.UserName
		AND Users.ServerName = Users_Stage.ServerName
		AND Users.DBName = Users_Stage.DBName
		AND ISNULL(Users.RoleName ,'') = ISNULL(Users_Stage.RoleName,'')

--insert users that are unknown to the catlogue
INSERT INTO Catalogue.Users
(ServerName, DBName, UserName, SID, RoleName,MappedLoginName,FirstRecorded,LastRecorded)
SELECT ServerName,
		DBName,
		UserName,
		SID,
		RoleName,
		MappedLoginName,
		GETDATE(),
		GETDATE()
FROM Catalogue.Users_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.Users
		WHERE UserName = Users_Stage.UserName
		AND ServerName= Users_Stage.ServerName
		AND DBName = Users_Stage.DBName
		AND ISNULL(RoleName,'') = ISNULL(RoleName,''))

END
