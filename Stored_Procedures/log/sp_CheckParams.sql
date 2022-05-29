USE [DBATOOLS]
GO
/****** Object:  StoredProcedure [log].[sp_CheckParams]    Script Date: 29/05/2022 17:57:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [log].[sp_CheckParams]	@p_RunCommand NVARCHAR(MAX),
										@p_ProcId INT,
										@p_DatabaseName SYSNAME
AS
BEGIN
	DECLARE @v_ParamName sysname;
	DECLARE @v_Check BIT = 1;

	-- Getting list of params for stored procedure
	DECLARE @v_SQL NVARCHAR(MAX) = '
	SELECT name
	FROM ' + QUOTENAME(@p_DatabaseName) + '.sys.parameters
	WHERE object_id = ' + CONVERT(NVARCHAR, @p_ProcId);

	-- Storing params in temp table
	CREATE TABLE #sp_params (name sysname)
	INSERT INTO #sp_params
	EXEC sp_executesql @v_SQL;

	-- Looping on each param to check missing ones
	DECLARE cursor_param CURSOR FOR
	SELECT name
	FROM #sp_params

	OPEN cursor_param;
	FETCH NEXT FROM cursor_param INTO @v_ParamName;
	WHILE @@fetch_status = 0
	BEGIN
		-- On regarde si la chaîne passée en paramètre contient le nom du paramètre
		SET @v_Check = CASE WHEN @p_RunCommand LIKE '%' + @v_ParamName + '%' THEN 1 ELSE 0 END

		-- Si on a trouvé un paramètre manquant on peut arrêter
		IF @v_Check = 0
		BEGIN
			DECLARE @v_ErrorMessage NVARCHAR(4000) = 'Missing parameter : ' + @v_ParamName;
			RAISERROR(@v_ErrorMessage, 16, 1);
		END

		FETCH NEXT FROM cursor_param INTO @v_ParamName;
	END
	CLOSE cursor_param;
	DEALLOCATE cursor_param;
END