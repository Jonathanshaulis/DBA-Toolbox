SELECT  req.session_id
       ,sqltext.text
       ,blocking_session_id
       ,ses.host_name
       ,DB_NAME(req.database_id) AS DB_NAME
       ,ses.login_name
       ,req.status
       ,req.command
       ,req.start_time
       ,req.cpu_time
       ,req.total_elapsed_time / 1000.0 AS total_elapsed_time
       ,req.command
       ,req.wait_type

FROM    sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
JOIN    sys.dm_exec_sessions ses
        ON ses.session_id = req.session_id
WHERE req.wait_type IS NOT NULL
--WHERE req.wait_type = '?'

go

sp_who2

select session_id,
	status,
	command,
	blocking_session_id,
	wait_type,
	wait_time,
	last_wait_type,
	wait_resource
from sys.dm_exec_requests
where session_id >= 50
and session_id <> @@spid;

select r.session_id,
	status,
	command,
	r.blocking_session_id,
	r.wait_type as [request_wait_type],
	r.wait_time as [request_wait_time],
	t.wait_type as [task_wait_type],
	t.wait_duration_ms as [task_wait_time],
	t.blocking_session_id,
	t.resource_description
from sys.dm_exec_requests r
left join sys.dm_os_waiting_tasks t
	on r.session_id = t.session_id
where r.session_id >= 50
and r.session_id <> @@spid;



SELECT sqltext.TEXT,
req.session_id,
req.status,
req.command,
req.cpu_time,
req.total_elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
