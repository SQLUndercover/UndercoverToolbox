/******************************************************************
Author: David Fowler
Revision date: 07/03/2018
Version: 1
Description: Return the name of the AG that a specified database belongs to

© www.sqlundercover.com 

MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
******************************************************************/

USE [master]
GO

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_WhatsMyAG')
DROP PROC [sp_WhatsmyAG]
GO


CREATE PROCEDURE [dbo].[sp_WhatsmyAG]
(
@DBname NVARCHAR(128) = NULL
)
AS
BEGIN
SELECT cluster.database_name,ag.name AS AGname
FROM master.sys.availability_groups ag 
INNER JOIN sys.availability_databases_cluster cluster ON ag.group_id = cluster.group_id
WHERE cluster.database_name = ISNULL(@DBname, db_name())
END


GO
