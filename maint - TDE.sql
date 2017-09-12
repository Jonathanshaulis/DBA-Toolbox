
-- Create database master key
USE [master]

CREATE MASTER KEY 
ENCRYPTION BY PASSWORD = '';
GO
-- 


-- Create certificate
USE [master]

CREATE CERTIFICATE TDECert 
WITH SUBJECT = 'TDE Certificate'
GO
--
--Check the certificate
SELECT name, pvt_key_encryption_type_desc 
FROM sys.certificates
WHERE name = 'TDECert'
GO
--Don't forget to backup the certificate and keep it in secure place
BACKUP CERTIFICATE TDECert
--TO FILE='\\l-supremo\DbBakupVol1\Zephyr\Certificates\TDECert.certbak'
TO FILE='C:\temp\TDECert.certbak'
WITH PRIVATE KEY (
--FILE='\\l-supremo\DbBakupVol1\Zephyr\Certificates\TDECert.pkbak',
FILE='C:\temp\TDECert.pkbak',
ENCRYPTION BY PASSWORD='')
GO
