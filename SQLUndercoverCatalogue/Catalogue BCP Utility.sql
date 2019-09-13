/******************************************************************

Author: David Fowler
Revision date: 12 September 2019
Version: 1

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


USE SQLUndercover
GO


CREATE PROC Catalogue.BCPCopy
@ExportFileLocation VARCHAR(MAX),  --BCP file location
@Direction VARCHAR(3) = 'out',	--out = export, in = import
@TruncateDestination BIT = 0, --truncate tables at destination, ignored if exporting
@ImportConfig BIT = 1, --import config tables, ignored if importing
@IncludeExecutionLog BIT = 1 --exclude the execution log table from the import\export

AS

BEGIN

DECLARE @Module VARCHAR(50)
DECLARE @BCP VARCHAR(4000)

IF @ImportConfig = 1
BEGIN
	--truncate config tables if import
	IF @Direction = 'IN' AND @TruncateDestination = 1 
	BEGIN
		TRUNCATE TABLE Catalogue.ConfigInstances
		TRUNCATE TABLE Catalogue.ConfigModules
		TRUNCATE TABLE Catalogue.ConfigPoSH
	END

	--import\export config tables
	SET @BCP = 'bcp Minion.Catalogue.ConfigInstances ' + @Direction + ' ' + @ExportFileLocation + 'ConfigInstances.bcp -c -T'
	EXEC xp_cmdshell @BCP

	SET @BCP = 'bcp Minion.Catalogue.ConfigModules ' + @Direction + ' ' + @ExportFileLocation + 'ConfigModules.bcp -c -T'
	EXEC xp_cmdshell @BCP

	SET @BCP = 'bcp Minion.Catalogue.ConfigPoSH ' + @Direction + ' ' + @ExportFileLocation + 'ConfigPoSH.bcp -c -T'
	EXEC xp_cmdshell @BCP
END

IF @IncludeExecutionLog = 1
BEGIN
		IF @Direction = 'IN' AND @TruncateDestination = 1 
	BEGIN
		TRUNCATE TABLE Catalogue.ExecutionLog
	END

	SET @BCP = 'bcp Minion.Catalogue.ExecutionLog ' + @Direction + ' ' + @ExportFileLocation + 'ExecutionLog.bcp -c -T'
	EXEC xp_cmdshell @BCP
END

--carry out import\export
DECLARE ModulesCur CURSOR STATIC FORWARD_ONLY
FOR
SELECT MainTableName 
FROM Catalogue.ConfigModules
WHERE ModuleName != 'LinkedServers'

OPEN ModulesCur

FETCH NEXT FROM ModulesCur INTO @Module

WHILE @@FETCH_STATUS = 0
BEGIN
	
	IF @Direction = 'IN' AND @TruncateDestination = 1
	BEGIN
		SET @BCP = 'TRUNCATE TABLE Catalogue.' + @Module
		EXEC (@BCP)
	END

	SET @BCP = 'bcp "Minion.Catalogue.' + @Module + '" ' + @Direction + ' "' + @ExportFileLocation + @Module + '.bcp" -c -T'
	EXEC xp_cmdshell @BCP

	SET @BCP = 'bcp "Minion.Catalogue.' + @Module + '_Audit" ' + @Direction + ' "' + @ExportFileLocation + @Module + '_Audit.bcp" -c -T'
	EXEC xp_cmdshell @BCP

	FETCH NEXT FROM ModulesCur INTO @Module

END

CLOSE ModulesCur
DEALLOCATE ModulesCur



END