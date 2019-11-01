USE MSDB;
-- See https://jonshaulis.com/index.php/2018/12/11/how-to-stop-the-sql-scheduler-with-t-sql/ for documentation

/*************************************************************
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |  ________    | || |     _____    | || |    _______   | || |      __      | || |   ______     | || |   _____      | || |  _________   | |
| | |_   ___ `.  | || |    |_   _|   | || |   /  ___  |  | || |     /  \     | || |  |_   _ \    | || |  |_   _|     | || | |_   ___  |  | |
| |   | |   `. \ | || |      | |     | || |  |  (__ \_|  | || |    / /\ \    | || |    | |_) |   | || |    | |       | || |   | |_  \_|  | |
| |   | |    | | | || |      | |     | || |   '.___`-.   | || |   / ____ \   | || |    |  __'.   | || |    | |   _   | || |   |  _|  _   | |
| |  _| |___.' / | || |     _| |_    | || |  |`\____) |  | || | _/ /    \ \_ | || |   _| |__) |  | || |   _| |__/ |  | || |  _| |___/ |  | |
| | |________.'  | || |    |_____|   | || |  |_______.'  | || ||____|  |____|| || |  |_______/   | || |  |________|  | || | |_________|  | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
 Checking for history table. Creating it if it doesn't exist. 
*************************************************************/

IF OBJECT_ID('dbo.JobsEnabledTracker', 'U') IS NULL
BEGIN
CREATE TABLE [dbo].[JobsEnabledTracker](
[Id] [INT] IDENTITY(1, 1) NOT NULL, 
[job_id]      [UNIQUEIDENTIFIER] NULL, 
[schedule_id] [BIGINT] NULL, 
[enabled]     [BIT] NULL);
END;
IF EXISTS
(
    SELECT 
           1
    FROM [dbo].[JobsEnabledTracker]
    WHERE [enabled] = 1
)
   OR
(
    SELECT 
           COUNT(*)
    FROM [dbo].[JobsEnabledTracker]
) = 0
    BEGIN
        PRINT 'There are jobs enabled or there are no jobs yet populated in the history table.';

/***********************
 Clear out history table
***********************/

        PRINT 'Truncating history table: dbo.JobsEnabledTracker';
        TRUNCATE TABLE [dbo].[JobsEnabledTracker];

        PRINT 'Inserting records into history table: dbo.JobsEnabledTracker';

/******************************
 Add in values to history table
******************************/

        INSERT INTO [dbo].[JobsEnabledTracker]
        (
               [job_id], 
               [schedule_id], 
               [enabled]
        )
        SELECT 
               [jss].[job_id], 
               [jss].[schedule_id], 
               1 AS 'enabled'
        FROM [msdb].[dbo].[sysschedules] AS [ss]
             INNER JOIN [msdb].[dbo].[sysjobschedules] AS [jss] ON [jss].[schedule_id] = [ss].[schedule_id]
        WHERE [ss].[enabled] = 1;

/**********************************************************************************
 Table variable to hold schedules and jobs enabled. This is important for the loop.
**********************************************************************************/

        DECLARE @JobsEnabled TABLE
        ([Id]          INT
         PRIMARY KEY IDENTITY(1, 1), 
         [job_id]      UNIQUEIDENTIFIER, 
         [schedule_id] BIGINT, 
         [enabled]     BIT
        );

/*****************************************
 Insert schedules that we need to disable.
*****************************************/

        INSERT INTO @JobsEnabled
        (
               [job_id], 
               [schedule_id], 
               [enabled]
        )
        SELECT 
               [job_id], 
               [schedule_id], 
               [enabled]
        FROM [dbo].[JobsEnabledTracker];

/********************************
 Holds the job id and schedule id
********************************/

        DECLARE @jobid UNIQUEIDENTIFIER;
        DECLARE @scheduleid BIGINT;

/***********************************
 Holds the ID of the row in the loop
***********************************/

        DECLARE @ID INT= 0;

/**********************
 Check if records exist
**********************/

        IF EXISTS
        (
            SELECT 
                   [Id]
            FROM @JobsEnabled
        )
            BEGIN
                PRINT 'Loop mode, jobs found enabled.';

/**********
 Begin loop
**********/

                WHILE(1 = 1)
                    BEGIN

/***************************************
 Grab jobid, scheduleid, and id of rows.
***************************************/

                        SELECT 
                               @jobid =
                        (
                            SELECT TOP 1 
                                   [job_id]
                            FROM @JobsEnabled
                            ORDER BY 
                                     [job_id]
                        );
                        SELECT 
                               @scheduleid =
                        (
                            SELECT TOP 1 
                                   [schedule_id]
                            FROM @JobsEnabled
                            ORDER BY 
                                     [job_id]
                        );
                        SELECT 
                               @ID =
                        (
                            SELECT TOP 1 
                                   [Id]
                            FROM @JobsEnabled
                            ORDER BY 
                                     [job_id]
                        );

/************************************
 Re-enable schedule associated to job
************************************/

                        PRINT 'Disabling schedule_id: '+CAST(@scheduleid AS VARCHAR(255))+' paired to job_id: '+CAST(@jobid AS VARCHAR(255));
                        EXEC [sp_update_schedule] 
                             @schedule_id = @scheduleid, 
                             @enabled = 0;

/*********************
 Removes row from loop
*********************/

                        DELETE FROM @JobsEnabled
                        WHERE 
                              [Id] = @ID;

                        UPDATE [dbo].[JobsEnabledTracker]
                          SET 
                              [enabled] = 0
                        WHERE 
                              [job_id] = @jobid
                              AND [schedule_id] = @scheduleid;

/****************************
 No more rows, stops deleting
****************************/

                        IF
                        (
                            SELECT 
                                   COUNT(*)
                            FROM @JobsEnabled
                        ) <= 0
                            BEGIN
                                BREAK
                            END;

/********
 End Loop
********/
                    END;
                PRINT 'Exiting loop, disabling schedules paired to jobs complete.';

/**********
 End elseif
**********/
            END;
            ELSE
            BEGIN
                PRINT 'All done';
            END;
    END;
    ELSE
    BEGIN
        PRINT 'YOU HAVE JOBS STILL DISABLED, EXITING SCRIPT. PLEASE RUN SCRIPT TWO FIRST.';
    END;