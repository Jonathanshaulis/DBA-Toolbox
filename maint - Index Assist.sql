-- Possible bad Indexes (writes > reads)
    DECLARE @dbid int
    SELECT @dbid = db_id()

    SELECT 'Table Name' = object_name(s.object_id), 'Index Name' =i.name, i.index_id,
           'Total Writes' =  user_updates, 'Total Reads' = user_seeks + user_scans + user_lookups,
            'Difference' = user_updates - (user_seeks + user_scans + user_lookups)
    FROM sys.dm_db_index_usage_stats AS s 
    INNER JOIN sys.indexes AS i
    ON s.object_id = i.object_id
    AND i.index_id = s.index_id
    WHERE objectproperty(s.object_id,'IsUserTable') = 1
    AND s.database_id = @dbid
    AND user_updates > (user_seeks + user_scans + user_lookups)
    ORDER BY 'Difference' DESC, 'Total Writes' DESC, 'Total Reads' ASC;

 
--- Index Read/Write stats for a single table
    DECLARE @dbid int
    SELECT @dbid = db_id()

    SELECT objectname = object_name(s.object_id), indexname = i.name, i.index_id,
           reads = user_seeks + user_scans + user_lookups, writes =  user_updates
    FROM sys.dm_db_index_usage_stats AS s, sys.indexes AS i
    WHERE objectproperty(s.object_id,'IsUserTable') = 1
    AND s.object_id = i.object_id
    AND i.index_id = s.index_id
    AND s.database_id = @dbid
    AND object_name(s.object_id) IN( 'tablename')
    ORDER BY object_name(s.object_id), writes DESC, reads DESC;
    
-- Show existing indexes for this table
    EXEC sp_HelpIndex 'tablename'
    
-- Missing Indexes 
    SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS index_advantage, migs.last_user_seek, mid.statement as 'Database.Schema.Table',
    mid.equality_columns, mid.inequality_columns, mid.included_columns,
    migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
    FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
    INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
    ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
    ON mig.index_handle = mid.index_handle
    ORDER BY index_advantage DESC;

-- Missing indexes for a single table
    SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS index_advantage, migs.last_user_seek, mid.statement as 'Database.Schema.Table',
    mid.equality_columns, mid.inequality_columns, mid.included_columns,
    migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
    FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
    INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
    ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
    ON mig.index_handle = mid.index_handle
    WHERE statement = '[databasename].[dbo].[tablename]' -- Specify one table
    ORDER BY index_advantage DESC;

-- Examine current indexes
    EXEC sp_HelpIndex 'dbo.tablename'