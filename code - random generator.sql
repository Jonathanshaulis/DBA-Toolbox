DECLARE @min INT, @max INT, @rowCnt INT

SET @min = 1;
SET @max = 1000;
SET @rowCnt = 1000;

SELECT TOP (@rowCnt)

--ints
RandInt				= ABS(CHECKSUM(NEWID())),									-- Random integer
RandIntMinMaxInc	= (ABS(CHECKSUM(NEWID())) % (@max - @min + 1)) + @min,		-- @min & @max inclusive
RandIntMinIncMaxExc	= (ABS(CHECKSUM(NEWID())) % (@max - @min)) + @min,			-- @min inclusive & @max exclusive
RandIntMinExcMaxInc	= (ABS(CHECKSUM(NEWID())) % (@max - @min)) + @min + 1,		-- @min exclusive & @max inclusive
RandIntMinMaxExc	= (ABS(CHECKSUM(NEWID())) % (@max - @min - 1)) + @min + 1,	-- @min exclusive & @max exclusive

--decimals/floats
RandFloatMinMaxExc	= RAND(CHECKSUM(NEWID())) * (@max - @min ) + @min,			-- min & max exlusive
RandDecMinMaxExc	= CONVERT(DECIMAL(11,2), RAND(CHECKSUM(NEWID())) * (@max - @min ) + @min),-- min & max exlusive (set presicion & scale appropriately)

-- DateTime (3,012,153 is max # of days for datetime, 3,652,058 max days for datetime2)
RandDate	= DATEADD(DAY, ABS(CHECKSUM(NEWID())) % (3012153 + 1), CONVERT(DATETIME, '17530101')), -- Datetime (min = 1753-01-01, max = 9999-12-31)
RandDate2	= DATEADD(DAY, ABS(CHECKSUM(NEWID())) % (3652058 + 1), CONVERT(DATETIME2, '00010101')), -- Datetime2 (min = 0001-01-01, max = 9999-12-31)

-- Bit
RandBit		= CONVERT(BIT, ROUND(RAND(CHECKSUM(NEWID())), 0)),

-- varchar
RandLetter	= SUBSTRING('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 1 + ABS(CHECKSUM(NEWID())) % 26, 1),

-- replicate a random letter a random number of times between @min and @max
RandString	= CONVERT(VARCHAR(MAX), REPLICATE(SUBSTRING('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 1 + ABS(CHECKSUM(NEWID())) % 26, 1),(ABS(CHECKSUM(NEWID())) % (@max - @min + 1)) + @min))

FROM dbo.Numbers
--FROM sys.columns A CROSS JOIN sys.columns B CROSS JOIN sys.columns C