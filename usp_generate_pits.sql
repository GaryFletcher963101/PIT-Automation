SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [metadata].[usp_generate_pits]
AS
	DECLARE @sql_string VARCHAR(MAX)

	DECLARE @hub_schema VARCHAR(126)
	DECLARE @hub_table VARCHAR(126)
	DECLARE @sat_schema VARCHAR(126)
	DECLARE @sat_table VARCHAR(126)
	DECLARE @hub_column VARCHAR(126)
	DECLARE @sat_column VARCHAR(126)

	DECLARE @pit_schema VARCHAR(126)
	DECLARE @pit_table VARCHAR(126)

	DECLARE @error_code INTEGER = 0 

BEGIN
	
	/*** Run through main processing tables for this process ***/
	PRINT 'usp_generate_pits Started@'+FORMAT(GETDATE(), 'yyyy-MM-dd hh:mm:ss')
	PRINT 'DECLARING pitdetails_curs for UPDATE'

	/* Job Cursor for this run */
	DECLARE pitdetails_curs CURSOR FOR
	SELECT hubschema, hubtable, satschema, sattable, hubcolumn, satcolumn, pitschema, pittable
	FROM metadata.pitdetails
	WHERE completed = 0
	ORDER BY pittable DESC
	FOR UPDATE

	open pitdetails_curs

	/* Fetch the first record from the cursor */
	PRINT 'FETCHING Initial pitdetails_curs record'
	FETCH NEXT FROM pitdetails_curs INTO
		@hub_schema, @hub_table, @sat_schema, @sat_table, @hub_column, @sat_column, @pit_schema, @pit_table

	WHILE @@FETCH_STATUS = 0
	BEGIN

		PRINT 'hub_schema = '+@hub_schema
		PRINT 'hub_table = '+@hub_table
		PRINT 'sat_schema = '+@sat_schema
		PRINT 'sat_table = '+@sat_table
		PRINT 'hub_column = '+@hub_column
		PRINT 'sat_column = '+@sat_column
		PRINT 'pit_schema = '+@pit_schema
		PRINT 'pit_table = '+@pit_table

		SET @error_code = 0

		/* Create/Alter pit table */
		EXEC [metadata].[usp_create_pits_ddl] @pit_schema, @pit_table, @hub_table, @error_code OUTPUT

		PRINT 'Error code back from usp_create_pits_ddl = '+CONVERT(varchar,@error_code)
	
		/* Populate pit details  - INSERT */
		IF @error_code = 1
		BEGIN
			EXEC [metadata].[usp_insert_pit_details] @pit_schema, @pit_table, @hub_schema, @hub_table, @hub_column, @sat_schema, @sat_table
		END

		/* Populate pit details  - UPDATE */
		IF  @error_code = 2
		BEGIN
			EXEC [metadata].[usp_update_pit_details] @pit_schema, @pit_table, @hub_schema, @hub_table, @sat_schema, @sat_table, @sat_column
		END

		/* Problem Creating PIT table */
		IF  @error_code = 3
		BEGIN
			PRINT 'Error creating PIT table ['+@pit_schema+'].['+@pit_table+']'
		END

		/* Problem Altering PIT table */
		IF  @error_code = 4
		BEGIN
			PRINT 'Error Altering PIT table ['+@pit_schema+'].['+@pit_table+']'
		END
	
		/* Update the meta table to indicate this row has been processed */
		PRINT 'Update meta table details to processed '
		UPDATE [metadata].[pitdetails]
		SET 
				completed = 1, 
				completed_date = GETDATE()
		WHERE 
				satschema = @sat_schema AND
				sattable = @sat_table

		/* Get the next job row to process */
		PRINT 'Get next row from pitdetails_curs'
		FETCH NEXT FROM pitdetails_curs INTO
			@hub_schema, @hub_table, @sat_schema, @sat_table, @hub_column, @sat_column, @pit_schema, @pit_table

	END

	CLOSE pitdetails_curs
	DEALLOCATE pitdetails_curs

END

