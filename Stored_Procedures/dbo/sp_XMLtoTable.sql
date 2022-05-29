USE [DBATOOLS]
GO
/****** Object:  StoredProcedure [dbo].[sp_XMLtoTable]    Script Date: 29/05/2022 17:56:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_XMLtoTable]	
		-- Technical parameters (mandatory)
		@p_BatchId BIGINT = NULL,
		@p_LogLevelTrace TINYINT = NULL,
		@p_SystemId INT = 0,

		-- User parameters (optional)
		@p_XML XML,
		@p_Database SYSNAME = NULL,
		@p_Schema SYSNAME = 'dbo',
		@p_TablePrefix SYSNAME = '',
		@p_DataCompression NVARCHAR(50) = 'ROW'
AS
BEGIN
	/************************************************************************
	*							1a. User Variables							*
	*************************************************************************/
	DECLARE @p_TargetName NVARCHAR(256) = '';

	
	/************************************************************************
	*							1b. Tech Variables							*
	*************************************************************************/
	DECLARE @v_ErrorCode INT;
	DECLARE @v_ErrorSeverity INT;
	DECLARE @v_ErrorState INT;
	DECLARE @v_ErrorMessage NVARCHAR(4000);
	DECLARE @v_UserMessage NVARCHAR(4000);
	DECLARE @v_RunCommand NVARCHAR(MAX);
	DECLARE @v_DatabaseName sysname = DB_NAME();
	DECLARE @v_TypeLogId SMALLINT = 1; -- Numéro du premier évènement;
	DECLARE @v_DateFirstEventUTC DATETIME2(7) = GETUTCDATE();
	DECLARE @v_DateLastEventUTC DATETIME2(7) = @v_DateFirstEventUTC;
	DECLARE @v_ObjectName SYSNAME = OBJECT_NAME(@@PROCID);
	DECLARE @v_SchemaName SYSNAME = OBJECT_SCHEMA_NAME(@@PROCID);
	DECLARE @v_LastTypeLogId INT = 9999;

	-- Log Level variables
	DECLARE @c_LOGLEVEL_CRITICAL	TINYINT = 1;
	DECLARE @c_LOGLEVEL_ERROR		TINYINT = 2;
	DECLARE @c_LOGLEVEL_WARNING		TINYINT = 3;
	DECLARE @c_LOGLEVEL_INFO		TINYINT = 4;
	DECLARE @c_LOGLEVEL_VERBOSE		TINYINT = 5;
	DECLARE @c_LOGLEVEL_DEBUG		TINYINT = 6;
	

	/************************************************************************
	*							2. Setting values							*
	*************************************************************************/
	-- If we didnt got a BatchID we generate a new one
	IF @p_BatchId IS NULL
		SET @p_BatchId = NEXT VALUE FOR [DBATOOLS].[log].[SEQ_LOG_BATCHID];

		 
	/************************************************************************
	*							3. Get LogLevel								*
	*************************************************************************/
	BEGIN TRY
		IF @p_LogLevelTrace IS NULL
		BEGIN
			SELECT @p_LogLevelTrace = [DBATOOLS].[log].[fn_GetParamLogLevel](@v_DatabaseName)

			SET @v_UserMessage = 'Executing function [DBATOOLS].[log].[fn_GetParamLogLevel](''' + @v_DatabaseName + '''), return result : @p_LogLevelTrace = ' + TRY_CAST(@p_LogLevelTrace AS VARCHAR(100));
			EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_RunCommand = @v_RunCommand, @p_TargetName = @p_TargetName, @p_UserMessage = @v_UserMessage,
										@p_LogLevelMessage = @c_LOGLEVEL_VERBOSE;
		END
	END TRY
	BEGIN CATCH
		SET @v_UserMessage = 'Error while getting LogLevel.';
		SELECT @v_ErrorMessage = ERROR_MESSAGE(), @v_ErrorCode = ERROR_NUMBER(), @v_ErrorSeverity = ERROR_SEVERITY(), @v_ErrorState = ERROR_STATE();
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_ErrorMessage = @v_ErrorMessage, @p_ErrorCode = @v_ErrorCode, @p_ErrorSeverity = @v_ErrorSeverity, @p_ErrorState = @v_ErrorState, @p_UserMessage = @v_UserMessage, @p_TargetName = @p_TargetName,
									@p_LogLevelMessage = @c_LOGLEVEL_ERROR;
	
		SET @v_UserMessage = 'Stored procedure ' + QUOTENAME(@v_SchemaName) + '.' + QUOTENAME(@v_ObjectName) + ' finished with an error.';
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_LastTypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_ErrorMessage = @v_ErrorMessage, @p_ErrorCode = @v_ErrorCode, @p_ErrorSeverity = @v_ErrorSeverity, @p_ErrorState = @v_ErrorState, @p_UserMessage = @v_UserMessage, @p_TargetName = @p_TargetName,
									@p_LogLevelMessage = @c_LOGLEVEL_INFO;
		THROW;
	END CATCH


	/************************************************************************
	*							4. Get Params								*
	*************************************************************************/
	BEGIN TRY
		SET @v_RunCommand = 'EXEC ' + QUOTENAME(@v_DatabaseName) + '.' + QUOTENAME(@v_SchemaName) + '.' + QUOTENAME(@v_ObjectName)
				+ ' @p_BatchId = ' + COALESCE(CAST(@p_BatchId AS VARCHAR(MAX)), 'NULL')
				+ ', @p_LogLevelTrace = ' + COALESCE(CAST(@p_LogLevelTrace AS VARCHAR(MAX)), 'NULL')
				+ ', @p_SystemId = ' + COALESCE(CAST(@p_SystemId AS VARCHAR(MAX)), 'NULL')
				+ ', @p_XML = ' + COALESCE(CAST(@p_XML AS VARCHAR(MAX)), 'NULL')
				+ ', @p_Database = ' + COALESCE('''' + @p_Database + '''', 'NULL') 
				+ ', @p_Schema = ' + COALESCE('''' + @p_Schema + '''', 'NULL') 
				+ ', @p_TablePrefix = ' + COALESCE('''' + @p_TablePrefix + '''', 'NULL')
				+ ', @p_DataCompression = ' + COALESCE('''' + @p_DataCompression + '''', 'NULL');
				
		SET @v_UserMessage = 'Getting execute command for stored procedure : ' + @v_RunCommand;
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_RunCommand = @v_RunCommand, @p_TargetName = @p_TargetName, @p_UserMessage = @v_UserMessage,
									@p_LogLevelMessage = @c_LOGLEVEL_VERBOSE;
	END TRY
	BEGIN CATCH
		SET @v_UserMessage = 'Error while getting parameters.';
		SELECT @v_ErrorMessage = ERROR_MESSAGE(), @v_ErrorCode = ERROR_NUMBER(), @v_ErrorSeverity = ERROR_SEVERITY(), @v_ErrorState = ERROR_STATE();
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_ErrorMessage = @v_ErrorMessage, @p_ErrorCode = @v_ErrorCode, @p_ErrorSeverity = @v_ErrorSeverity, @p_ErrorState = @v_ErrorState, @p_UserMessage = @v_UserMessage, @p_TargetName = @p_TargetName,
									@p_LogLevelMessage = @c_LOGLEVEL_ERROR;
	
		SET @v_UserMessage = 'Stored procedure ' + QUOTENAME(@v_SchemaName) + '.' + QUOTENAME(@v_ObjectName) + ' finished with an error.';
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_LastTypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_ErrorMessage = @v_ErrorMessage, @p_ErrorCode = @v_ErrorCode, @p_ErrorSeverity = @v_ErrorSeverity, @p_ErrorState = @v_ErrorState, @p_UserMessage = @v_UserMessage, @p_TargetName = @p_TargetName,
									@p_LogLevelMessage = @c_LOGLEVEL_INFO;
		THROW;
	END CATCH
	

	/************************************************************************
	*							5. Check Param								*
	*************************************************************************/
	BEGIN TRY
		EXEC [DBATOOLS].[log].[sp_CheckParams]	@p_RunCommand = @v_RunCommand, 
											@p_ProcId = @@PROCID,
											@p_DatabaseName = @v_DatabaseName;

		SET @v_UserMessage = 'Execution de la procédure [DBATOOLS].[log].[sp_CheckParams]';
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_RunCommand = @v_RunCommand, @p_TargetName = @p_TargetName, @p_UserMessage = @v_UserMessage,
									@p_LogLevelMessage = @c_LOGLEVEL_VERBOSE;
	END TRY
	BEGIN CATCH
		SET @v_UserMessage = 'Error while verifying parameters.';
		SELECT @v_ErrorMessage = ERROR_MESSAGE(), @v_ErrorCode = ERROR_NUMBER(), @v_ErrorSeverity = ERROR_SEVERITY(), @v_ErrorState = ERROR_STATE();
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_ErrorMessage = @v_ErrorMessage, @p_ErrorCode = @v_ErrorCode, @p_ErrorSeverity = @v_ErrorSeverity, @p_ErrorState = @v_ErrorState, @p_UserMessage = @v_UserMessage, @p_TargetName = @p_TargetName,
									@p_LogLevelMessage = @c_LOGLEVEL_ERROR;
	
		SET @v_UserMessage = 'Stored procedure ' + QUOTENAME(@v_SchemaName) + '.' + QUOTENAME(@v_ObjectName) + ' finished with an error.';
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_LastTypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_ErrorMessage = @v_ErrorMessage, @p_ErrorCode = @v_ErrorCode, @p_ErrorSeverity = @v_ErrorSeverity, @p_ErrorState = @v_ErrorState, @p_UserMessage = @v_UserMessage, @p_TargetName = @p_TargetName,
									@p_LogLevelMessage = @c_LOGLEVEL_INFO;
		THROW;
	END CATCH


	/************************************************************************
	*							99. Log Start								*
	*************************************************************************/
	SET @v_TypeLogId = 99;
	SET @v_UserMessage = 'Executing stored procedure : ' + QUOTENAME(@v_SchemaName) + '.' + QUOTENAME(@v_ObjectName);
	EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_RunCommand = @v_RunCommand, @p_TargetName = @p_TargetName, @p_UserMessage = @v_UserMessage,
								@p_LogLevelMessage = @c_LOGLEVEL_INFO;
	

	/************************************************************************
	*							100. Start of procedure						*
	*************************************************************************/
	BEGIN TRY
		-- Setting default values if NULL
		IF @p_Database IS NULL
			SET @p_Database = DB_NAME();

		IF @p_Schema IS NULL
			SET @p_Schema = 'dbo';

		IF @p_TablePrefix IS NULL
			SET @p_TablePrefix = '';

		IF @p_DataCompression IS NULL
			SET @p_DataCompression = 'ROW';

		-- Getting DocHandle from XML
		DECLARE @v_docHandle int; 
		EXEC sp_xml_preparedocument @v_docHandle OUTPUT, @p_XML; 

		DECLARE @v_SQL NVARCHAR(MAX);

		-- Looping on each node having child nodes
		DECLARE table_cursor CURSOR FOR 
		SELECT DISTINCT 'IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@p_Database) + '.sys.tables 
					INNER JOIN ' + QUOTENAME(@p_Database) + '.sys.schemas ON schemas.schema_id = tables.schema_id
				WHERE schemas.name = ''' + @p_Schema + '''
					AND tables.name = ''' + [DBATOOLS].[dbo].[fn_TableName_from_Node](@p_TablePrefix, A.localname) + ''')
	CREATE TABLE ' + QUOTENAME(@p_Database) + '.' + QUOTENAME(@p_Schema) + '.' + QUOTENAME([DBATOOLS].[dbo].[fn_TableName_from_Node](@p_TablePrefix, A.localname)) + ' 
		(ID BIGINT IDENTITY(1,1) NOT NULL, ' + -- Adding PK
		'ID_' + [DBATOOLS].[dbo].[fn_TableName_from_Node](@p_TablePrefix, A.parentname) + ' BIGINT NOT NULL) ' + -- Adding FK to parent table
		'WITH (DATA_COMPRESSION = ' + @p_DataCompression + ');' 
		FROM [DBATOOLS].[dbo].[fn_list_xml_nodes_group] (@v_docHandle) A
			LEFT JOIN [DBATOOLS].[dbo].[fn_list_xml_nodes_group] (@v_docHandle) B ON B.parentname = A.localname AND B.level = A.level + 1
		WHERE B.localname IS NOT NULL;

		OPEN table_cursor;
		FETCH NEXT FROM table_cursor INTO @v_SQL;

		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			--SELECT @v_SQL;
			EXEC sp_executesql @v_SQL;
			FETCH NEXT FROM table_cursor INTO @v_SQL;
		END 

		CLOSE table_cursor;
		DEALLOCATE table_cursor;

		-- Looping on each children having a parent
		DECLARE column_cursor CURSOR FOR 
		SELECT 'IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@p_Database) + '.sys.columns
					INNER JOIN ' + QUOTENAME(@p_Database) + '.sys.tables ON tables.object_id = columns.object_id
					INNER JOIN ' + QUOTENAME(@p_Database) + '.sys.schemas ON schemas.schema_id = tables.schema_id
				WHERE schemas.name = ''' + @p_Schema + '''
					AND tables.name = ''' + [DBATOOLS].[dbo].[fn_TableName_from_Node](@p_TablePrefix, A.localname) + '''
					AND columns.name = ''' + B.name + ''')
	ALTER TABLE ' + QUOTENAME(@p_Database) + '.' + QUOTENAME(@p_Schema) + '.' + QUOTENAME(@p_TablePrefix + REPLACE(A.localname, '/', '_')) + ' ADD ' + QUOTENAME(B.name) + ' NVARCHAR(MAX);'
		FROM [DBATOOLS].[dbo].[fn_list_xml_nodes_group] (@v_docHandle) A
			INNER JOIN [DBATOOLS].[dbo].[fn_list_xml_nodes_group] (@v_docHandle) B ON B.parentname = A.localname AND B.level = A.level + 1
		WHERE B.isColumn = 1

		OPEN column_cursor;
		FETCH NEXT FROM column_cursor INTO @v_SQL;
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			--SELECT @v_SQL;
			EXEC sp_executesql @v_SQL;
			FETCH NEXT FROM column_cursor INTO @v_SQL;
		END 

		CLOSE column_cursor;
		DEALLOCATE column_cursor;
	END TRY
	BEGIN CATCH
		SET @v_UserMessage = 'Error while running.';
		SELECT @v_ErrorMessage = ERROR_MESSAGE(), @v_ErrorCode = ERROR_NUMBER(), @v_ErrorSeverity = ERROR_SEVERITY(), @v_ErrorState = ERROR_STATE();
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_ErrorMessage = @v_ErrorMessage, @p_ErrorCode = @v_ErrorCode, @p_ErrorSeverity = @v_ErrorSeverity, @p_ErrorState = @v_ErrorState, @p_UserMessage = @v_UserMessage, @p_TargetName = @p_TargetName,
									@p_LogLevelMessage = @c_LOGLEVEL_ERROR;
	
		SET @v_UserMessage = 'Stored procedure ' + QUOTENAME(@v_SchemaName) + '.' + QUOTENAME(@v_ObjectName) + ' finished with an error.';
		EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_TypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_ErrorMessage = @v_ErrorMessage, @p_ErrorCode = @v_ErrorCode, @p_ErrorSeverity = @v_ErrorSeverity, @p_ErrorState = @v_ErrorState, @p_UserMessage = @v_UserMessage, @p_TargetName = @p_TargetName,
									@p_LogLevelMessage = @c_LOGLEVEL_INFO;
		THROW;
	END CATCH


	/************************************************************************
	*							9999. End Log								*
	*************************************************************************/
	SET @v_UserMessage = 'Stored procedure ' + QUOTENAME(@v_SchemaName) + '.' + QUOTENAME(@v_ObjectName) + ' finished with success.';
	EXEC [DBATOOLS].[log].[sp_PutLog]	@p_BatchId = @p_BatchId, @p_SystemId = @p_SystemId, @o_TypeLogId = @v_LastTypeLogId OUTPUT, @p_LogLevelTrace = @p_LogLevelTrace, @o_DateLastEventUTC = @v_DateLastEventUTC, @p_ObjectName = @v_ObjectName, @p_DatabaseName = @v_DatabaseName, @p_SchemaName = @v_SchemaName, @p_RunCommand = @v_RunCommand, @p_TargetName = @p_TargetName, @p_UserMessage = @v_UserMessage, 
								@p_LogLevelMessage = @c_LOGLEVEL_INFO;
END