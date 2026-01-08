ALTER FUNCTION [dbo].[fn_SplitMulti]

/* This function is used to split up multi-value parameters from SSRS */

/* Only SQL Server 2005 compatible*/

(

@ItemList NVARCHAR(MAX),

@delimiter CHAR(1)

)

RETURNS @IDTable TABLE (Item VARCHAR(MAX))

AS

BEGIN

DECLARE @tempItemList NVARCHAR(MAX)

SET @tempItemList = @ItemList

DECLARE @i INT

DECLARE @Item NVARCHAR(MAX)

SET @tempItemList = REPLACE (@tempItemList, @delimiter + ' ', @delimiter)

SET @i = CHARINDEX(@delimiter, @tempItemList)

WHILE (LEN(@tempItemList) > 0)

BEGIN

IF @i = 0

SET @Item = @tempItemList

ELSE

SET @Item = LEFT(@tempItemList, @i - 1)

INSERT INTO @IDTable(Item) VALUES(@Item)

IF @i = 0

SET @tempItemList = ''

ELSE

SET @tempItemList = RIGHT(@tempItemList, LEN(@tempItemList) - @i)

SET @i = CHARINDEX(@delimiter, @tempItemList)

END

RETURN

END