------------------------------------------------------------------
---------------- What server is my instance running on?  ---------
------------------------------------------------------------------
-- where am i? 
SELECT SERVERPROPERTY ('ComputerNamePhysicalNetBIOS') AS ComputerBIOS; -- Node where this instance is running
Go
SELECT @@Servername
Go
--