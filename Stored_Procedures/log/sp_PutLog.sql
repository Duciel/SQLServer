USE [DBATOOLS]
GO
/****** Object:  StoredProcedure [log].[sp_PutLog]    Script Date: 29/05/2022 17:57:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [log].[sp_PutLog]	@p_BatchId BIGINT,
									@p_SystemId INT,
									@o_TypeLogId SMALLINT OUTPUT,
									@p_LogLevelTrace TINYINT,
									@p_LogLevelMessage TINYINT,
									@o_DateLastEventUTC DATETIME2(7) OUTPUT,
									@p_ObjectName sysname,
									@p_DatabaseName sysname = NULL,
									@p_SchemaName sysname = NULL,
									@p_ErrorMessage NVARCHAR(MAX) = NULL,
									@p_ErrorCode NVARCHAR(10) = NULL,
									@p_ErrorSeverity SMALLINT = NULL,
									@p_ErrorState SMALLINT = NULL,
									@p_UserMessage NVARCHAR(MAX) = NULL,
									@p_RunCommand NVARCHAR(MAX) = NULL,
									@p_TargetName NVARCHAR(256) = NULL
AS
BEGIN
	-- Get LogTime
	DECLARE @v_EventUTC DATETIME2(7) = GETUTCDATE();

	-- Only inserting if LogLevelTrace is higher than LogLevelMessage
	IF @p_LogLevelTrace >= @p_LogLevelMessage
	BEGIN
		-- Calculating duration since last event
		DECLARE @v_DurationMS BIGINT = DATEDIFF(MILLISECOND, @o_DateLastEventUTC, @v_EventUTC);

		-- If ErrorSeverity is higher than 11 we treat this as an error
		DECLARE @v_StatusId TINYINT = CASE WHEN @p_ErrorSeverity >= 11 THEN 1 ELSE 0 END;
		
		-- Truncating NVARCHAR(MAX) into NVARCHAR(4000)
		DECLARE @v_ErrorMessageTruncated NVARCHAR(4000) = TRY_CAST(@p_ErrorMessage AS NVARCHAR(4000));
		DECLARE @v_UserMessageTruncated NVARCHAR(4000) = TRY_CAST(@p_UserMessage AS NVARCHAR(4000));
		DECLARE @v_RunCommandTruncated NVARCHAR(4000) = TRY_CAST(@p_RunCommand AS NVARCHAR(4000));

		-- Inserting event
		INSERT INTO [DBATOOLS].[log].[TraceEvent] ([EventTimestampUTC], [BatchId], [SystemId], [TypeLogId], [LogLevel], [DurationMs], [ObjectName], [DatabaseName], [SchemaName], [StatusId], [ErrorMessage], [ErrorCode], [ErrorSeverity], [ErrorState], [UserMessage], [RunUser], [SystemPid], [RunCommand], [TargetName])
		VALUES (@v_EventUTC, @p_BatchId, @p_SystemId, @o_TypeLogId, @p_LogLevelMessage, @v_DurationMS, @p_ObjectName, @p_DatabaseName, @p_SchemaName, @v_StatusId, @v_ErrorMessageTruncated, @p_ErrorCode, @p_ErrorSeverity, @p_ErrorState, @v_UserMessageTruncated, ORIGINAL_LOGIN(), @@spid, @v_RunCommandTruncated, @p_TargetName);

		-- Increasing step count by 1
		SET @o_TypeLogId += 1;
	END

	-- Setting DateLastEvent to current Event
	SET @o_DateLastEventUTC = @v_EventUTC;
END