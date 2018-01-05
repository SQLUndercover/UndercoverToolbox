
/******************************************************************

Author: David Fowler
Revision date: 01/06/2017
Version: 1

Table valued function that breaks a delimited string into a table of discrete values
URL: //sqlundercover.com/2017/06/01/undercover-toolbox-fn_splitstring-its-like-string_split-but-for-luddites-or-those-who-havent-moved-to-sql-2016-yet/

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

 
USE master
GO
 
CREATE FUNCTION fn_SplitString(@DelimitedString VARCHAR(MAX), @Delimiter CHAR(1) = ',')
RETURNS @SplitStrings TABLE (StringElement VARCHAR(255))
 
AS
 
BEGIN
 
WITH Split(XMLSplit)
AS
(SELECT CAST('<element>' + REPLACE(@DelimitedString,@Delimiter,'</element><element>') + '</element>' AS XML))
INSERT INTO @SplitStrings
SELECT p.value('.', 'VARCHAR(255)')
FROM Split
CROSS APPLY XMLSplit.nodes('/element') t(p)
 
RETURN
 
END