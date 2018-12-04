/**********************************************
Author: David Fowler
Revision date: 04/12/2018
Version: 1.0

Description: Scripts to indentify missing logins in an availability group as well as mismatched SIDs and logins

For more info see associated blog post,


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

*********************************************/


--create temp table to hold your AG details (this will be included in the Undercover Catalogue v0.2 release, so if you're in the future and that is out then tweek the scripts to point at Catalogue.AvailabilityGroups)

IF OBJECT_ID('tempdb.dbo.#AGs') IS NOT NULL
DROP TABLE #AGs

CREATE TABLE #AGs
(AGName SYSName,
ServerName SYSNAME,
AGRole VARCHAR(9))

INSERT INTO #AGs
VALUES ('AG1','SQLUndercoverTest01', 'PRIMARY'),
('AG1','SQLUndercoverTest02', 'SECONDARY'),
('AG1','SQLUndercoverTest03', 'SECONDARY'),
('AG1','SQLUndercoverTest04', 'SECONDARY'),
('AG1','SQLUndercoverTest05', 'SECONDARY')


--Identify missing logins
SELECT DISTINCT AGs.AGName, Logins.LoginName, AGs2.ServerName AS [Missing On Node]
FROM #AGs AGs
JOIN Catalogue.Logins Logins ON AGs.ServerName = Logins.ServerName
JOIN #AGs AGs2 ON AGs.AGName = AGs2.AGName
WHERE NOT EXISTS (SELECT 1
					FROM #AGs AGs3
					JOIN Catalogue.Logins Logins3 ON AGs3.ServerName = Logins3.ServerName
					WHERE AGs3.AGName = AGs.AGName
					AND AGs3.ServerName = AGs2.ServerName
					AND Logins3.LoginName = Logins.LoginName)



--Identify mismatched SIDs
SELECT	DISTINCT PrimaryLogins.ServerName AS PrimaryServer,
		SecondaryLogins.ServerName AS SecondaryServer, 
		SecondaryLogins.LoginName, 
		PrimaryLogins.sid AS PrimarySID, 
		SecondaryLogins.sid AS SecondarySID, 
		'DROP LOGIN ' + QUOTENAME(SecondaryLogins.LoginName) +'; CREATE LOGIN ' + QUOTENAME(SecondaryLogins.LoginName) + ' WITH PASSWORD = 0x' + CONVERT(VARCHAR(MAX), PrimaryLogins.PasswordHash, 2) + ' HASHED, SID = 0x' + CONVERT(VARCHAR(MAX), PrimaryLogins.sid, 2) + ';' AS CreateCMD
FROM
		(SELECT AGs.AGName, AGs.ServerName, Logins.LoginName,Logins.sid, Logins.PasswordHash
		FROM #AGs AGs
		JOIN Catalogue.Logins Logins ON AGs.ServerName = Logins.ServerName
		WHERE AGs.AGRole = 'PRIMARY') PrimaryLogins
JOIN
		(SELECT AGs.AGName, AGs.ServerName, Logins.LoginName,Logins.sid
		FROM #AGs AGs
		JOIN Catalogue.Logins Logins ON AGs.ServerName = Logins.ServerName
		WHERE AGs.AGRole = 'SECONDARY') SecondaryLogins ON PrimaryLogins.AGName = SecondaryLogins.AGName AND PrimaryLogins.LoginName = SecondaryLogins.LoginName
WHERE PrimaryLogins.sid != SecondaryLogins.sid


--Identify mismatched passwords
SELECT	DISTINCT PrimaryLogins.ServerName AS PrimaryServer,
		SecondaryLogins.ServerName AS SecondaryServer, 
		SecondaryLogins.LoginName, 
		PrimaryLogins.PasswordHash AS PrimaryPasswordHash, 
		SecondaryLogins.PasswordHash AS SecondaryPasswordHash, 
		'DROP LOGIN ' + QUOTENAME(SecondaryLogins.LoginName) +'; CREATE LOGIN ' + QUOTENAME(SecondaryLogins.LoginName) + ' WITH PASSWORD = 0x' + CONVERT(VARCHAR(MAX), PrimaryLogins.PasswordHash, 2) + ' HASHED, SID = 0x' + CONVERT(VARCHAR(MAX), PrimaryLogins.sid, 2) + ';' AS CreateCMD
FROM
		(SELECT AGs.AGName, AGs.ServerName, Logins.LoginName,Logins.sid, Logins.PasswordHash
		FROM #AGs AGs
		JOIN Catalogue.Logins Logins ON AGs.ServerName = Logins.ServerName
		WHERE AGs.AGRole = 'PRIMARY') PrimaryLogins
JOIN
		(SELECT AGs.AGName, AGs.ServerName, Logins.LoginName,Logins.sid, Logins.PasswordHash
		FROM #AGs AGs
		JOIN Catalogue.Logins Logins ON AGs.ServerName = Logins.ServerName
		WHERE AGs.AGRole = 'SECONDARY') SecondaryLogins ON PrimaryLogins.AGName = SecondaryLogins.AGName AND PrimaryLogins.LoginName = SecondaryLogins.LoginName
WHERE PrimaryLogins.PasswordHash != SecondaryLogins.PasswordHash

