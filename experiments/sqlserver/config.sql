use aqit;
GO
GO
RECONFIGURE WITH OVERRIDE;
GO
/*Configuration for parallelism*/
sp_configure 'show advanced options', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO
/*0 means allowing parallelism*/
/*1 means no parallelism*/
sp_configure 'max degree of parallelism', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO

/*Force SQL Server to flush away the cache*/
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE

GO
USE [aqit]
GO


CREATE TABLE [dbo].[tblbtree](
	[x] [int] NOT NULL,
	[y] [int] NULL,
 CONSTRAINT [PK_tblbtree] PRIMARY KEY CLUSTERED 
(
	[x] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


set showplan_text off
go