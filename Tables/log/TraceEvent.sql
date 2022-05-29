USE [DBATOOLS]
GO

/****** Object:  Table [log].[TraceEvent]    Script Date: 29/05/2022 18:06:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [log].[TraceEvent](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[EventTimestampUTC] [datetime2](7) NOT NULL,
	[BatchId] [bigint] NOT NULL,
	[SystemId] [int] NOT NULL,
	[TypeLogId] [smallint] NOT NULL,
	[LogLevel] [tinyint] NOT NULL,
	[DurationMs] [bigint] NOT NULL,
	[ObjectName] [sysname] NOT NULL,
	[DatabaseName] [sysname] NULL,
	[SchemaName] [sysname] NULL,
	[StatusId] [tinyint] NOT NULL,
	[ErrorMessage] [nvarchar](4000) NULL,
	[ErrorCode] [nvarchar](10) NULL,
	[ErrorSeverity] [smallint] NULL,
	[ErrorState] [smallint] NULL,
	[UserMessage] [nvarchar](4000) NULL,
	[RunUser] [sysname] NULL,
	[SystemPid] [int] NULL,
	[RunCommand] [nvarchar](4000) NULL,
	[TargetName] [nvarchar](256) NULL
) ON [PRIMARY]
GO


