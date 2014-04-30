USE inmemtest
GO

SET NOCOUNT ON

IF EXISTS(SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '%fndblog%')
BEGIN

	DROP TABLE #fndblog

END

IF EXISTS(SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '%dbccpage%')
BEGIN

	DROP TABLE #dbccpage

END

IF EXISTS(SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '%dbccpagealloc%')
BEGIN

	DROP TABLE #dbccpagealloc

END

IF EXISTS(SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '%dbccind%')
BEGIN

	DROP TABLE #dbccind

END



DECLARE @intpage INT
DECLARE @looplimit INT
DECLARE @loopcount INT
DECLARE @pagenum CHAR(8)
DECLARE @allocunitname SYSNAME
DECLARE @sqlstr VARCHAR(1000)
DECLARE @pagetype TINYINT

CREATE TABLE #dbccpage
(parentobject VARCHAR(100)
,objectname VARCHAR(100)
,field VARCHAR(100)
,value VARCHAR(100)) 

CREATE TABLE #dbccpagealloc
(allocunit VARCHAR(100)
,intpage INT
,parentobject VARCHAR(100)
,objectname VARCHAR(100)
,field VARCHAR(100)
,value VARCHAR(100)) 

SET @loopcount = 1

SELECT OBJECT_NAME(object_id) AS objectname, allocated_page_page_id, page_type, page_type_desc
INTO #dbccind
FROM sys.dm_db_database_page_allocations(DB_ID('inmemtest'),NULL,NULL,NULL,'DETAILED') 

--SELECT * FROM fn_dblog(NULL,NULL)
--WHERE [Page ID] LIKE'%00000069%'
SELECT DISTINCT AllocUnitName, SUBSTRING([Page ID],6,8) AS intpage
INTO #fndblog
FROM fn_dblog(NULL,NULL)
WHERE AllocUnitName IS NOT NULL
--AND AllocUnitName NOT LIKE '%.nc%'
--AND Context NOT LIKE 'LCX_INDEX%'
--AND AllocUnitName <> 'Unknown Alloc Unit'

SELECT @looplimit = COUNT(*) FROM #fndblog

--SET @looplimit = @@ROWCOUNT

DBCC TRACEON(3604) WITH NO_INFOMSGS

WHILE @loopcount <= @looplimit
BEGIN

	--SELECT d.*
	--FROM #fndblog f
	--INNER JOIN #dbccind d
	--ON f.intpage = d.allocated_page_page_id
	
	SELECT TOP 1 @pagenum = intpage
	FROM #fndblog

	SELECT TOP 1 @allocunitname = allocunitname
	FROM #fndblog

	SET @intpage = dbo.ufn_hextodecimal(@pagenum)
	
	SELECT @pagetype = page_type FROM #dbccind
	WHERE allocated_page_page_id = @intpage

	IF @pagetype = 1
	BEGIN

			--SELECT 'Gotta data page, skibby!'

		--SELECT @pagenum, @allocunitname
		--DBCC PAGE(inmemtest,1,@intpage,3) WITH TABLERESULTS
		SET @sqlstr = 'DBCC PAGE(inmemtest,1,' + CAST(@intpage AS VARCHAR(8)) + ',3) WITH TABLERESULTS, NO_INFOMSGS'

		INSERT INTO #dbccpage
		EXEC(@sqlstr)

		INSERT INTO #dbccpagealloc
		SELECT @allocunitname, @intpage, *
		FROM #dbccpage

	END
	ELSE IF @pagetype = 2
	BEGIN
		
		SET @sqlstr = 'DBCC PAGE(inmemtest,1,' + CAST(@intpage AS VARCHAR(8)) + ',3) WITH TABLERESULTS, NO_INFOMSGS'

		PRINT @sqlstr
		EXEC(@sqlstr)

	END
	DELETE TOP (1) FROM #fndblog
	
	DELETE FROM #dbccpage

	SET @loopcount += 1

END
GO

--SELECT [Current LSN], Operation, Context, AllocUnitName, [Page ID], [Number of Locks], [Lock Information], Description
--FROM fn_dblog(NULL,NULL)
--WHERE AllocUnitName LIKE '%disk%'

SELECT * FROM #dbccpagealloc
WHERE allocunit NOT LIKE '%sys%'
