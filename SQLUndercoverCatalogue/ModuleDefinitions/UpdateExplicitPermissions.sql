BEGIN

--update permissions where they are known
UPDATE	Catalogue.ExplicitPermissions 
SET		Name = ExplicitPermissions_Stage.Name,
		PermissionName = ExplicitPermissions_Stage.PermissionName,
		StateDesc = ExplicitPermissions_Stage.StateDesc,
		ServerName = ExplicitPermissions_Stage.ServerName,
		DBName = ExplicitPermissions_Stage.DBName,
		MajorObject = ExplicitPermissions_Stage.MajorObject,
		MinorObject = ExplicitPermissions_Stage.MinorObject,
		LastRecorded = GETDATE()
FROM Catalogue.ExplicitPermissions_Stage
WHERE ExplicitPermissions.Name  = ExplicitPermissions_Stage.Name
		AND ExplicitPermissions.PermissionName = ExplicitPermissions_Stage.PermissionName
		AND ExplicitPermissions.StateDesc = ExplicitPermissions_Stage.StateDesc
		AND ExplicitPermissions.ServerName = ExplicitPermissions_Stage.ServerName
		AND ExplicitPermissions.DBName  = ExplicitPermissions_Stage.DBName
		AND ISNULL(ExplicitPermissions.MajorObject,'') = ISNULL(ExplicitPermissions_Stage.MajorObject,'')
		AND ISNULL(ExplicitPermissions.MinorObject,'') = ISNULL(ExplicitPermissions_Stage.MinorObject,'')

--insert permissions that are unknown to the catlogue
INSERT INTO Catalogue.ExplicitPermissions
(Name, PermissionName,StateDesc,ServerName,DBName,MajorObject,MinorObject,FirstRecorded,LastRecorded)
SELECT	Name,
		PermissionName,
		StateDesc,
		ServerName,
		DBName,
		MajorObject,
		MinorObject,
		GETDATE(),
		GETDATE()
FROM Catalogue.ExplicitPermissions_Stage
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.ExplicitPermissions
		WHERE ExplicitPermissions.Name = ExplicitPermissions_Stage.Name
		AND ExplicitPermissions.PermissionName = ExplicitPermissions_Stage.PermissionName
		AND ExplicitPermissions.StateDesc = ExplicitPermissions_Stage.StateDesc
		AND ExplicitPermissions.ServerName = ExplicitPermissions_Stage.ServerName
		AND ExplicitPermissions.DBName = ExplicitPermissions_Stage.DBName
		AND ISNULL(ExplicitPermissions.MajorObject,'') = ISNULL(ExplicitPermissions_Stage.MajorObject,'')
		AND ISNULL(ExplicitPermissions.MinorObject, '') = ISNULL(ExplicitPermissions_Stage.MinorObject,''))


END
