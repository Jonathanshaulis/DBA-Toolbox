/*---------------------------------------------------------------------
Check CPU load; Email if last 5 min average is above x %
----------------------------------------------------------------------
Version		: 1.0
Auteur		: Theo Ekelmans (theo@ekelmans.com)
Datum		: 2015-07-28
Change		: Quick port as requested by the SqlServerCentral community
----------------------------------------------------------------------*/
set nocount on

DECLARE @InstanceName VARCHAR(100)
DECLARE @EmailHeader VARCHAR(200)
DECLARE @Emailbody VARCHAR(MAX)
DECLARE @EmailStatus int
declare @DT datetime
declare @cpuWarningHigh int
declare @cpuErrorHigh int
declare @SqlCpuUtilization as float
declare @OtherProcessUtilization as float
declare @ShowAllways int
declare @SystemIdle as float
declare @Emailprofilename varchar(50)
declare @EmailRecipients varchar(50)
declare @GoogleGraph  varchar(max)

--****************************************************************************************
-- Pre-run cleanup (just in case)
--***************************************************************************************
IF OBJECT_ID('tempdb..##GoogleGraph') IS NOT NULL DROP TABLE ##GoogleGraph;

--***************************************************************************************
-- Create a table for HTML assembly
--***************************************************************************************
create table ##GoogleGraph ([ID] [int] IDENTITY(1,1) NOT NULL,
							[HTML] [varchar](8000) NULL)

--****************************************************************************************
-- Set threshold(s)
--***************************************************************************************
set @ShowAllways = 1 -- 0 = use the 2 CPU thresholds -- 1 = ShowAllways
set @cpuWarningHigh = 70
set @cpuErrorHigh = 85
set @Emailprofilename = '<ProfileName>'
set @EmailRecipients = '<email>'


SET @InstanceName = @@SERVERNAME
SET @DT = GETDATE()

--****************************************************************************************
-- Calculate 5 min Averages
--****************************************************************************************
select		@SqlCpuUtilization = avg(SQLProcessUtilization * 1.0) --as SqlCpuUtilization
			,@OtherProcessUtilization = avg((100 - SystemIdle - SQLProcessUtilization) * 1.0) --as OtherProcessUtilization
			,@SystemIdle = avg(SystemIdle * 1.0) --as SystemIdle
from		(	select	top 5 
						record.value('(./Record/@id)[1]', 'int') as record_id,
						record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as SystemIdle,
						record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as SQLProcessUtilization,
						timestamp 
				from	(select	timestamp
								,convert(xml, record) as record
							from	sys.dm_os_ring_buffers with (nolock)
							where	ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
							and	record like '%<SystemHealth>%'
						) as x
			) as y 
			, sys.dm_os_sys_info with (nolock)
				

--****************************************************************************************
-- Check if threshold(s) are reached or  @ShowAllways = 1
--****************************************************************************************
if ((@SqlCpuUtilization + @OtherProcessUtilization) > @cpuWarningHigh) or (@ShowAllways = 1)
begin
	if (@SqlCpuUtilization + @OtherProcessUtilization) > @cpuWarningHigh
	begin
		set @EmailHeader = 'CPU load warning @ ' + @InstanceName
	end
		
	if (@SqlCpuUtilization + @OtherProcessUtilization) > @cpuErrorHigh
	begin
		set @EmailHeader = 'CPU load error @ ' + @InstanceName
	end

	set @Emailbody = '@ '+convert(varchar(20), @DT, 120)
					+' on '+ replace(@InstanceName, '\', '_') 
					+' (Node: ' +cast(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as varchar(128)) +') <hr>'
					+'SQL: ' + cast(@SqlCpuUtilization as varchar) + '% <br> '
					+'Other: ' + cast(@OtherProcessUtilization as varchar) + '% <br> '
					+'Idle: ' + cast(@SystemIdle as varchar) + '%'

	-- HTML code for google graph attachment; header, declarations and AJAX API's
	insert into ##GoogleGraph (HTML) 
	select 
	'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
	<html>
	<head>
	<title>CPU report</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-16">
	<!--<META HTTP-EQUIV="refresh" CONTENT="3">-->

	<!--Load the AJAX API-->
	<script type="text/javascript" src="https://www.google.com/jsapi"></script>
	<script type="text/javascript">

	// Init Visualization API 
	google.load("visualization", "1", {packages:["corechart"]});
	google.setOnLoadCallback(drawChart);

	//De container
	function drawChart() {
	
	//Load data for Linegraph into LineData table
	var LineData = new google.visualization.DataTable();
	LineData.addColumn(''datetime'', ''Datetime'');
	LineData.addColumn(''number'', ''SQL'');
	LineData.addColumn(''number'', ''Other'');
	LineData.addRows([
	'

	set @GoogleGraph = ''

	-- Get 256 CPU measurements from the ringbuffer and format the data for google graph
	insert into ##GoogleGraph (HTML) 
	SELECT  coalesce(   '[new Date(''' + convert(varchar(20), Dateadd(ms, -1 * ( cpu_ticks / ( cpu_ticks / ms_ticks ) - [timestamp] ), @DT), 120) +'''), '
					  + '' + cast(SQLProcessUtilization as varchar(50)) +', '
					  + '' + cast((100 - SystemIdle - SQLProcessUtilization) as varchar(50)) +'], ' + char(13) + char(10)
					  , ''  )
	FROM   (SELECT record.value('(./Record/@id)[1]', 'int')                                                    AS record_id
				   ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int')         AS SystemIdle
				   ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLProcessUtilization
				   ,timestamp
			FROM   (SELECT
				   timestamp
				   ,CONVERT(XML, record) AS record
					FROM   sys.dm_os_ring_buffers
					WHERE  ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
						   AND record LIKE '%<SystemHealth>%'
				   ) AS x) AS y,
		   sys.dm_os_sys_info
	ORDER  BY timestamp DESC 


	--Add the chart options
	insert into ##GoogleGraph (HTML) 
	select 	'      
	]);

	
	// Set Line chart options
	var LineOptions = {
		title: ''CPU load; last 256 minutes ringbuffer @ '+convert(varchar(20), @DT, 120)+' on '+ replace(@InstanceName, '\', '_') + ' (Node: ' +cast(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as varchar(128)) +')'', 
		titleTextStyle: {	color: ''black'',
							fontName: ''arial'', 
							fontSize: 12, 
							bold: 1
						},
		legend:{position:''bottom''},
		curveType:''none'', //function = smooth lines
		backgroundColor:{	fill: ''#FFFFFF'', 
							stroke: ''#000000'', 
							strokeWidth: 5
						},
		chartArea:		{	left:80,
							top:40,
							width:"85%",
							height:"80%"
						},
		lineWidth: 1,
		pointSize: 0,
		isStacked: true, 
		hAxis: 			{	//title: ''Datum'', 
							//format:''yyyy-MM-dd HH:mm'',
							format:''HH:mm'',
							//baseline: ''2013-09-03 00:00'',
							//minValue: ''2013-09-01'',
							//maxValue: ''2013-09-06 00:00'',
							logScale: 0,
							baselineColor: ''black'',
							gridlines: 		{color: ''#c0c0c0'',
											//color: ''black''
											},
							//minorGridlines: {	color: ''black'',
							//					count: 2},
							textStyle: 		{	color: ''black'', 
												fontName: ''arial'', 
												fontSize: 12, 
												bold: 1},
							//maxAlternation: 2,
							//maxTextLines: 1
							slantedText: 1,
							slantedTextAngle: 90,
							//minTextSpacing: 50, //Werkt niet: bekende bug
							showTextEveryshowTextEvery:1  //Let op: werkt wel,maar moet berekend worden 
						},

		vAxis: 			{	title: ''CPU %'', 
							format: "#######",
							minValue: 0, 
							maxValue: 100, 
							logScale: 0,
							baseline: 0,
							textPosition: ''out'',
							ticks: [0, 20, 40, 60, 80, 100],
							//viewWindow:{	maxValue:100, minValue:50},
							//viewWindowMode: ''explicit'',
							baselineColor: ''black'',
							gridlines: {	//color: ''gray'',
											color: ''#c0c0c0'',
											count: 5},
							//minorGridlines: {	color: ''black'',
							//				count: 2},
							textStyle: {	color: ''black'', 
											fontName: ''arial'', 
											fontSize: 12, 
											bold: 1}
						},
			};		

	var LineChart = new google.visualization.AreaChart(document.getElementById(''LineChart_div''));
	LineChart.draw(LineData, LineOptions);

	}	  
	</script>
	
	</head><body>
	<div id="LineChart_div" style="width: 800px; height: 600px;"></div>
	<br>
	<br>
	</body></html>
	'
			

--***************************************************************************************
-- Send Email - 
--***************************************************************************************
execute msdb.dbo.sp_send_dbmail	
	 @profile_name = @Emailprofilename
	,@recipients = @EmailRecipients
	,@subject = @EmailHeader
	,@body = 'See attachment for CpuLoad, open with Google Chrome!' 
	,@body_format = 'HTML' -- or TEXT
	,@importance = 'Normal' --Low Normal High
	,@sensitivity = 'Normal' --Normal Personal Private Confidential
	,@execute_query_database = 'master'
	,@query_result_header = 0
	,@query = 'set nocount on; SELECT HTML FROM ##GoogleGraph'
	,@query_result_no_padding = 1  -- prevent SQL adding padding spaces in the result
	--,@query_no_truncate= 1       -- mutually exclusive with @query_result_no_padding 
	,@attach_query_result_as_file = 1
	,@query_attachment_filename= 'CpuLoad.HTML'


end
	


