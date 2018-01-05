/******************************************************************

Author: David Fowler
Revision date: 26/10/2017
Version: 1

--Description: Copy logins from source server that don't exist on destination server
@RecreateSIDOnMismatch = 1, Users with a mismatching SID are dropped and recreated with the same SID as on the source server

© www.sqlundercover.com 


This script is for personal, educational, and internal 
corporate purposes, provided that this header is preserved. Redistribution or sale 
of this script,in whole or in part, is prohibited without the author's express 
written consent. 

The software is provided "as is", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. in no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in the
software.

******************************************************************/

 
EXEC sp_execute_external_script
@language = N'python',
@script =
N'import pyodbc
import pandas as pa
 
#build where clause
if includes != "%":
    WhereClause = " AND name IN (''" + includes.replace(",","'',''") + "'')"
elif excludes != "%":
    WhereClause = " AND name NOT IN (''" + excludes.replace(",","'',''") + "'')"
else:
    WhereClause = ""
 
#add WhereClause to the query
query = query + WhereClause
 
#get source connection
SourceConnection = pyodbc.connect(sourceConnectionString)
SourceLogins = pa.read_sql(query,SourceConnection)
 
#get destination connection
DestinationConnection = pyodbc.connect(destinationConnectionString)
DestinationLogins = pa.read_sql(query,DestinationConnection)
 
#get all logins that exist in source but not in destination, if RecreateOnSIDMismatch =1, also get logins where the SIDs are different
if RecreateOnSIDMismatch == 0:
    MissingLogins = SourceLogins[~SourceLogins[''name''].isin(DestinationLogins[''name''])].dropna()
else:
    MissingLogins = SourceLogins[~SourceLogins[''sid''].isin(DestinationLogins[''sid''])].dropna()
 
    #get accounts where SIDs differ but exist on both servers
    MismatchingLogins = DestinationLogins[DestinationLogins[''name''].isin(MissingLogins[''name''])].dropna()
 
    #drop mismatching logins
    for counter in range(len(MismatchingLogins.index)):
        Statement = "DROP LOGIN [" + MismatchingLogins.values[counter][0] + "]"
        DropLoginCursor = DestinationConnection.cursor()
        DropLoginCursor.execute(Statement)
        DropLoginCursor.commit()
 
counter = 0
 
#loop through and create logins on the destination server
for counter in range(len(MissingLogins.index)):
    if MissingLogins.values[counter][0].find("\\") >= 0:
        Statement = "CREATE LOGIN [" + MissingLogins.values[counter][0] + "] FROM WINDOWS"
    else:
        Statement = "CREATE LOGIN [" + MissingLogins.values[counter][0] + "] WITH PASSWORD = 0x" + MissingLogins.values[counter][2].hex() + '' HASHED, SID = 0x'' + MissingLogins.values[counter][1].hex()
    NewLoginCursor = DestinationConnection.cursor()
    print(Statement)
    NewLoginCursor.execute(Statement)
    NewLoginCursor.commit()
 
OutputDataSet = MissingLogins
',
@params = N'@query VARCHAR(MAX),@includes VARCHAR(4000), @excludes VARCHAR(4000), @destinationConnectionString VARCHAR(4000), @sourceConnectionString VARCHAR(4000), @RecreateOnSIDMismatch BIT',
@includes = '%',
@excludes = '%',
@destinationConnectionString = 'DRIVER={SQL Server};SERVER=laptop-fowlerd\sql2017;UID=PythonUser;PWD=P4ssw0rd',
@sourceConnectionString = 'DRIVER={SQL Server};SERVER=laptop-fowlerd\sql2016;UID=PythonUser;PWD=P4ssw0rd',
@RecreateOnSIDMismatch = 0,
@query = 'select name, CAST(sid AS VARBINARY(256)) AS sid, ISNULL(CAST(LOGINPROPERTY(name,''PasswordHash'') AS VARBINARY(256)),0x0) AS PasswordHash FROM sys.syslogins WHERE name NOT LIKE ''NT AUTHORITY%'' AND name NOT LIKE ''NT SERVICE%'' AND name NOT LIKE ''sa'' AND name NOT LIKE ''#%##'''
WITH RESULT SETS UNDEFINED