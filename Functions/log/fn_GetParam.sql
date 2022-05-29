USE [DBATOOLS]
GO
/****** Object:  UserDefinedFunction [log].[fn_GetParam]    Script Date: 29/05/2022 18:02:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexandre Blois
-- Create date: 28/03/2021
-- Description:	
-- =============================================
CREATE OR ALTER FUNCTION [log].[fn_GetParam]	(@p_DatabaseName NVARCHAR(128),
									@p_ParamName NVARCHAR(1000))
RETURNS NVARCHAR(1000)
AS
BEGIN
	DECLARE @v_ParamValue NVARCHAR(MAX) = NULL;
	SELECT @v_ParamValue = [ParamValue]
	FROM [log].[Params]
	WHERE [ParamName] = @p_ParamName
		AND [DatabaseName] = @p_DatabaseName;

	-- Si on n'a pas réussi à récupérer la valeur pour la base renseignée, on récupère la valeur pour toutes les bases par défaut "*"
	IF @v_ParamValue IS NULL
		SELECT @v_ParamValue = [ParamValue]
		FROM [log].[Params]
		WHERE [ParamName] = @p_ParamName
			AND [DatabaseName] = '*';

	RETURN @v_ParamValue;
END