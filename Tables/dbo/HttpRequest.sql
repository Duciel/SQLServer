USE [DBATOOLS]
GO

/****** Object:  Table [dbo].[HttpRequest]    Script Date: 29/05/2022 18:04:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[HttpRequest](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](500) NOT NULL,
	[Type] [nvarchar](50) NOT NULL,
	[URL] [nvarchar](max) NOT NULL,
	[Parameters] [nvarchar](max) NULL,
	[Headers] [nvarchar](max) NULL,
	[Timeout] [int] NULL,
	[AutoDecompress] [bit] NOT NULL,
	[ConvertToBase64] [bit] NOT NULL,
 CONSTRAINT [PK_HttpRequest] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[HttpRequest] ADD  CONSTRAINT [DF_Table_1_autoDecompress]  DEFAULT ((0)) FOR [AutoDecompress]
GO

ALTER TABLE [dbo].[HttpRequest] ADD  CONSTRAINT [DF_HttpRequest_ConvertToBase64]  DEFAULT ((0)) FOR [ConvertToBase64]
GO


