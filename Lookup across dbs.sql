/*************Lookup across dbs********************************************************/

declare @sql varchar(max), @db_name varchar(50)

 

declare DB_Cursor cursor  for

 

 

SELECT name --, database_id, create_date

FROM sys.databases

where name not in

(

'master',

'model',

'msdb',

'tempdb'

)

 

open DB_Cursor

 

fetch next from DB_Cursor into @db_name

while @@fetch_status = 0

BEGIN

fetch next from DB_Cursor into @db_name

set @sql=

'

use '+@db_name+'

SELECT

SCHEMA_NAME(schema_id) AS schema_name,db_name() as db_name,

t.name AS table_name,

c.name AS column_name

FROM sys.tables AS t

INNER JOIN sys.columns c ON t.OBJECT_ID = c.OBJECT_ID

WHERE c.name LIKE ''%DETERM%''

ORDER BY schema_name, table_name

'

print @db_name

--print @sql

exec (@sql)

 

end

close DB_Cursor

deallocate DB_Cursor             

 
/*********************************************************************/

declare @sql varchar(max), @db_name varchar(50)

 

declare DB_Cursor cursor  for

 

 

SELECT name --, database_id, create_date

FROM sys.databases;

 

open DB_Cursor

 

fetch next from DB_Cursor into @db_name

while @@fetch_status = 0

BEGIN

fetch next from DB_Cursor into @db_name

set @sql=

'

use '+@db_name+'

 SELECT

SCHEMA_NAME(schema_id) AS schema_name,

t.name AS table_name,

c.name AS column_name

FROM sys.tables AS t

INNER JOIN sys.columns c ON t.OBJECT_ID = c.OBJECT_ID

WHERE C.name LIKE ''%DECIS%''

'

print @db_name

--print @sql

exec (@sql)

 

end

close DB_Cursor


deallocate DB_Cursor         
