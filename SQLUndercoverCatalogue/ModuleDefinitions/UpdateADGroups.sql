BEGIN

--update LastRecorded date where the account and group is known to the catalogue
UPDATE	Catalogue.ADGroups 
SET		LastRecorded = GETDATE()
WHERE EXISTS 
		(SELECT 1 
		FROM [Catalogue].[ADGroups_Stage]
		WHERE	ADGroups.GroupName = ADGroups_Stage.GroupName
				AND ADGroups.AccountName = ADGroups_Stage.AccountName)

--insert ADGroup details where not known to the Catalogue
INSERT INTO Catalogue.ADGroups(GroupName,AccountName,AccountType,FirstRecorded,LastRecorded,Notes)
SELECT GroupName,
		AccountName,
		AccountType,
		GETDATE(),
		GETDATE(),
		NULL
FROM [Catalogue].[ADGroups_Stage]
WHERE NOT EXISTS 
(SELECT 1 FROM Catalogue.ADGroups
		WHERE	ADGroups.GroupName = ADGroups_Stage.GroupName
				AND ADGroups.AccountName = ADGroups_Stage.AccountName)

END
