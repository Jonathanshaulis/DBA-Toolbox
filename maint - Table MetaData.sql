SELECT t.NAME AS table_name
    ,SCHEMA_NAME(t.schema_id) AS schema_name
    ,c.NAME AS column_name
    ,st.NAME 'Data type'
    ,c.max_length 'Max Length'
    ,c.precision
    ,c.scale
    ,c.is_nullable
    ,ISNULL(i.is_primary_key, 0) 'Primary Key'
FROM sys.tables AS t
INNER JOIN sys.columns c ON t.OBJECT_ID = c.OBJECT_ID
INNER JOIN sys.types st ON c.user_type_id = st.user_type_id
LEFT JOIN sys.index_columns ic ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
LEFT JOIN sys.indexes i ON ic.object_id = i.object_id
    AND ic.index_id = i.index_id
ORDER BY schema_name
    ,table_name;