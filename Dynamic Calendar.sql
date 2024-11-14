-- Dynamic calendar
--Define parameters YEAR, MONTH OR QUARTER
declare @part as varchar(10)='YEAR'
declare @Quantity int=4--NUMBER OF YEARS BACK FROM NOW
----------------------------------------------------------------
DECLARE @StartDate  date = case @part 
            when 'YEAR' then dateadd(YEAR,-1*@Quantity,GETDATE()) 
            when 'MONTH' then dateadd(MONTH,-1*@Quantity,GETDATE()) 
			 when 'QUARTER' then 
			 case datepart(qq,dateadd(QUARTER,-1*@Quantity,GETDATE()) )
			 when 1 then DATEFROMPARTS(year(dateadd(QUARTER,-1*@Quantity,GETDATE())),1,1)
			 when 2 then DATEFROMPARTS(year(dateadd(QUARTER,-1*@Quantity,GETDATE())),4,1)
             when 3 then DATEFROMPARTS(year(dateadd(QUARTER,-1*@Quantity,GETDATE())),7,1)
			 when 4 then DATEFROMPARTS(year(dateadd(QUARTER,-1*@Quantity,GETDATE())),10,1)
			 end
            
        end

PRINT @Startdate

DECLARE @CutoffDate date = DATEADD(DAY, -1, 
--DATEADD(YEAR, 1, @StartDate)
case @part 
            when 'YEAR' then dateadd(YEAR,@Quantity,@StartDate) 
            when 'MONTH' then dateadd(MONTH,@Quantity,@StartDate) 
			 when 'QUARTER' then 
			 case datepart(qq,dateadd(QUARTER,@Quantity,@StartDate) )
			 when 1 then DATEFROMPARTS(year(dateadd(QUARTER,@Quantity,@StartDate)),1,1)
			 when 2 then DATEFROMPARTS(year(dateadd(QUARTER,@Quantity,@StartDate)),4,1)
             when 3 then DATEFROMPARTS(year(dateadd(QUARTER,@Quantity,@StartDate)),7,1)
			 when 4 then DATEFROMPARTS(year(dateadd(QUARTER,@Quantity,@StartDate)),10,1)
			 end
            
        end


);

declare @Year int=YEAR(GETDATE())

print @CutoffDate

/****calendar**************/

;WITH seq(n) AS --recursive CTE: DAYS BETWEEB 
(

  SELECT 0 UNION ALL SELECT n + 1 FROM seq

  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)

),

d(d) AS

(

  SELECT DATEADD(DAY, n, @StartDate) FROM seq

)

SELECT d  FROM d

ORDER BY d

OPTION (MAXRECURSION 0) --maximum number of recursions allowed for this query--0 means no limit


----SELECT DATENAME(Quarter, CAST(CONVERT(VARCHAR(8), GETDATE()) AS DATETIME))

--SELECT DATEPART(qq,GETDATE())