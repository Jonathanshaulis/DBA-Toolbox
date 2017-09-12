
-- separate first name to first, middle, and last. Based on first name is not blank, has a space, middle name will be between two spaces found.
	
	BEGIN TRANSACTION
	UPDATE races.dbo.Peach_08222015
	SET Firstname = (LEFT(firstname , CHARINDEX(' ' , FirstName))),
	MiddleName = (CASE	WHEN LEN(firstname) = ((CHARINDEX(' ' , REVERSE(FirstName))) + (CHARINDEX(' ' , FirstName)) - 1) THEN NULL
			ELSE SUBSTRING(FirstName , (CHARINDEX(' ' , FirstName)) + 1 ,
							(1 + LEN(firstname)) - (CHARINDEX(' ' , FirstName) + CHARINDEX(' ' , REVERSE(FirstName))))
		END),
		LastName = (CASE	WHEN LEN(firstname) = 0 THEN NULL
			ELSE RIGHT(firstname , (CHARINDEX(' ' , REVERSE(FirstName)) - 1))
		END)
	FROM races.dbo.Peach_08222015
	SELECT * FROM races.dbo.Peach_08222015
	commit TRANSACTION
	
	