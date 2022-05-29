USE [DBATOOLS]
GO
/****** Object:  StoredProcedure [dbo].[sp_HttpRequest]    Script Date: 29/05/2022 17:56:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alexandre Blois
-- Create date: 27/03/2021
-- Description:	Request an HTTP URL and store the results in the HttpRequestLog table
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_HttpRequest]	
		-- Technical parameters (mandatory)
		@p_BatchId BIGINT = NULL,
		@p_LogLevelTrace TINYINT = NULL,
		@p_SystemId INT = 0,

		-- User parameters (optional)
		@p_RequestMethod NVARCHAR(50) = NULL, -- Type of request (GET or POST)
		@p_URL NVARCHAR(4000) = NULL, -- URL of the request
		@p_Parameters NVARCHAR(4000) = NULL, -- Parameters of the request format : param1=value1&param2=value2...
		@p_Headers NVARCHAR(4000) = NULL, 
		@p_Timeout INT = 10000, -- Timeout duration in milliseconds
		@p_AutoDecompress BIT = 0, 
		@p_ConvertResponseToBas64 BIT = 0,
		@p_HttpRequestName NVARCHAR(500) = NULL -- Will fetch the other parameters from the HttpRequest table (overrides the other parameters if @p_URL is NULL)
AS
BEGIN
	/************************************************************************
	*							1a. User Variables							*
	*************************************************************************/
	DECLARE @p_TargetName NVARCHAR(256) = '[DBATOOLS].[dbo].[HttpRequestLog]';
	DECLARE @v_ID_Log BIGINT;
	DECLARE @v_ID_HttpRequest SMALLINT;

	
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
				+ ', @p_RequestMethod = ' + COALESCE('''' + @p_RequestMethod + '''', 'NULL') 
				+ ', @p_URL = ' + COALESCE('''' + @p_URL + '''', 'NULL') 
				+ ', @p_Parameters = ' + COALESCE('''' + @p_Parameters + '''', 'NULL') 
				+ ', @p_Headers = ' + COALESCE('''' + @p_Headers + '''', 'NULL') 
				+ ', @p_Timeout = ' + COALESCE(CAST(@p_Timeout AS VARCHAR(MAX)), 'NULL') 
				+ ', @p_AutoDecompress = ' + COALESCE(CAST(@p_AutoDecompress AS VARCHAR(MAX)), 'NULL') 
				+ ', @p_ConvertResponseToBas64 = ' + COALESCE(CAST(@p_ConvertResponseToBas64 AS VARCHAR(MAX)), 'NULL') 
				+ ', @p_HttpRequestName = ' + COALESCE('''' + @p_HttpRequestName + '''', 'NULL');

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
		IF @p_HttpRequestName IS NOT NULL AND @p_URL IS NULL
		BEGIN
			-- We get the parameters for this specific request
			SELECT	@v_ID_HttpRequest = [ID],
					@p_RequestMethod = [Type],
					@p_URL = [URL],
					@p_Parameters = [Parameters],
					@p_Headers = [Headers],
					@p_Timeout = [Timeout],
					@p_AutoDecompress = [AutoDecompress],
					@p_ConvertResponseToBas64 = [ConvertToBase64]
			FROM [DBATOOLS].[dbo].[HttpRequest]
			WHERE [Name] = @p_HttpRequestName
		END
		ELSE
		BEGIN
			SELECT	@v_ID_HttpRequest = [ID]
			FROM [DBATOOLS].[dbo].[HttpRequest]
			WHERE [Name] = @p_HttpRequestName
		END

		-- We insert the line to specify that we started the request
		INSERT INTO [DBATOOLS].[dbo].[HttpRequestLog] (ID_HttpRequest, Response, StartTime, EndTime, Status, ErrorMsg)
		VALUES (@v_ID_HttpRequest, NULL, GETDATE(), NULL, 'Running', NULL)

		-- We get the ID of the previously inserted line
		SET @v_ID_Log = SCOPE_IDENTITY();

		BEGIN TRY
			UPDATE [DBATOOLS].[dbo].[HttpRequestLog]
			SET [Response] = [DBATOOLS].[dbo].[clr_HttpRequest] (@p_RequestMethod, @p_URL, @p_Parameters, @p_Headers, @p_Timeout, @p_AutoDecompress, @p_ConvertResponseToBas64),
				[EndTime] = GETDATE(),
				[Status] = 'Finished'
			WHERE ID = @v_ID_Log;
		END TRY
		BEGIN CATCH
			UPDATE [DBATOOLS].[dbo].[HttpRequestLog]
			SET [EndTime] = GETDATE(),
				[Status] = 'Error',
				[ErrorMsg] = ERROR_MESSAGE()
			WHERE ID = @v_ID_Log;
			THROW;
		END CATCH
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