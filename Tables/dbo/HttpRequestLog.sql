USE [DBATOOLS]
GO

/****** Object:  Table [dbo].[HttpRequestLog]    Script Date: 29/05/2022 18:05:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[HttpRequestLog](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ID_HttpRequest] [smallint] NULL,
	[Response] [xml] NULL,
	[StartTime] [datetime2](7) NOT NULL,
	[EndTime] [datetime2](7) NULL,
	[Status] [nvarchar](50) NOT NULL,
	[ErrorMsg] [nvarchar](max) NULL,
 CONSTRAINT [PK_HttpRequestLog] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[HttpRequestLog]  WITH CHECK ADD  CONSTRAINT [FK_HttpRequest] FOREIGN KEY([ID_HttpRequest])
REFERENCES [dbo].[HttpRequest] ([ID])
GO

ALTER TABLE [dbo].[HttpRequestLog] CHECK CONSTRAINT [FK_HttpRequest]
GO


