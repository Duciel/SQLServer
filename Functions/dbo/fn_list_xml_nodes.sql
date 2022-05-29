USE [DBATOOLS]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_list_xml_nodes]    Script Date: 29/05/2022 17:58:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexandre Blois
-- Create date: 27/03/2021
-- Description:	Returns all the nodes from an XML variable
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[fn_list_xml_nodes] (@p_DocHandle INT)
RETURNS TABLE 
AS
RETURN
(
	WITH base AS (
		SELECT A.id, 
			A.parentid, 
			A.localname,
			1 AS [Level],
			B.id AS [isColumnID],
			CASE WHEN B.id IS NOT NULL THEN 1 ELSE 0 END AS [isColumn]
		FROM OPENXML(@p_DocHandle, N'/') A
			LEFT JOIN OPENXML(@p_DocHandle, N'/') B ON A.id = B.parentid AND B.nodetype <> 1
		WHERE A.nodetype = 1
	),
	Xml_CTE AS (
		SELECT base.id, 
			base.parentid,
			'/' + base.localname AS localname,
			base.Level,
			base.isColumn,
			base.localname AS name
		FROM base
		WHERE base.parentid IS NULL

		UNION ALL

		SELECT base.id, 
			base.parentid, 
			Xml_CTE.localname + '/' + base.localname AS localname,
			Xml_CTE.Level + 1 AS [Level],
			CASE WHEN base.isColumnID IS NOT NULL THEN 1 ELSE 0 END AS [isColumn],
			base.localname AS name
		FROM base
			INNER JOIN Xml_CTE ON Xml_CTE.id = base.parentid
	),
	XML_CTE_group AS (
		SELECT id,
			parentid,
			localname,
			level,
			MAX(isColumn) AS [isColumn],
			name
		FROM Xml_CTE
		GROUP BY id, parentid, localname, level, name
	)
	SELECT id,
		parentid,
		localname,
		level,
		isColumn,
		name,
		ROW_NUMBER() OVER(PARTITION BY localname ORDER BY id) AS Nb
	FROM XML_CTE_group
)