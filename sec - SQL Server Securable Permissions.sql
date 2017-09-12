SELECT Us.name AS username, Obj.name AS object, dp.permission_name AS permission, dp.state_desc
FROM sys.database_permissions dp 
JOIN sys.sysusers Us 
ON dp.grantee_principal_id = Us.uid 
JOIN sys.sysobjects Obj 
ON dp.major_id = Obj.id
WHERE Us.name = ''
ORDER BY Us.name, Obj.name