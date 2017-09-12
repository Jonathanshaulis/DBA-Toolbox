SELECT  name ,
        is_policy_checked ,
        is_expiration_checked ,
        LOGINPROPERTY(name, 'IsMustChange') AS is_must_change ,
        LOGINPROPERTY(name, 'IsLocked') AS [Account Locked] ,
        LOGINPROPERTY(name, 'LockoutTime') AS LockoutTime ,
        LOGINPROPERTY(name, 'PasswordLastSetTime') AS PasswordLastSetTime ,
        LOGINPROPERTY(name, 'IsExpired') AS IsExpired ,
        LOGINPROPERTY(name, 'IsLocked') AS IsLocked,
        LOGINPROPERTY(name, 'BadPasswordCount') AS BadPasswordCount ,
        LOGINPROPERTY(name, 'BadPasswordTime') AS BadPasswordTime ,
        LOGINPROPERTY(name, 'HistoryLength') AS HistoryLength ,
        LOGINPROPERTY(name, 'DaysUntilExpiration') AS ExpirationDays,
        modify_date
FROM    sys.sql_logins 
ORDER BY Name
