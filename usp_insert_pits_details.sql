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
	PRINT 'Populate ['+ @pit_schema + '].[' + @pit_table + '] with current dataset'

	SET @sql_string = NULL
	SET @select_string = NULL
	SET @from_string = NULL
	SET @from_rowcount = 0
	SET @sql_string = 'WITH
					   satdetails
					   AS
						(
							SELECT * from ['+@sat_schema+'].['+@sat_table+'] WHERE loadenddate IS NULL
						)
						INSERT INTO ['+@pit_schema+'].['+@pit_table+'] 
						(
							['+@hub_table+'key]
							,['+@hub_table+'hashkey]
							,[snapshotdate]'

	PRINT 'Declaring pitcolumn_curs'
	DECLARE pitcolumn_curs CURSOR FOR
			SELECT pitcolumn, satcolumn
			FROM [metadata].[pitcolumns] 
			WHERE pitschema = @pit_schema AND pittable = @pit_table

	PRINT 'Opening pitcolumn_curs'
	OPEN pitcolumn_curs

	PRINT 'Fetching pitcolumn_curs'
	FETCH pitcolumn_curs INTO
		@pit_column, @sat_column

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		SET @from_rowcount = @from_rowcount + 1

		PRINT 'Looping pitcolumn_curs'

		SET @sql_string = @sql_string + ',['+@pit_column+']' 

		if @select_string IS NULL
		BEGIN
			SET @select_string = @select_string + ')
												   SELECT
													CONVERT(NVARCHAR(MAX),HASHBYTES(''SHA1'',CONCAT_WS(''::'', '''+@hub_table+''','''+@sat_table+''')),2) AS ['+@hub_table+'key] 
													,['+@hub_schema+'].['+@hub_table+'].'+@hub_column + 'AS ['+@hub_table+'hashkey]
												    ,GETDATE() AS [snapshotdate]
													,[A].['+@sat_column+'] AS ['''+@pit_column+''']'
		END
		ELSE
		BEGIN
			SET @select_string = @select_string + ',[A].['+@sat_column+'] AS ['''+@pit_column+''']'
		END

		if @from_string IS NULL
		BEGIN
			SET @from_string = @from_string + ' FROM satdetails AS [A]
												LEFT JOIN ['+@pit_schema+'].['+@pit_table+'] AS [B'+CONVERT(VARCHAR,@from_rowcount)+'] ON [A].hashkey = [B'+CONVERT(VARCHAR,@from_rowcount)+'].['+@hub_table+'key] '
													
		END
		ELSE
		BEGIN
			SET @from_string = @from_string + 'LEFT JOIN ['+@pit_schema+'].['+@pit_table+'] AS [B'+CONVERT(VARCHAR,@from_rowcount)+'] ON [A].hashkey = [B'+CONVERT(VARCHAR,@from_rowcount)+'].['+@hub_table+'key] '
		END

		PRINT 'Fetching next pitcolumn_curs'
		FETCH NEXT FROM pitcolumn_curs INTO
			@pit_column, @sat_column
	END

	CLOSE pitcolumn_curs
	DEALLOCATE pitcolumn_curs

	PRINT '1'
	PRINT @sql_string
	PRINT '2'
	PRINT @select_string
	PRINT '3'
	PRINT @from_string
	
	PRINT '4'
	SET @sql_string = @sql_string+@select_string+@from_string

	PRINT '5'
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
