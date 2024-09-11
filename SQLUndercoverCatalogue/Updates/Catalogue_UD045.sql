/*                                                                                                                      
                                                                                                                                                                                                                                             
              @     ,@                                                                                                  
             #@@   @@@                                                                                                  
             @@@@@@@@@;                                                                                                 
             @@@@@@@@@@                                                                                                 
            :@@@@@@@@@@                                                                                                 
            @@@@@@@@@@@                                                                                                 
            @@@@@@@@@@@;                                                                                                
            @@@@@@@@@@@@                                                                                                
            @@@@@@@@@@@@                                                                                                
           `+@@@@@@@@@@+                                                                                                
                                                                                                                        
                                                                                                                        
         .@@`           #@,                                                                                             
     .@@@@@@@@@@@@@@@@@@@@@@@@:                                                                                         
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@     @@   @@      #@   @           @                                         
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@   @@@@  @#      #@   @           @                                         
    ;@@@@@@@@@@@@@@@@@@@@@@@@@@'        @     @   @# @#      #@   @ #@@@   @@@@  @@@  @@@@@  @@@   @@  @   @  @@   @ @@     
        .+@@@@@@@@@@@@@@@@+.            @@@@  @   @@ @#      #@   @ #@  @ @@  @  @  @  @@   @  @  @ `@  @ @  @  @  @@    
       '`                  `,#           @@@@ @   @@ @#      #@   @ #@  @ @#  @ @@@@@  @    @     @  @  @ @  @@@@  @`     
     ,@@@@ '@@@@@@@@@@@@@ .@@@@;           @  @   @@ @#      #@   @ #@  @ @@  @ @@     @ `  @     @  @  @@@  @     @      
    #@@@@@@ @@@@@  +@@@@  +@@@@@@       @@@@   @@@@  @@@@@   `@@@@@ #@  @ #@ @@  @  @  @    @@ @  @  @   @   @  @  @      
   @@@@@@@@  ,#.    `#;   @@@@@@@@'      @@     @@   @@@@@     @@,  #@  @  @@ @   @@  @@     #@    @@    @    @@   @      
  ;#@@@@@@@@             @@@@@@@@@#,              @                                                                     
       ,@@@@+           @@@@@+`                                                                                         
          .@@`        `@@@@                                          www.sqlundercover.com                                                             
         +@@@@        @@@@@+                                                                                            
        @@@@@@@      @@@@@@@@#                                                                                          
         @@@@@@@    @@@@@@,                                                                                             
         @@@@@@@    @@@@@@,                                                                                             
           :@@@@@' ;@@@@`                                                                                               
             `@@@@ @@@+                                                                                                 
                @#:@@                                                                                                   
                  @@                                                                                                    
                  @`                                                                                                    
                  #                                                                                                     
                                                                                                                            
Sequential Upgrade - 0.4.5
David Fowler
15/04/2024

MIT License
------------

Copyright 2024 Sql Undercover

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

Change Log
----------

BUG FIX: Bug causing problems representing file path in Databases moule

*/


----------------------------------------------------
--Module Definition Changes
----------------------------------------------------

DECLARE @ModuleID INT

SELECT @ModuleID = ID 
FROM Catalogue.ConfigModules
WHERE ModuleName = 'Databases'

UPDATE Catalogue.ConfigModulesDefinitions
SET GetDefinition = '--Undercover Catalogue
--David Fowler
--Version 0.4.5 - 10 September 2024
--Module: Databases
--Script: Get
BEGIN
	--get all databases on server
	SELECT @@SERVERNAME AS ServerName
		,databases.name AS DBName
		,databases.database_id AS DatabaseID
		,server_principals.name AS OwnerName
		,databases.compatibility_level AS CompatibilityLevel
		,databases.collation_name AS CollationName
		,databases.recovery_model_desc AS RecoveryModelDesc
		,availability_groups.name AS AGName
		,files.FilePaths
		,files.DatabaseSizeMB
		,databases.state_desc AS StateDesc
		,lastaccess.last_user_access
	FROM sys.databases
	LEFT OUTER JOIN sys.server_principals ON server_principals.sid = databases.owner_sid
	LEFT OUTER JOIN sys.availability_replicas ON availability_replicas.replica_id = databases.replica_id
	LEFT OUTER JOIN sys.availability_groups ON availability_groups.group_id = availability_replicas.group_id
	JOIN (
		SELECT database_id
			,(SUM(CAST(size AS BIGINT)) * 8) / 1024 AS DatabaseSizeMB
			,STUFF((
					SELECT '' ,'' + files2.physical_name
					FROM sys.master_files files2
					WHERE files2.database_id = files1.database_id
					FOR XML PATH('''')
					), 1, 2, '''') AS FilePaths
		FROM sys.master_files files1
		GROUP BY database_id
		) files ON files.database_id = databases.database_id
	JOIN (
		SELECT db_name(databases.database_id) AS DBName
			,(
				SELECT MAX(last_user_access)
				FROM (
					VALUES (MAX(last_user_seek))
						,(MAX(last_user_scan))
						,(MAX(last_user_lookup))
					) AS value(last_user_access)
				) AS last_user_access
		FROM sys.dm_db_index_usage_stats indexstats
		RIGHT OUTER JOIN sys.databases databases ON indexstats.database_id = databases.database_id
		GROUP BY databases.database_id
		) AS lastaccess ON databases.name = lastaccess.DBName
	WHERE databases.source_database_id IS NULL
END'
WHERE ModuleID = @ModuleID



--update versions tables

UPDATE Catalogue.ConfigPoSH
SET ParameterValue = '0.4.5'
WHERE ParameterName = 'CatalogueVersion'

--update history

INSERT INTO Catalogue.UpgradeHistory (UpgradeVersion, UpgradeDate)
VALUES ('0.4.5', GETDATE())