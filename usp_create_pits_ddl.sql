SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [metadata].[usp_create_pits_ddl]
(
	@pit_schema VARCHAR(126),
	@pit_table VARCHAR(126),
	@hub_table VARCHAR(126),
	@error_code INTEGER OUTPUT

)
AS
	DECLARE @sql_string VARCHAR(MAX)
	
	DECLARE @pit_column VARCHAR(128)

BEGIN

	/*** Run through main processing tables for this process ***/
	PRINT 'usp_create_pits_ddl Started@'+FORMAT(GETDATE(), 'yyyy-MM-dd hh:mm:ss')

	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @pit_schema  AND TABLE_NAME = @pit_table)
	BEGIN

		SET @sql_string = 'CREATE TABLE ['+@pit_schema+'].['+@pit_table+']' +
						   '(' +
						   '[masterhashkey] [NVARCHAR](4000) NULL' + -- PRIMARY KEY,' +
						   ',[hashkey] [NVARCHAR](4000) NULL' + -- FOREIGN KEY REFERENCES ['+@hub_schema+'].['+@hub_table+'](['+@hub_column+']),' +
						   ',[loaddate] [DATETIME] NULL' +
						   ',[earliest] [INT] NULL' +
						   ',[latest] [INT] NULL'

		DECLARE pitcolumn_curs CURSOR FOR
			SELECT pitcolumn 
			FROM [metadata].[pitcolumns] 
			WHERE pitschema = @pit_schema AND pittable = @pit_table

		OPEN pitcolumn_curs

		FETCH pitcolumn_curs INTO
			@pit_column

		WHILE @@FETCH_STATUS = 0
		BEGIN
		
			SET @sql_string = @sql_string + ',['+@pit_column+'] [NVARCHAR](4000)'

			FETCH NEXT FROM pitcolumn_curs INTO
				@pit_column

		END

		SET @sql_string = @sql_string + ') ON [PRIMARY]'

		PRINT 'Create table string = '+@sql_string

		BEGIN TRY
			PRINT 'Executing SQL statement...'
			EXEC (@sql_string);
			SET @error_code = 1
			PRINT 'Table [' + @pit_schema + '].[' + @pit_table + '] has been successfully created'
		END TRY
		BEGIN CATCH
			PRINT 'Error creating table: ['+ @pit_schema + '].[' + @pit_table + ']' + CAST(ERROR_MESSAGE() AS VARCHAR(MAX))
			SET @error_code = 3
		END CATCH

	END
	/* Check if the column exists. Add if it doesnt */
	ELSE IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @pit_schema AND TABLE_NAME = @pit_table AND COLUMN_NAME = @pit_column)
	BEGIN
		EXEC [metadata].[usp_alter_pits_ddl] @pit_schema, @pit_table, @pit_column, @error_code OUTPUT

	END

	CLOSE pitcolumn_curs
	DEALLOCATE pitcolumn_curs

END
