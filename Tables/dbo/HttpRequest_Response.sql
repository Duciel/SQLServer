USE [DBATOOLS]
GO

/****** Object:  Table [dbo].[HttpRequest_Response]    Script Date: 29/05/2022 18:04:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[HttpRequest_Response](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ID_HttpRequest] [bigint] NOT NULL,
	[Body] [nvarchar](max) NULL,
	[ContentLength] [nvarchar](max) NULL,
	[ContentType] [nvarchar](max) NULL,
	[CookiesCount] [nvarchar](max) NULL,
	[HeadersCount] [nvarchar](max) NULL,
	[IsFromCache] [nvarchar](max) NULL,
	[IsMutuallyAuthenticated] [nvarchar](max) NULL,
	[LastModified] [nvarchar](max) NULL,
	[Method] [nvarchar](max) NULL,
	[ProtocolVersion] [nvarchar](max) NULL,
	[ResponseUri] [nvarchar](max) NULL,
	[Server] [nvarchar](max) NULL,
	[StatusCode] [nvarchar](max) NULL,
	[StatusDescription] [nvarchar](max) NULL,
	[StatusNumber] [nvarchar](max) NULL,
	[SupportsHeaders] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


