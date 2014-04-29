CREATE TABLE [dbo].[ClusteredIndexTable]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[UserName] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_CLusterIndexTable_ID] ON [dbo].[ClusteredIndexTable] ([ID]) ON [PRIMARY]

GO
