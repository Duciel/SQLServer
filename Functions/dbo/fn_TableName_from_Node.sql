USE [DBATOOLS]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_TableName_from_Node]    Script Date: 29/05/2022 18:01:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexandre Blois
-- Create date: 28/03/2021
-- Description:	
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[fn_TableName_from_Node] (@p_TablePrefix SYSNAME, @p_Node SYSNAME)
RETURNS SYSNAME
BEGIN
	RETURN COALESCE(@p_TablePrefix, '') + COALESCE(REPLACE(@p_Node, '/', '_'), '')
END
