SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [metadata].[usp_alter_pits_ddl]
(
	@pit_schema VARCHAR(128),
	@pit_table VARCHAR(128),
	@pit_column VARCHAR(128),
	@error_code INTEGER OUTPUT
)
AS
	DECLARE @sql_string VARCHAR(MAX)

BEGIN
	
	/*** Run through main processing tables for this process ***/
	PRINT 'usp_alter_pits_ddl Started@'+FORMAT(GETDATE(), 'yyyy-MM-dd hh:mm:ss')

	PRINT 'Building SQL statement to alter table and add the column' 

	SET @sql_string = NULL
	SET @sql_string = 'ALTER TABLE [' + @pit_schema + '].[' + @pit_table + '] ' +
					  'ADD '

	DECLARE pitcolumn_curs CURSOR FOR
		SELECT pitcolumn 
		FROM [metadata].[pitcolumns] 
		WHERE pitschema = @pit_schema AND pittable = @pit_table

	OPEN pitcolumn_curs

	FETCH pitcolumn_curs INTO
		@pit_column

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @sql_string = @sql_string + 
						 ',['+@pit_column+'] NVARCHAR(4000)'
						 
		FETCH NEXT FROM pitcolumn_curs INTO
			@pit_column

	END

	PRINT 'Alter table string = '+@sql_string

	BEGIN TRY
		PRINT 'Executing SQL statement...'
		EXEC (@sql_string);
		SET @error_code = 2
		PRINT 'Table [' + @pit_schema + '].[' + @pit_table + '] has been successfully altered'
	END TRY
	BEGIN CATCH
		SET @error_code = 4
		PRINT 'Error altering table: ' + CAST(ERROR_MESSAGE() AS VARCHAR(MAX))
	END CATCH

END

