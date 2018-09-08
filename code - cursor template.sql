CREATE TABLE ##t(
    tablename nvarchar(200)
    ,izho nvarchar(200)
)

DECLARE @id nvarchar(200);

DECLARE C CURSOR FAST_FORWARD FOR
select id from cond 
where CONN_HOST = ''
OPEN C;

FETCH NEXT FROM C INTO @id;

DECLARE @Sql nvarchar(max);
DECLARE @tablename nvarchar(200)
WHILE @@FETCH_STATUS = 0
BEGIN

    SET @tablename = N'consw_' + @id
    SET @sql = N'INSERT INTO ##t ' + 
               N'SELECT ' + @id + N', izho ' + 
               N'FROM ' + @tablename;
    EXEC(@sql)

    FETCH NEXT FROM C INTO @id;
END
CLOSE C;
DEALLOCATE C;


SELECT tablename, izho
FROM ##t;

DROP TABLE ##t;

