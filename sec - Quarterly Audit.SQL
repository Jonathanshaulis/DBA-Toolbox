/*
This is the quartely audit SQL report. It is adjusted to run against all production instances against all databases and users that are SQL or User accounts. 
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
SQL_Login_Properties

Checks all SQL Logins for login property information. Checks and returns policy information on SQL Accounts as sys accounts can have information stored at the AD level, this is information available to the SQL Accounts at the SQL Server level.
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Returns instance name and server name as well as SQL Server Version.
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @@SERVERNAME AS 'SQL Server Name and Instance'
SELECT @@VERSION AS 'SQL Server Version'


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  name ,
        Is_Policy_Checked ,
        Is_Expiration_Checked ,
        LOGINPROPERTY(name, 'IsMustChange') AS Is_Must_Change ,
        LOGINPROPERTY(name, 'IsLocked') AS [Account Locked] ,
        LOGINPROPERTY(name, 'LockoutTime') AS LockoutTime ,
        LOGINPROPERTY(name, 'PasswordLastSetTime') AS PasswordLastSetTime ,
        LOGINPROPERTY(name, 'IsExpired') AS IsExpired ,
        LOGINPROPERTY(name, 'BadPasswordCount') AS BadPasswordCount ,
        LOGINPROPERTY(name, 'BadPasswordTime') AS BadPasswordTime ,
        LOGINPROPERTY(name, 'HistoryLength') AS HistoryLength ,
        Modify_date
FROM    sys.sql_logins 


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
System_Login_Membership_Properties

Checks all accounts and quickly lays out what membership they have at a high level overview. The next SQL will provide a more detailed list of these roles.
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  Name ,
        DenyLogin ,
        HasAccess ,
        SysAdmin ,
        SecurityAdmin ,
        ServerAdmin ,
        SetupAdmin ,
        ProcessAdmin ,
        DiskAdmin ,
        DBCreator ,
        BulkAdmin ,
        UpdateDate
FROM    syslogins
ORDER BY name


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
System_Login_Permissions_and_Roles

Checks all SQL and User accounts for permissions and roles. Returns a more indepth report of users than the previous report.
*/	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;WITH    ServerPermsAndRoles
          AS ( SELECT   spr.name AS login_name ,
                        spr.type_desc AS login_type ,
                        spm.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS AS permission_name ,
                      --  CONVERT(NVARCHAR(1), spr.is_disabled) AS is_disabled ,
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
                       -- CONVERT(NVARCHAR(1), spr.is_disabled) AS is_disabled ,
                        'role membership' AS permission_type ,
                        spr.create_date AS create_date ,
                        spr.modify_date AS modify_date
               FROM     sys.server_principals sp
                        INNER JOIN sys.server_role_members srm ON sp.principal_id = srm.member_principal_id
                        INNER JOIN sys.server_principals spr ON srm.role_principal_id = spr.principal_id
               WHERE    sp.type IN ( 's', 'u' )
             ),
        MapDisabled
          AS ( SELECT
          DISTINCT      SP.NAME ,
                        SP.IS_DISABLED
               FROM     SYS.server_principals SP
                        FULL JOIN sys.server_role_members RM ON SP.PRINCIPAL_ID = RM.MEMBER_PRINCIPAL_ID
               WHERE    SP.type IN ( 's', 'u' )
             )
    SELECT  ServerPermsAndRoles.Login_Name ,
            ServerPermsAndRoles.Login_Type ,
            ServerPermsAndRoles.Permission_Name ,
            ServerPermsAndRoles.Permission_Type ,
            ServerPermsAndRoles.Create_Date ,
            ServerPermsAndRoles.Modify_Date ,
            MapDisabled.Is_Disabled
    FROM    ServerPermsAndRoles
            LEFT JOIN MapDisabled ON MapDisabled.name = ServerPermsAndRoles.login_name
    ORDER BY MapDisabled.is_disabled DESC ,
            ServerPermsAndRoles.login_name;
			
			
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Database_Role_Login_Membership

Lists out the users associated to databases, their logins, and their permissions.
*/	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @DBRolePermissions TABLE(
 DatabaseName varchar(300), 
 Principal_Name sysname, 
 Login_Name sysname NULL, 
 DB_RoleMember varchar(300), 
 Permission_Type sysname)

INSERT INTO @DBRolePermissions
EXEC sp_MSforeachdb '
 SELECT DISTINCT ''?'' AS DatabaseName, users.Name AS UserName, suser_sname(users.sid) AS Login_Name, 
 roles.Name AS Role_Member_Name, roles.type_desc
 FROM [?].sys.database_role_members r 
 LEFT OUTER JOIN [?].sys.database_principals users on r.member_principal_id = users.principal_id
 LEFT OUTER JOIN [?].sys.database_principals roles on r.role_principal_id = roles.principal_id
   --JOIN [?].sys.database_permissions Action on Action.grantee_principal_id = users.principal_id'

INSERT INTO @DBRolePermissions
EXEC sp_msforeachdb '
 SELECT DISTINCT ''?'' AS DatabaseName, users.Name AS UserName, suser_sname(users.sid) AS Login_Name, 
 r.Permission_Name AS DB_RoleMember, r.class_desc
 FROM [?].sys.database_permissions r 
 LEFT OUTER JOIN [?].sys.database_principals users on r.grantee_principal_id = users.principal_id
 WHERE r.class_desc = ''DATABASE'''

SELECT DISTINCT Principal_Name, Login_Name, DatabaseName, DB_RoleMember AS Permission_Name
FROM @DBRolePermissions 
WHERE  Permission_Type <> 'DATABASE'
ORDER BY Principal_Name, DatabaseName, DB_RoleMember
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
