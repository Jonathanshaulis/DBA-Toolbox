SQL Server Quick Pull 2005 and below

SELECT  s.loginame, db_name(s.dbid) name, s.hostname,  
         s.program_name,  
         s.sql_handle, s.stmt_start, s.stmt_end,  
         s.spid, CONVERT(smallint, s.waittype) waittype,  
         s.lastwaittype, s.ecid, s.waittime , s.blocked,  
         r.plan_handle,  r.statement_start_offset, r.statement_end_offset, r.query_plan_hash, r.start_time, 
         q.plan_generation_num 
FROM master..sysprocesses AS s WITH(NOLOCK)  
LEFT OUTER JOIN sys.dm_exec_requests AS r WITH(NOLOCK)  
   ON (s.spid = r.session_id) 
LEFT OUTER JOIN sys.dm_exec_query_stats q  
  ON q.plan_handle = r.plan_handle  
  AND q.statement_start_offset = r.statement_start_offset  
  AND q.statement_end_offset = r.statement_end_offset 
WHERE (s.cmd<>'AWAITING COMMAND'  
                AND s.cmd NOT LIKE '%BACKUP%'  
                AND s.cmd NOT LIKE '%RESTORE%'  
                AND s.cmd NOT LIKE 'FG MONITOR%' 
                AND s.hostprocess > '' 
                AND s.spid>50  
                AND s.spid<>@@SPID)   
AND lastwaittype NOT IN ('WAITFOR', 'SLEEP_TASK')  
ORDER BY s.spid, s.ecid ASC 

SQL Server Quick Pull 2008 and up
 
SELECT  s.loginame, db_name(s.dbid) name, s.hostname,  
	 s.program_name,  
	 s.sql_handle, s.stmt_start, s.stmt_end,  
	 s.spid, CONVERT(smallint, s.waittype) waittype,  
	 s.lastwaittype, s.ecid, s.waittime , s.blocked,  
	 r.plan_handle,  r.statement_start_offset, r.statement_end_offset, r.query_plan_hash, r.start_time, 
	 q.plan_generation_num 
FROM master..sysprocesses AS s WITH(NOLOCK)  
LEFT OUTER JOIN sys.dm_exec_requests AS r WITH(NOLOCK)  
   ON (s.spid = r.session_id) 
LEFT OUTER JOIN sys.dm_exec_query_stats q  
  ON q.plan_handle = r.plan_handle  
  AND q.statement_start_offset = r.statement_start_offset  
  AND q.statement_end_offset = r.statement_end_offset 
WHERE (s.cmd<>'AWAITING COMMAND'  
                AND s.cmd NOT LIKE '%BACKUP%'  
                AND s.cmd NOT LIKE '%RESTORE%'  
                AND s.cmd NOT LIKE 'FG MONITOR%' 
                AND s.hostprocess > '' 
                AND s.spid>50  
                AND s.spid<>@@SPID)   
AND lastwaittype NOT IN ('WAITFOR', 'SLEEP_TASK')  
ORDER BY s.spid, s.ecid ASC 

SQL Server Plan Poll

SELECT 2528307371 as plan_hash, query_plan  
FROM sys.dm_exec_text_query_plan (?, ?, ?) 
where query_plan is not null 

SQL Server Text Poll

SELECT o.name pn, u.name sn 
FROM [DATABASE_NAME].sys.objects o, [DATABASE_NAME].sys.schemas u 
WHERE o.schema_id = u.schema_id 
AND o.object_id = 


SQL Server Stats Poll

SELECT sql_handle, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, 
       Sum(execution_count) sum_execution_count, Sum(total_logical_writes) sum_total_logical_writes, 
       Sum(total_physical_reads) sum_total_physical_reads, Sum(total_logical_reads) sum_total_logical_reads 
FROM master.sys.dm_exec_query_stats WITH (nolock) 
GROUP BY sql_handle, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle 



SELECT sql_handle, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, 
       Sum(execution_count) sum_execution_count, Sum(total_logical_writes) sum_total_logical_writes, 
       Sum(total_physical_reads) sum_total_physical_reads, Sum(total_logical_reads) sum_total_logical_reads,
       SUM(total_rows) sum_total_rows
FROM master.sys.dm_exec_query_stats WITH (nolock) 
GROUP BY sql_handle, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle 

Limited Stats:  

SELECT sql_handle, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, 
       Sum(execution_count) sum_execution_count, Sum(total_logical_writes) sum_total_logical_writes, 
       Sum(total_physical_reads) sum_total_physical_reads, Sum(total_logical_reads) sum_total_logical_reads 
FROM (SELECT s1.sql_handle, s1.statement_start_offset, s1.statement_end_offset, 
             s1.plan_generation_num, s1.plan_handle, s1.execution_count, 
             s1.total_logical_writes, s1.total_physical_reads, s1.total_logical_reads 
      FROM  master.sys.dm_exec_query_stats s1 WITH (nolock) 
      WHERE CONVERT(VARCHAR(64), s1.sql_handle) + '+' +  
            CONVERT(VARCHAR(32), s1.statement_start_offset) + '+' +  
            CONVERT(VARCHAR(32), s1.statement_end_offset) IN (SELECT k  
                                                              FROM (SELECT TOP 10000 (CONVERT(VARCHAR(64), s2.sql_handle) + '+' +  
                                                                                      CONVERT(VARCHAR(32), s2.statement_start_offset) + '+' +  
                                                                                      CONVERT(VARCHAR(32), s2.statement_end_offset)  
                                                                                      ) k, 
                                                                    Sum(s2.total_elapsed_time) e 
                                                                    FROM master.sys.dm_exec_query_stats s2 WITH (nolock) 
                                                                    GROUP BY (CONVERT(VARCHAR(64), s2.sql_handle) + '+' +  
                                                                              CONVERT(VARCHAR(32), s2.statement_start_offset) + '+' +  
                                                                              CONVERT(VARCHAR(32), s2.statement_end_offset) 
                                                                             ) 
                                                                    ORDER BY Sum(s2.total_elapsed_time) DESC 
                                                                   ) AS t1 
                                                             ) 
     ) AS t2 
GROUP  BY sql_handle, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle   

IO Metric SQL:

SELECT a.database_id, 
        a.file_id, 
        b.name as fname,  
        db_name(a.database_id) AS dbname, 
        a.num_of_reads, 
        a.num_of_writes,  
        a.io_stall_read_ms as read_latency, 
        a.io_stall_write_ms as write_latency, 
        a.num_of_bytes_read, 
        a.num_of_bytes_written, 
        UPPER(SUBSTRING(b.physical_name, 1, 2)) AS disk_location 
FROM sys.dm_io_virtual_file_stats (NULL, NULL) a 
JOIN sys.master_files b ON a.file_id = b.file_id AND a.database_id = b.database_id 
ORDER BY a.database_i
