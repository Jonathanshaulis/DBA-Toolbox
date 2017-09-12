
-- SQL variable declare
		DECLARE	@PreviousDate DATETIME 
		DECLARE	@Year VARCHAR(4) 
		DECLARE	@Month VARCHAR(2) 
		DECLARE	@MonthPre VARCHAR(2) 
		DECLARE	@Day VARCHAR(2) 
		DECLARE	@DayPre VARCHAR(2) 
		DECLARE	@FinalDate INT 
-- Table and email variable declare
		DECLARE	@Body VARCHAR(MAX)
		DECLARE	@TableHead VARCHAR(MAX)
		DECLARE	@TableTail VARCHAR(MAX)
		DECLARE	@ProfileName SYSNAME
		DECLARE	@tRecipients VARCHAR(400)
		DECLARE	@Server SYSNAME
		DECLARE	@tSubject VARCHAR(255)
		DECLARE	@tBody VARCHAR(MAX)
		DECLARE	@tImportance VARCHAR(6)

		DECLARE	@Subquery TABLE
			(
				[name] VARCHAR(MAX)
				,[step_name] VARCHAR(MAX)
				,[step_id] VARCHAR(MAX)
				,[step_name2] VARCHAR(MAX)
				,[run_date] VARCHAR(MAX)
				,[run_time] VARCHAR(MAX)
				,[sql_severity] VARCHAR(MAX)
				,[message] VARCHAR(MAX)
				,[server] VARCHAR(MAX)
				,[instance_id] VARCHAR(MAX)
				,[command] VARCHAR(MAX)
			)

		INSERT	INTO @Subquery
				(
					[name]
					,[step_name]
					,[step_id]
					,[step_name2]
					,[run_date]
					,[run_time]
					,[sql_severity]
					,[message]
					,[server]
					,[instance_id]
					,[command]
				)
				SELECT
					j.[name] AS [name]
					,s.step_name AS [step_name]
					,h.step_id AS [step_id]
					,h.step_name AS [step_name]
					,h.run_date AS [run_date]
					,h.run_time AS [run_time]
					,h.sql_severity AS [sql_severity]
					,h.message AS [message]
					,h.server AS [server]
					,h.instance_id
					,s.command
				FROM
					msdb.dbo.sysjobhistory h
				INNER JOIN msdb.dbo.sysjobs j
				ON	h.job_id = j.job_id
				INNER JOIN msdb.dbo.sysjobsteps s
				ON	j.job_id = s.job_id AND
					h.step_id = s.step_id
				WHERE
					h.run_status = 0 -- Failure 
					AND
					h.run_date > @FinalDate AND
					j.name <> ''

		IF (
			(
	SELECT
		COUNT(*)
	FROM
		@SubQuery
		)
			) > 0
			BEGIN 					

-- Initialize Variables 
				SET @PreviousDate = DATEADD(dd , -7 , GETDATE()) -- Last 7 days  
				SET @Year = DATEPART(yyyy , @PreviousDate)  
				SELECT
					@MonthPre = CONVERT(VARCHAR(2) , DATEPART(mm , @PreviousDate)) 
				SELECT
					@Month = RIGHT(CONVERT(VARCHAR , (@MonthPre + 1000000000)) , 2) 
				SELECT
					@DayPre = CONVERT(VARCHAR(2) , DATEPART(dd , @PreviousDate)) 
				SELECT
					@Day = RIGHT(CONVERT(VARCHAR , (@DayPre + 1000000000)) , 2) 
				SET @FinalDate = CAST(@Year + @Month + @Day AS INT) 

	---- SEND EMAIL 



	   
				SET @TableTail = '</table></body></html>';
				SET @TableHead = '<html><head>' + '<style>' +
					'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:11pt;} ' +
					'</style>' + '</head>' + '<body><table cellpadding=0 cellspacing=0 border=0>' +
					'<tr bgcolor=#42f4aa>' + '<td align=center><b>Name</b></td>' +
					'<td align=center><b>Step_Name</b></td>' + '<td align=center><b>Step_ID</b></td>' +
					'<td align=center><b>Step_Name</b></td>' + '<td align=center><b>Run_Date</b></td>' +
					'<td align=center><b>Run_Time</b></td>' + '<td align=center><b>SQL_Severity</b></td>' +
					'<td align=center><b>Message</b></td>' + '<td align=center><b>Server</b></td>';

				SELECT
					@Body = (
								SELECT
									ROW_NUMBER() OVER (ORDER BY Command) % 2 AS [TRRow]
									,[name] AS [TD]
									,[step_name] AS [TD]
									,[step_id] AS [TD]
									,[step_name2] AS [TD]
									,[run_date] AS [TD]
									,[run_time] AS [TD]
									,[sql_severity] AS [TD]
									,[message] AS [TD]
									,[server] AS [TD]
								FROM
									@subquery
								ORDER BY
									[instance_id] DESC
							FOR
								XML	RAW('tr')
									,ELEMENTS
							)
						
						--#4286f4 C6CFFF #f4aa42 #FFFF99
	-- Replace the entity codes and row numbers
				SET @Body = REPLACE(@Body , '_x0020_' , SPACE(1))
				SET @Body = REPLACE(@Body , '_x003D_' , '=')
				SET @Body = REPLACE(@Body , '<tr><TRRow>1</TRRow>' , '<tr bgcolor=#4286f4>')
				SET @Body = REPLACE(@Body , '<TRRow>0</TRRow>' , '')

				SET @Server = (
								SELECT @@SERVERNAME
								)

				SET @tSubject = 'From ' + @Server + '. Failed Job History for the timeframe: ' +
					CAST(@FinalDate AS VARCHAR(24)) + ' to ' + CAST(@FinalDate AS VARCHAR(24))


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


				EXECUTE msdb.dbo.sp_send_dbmail @profile_name = @ProfileName , @Recipients = @tRecipients ,
					@Subject = @tSubject , @Body = @tBody , @Body_Format = 'HTML' , @Importance = @tImportance



			END
		ELSE
			BEGIN
				PRINT 'all good' 
			END