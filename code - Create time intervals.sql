DECLARE @today smalldatetime = CAST(GETDATE() AS date);

WITH tally AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) a(n)
    CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) b(n)
    )
,intervals AS (
    SELECT
        DATEADD(mi,15*n,@today) AS interval_start
        ,DATEADD(mi,15*(n+1),@today) AS interval_end
    FROM tally
    WHERE n < 96
    )
SELECT *
FROM intervals
-- JOIN HERE