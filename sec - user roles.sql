;
WITH    ServerPermsAndRoles
          AS ( SELECT   spr.name AS login_name ,
                        spr.type_desc AS login_type ,
                        spm.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS AS permission_name ,
                        CONVERT(NVARCHAR(1), spr.is_disabled) AS is_disabled ,
                        'permission' AS permission_type ,
                        spr.create_date AS create_date ,
                        spr.modify_date AS modify_date
               FROM     sys.server_principals spr
                        INNER JOIN sys.server_permissions spm ON spr.principal_id = spm.grantee_principal_id
               WHERE    spr.type IN ( 's', 'u' )
               UNION ALL
               SELECT   sp.name AS login_name ,
                        sp.type_desc AS login_type ,
                        spr.name AS permission_name ,
                        CONVERT(NVARCHAR(1), spr.is_disabled) AS is_disabled ,
                        'role membership' AS permission_type ,
                        spr.create_date AS create_date ,
                        spr.modify_date AS modify_date
               FROM     sys.server_principals sp
                        INNER JOIN sys.server_role_members srm ON sp.principal_id = srm.member_principal_id
                        INNER JOIN sys.server_principals spr ON srm.role_principal_id = spr.principal_id
               WHERE    sp.type IN ( 's', 'u' )
             )
    SELECT  *
    FROM    ServerPermsAndRoles
    ORDER BY login_name