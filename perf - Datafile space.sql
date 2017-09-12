SELECT DISTINCT dovs.logical_volume_name AS LogicalName,
dovs.volume_mount_point AS Drive
	,CONVERT(INT , dovs.available_bytes / 1048576.0) AS DiskFreeSpaceInMB
	,CONVERT(INT , dovs.total_bytes / 1048576.0) AS DiskTotalSpaceInMB
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
ORDER BY LogicalName ASC
GO

SELECT [SQLServerName]=@@ServerName, [Database Name] = DB_NAME(mf.database_id),
       [Type] = CASE WHEN Type_Desc = 'ROWS' THEN 'Data File(s)'
                     WHEN Type_Desc = 'LOG'  THEN 'Log File(s)'
                     WHEN Type_Desc  IS NULL THEN 'Total(MB)' 
                     ELSE Type_Desc END, ISNULL(dovs.volume_mount_point,'') AS Drive,
       [Size in MB] = CAST( ((SUM(CAST(Size AS BIGINT) )* 8) / 1024.0) AS DECIMAL(18,2) )
FROM   sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
GROUP BY      GROUPING SETS
              (
                     (DB_NAME(mf.database_id), Type_Desc),
                     (DB_NAME(mf.database_id),(dovs.volume_mount_point))
              )
ORDER BY     (dovs.volume_mount_point), DB_NAME(mf.database_id), Type_Desc DESC
GO 

SELECT
	[SQLServerName] = @@ServerName
	,DB_NAME(mf.database_id) AS database_name
	,dovs.volume_mount_point AS Drive
	,CONVERT(INT , dovs.available_bytes / 1048576.0) AS DiskFreeSpaceInMB
	,CONVERT(INT , dovs.total_bytes / 1048576.0) AS DiskTotalSpaceInMB
	,name AS logical_file_name
        --, mf.database_id
        --, mf.[file_id]
	,[Type] = CASE	WHEN Type_Desc = 'ROWS' THEN 'Data File(s)'
					WHEN Type_Desc = 'LOG' THEN 'Log File(s)'
					WHEN Type_Desc IS NULL THEN 'Total(MB)'
					ELSE Type_Desc
				END 
   -- , data_space_id
	,physical_name
	,(SIZE * 8 / 1024) AS size_mb
	/*,CASE max_size
		WHEN -1 THEN 'unlimited'
		ELSE CAST((CAST (max_size AS BIGINT)) * 8 / 1024 AS VARCHAR(10))
		END AS max_size_mb*/
	/*,CASE is_percent_growth
		WHEN 1 THEN CAST(growth AS VARCHAR(3)) + ' %'
		WHEN 0 THEN CAST(growth * 8 / 1024 AS VARCHAR(10)) + ' mb'
		END AS growth_increment */
    --, is_percent_growth,
FROM
	sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id , mf.FILE_ID) dovs
ORDER BY
	DB_NAME(mf.database_id)
	,dovs.volume_mount_point 
	,type_desc 
	
	
	