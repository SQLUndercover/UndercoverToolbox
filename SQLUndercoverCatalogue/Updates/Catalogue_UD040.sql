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
          .@@`        `@@@@                                          ? www.sqlundercover.com                                                             
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
                                                                                                                            
Sequential Upgrade - 0.4.0
David Fowler

MIT License
------------

Copyright 2019 Sql Undercover

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

*/



--setup and populate ConfigModulesDefinitions table

CREATE TABLE Catalogue.ConfigModulesDefinitions
(ModuleID INT NOT NULL PRIMARY KEY,
Online BIT NOT NULL,
GetDefinition VARCHAR(MAX),
UpdateDefinition VARCHAR(MAX),
GetURL VARCHAR(2048) NULL,
UpdateURL VARCHAR(2048) NULL)
GO

--get module proc definitions and insert them into ConfigModuleDefinitions

INSERT INTO Catalogue.ConfigModulesDefinitions
SELECT ConfigModules.ID, 
		1, 
		SUBSTRING(OBJECT_DEFINITION(GetProcs.object_id), PATINDEX('%BEGIN%', OBJECT_DEFINITION(GetProcs.object_id)), LEN(OBJECT_DEFINITION(GetProcs.object_id))),
		SUBSTRING(OBJECT_DEFINITION(UpdateProcs.object_id), PATINDEX('%BEGIN%', OBJECT_DEFINITION(UpdateProcs.object_id)), LEN(OBJECT_DEFINITION(UpdateProcs.object_id)))
FROM Catalogue.ConfigModules
JOIN sys.procedures GetProcs ON GetProcs.name = ConfigModules.GetProcName
JOIN sys.procedures UpdateProcs ON UpdateProcs.name = ConfigModules.UpdateProcName
GO


--drop redundant module procs

DECLARE @DropGetProc NVARCHAR(1000)
DECLARE @DropUpdateProc NVARCHAR(1000)

DECLARE DropCur CURSOR LOCAL FAST_FORWARD
FOR
SELECT	N'DROP PROC ' + QUOTENAME(SCHEMA_NAME(GetProcs.schema_id)) + N'.' + QUOTENAME(GetProcs.name),
		N'DROP PROC ' + QUOTENAME(SCHEMA_NAME(UpdateProcs.schema_id)) + N'.' + QUOTENAME(UpdateProcs.name)
FROM Catalogue.ConfigModules
JOIN sys.procedures GetProcs ON GetProcs.name = ConfigModules.GetProcName
JOIN sys.procedures UpdateProcs ON UpdateProcs.name = ConfigModules.UpdateProcName

OPEN DropCur

FETCH NEXT FROM DropCur INTO @DropGetProc, @DropUpdateProc

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sp_executesql @DropGetProc
	EXEC sp_executesql @DropUpdateProc

	FETCH NEXT FROM DropCur INTO @DropGetProc, @DropUpdateProc
END

CLOSE DropCur
DEALLOCATE DropCur