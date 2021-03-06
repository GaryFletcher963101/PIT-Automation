SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [metadata].[usp_insert_pit_details]
(
	@pit_schema VARCHAR(128),
	@pit_table VARCHAR(128),
	@hub_schema VARCHAR(128),
	@hub_table VARCHAR(128),
	@hub_column VARCHAR(128),
	@sat_schema VARCHAR(128),
	@sat_table VARCHAR(128)
)
AS
	DECLARE @sql_string VARCHAR(MAX)
	DECLARE @select_string VARCHAR(MAX)
	DECLARE @from_string VARCHAR(MAX)
	DECLARE @from_rowcount INTEGER

	DECLARE @pit_column VARCHAR(128)
	DECLARE @sat_column VARCHAR(128)

BEGIN
	
	PRINT 'usp_insert_pit_details Started@'+FORMAT(GETDATE(), 'yyyy-MM-dd hh:mm:ss')

	/* Populate with current dataset */
	PRINT 'Populate ['+ @pit_schema + '].[' + @pit_table + ']'

	PRINT 'Initialising variable'
	SET @sql_string = NULL
	SET @select_string = NULL
	SET @from_string = NULL
	SET @from_rowcount = 0

	PRINT 'Building initial sql string'
	SET @sql_string = 'WITH '+
					  'satdetails '+
					  'AS'+
					  '('+
						'SELECT * from ['+@sat_schema+'].['+@sat_table+'] WHERE loadenddate IS NULL'+
					  ')'+
					  'INSERT INTO ['+@pit_schema+'].['+@pit_table+']'+
					  '(' +
							'[masterhashkey]'+
							',[hashkey]'+
							',[loaddate]'+
							',[earliest]'+
							',[lastest]'

	PRINT 'Declaring pitcolumn_curs'
	PRINT 'pit_schema = '+@pit_schema
	PRINT 'pit_table = '+@pit_table

	DECLARE pitcolumn_curs CURSOR FOR
		SELECT pitcolumn, satcolumn
		FROM [metadata].[pitcolumns] 
		WHERE pitschema = @pit_schema 
		AND pittable = @pit_table

	PRINT 'Opening pitcolumn_curs'
	OPEN pitcolumn_curs

	PRINT 'Fetching pitcolumn_curs'
	FETCH pitcolumn_curs INTO
		@pit_column, @sat_column

	PRINT 'pit_column = '+@pit_column
	PRINT 'sat_column = '+@sat_column

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		SET @from_rowcount = @from_rowcount + 1

		PRINT 'Looping pitcolumn_curs'

		/* Add any extra columns from pt_columns table */
		IF @pit_column IS NOT NULL
		BEGIN
			SET @sql_string = @sql_string + ',['+@pit_column+']'
		END

		/* Build the SELECT sting */
		IF @select_string IS NULL
		BEGIN

			/* Add default caolumns */
			SET @select_string = @select_string + ') ' +
												  'SELECT ' +
												  '[A].['+@sat_column+'] AS [masterhashkey]' +
												  ',[A].['+@sat_column+'] AS [hashkey]' +
												  ',GETDATE() AS [loaddate]' +
												  ',1 AS [earliest]' +
												  ',1 AS [latest]'
		END
		ELSE
		/* Add extra columns from pit_columns */
		BEGIN
			IF @sat_column IS NOT NULL
			BEGIN
				SET @select_string = @select_string + ',[A].['+@sat_column+'] AS ['+@pit_column+']'
			END
		END

		/* Build the FROM clause */
		IF @from_string IS NULL
		BEGIN
			
			/* May have multiple satellites so use an incremental Alias */
			SET @from_string = @from_string + ' FROM satdetails AS [A]' +
											  ' LEFT JOIN ['+@pit_schema+'].['+@pit_table+'] AS [B'+CONVERT(VARCHAR,@from_rowcount)+'] ON [B'+CONVERT(VARCHAR,@from_rowcount)+'].[masterhashkey] = [A].hashkey'
													
		END
		ELSE
		BEGIN
			SET @from_string = @from_string + ' LEFT JOIN ['+@pit_schema+'].['+@pit_table+'] AS [B'+CONVERT(VARCHAR,@from_rowcount)+'] ON [B'+CONVERT(VARCHAR,@from_rowcount)+'].[masterhashkey] = [A].hashkey'
		END

		PRINT @from_string

		PRINT 'Fetching next pitcolumn_curs'
		FETCH NEXT FROM pitcolumn_curs INTO
			@pit_column, @sat_column
	END

	CLOSE pitcolumn_curs
	DEALLOCATE pitcolumn_curs

	PRINT '1'
	PRINT 'length sql_string = '+convert(varchar,len(@sql_string))
	PRINT 'Partial sql_string = '+@sql_string
	PRINT '2'
	PRINT 'length select_string = '+convert(varchar,len(@select_string))
	PRINT 'select_string = '+@select_string
	PRINT '3'
	PRINT 'length from_string = '+convert(varchar,len(@from_string))
	PRINT 'from_string = '+@from_string
	PRINT '4'
	SET @sql_string = @sql_string+@select_string+@from_string
	PRINT '5'
	PRINT 'length sql_string = '+convert(varchar,len(@sql_string))
	PRINT 'Insert table string = '+@sql_string
	PRINT '6'

	BEGIN TRY
		PRINT 'Executing SQL statement...'
		EXEC (@sql_string);
		PRINT 'Table [' + @pit_schema + '].[' + @pit_table + '] has been successfully Inserted into'
	END TRY
	BEGIN CATCH
		PRINT 'Error Inserting into table: ['+ @pit_schema + '].[' + @pit_table + ']' + CAST(ERROR_MESSAGE() AS VARCHAR(MAX))
	END CATCH

END
