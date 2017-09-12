-- =============================================
-- Author:		Jon Shaulis
-- Create date: 08/11/2015
-- Description:	Quickly shows SSIS logs that matter at a high level when executed.
-- =============================================
CREATE PROCEDURE [dbo].[uspViewSSISLogs] 
	
AS
BEGIN
	;WITH MultiPackageFinderCTE AS (
    SELECT DISTINCT executionid, sourceid, source, MIN(starttime) AS MinStartTime, computer,
        ROW_NUMBER() over (PARTITION BY executionid ORDER BY MIN(starttime) DESC) AS PackageOrdinal
    FROM dbo.sysssislog
    WHERE sourceid IN (SELECT DISTINCT sourceid FROM dbo.sysssislog WHERE event = 'PackageStart')
    GROUP BY executionid, sourceid, source, computer
)
   
--Main Query
SELECT * FROM (
    SELECT A.executionid, A.computer, A.operator, A.starttime,
        A.Duration, A.endtime, A.Messages, A.MessageSources,
        COALESCE(B.PackageID,A.executionid) AS PackageID, B.PackageName, B.ExecutionNo,
        C.PackageStart, D.PackageEnd, D.datacode,
        E.ErrorCount,  F.FirstError, G.ConfigMessage, H.PackageRows,
        Status = ( CASE
            --Infer a status using PackageStart, PackageEnd, the endtime, and OnError messages.
            WHEN PackageStart IS NOT NULL AND PackageEnd IS NOT NULL AND ErrorCount IS NULL THEN 'Success'
            WHEN PackageStart IS NOT NULL AND PackageEnd IS NULL AND ErrorCount IS NULL AND endtime > DATEADD(s,-10,GETDATE()) THEN 'Executing'
            WHEN PackageStart IS NOT NULL AND PackageEnd IS NULL AND ErrorCount IS NULL AND endtime < DATEADD(s,-10,GETDATE()) THEN 'Stalled'           
            WHEN PackageStart IS NOT NULL AND ErrorCount > 0 THEN 'Failure'
            WHEN PackageStart IS NULL AND PackageEnd IS NULL AND ErrorCount IS NULL THEN 'Config Success'
            WHEN PackageStart IS NULL AND PackageEnd IS NULL AND ErrorCount > 0 THEN 'Config Failure'
            ELSE 'Other'
        END )
    FROM (
        SELECT executionid
            ,MAX(computer) AS computer
            ,MAX(operator) AS operator
            ,MIN(starttime) AS starttime
            ,DATEDIFF(second, MIN(starttime), MAX(endtime)) As Duration
            ,MAX(endtime) AS endtime
            ,COUNT(message) AS Messages
            ,COUNT(DISTINCT sourceid) AS MessageSources
        FROM dbo.sysssislog
        GROUP BY executionid
    ) AS A
   
    LEFT JOIN (
        SELECT executionid
            ,sourceid AS PackageID
            ,source AS PackageName
            ,ROW_NUMBER() OVER (PARTITION BY computer, sourceid ORDER BY MinStartTime) AS ExecutionNo
        FROM MultiPackageFinderCTE
    ) AS B
    ON A.executionid = B.executionid
   
    -- Get the PackageStart event time.
    LEFT JOIN (
        SELECT executionid
            ,starttime AS PackageStart
        FROM dbo.SysSSISLog
        WHERE event = 'PackageStart'
    ) AS C
    ON A.executionid = C.executionid
   
    -- Get the PackageEnd event time.
    LEFT JOIN (
        SELECT executionid
            ,datacode
            ,endtime AS PackageEnd
        FROM dbo.SysSSISLog
        WHERE event = 'PackageEnd'
    ) AS D
    ON A.executionid = D.executionid
   
    -- Count the error messages.
    LEFT JOIN (
        SELECT executionid
            ,COUNT(message) AS ErrorCount
        FROM dbo.SysSSISLog
        WHERE event = 'OnError'
        GROUP BY executionid
    ) AS E
    ON A.executionid = E.executionid
   
    -- Promote the first error message inside the executionid.
    LEFT JOIN (
        SELECT executionid
            ,message AS FirstError
        FROM (
            SELECT executionid
                ,message
                ,ROW_NUMBER() OVER(PARTITION BY executionid ORDER BY starttime ASC) AS ErrorNumber
            FROM dbo.sysssislog
            WHERE event = 'OnError'
            ) AS F1
        WHERE ErrorNumber=1
    ) AS F
    ON A.executionid = F.executionid
   
    -- Get the configuration message.
    -- Optional: If using eternal XML configs,
    -- uncomment the subtring method to parse out the UNC path.
    LEFT JOIN (
        SELECT executionid
            ,message as ConfigMessage
            --,SUBSTRING(message, charindex('configure from the XML file "', message) + 29, charindex('".', message) - charindex('configure from the XML file "', message) - 29) AS dtsConfig
        FROM dbo.SysSSISLog
        WHERE event = 'OnInformation'
        AND message LIKE '%package%attempting%configure%'
        GROUP BY executionid, message
    ) AS G
    ON A.executionid = G.executionid
   
    -- Get package-level OnInformation messages having the words "wrote rows"
    -- Extract integers from these messages. Sum them per executionid.
    LEFT JOIN (
        SELECT executionid
              ,SUM(ISNULL(CONVERT(INT, SUBSTRING(message, charindex('wrote ', message) + 5, charindex('rows.', message) - charindex('wrote ', message) - 5)),0)) As PackageRows
        FROM dbo.SysSSISLog
        WHERE event = 'OnInformation'
        AND message LIKE '%wrote%rows%'
        AND sourceid IN (SELECT DISTINCT sourceid FROM dbo.sysssislog WHERE event = 'PackageStart')
        GROUP BY executionid
    ) AS H
    ON A.executionid = H.executionid
) AS X
   
ORDER BY starttime DESC
END


GO


