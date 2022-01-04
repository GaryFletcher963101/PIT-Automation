SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'metadata.pitdetails', N'U') IS NOT NULL  
   DROP TABLE [metadata].[pitdetails];  
GO

CREATE TABLE [metadata].[pitdetails](
	[hubtable] [varchar](128) NOT NULL,
	[sattable] [varchar](128) NOT NULL,
	[pittable] [varchar](128) NOT NULL,
	[hubschema] [varchar](128) NOT NULL,
	[satschema] [varchar](128) NOT NULL,
	[pitschema] [varchar](128) NOT NULL,
	[hubcolumn] [varchar](128) NOT NULL,
	[satcolumn] [varchar](128) NOT NULL,
	[completed] [bit] NOT NULL default 0,
	[completed_date] [datetime] NULL
	CONSTRAINT [pk_metadata_pithubsats] PRIMARY KEY NONCLUSTERED 
	(
		[hubtable],[sattable] ASC
	)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

IF OBJECT_ID(N'metadata.pitcolumns', N'U') IS NOT NULL  
   DROP TABLE [metadata].[pitcolumns];  
GO

CREATE TABLE [metadata].[pitcolumns](
	[pittable] [varchar](128) NOT NULL,
	[pitschema] [varchar](128) NOT NULL,
	[pitcolumn] [varchar](128) NOT NULL,
	[satschema] [varchar](128) NOT NULL,
	[sattable] [varchar](128) NOT NULL,
	[satcolumn] [varchar](128) NOT NULL
	CONSTRAINT [pk_metadata_pitcolumns] PRIMARY KEY NONCLUSTERED 
	(
		[pittable],[pitcolumn]  ASC
	)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]
