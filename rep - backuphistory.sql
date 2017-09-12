	DECLARE @StartDate DATETIME 
	DECLARE @EndDate DATETIME 
	SET @StartDate = (SELECT DATEADD(ms, -1, DATEADD(dd, -0, DATEDIFF(dd, 0, GETDATE())))) 
	SET @EndDate = (SELECT GETDATE())

	--	PRINT @StartDate
	--  PRINT @EndDate

	/****** Object:  Table [dbo].[RollingBUHist]    Script Date: 08/26/2015 12:52:11 ******/
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RollingBUHist]') AND type IN (N'U'))
	DROP TABLE [dbo].[RollingBUHist]

	CREATE TABLE [dbo].[RollingBUHist](
		[Command] [VARCHAR](255) NULL,
		[EndTime] [DATETIME] NULL,
		[Duration] VARCHAR(12) NULL
	) ON [PRIMARY]



	-- Populate RollingBUHist table. 

	INSERT INTO dbo.RollingBUHist 
			( Command ,
			  EndTime ,
			  Duration 
			)

	SELECT  CASE
		WHEN (Command LIKE 'BACKUP DATABASE%'  AND Command LIKE '%_FULL_%') THEN
			(REPLACE(dbo.fn_StripSingleQuote(command),'WITH CHECKSUM, COMPRESSION', ''))
		WHEN (Command LIKE 'BACKUP DATABASE%'  AND Command LIKE '%_DIFF_%') THEN
			(REPLACE(dbo.fn_StripSingleQuote(command),'WITH CHECKSUM, COMPRESSION, DIFFERENTIAL', ''))
		WHEN (Command LIKE 'BACKUP LOG%') THEN 	 
			(REPLACE(dbo.fn_StripSingleQuote(command),'WITH CHECKSUM, COMPRESSION', ''))
		ELSE
			'N/A'
	END Command ,        
			CAST(EndTime AS SmallDateTime) AS EndTime ,
			CONVERT(VARCHAR(24), DATEADD(MILLISECOND, DATEDIFF(MILLISECOND, StartTime, EndTime),0), 114) AS Duration 
	FROM    dbo.CommandLog
	WHERE   CommandType LIKE '%BACKUP%'
			AND starttime BETWEEN @StartDate AND @EndDate
	ORDER BY DatabaseName, StartTime

	---- SEND EMAIL 

	DECLARE 
	@Body		 VARCHAR(MAX),
	@TableHead	 VARCHAR(MAX),
	@TableTail	 VARCHAR(MAX),
	@ProfileName sysname,
	@tRecipients VARCHAR(400),
	@Server sysname, 
	@tSubject	 VARCHAR(255),
	@tBody		 VARCHAR(MAX),
	@tImportance VARCHAR(6)
	   
	SET @TableTail =  '</table></body></html>';
	SET @TableHead =  '<html><head>' +
					  '<style>' +
					  'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} ' +
					  '</style>' +
					  '</head>' +
					  '<body><table cellpadding=0 cellspacing=0 border=0>' +
					  '<tr bgcolor=#FFFF99>' +
					  '<td align=center><b>Command</b></td>' + 
					  '<td align=center><b>EndTime</b></td>' + 
					  '<td align=center><b>Duration</b></td>' ;

	SELECT @Body = (SELECT  ROW_NUMBER() OVER (ORDER BY Command) % 2 AS [TRRow],
					Command AS [TD],
					EndTime AS [TD],
					Duration AS [TD]
					FROM RollingBUHist 
					ORDER BY Command
					FOR XML RAW('tr'), ELEMENTS)
						
						
	-- Replace the entity codes and row numbers
	SET @Body = REPLACE(@Body, '_x0020_', SPACE(1))
	SET @Body = REPLACE(@Body, '_x003D_', '=')
	SET @Body = REPLACE(@Body, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#C6CFFF>')
	SET @Body = REPLACE(@Body, '<TRRow>0</TRRow>', '')

	SET @Server = (SELECT @@SERVERNAME)

	SET @tSubject = 'From ' + @Server + '. Backup History for the timeframe: ' + CAST(@StartDate AS VARCHAR(24)) + ' to ' + CAST(@EndDate AS VARCHAR(24))


	SELECT
		 @Body = @TableHead + @Body + @TableTail,
		 @profilename	= [name]
--		,@tRecipients = ''
		,@tRecipients = ''		
		,@tBody			= @Body
		,@tImportance	= 'NORMAL'
			FROM msdb.dbo.sysmail_profile
			WHERE [name] LIKE '%%'
	--		WHERE [name] LIKE '%%'		

			EXECUTE msdb.dbo.sp_send_dbmail
				 @profile_name 				  = @ProfileName
				,@Recipients  				  = @tRecipients
				,@Subject     				  = @tSubject
				,@Body                        = @tBody
				,@Body_Format				  = 'HTML'
				,@Importance  				  = @tImportance