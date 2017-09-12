-- Set Database
USE <DATABASE_HERE>;
-- Declare variable table to hold table names
DECLARE	@variablenametable TABLE
	(
		Id INT PRIMARY KEY
				IDENTITY(1 , 1)
		,variablename VARCHAR(255)
	);
-- Holds the table name to stop
DECLARE	@variablename VARCHAR(255); 
-- Dynamic SQL holder
DECLARE	@variablenamekill NVARCHAR(MAX);
-- Holds the ID of the table in the loop
DECLARE	@ID INT = 0;
-- Check if tables exist
IF EXISTS ( SELECT
				name
			FROM
				<DATABASE_HERE>.dbo.sysobjects
			WHERE
				xtype = 'U' )
	BEGIN 
-- Insert names of table into the table variable
		INSERT	INTO @variablenametable
				(
					variablename
										
				)
				SELECT
					name
				FROM
					<DATABASE_HERE>.dbo.sysobjects
				WHERE
					xtype = 'U'; 

-- Begin loop               
		WHILE (1 = 1)
			BEGIN   
    -- Grab first name of table to delete
				SELECT
					@variablename = (
										SELECT TOP 1
											variablename
										FROM
											@variablenametable
									);  
    -- Sets dyanmic SQL to delete     
				SET @variablenamekill = N'DELETE FROM <DATABASE_HERE>.dbo.' + QUOTENAME(@variablename) + '';

    -- delete tables
				EXEC sp_executesql @variablenamekill;

    -- Removes table name from the list of tables
				DELETE FROM
					@variablenametable
				WHERE
					variablename = @variablename;

    -- No more tables, stops deleting
				IF (
					SELECT
						COUNT(*)
					FROM
						@variablenametable
					) <= 0
					BREAK;
    -- End Loop             
			END;
    -- End elseif
	END;
ELSE
	PRINT 'All done' 