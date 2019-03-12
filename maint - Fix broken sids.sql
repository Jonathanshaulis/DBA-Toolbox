-- This shows you any orphaned users.
	USE [DB]
	GO
	exec sp_change_users_login 'Report'
	

-- Run this to generate the create login script if you need to create a login.
	EXEC sp_help_revlogin

--	Run this script to change the local version of the account if needed
		Use DB
		go
		sp_change_users_login 'update_one', 'usernamehere', 'usernamehere'
