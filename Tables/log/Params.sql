USE [DBATOOLS]
GO

/****** Object:  Table [log].[Params]    Script Date: 29/05/2022 18:06:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [log].[Params](
	[DatabaseName] [nvarchar](128) NOT NULL,
	[ParamName] [nvarchar](128) NOT NULL,
	[ParamValue] [nvarchar](1000) NULL,
 CONSTRAINT [PK_PARAMS] PRIMARY KEY CLUSTERED 
(
	[DatabaseName] ASC,
	[ParamName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


