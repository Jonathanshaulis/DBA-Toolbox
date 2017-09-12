/*

-- Kill connections to allow DB to be rolled back, replace the DBName
USE master;
GO
ALTER DATABASE dbname SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- Back up the DB to the specified location, replace the dbname and location
Backup database dbname 
to disk='Drive:\folder\nameofbackup.bak'

-- Verify backup, replace the dbname and location
RESTORE VERIFYONLY FROM DISK = 'Drive:\folder\nameofbackup.bak'

-- Normal backup restore, replace dbname and backupfile location
RESTORE database dbname  FROM DISK = 'Drive:\folder\nameofbackup.bak'

-- Grab file names so you can replace them when you restore a DB by changing the name
RESTORE FILELISTONLY FROM DISK='Drive:\folder\nameofbackup.bak'

-- Restore a DB and rename it, use last above script to find the file names indicated here
RESTORE DATABASE dbnameyouwant FROM DISK='Drive:\folder\nameofbackup.bak'
WITH 
   MOVE 'Originalmdfname' TO 'Drive:\folder\dbnameyouwant.mdf',
   MOVE 'originalldfnamelog' TO 'Drive:\folder\dbnameyouwant.ldf'
