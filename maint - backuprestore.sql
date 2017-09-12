
USE Master; 
GO  
SET NOCOUNT ON 

-- 1 - Variable declaration 
DECLARE @dbName sysname 
DECLARE @backupPath NVARCHAR(500) 
DECLARE @cmd NVARCHAR(500) 
DECLARE @fileList TABLE (backupFile NVARCHAR(255)) 
DECLARE @lastFullBackup NVARCHAR(500) 
DECLARE @lastDiffBackup NVARCHAR(500) 
DECLARE @backupFile NVARCHAR(500) 
DECLARE @servername sysname

SELECT @servername = (@@SERVERNAME + '_')

-- 2 - Initialize variables 
SET @dbName = 'Database' 
SET @backupPath = 'C:\Backups\' 

-- 3 - get list of files 
SET @cmd = 'DIR /b "' + @backupPath + '"'

INSERT INTO @fileList(backupFile) 
EXEC master.sys.xp_cmdshell @cmd 

-- 4 - Find latest full backup 
SELECT @lastFullBackup = MAX(backupFile)  
FROM @fileList  
WHERE backupFile LIKE '%.BAK'  
   AND backupFile LIKE @servername + @dbName + '%'

SET @cmd = 'RESTORE DATABASE [' + @dbName + '] FROM DISK = '''  
       + @backupPath + @lastFullBackup + ''' WITH NORECOVERY, REPLACE' 
PRINT @cmd 

-- 4 - Find latest diff backup 
SELECT @lastDiffBackup = MAX(backupFile)  
FROM @fileList  
WHERE backupFile LIKE '%.DIF'  
   AND backupFile LIKE +@servername + @dbName + '%' 
   AND backupFile > @lastFullBackup 

-- check to make sure there is a diff backup 
IF @lastDiffBackup IS NOT NULL 
BEGIN 
   SET @cmd = 'RESTORE DATABASE [' + @dbName + '] FROM DISK = '''  
       + @backupPath + @lastDiffBackup + ''' WITH NORECOVERY' 
   PRINT @cmd 
   SET @lastFullBackup = @lastDiffBackup 
END 

-- 5 - check for log backups 
DECLARE backupFiles CURSOR FOR  
   SELECT backupFile  
   FROM @fileList 
   WHERE backupFile LIKE '%.TRN'  
   AND backupFile LIKE @servername + @dbName + '%' 
   AND backupFile > @lastFullBackup 

OPEN backupFiles  

-- Loop through all the files for the database  
FETCH NEXT FROM backupFiles INTO @backupFile  

WHILE @@FETCH_STATUS = 0  
BEGIN  
   SET @cmd = 'RESTORE LOG [' + @dbName + '] FROM DISK = '''  
       + @backupPath + @backupFile + ''' WITH NORECOVERY' 
   PRINT @cmd 
   FETCH NEXT FROM backupFiles INTO @backupFile  
END 

CLOSE backupFiles  
DEALLOCATE backupFiles  

-- 6 - put database in a useable state 
SET @cmd = 'RESTORE DATABASE [' + @dbName + '] WITH RECOVERY' 
PRINT @cmd 



------- Not working


-- 1 - Variable declaration 
DECLARE @dbName sysname 
DECLARE @backupPath1 NVARCHAR(500) 
DECLARE @backupPath2 NVARCHAR(500)
DECLARE @backupPath3 NVARCHAR(500)
DECLARE @cmd NVARCHAR(500) 
DECLARE @fileList TABLE (backupFile NVARCHAR(255)) 
DECLARE @lastFullBackup NVARCHAR(500) 
DECLARE @lastDiffBackup NVARCHAR(500) 
DECLARE @backupFile NVARCHAR(500) 
DECLARE @servername sysname

SELECT @servername = (@@SERVERNAME + '_')

-- 2 - Initialize variables 
SET @dbName = 'DirectoryDumps' 
SET @backupPath1 = 'C:\Backups\FULL\' 
SET @backupPath2 = 'C:\Backups\DIFF\' 
SET @backupPath3 = 'C:\Backups\LOG\' 

-- 3 - get list of files 
SET @cmd = 'DIR /b "' + @backupPath1 + '"'

INSERT INTO @fileList(backupFile) 
EXEC master.sys.xp_cmdshell @cmd 

SET @cmd = 'DIR /b "' + @backupPath2 + '"'

INSERT INTO @fileList(backupFile) 
EXEC master.sys.xp_cmdshell @cmd 

SET @cmd = 'DIR /b "' + @backupPath3 + '"'

-- 4 - Find latest full backup 
SELECT @lastFullBackup = MAX(backupFile)  
FROM @fileList  
WHERE backupFile LIKE '%.BAK'  
   AND backupFile LIKE @servername + @dbName + '%'

SET @cmd = 'RESTORE DATABASE [' + @dbName + '] FROM DISK = '''  
       + @backupPath1 + @lastFullBackup + ''' WITH NORECOVERY, REPLACE' 
PRINT @cmd 


-- 4 - Find latest diff backup 
SELECT @lastDiffBackup = MAX(backupFile)  
FROM @fileList  
WHERE backupFile LIKE '%.DIF'  
   AND backupFile LIKE +@servername + @dbName + '%' 
   AND backupFile > @lastFullBackup 

-- check to make sure there is a diff backup 
IF @lastDiffBackup IS NOT NULL 
BEGIN 
   SET @cmd = 'RESTORE DATABASE [' + @dbName + '] FROM DISK = '''  
       + @backupPath2 + @lastDiffBackup + ''' WITH NORECOVERY' 
   PRINT @cmd 
   SET @lastFullBackup = @lastDiffBackup 
END 


-- 5 - check for log backups 
DECLARE backupFiles CURSOR FOR  
   SELECT backupFile  
   FROM @fileList 
   WHERE backupFile LIKE '%.TRN'  
   AND backupFile LIKE @servername + @dbName + '%' 
   AND backupFile > @lastFullBackup 

OPEN backupFiles  

-- Loop through all the files for the database  
FETCH NEXT FROM backupFiles INTO @backupFile  

WHILE @@FETCH_STATUS = 0  
BEGIN  
   SET @cmd = 'RESTORE LOG [' + @dbName + '] FROM DISK = '''  
       + @backupPath3 + @backupFile + ''' WITH NORECOVERY' 
   PRINT @cmd 
   FETCH NEXT FROM backupFiles INTO @backupFile  
END 

CLOSE backupFiles  
DEALLOCATE backupFiles  

-- 6 - put database in a useable state 
SET @cmd = 'RESTORE DATABASE [' + @dbName + '] WITH RECOVERY' 
PRINT @cmd 


 
