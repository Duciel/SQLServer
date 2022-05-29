USE [DBATOOLS]
GO
/****** Object:  UserDefinedFunction [dbo].[clr_HttpRequest]    Script Date: 29/05/2022 18:00:52 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE OR ALTER FUNCTION [dbo].[clr_HttpRequest](@requestMethod [nvarchar](50) = N'GET', @url [nvarchar](4000), @parameters [nvarchar](4000) = N'', @headers [nvarchar](4000) = N'', @timeout [int] = 60000, @autoDecompress [bit] = False, @convertResponseToBas64 [bit] = False)
RETURNS [xml] WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [ClrHttpRequest].[UserDefinedFunctions].[clr_http_request]