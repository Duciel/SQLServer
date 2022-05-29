USE [DBATOOLS]
GO
/****** Object:  UserDefinedFunction [log].[fn_GetParamLogLevel]    Script Date: 29/05/2022 18:02:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alexandre Blois
-- Create date: 28/03/2021
-- Description:	
-- =============================================
CREATE OR ALTER FUNCTION [log].[fn_GetParamLogLevel]	(@p_DatabaseName NVARCHAR(128) = NULL)
RETURNS TINYINT
AS
BEGIN
	RETURN TRY_CAST([DBATOOLS].[log].[fn_GetParam](@p_DatabaseName, 'LogLevel') AS TINYINT);
END