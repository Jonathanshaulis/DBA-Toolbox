SELECT * FROM 
(
SELECT DB_NAME(p.dbid) AS DBName ,
OBJECT_NAME(p.objectid, p.dbid) AS OBJECT_NAME ,
cp.usecounts ,
p.query_plan ,
q.text ,
p.dbid ,
p.objectid ,
p.number ,
p.encrypted ,
cp.plan_handle
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) p
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS q
WHERE cp.cacheobjtype = 'Compiled Plan'
)a WHERE text LIKE '%SNIPPET OF SQL GOES HERE THAT IS PART OF THE QUERY YOU WANT TO FIND%'
ORDER BY dbid, objectID
