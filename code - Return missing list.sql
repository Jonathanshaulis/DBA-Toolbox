-- Holds list of servers I want to be alerted on, if a server was not part of a file import
DECLARE	@FactTable TABLE
	(
		HostServers VARCHAR(255)
		,AlertFlag BIT
	)
-- Holds list of files and the servers contained in them.
DECLARE	@DimTable TABLE
	(
		HostServers VARCHAR(255)
		,NameFile VARCHAR(255)
	)
-- Add all servers to be alerted or not alerted on.
INSERT	INTO @FactTable
		(HostServers , AlertFlag)
VALUES
		('ServerOne' , '1'),
		('ServerTwo' , '1'),
		('ServerThree' , '1'),
		('ServerFour' , '1')
		--,('ServerFive','1')          
-- Servers and files we are monitoring
INSERT	INTO @DimTable
		(HostServers , NameFile)
-- FileOne is missing ServerFour, ServerFive is included but we want to ignore it.      
VALUES
		('ServerOne' , 'FileOne')
		,('ServerTwo' , 'FileOne')
		,('ServerThree' , 'FileOne')
		,('ServerFive' , 'FileOne')
-- FileTwo has all servers including one we want to ignore.
		,('ServerOne' , 'FileTwo')
		,('ServerTwo' , 'FileTwo')
		,('ServerThree' , 'FileTwo')
		,('ServerFour' , 'FileTwo')
		,('ServerFive' , 'FileTwo')
-- FileThree has all four servers we want to monitor.
		,('ServerOne' , 'FileThree')
		,('ServerTwo' , 'FileThree')
		,('ServerThree' , 'FileThree')
		,('ServerFour' , 'FileThree')
-- FileFour is missing ServerThree and the server we want to ignore.
		,('ServerOne' , 'FileFour')
		,('ServerTwo' , 'FileFour')
		,('ServerFour' , 'FileFour')

-- Run these to view the data in the tables to get an idea of the data structure.
-- SELECT * FROM @DimTable 
-- SELECT * from @FactTable

SELECT 
    DISTINCT
	NameFile
	,F_one.HostServers
FROM
	@DimTable D_one
CROSS APPLY @FactTable F_one;
WITH	CTE	AS (
				SELECT
					NameFile
					,HostServers
					,COUNT(*) OVER (PARTITION BY NameFile) QtyMissingServers
				FROM
					(
						SELECT 
                        DISTINCT
							NameFile
							,F_one.HostServers
						FROM
							@DimTable D_one
						CROSS APPLY @FactTable F_one
						WHERE
							AlertFlag = 1 AND
							NOT EXISTS ( SELECT
												NameFile
												,F_two.HostServers
											FROM
												@FactTable F_two
											INNER JOIN @DimTable D_two
											ON	D_two.HostServers = F_two.HostServers
											WHERE
												F_one.HostServers = F_two.HostServers AND
												D_one.NameFile = D_two.NameFile )
					) Sub
				)
	SELECT
		*
	FROM
		CTE