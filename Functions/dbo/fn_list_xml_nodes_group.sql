USE [DBATOOLS]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_list_xml_nodes_group]    Script Date: 29/05/2022 18:00:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexandre Blois
-- Create date: 27/03/2021
-- Description:	Returns all the nodes from an XML variable
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[fn_list_xml_nodes_group] (@p_DocHandle INT)
RETURNS TABLE 
AS
RETURN
(
	SELECT A.localname, 
		A.level,
		A.name,
		B.localname AS parentname,
		A.isColumn
	FROM [DBATOOLS].[dbo].[fn_list_xml_nodes] (@p_DocHandle) A
		LEFT JOIN [DBATOOLS].[dbo].[fn_list_xml_nodes] (@p_DocHandle) B ON B.id = A.parentid
	GROUP BY A.localname, A.level, A.name, B.localname, A.isColumn
)