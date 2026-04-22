-- Lookup across databases: find column by name
 
DECLARE @sql     VARCHAR(MAX),
        @db_name VARCHAR(50)
 
DECLARE DB_Cursor CURSOR FOR
    SELECT name
    FROM sys.databases
    WHERE name NOT IN (
        'master',
        'model',
        'msdb',
        'tempdb'
    )
 
OPEN DB_Cursor
 
FETCH NEXT FROM DB_Cursor INTO @db_name
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
    SET @sql =
        '
        USE ' + @db_name + '
 
        SELECT
            SCHEMA_NAME(schema_id) AS schema_name,
            DB_NAME()              AS db_name,
            t.name                 AS table_name,
            c.name                 AS column_name
        FROM sys.tables AS t
            INNER JOIN sys.columns c ON t.OBJECT_ID = c.OBJECT_ID
        WHERE c.name LIKE ''%policy%''
        ORDER BY
            schema_name,
            table_name
        '
 
    PRINT @db_name
    -- PRINT @sql
 
    EXEC (@sql)
 
    FETCH NEXT FROM DB_Cursor INTO @db_name
 
END
 
CLOSE DB_Cursor
DEALLOCATE DB_Cursor

