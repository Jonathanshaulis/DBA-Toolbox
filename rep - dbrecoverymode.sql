-- Email Variables
DECLARE	@ProfileName SYSNAME;
DECLARE	@tRecipients VARCHAR(400);
DECLARE	@tSubject VARCHAR(255);
DECLARE	@tBody VARCHAR(8000);
DECLARE	@tImportance VARCHAR(6);

-- XML Variables
DECLARE	@TableHead VARCHAR(MAX);
DECLARE	@TableTail VARCHAR(MAX);
DECLARE	@Body VARCHAR(MAX);

-- Query and system variables
DECLARE	@Server SYSNAME;
DECLARE	@SubQuery TABLE
	(
		Database_Name VARCHAR(255)
		,Recovery_Model VARCHAR(255)
	);

SET @Server = (
				SELECT @@SERVERNAME
				);
									
INSERT	INTO @SubQuery
		(
			Database_Name
			,Recovery_Model
				
		)
		SELECT
			name AS [Database_Name]
			,recovery_model_desc AS [Recovery_Model]
		FROM
			sys.databases
		WHERE
			name NOT IN ('master' , 'tempdb' , 'model' , 'msdb' , 'distribution' ) AND
			recovery_model_desc != 'FULL';

IF (
	(
	SELECT
		COUNT(*)
	FROM
		@SubQuery
		)
	) > 0
	BEGIN 
	
		SET @tSubject = 'From ' + @Server + ' List of jobs not set to FULL mode.'




		SET @TableTail = '</table></body></html>';
		SET @TableHead = '<html><head>' + '<style>' +
			'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} ' +
			'</style>' + '</head>' + '<body><table cellpadding=0 cellspacing=0 border=0>' + '<tr bgcolor=#9b42f4>' +
			'<td align=center><b>Database_Name</b></td>' +
			'<td align=center><b>Recovery_Model</b></td>';

		SELECT
			@Body = (
						SELECT
							ROW_NUMBER() OVER (ORDER BY Database_Name) % 2 AS [TRRow]
							,[Database_Name] AS [TD]
							,[Recovery_Model] AS [TD]
						FROM
							@subquery
						ORDER BY
							[Recovery_Model] DESC
					FOR
						XML	RAW('tr')
							,ELEMENTS
					)
						
						--#4286f4 C6CFFF #f4aa42 #FFFF99
	-- Replace the entity codes and row numbers
		SET @Body = REPLACE(@Body , '_x0020_' , SPACE(1))
		SET @Body = REPLACE(@Body , '_x003D_' , '=')
		SET @Body = REPLACE(@Body , '<tr><TRRow>1</TRRow>' , '<tr bgcolor=#42f45f>')
		SET @Body = REPLACE(@Body , '<TRRow>0</TRRow>' , '')





		SELECT
			@Body = @TableHead + @Body + @TableTail
			,@profilename = [name]
			--,@tRecipients = ''
		,@tRecipients = ''		
			,@tBody = @Body
			,@tImportance = 'NORMAL'
		FROM
			msdb.dbo.sysmail_profile
		WHERE
			[name] LIKE '%%'


		EXECUTE msdb.dbo.sp_send_dbmail @profile_name = @ProfileName , @Recipients = @tRecipients , @Subject = @tSubject ,
			@Body = @tBody , @Body_Format = 'HTML' , @Importance = @tImportance
			
	END
ELSE
	BEGIN
		PRINT 'all good' 
	END