SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [metadata].[usp_update_pit_details]
(
	@pit_schema VARCHAR(128),
	@pit_table VARCHAR(128),
	@hub_schema VARCHAR(128),
	@hub_table VARCHAR(128),
	@sat_schema VARCHAR(128),
	@sat_table VARCHAR(128),
	@sat_column VARCHAR(128)
)
AS
	DECLARE @sql_string VARCHAR(MAX)

BEGIN

	PRINT 'usp_update_pit_details Started@'+FORMAT(GETDATE(), 'yyyy-MM-dd hh:mm:ss')

	/* Now we need to populate from the satellite */
	SET @sql_string = NULL
	SET @sql_string = 'UPDATE ['+@pit_schema+'].['+@pit_table+'] ' +
					  'SET '+
					  '['+@sat_column+'] =  (SELECT '+@sat_column+' FROM ['+@sat_schema+'].['+@sat_table+'] WHERE loadenddate IS NULL ORDER BY loaddate),' 

	PRINT 'Update table string = ' + @sql_string

	BEGIN TRY
		PRINT 'Executing SQL statement...'
		EXEC (@sql_string);
		PRINT 'Table [' + @pit_schema + '].[' + @pit_table + '] has been successfully Updated'
	END TRY
	BEGIN CATCH
		PRINT 'Error Updating table: ['+ @pit_schema + '].[' + @pit_table + ']' + CAST(ERROR_MESSAGE() AS VARCHAR(MAX))
	END CATCH

END