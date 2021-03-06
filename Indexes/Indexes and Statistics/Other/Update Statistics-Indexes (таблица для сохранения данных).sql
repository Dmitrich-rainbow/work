USE [dba_tasks]
GO

/****** Object:  Table [dbo].[index_defrag_statistic]    Script Date: 09/03/2014 12:18:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[index_defrag_statistic](
	[proc_id] [int] NULL,
	[start_time] [datetime] NULL,
	[end_time] [datetime] NULL,
	[database_id] [smallint] NULL,
	[object_id] [int] NULL,
	[table_name] [varchar](255) NULL,
	[schema_id] [int] NULL,
	[index_id] [int] NULL,
	[index_name] [varchar](255) NULL,
	[avg_frag_percent_before] [float] NULL,
	[fragment_count_before] [bigint] NULL,
	[pages_count_before] [bigint] NULL,
	[fill_factor] [tinyint] NULL,
	[partition_num] [int] NULL,
	[avg_frag_percent_after] [float] NULL,
	[fragment_count_after] [bigint] NULL,
	[pages_count_after] [bigint] NULL,
	[action] [varchar](4000) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


USE [dba_tasks]

GO

----------------------------------------------------------------------------
 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Outdated_statistics](
                [proc_id] [int] NULL,
                [start_time] [datetime] NULL,
                [end_time] [datetime] NULL,
                [database_id] [smallint] NULL,
                [object_id] [int] NULL,
                [table_name] [sysname] NOT NULL,
                [statistic_name] [sysname] NOT NULL,
				[schema_name] [sysname] NOT NULL,
                [Last_updated] [datetime] NULL,
                [Rows_modified_before] [int] NULL,				
                [Rows_modified_after] [int] NULL,
				[action] [varchar](4000) NULL)
GO
SET ANSI_PADDING OFF
GO