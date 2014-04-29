SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.usp_fn_dblog
	@beginlsn VARCHAR(25) = NULL, 
	@endlsn VARCHAR(25) = NULL
AS
	
	SELECT 
	[Current LSN], 
	Operation, 
	Context, 
	AllocUnitName, 
	[Page ID], 
	[Slot ID], 
	[Lock Information], 
	Description FROM fn_dblog(@beginlsn,@endlsn)

GO
