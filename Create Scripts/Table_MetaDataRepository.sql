/*
Creation Date	: 05/08/2013
Author			: Ravi Palihena
Purpose			: Create the Meta Data Repository

Revision history -
	03-03-2014 RP: Added PartitionSuffix and HistoryMode to metadata.Entity

*/

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'metadata')
	EXEC ('CREATE SCHEMA metadata AUTHORIZATION dbo')
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging')
	EXEC ('CREATE SCHEMA staging AUTHORIZATION dbo')
GO

-- DataMart
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'DataMart'  AND b.name='metadata')
	CREATE TABLE [metadata].[DataMart](
		[keyDataMart] [int] NOT NULL,
		[DataMartName] [varchar](128) NULL,
		[FullName] [varchar](256) NULL,
		[Type] [varchar](2) NULL,
		[Description] NVARCHAR(MAX)
	 CONSTRAINT [prkDataMart] PRIMARY KEY CLUSTERED 
	(
		[keyDataMart] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- Entity
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'Entity'  AND b.name='metadata')
	CREATE TABLE [metadata].[Entity](
		[keyEntity] [int] IDENTITY(1,1) NOT NULL,
		[keyDataMart] [int] NULL,
		[EntityName] [varchar](128) NULL,
		[FullName] [varchar](256) NULL,
		[Type] [varchar](2) NULL,
		[Description] NVARCHAR(MAX),
		[EntityImage] VARBINARY(MAX),
		[CreateDateTime] datetime,
		[UpdateDateTime] datetime,
		[UpdateUser] varchar(128),
		[PartitonSuffix] varchar(50),
		[HistoryMode] tinyint,
		[PopulationMethod] tinyint
	 CONSTRAINT [prkEntity] PRIMARY KEY CLUSTERED 
	(
		[keyEntity] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkEntityDataMart]') AND parent_object_id = OBJECT_ID(N'[metadata].[Entity]'))
	ALTER TABLE [metadata].[Entity]  WITH NOCHECK ADD  CONSTRAINT [frkEntityDataMart] FOREIGN KEY([keyDataMart])
	REFERENCES [metadata].[DataMart] ([keyDataMart])
	NOT FOR REPLICATION 
GO

ALTER TABLE [metadata].[Entity] NOCHECK CONSTRAINT [frkEntityDataMart]
GO

-- Attribute
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'Attribute'  AND b.name='metadata')
	CREATE TABLE [metadata].[Attribute](
		[keyAttribute] [int] IDENTITY(1,1) NOT NULL,
		[keyEntity] [int] NULL,
		[AttributeName] [varchar](128) NULL,
		[FullName] [varchar](256) NULL,
		[DataType] [varchar](20) NULL,
		[Type] [varchar](2) NULL,
		[Description] NVARCHAR(MAX),
		[CreateDateTime] datetime,
		[UpdateDateTime] datetime,
		[UpdateUser] varchar(128)
	 CONSTRAINT [prkAttribute] PRIMARY KEY CLUSTERED 
	(
		[keyAttribute] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO	

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkAttributeEntity]') AND parent_object_id = OBJECT_ID(N'[metadata].[Attribute]'))
	ALTER TABLE [metadata].[Attribute]  WITH NOCHECK ADD  CONSTRAINT [frkAttributeEntity] FOREIGN KEY([keyEntity])
	REFERENCES [metadata].[Entity] ([keyEntity])
	NOT FOR REPLICATION 
GO

ALTER TABLE [metadata].[Attribute] NOCHECK CONSTRAINT [frkAttributeEntity]
GO

-- Relationship
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'Relationship'  AND b.name='metadata')
	CREATE TABLE [metadata].[Relationship](
		[keyRelationship] [int] IDENTITY(1,1) NOT NULL,
		[keyJoinAttribute] [int] NULL,
		[keyReferenceAttribute] [int] NULL,
		[RelationshipName] [varchar](128) NULL,
		[FullName] [varchar](256) NULL,
		[Description] NVARCHAR(MAX),
		[CreateDateTime] datetime,
		[UpdateDateTime] datetime,
		[UpdateUser] varchar(128)
	 CONSTRAINT [prkRelationship] PRIMARY KEY CLUSTERED 
	(
		[keyRelationship] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkRelationshipAttributeJoin]') AND parent_object_id = OBJECT_ID(N'[metadata].[Relationship]'))
	ALTER TABLE [metadata].[Relationship]  WITH NOCHECK ADD  CONSTRAINT [frkRelationshipAttributeJoin] FOREIGN KEY([keyJoinAttribute])
	REFERENCES [metadata].[Attribute] ([keyAttribute])
	NOT FOR REPLICATION 
GO

ALTER TABLE [metadata].[Relationship] NOCHECK CONSTRAINT [frkRelationshipAttributeJoin]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkRelationshipAttributeReference]') AND parent_object_id = OBJECT_ID(N'[metadata].[Relationship]'))
	ALTER TABLE [metadata].[Relationship]  WITH CHECK ADD  CONSTRAINT [frkRelationshipAttributeReference] FOREIGN KEY([keyReferenceAttribute])
	REFERENCES [metadata].[Attribute] ([keyAttribute])
GO

ALTER TABLE [metadata].[Relationship] NOCHECK CONSTRAINT [frkRelationshipAttributeReference]
GO

-- Source
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'Source'  AND b.name='metadata')
	CREATE TABLE [metadata].[Source](
		[keySource] [int] IDENTITY(1,1) NOT NULL,
		[SourceName] [nvarchar](128) NULL,
		[FullName] [nvarchar](256) NULL,
		[Type] [varchar](20) NULL,
		[ConnectionString] [varchar](256) NULL,
		[SourceScript] [varchar](max),
		[BatchScript] [varchar](max)
	 CONSTRAINT [prkSource] PRIMARY KEY CLUSTERED 
	(
		[keySource] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

GO

-- Column
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'Column'  AND b.name='metadata')
	CREATE TABLE [metadata].[Column](
		[keyColumn] [int] IDENTITY(1,1) NOT NULL,
		[keySource] [int] NULL,
		[ColumnName] [nvarchar](128) NULL,
		[FullName] [nvarchar](256) NULL,
		[DataType] [nvarchar](128) NULL,
		[Type] [varchar](2) NULL,
		[OrderNo] [int] NULL,
		[IsValueParameter] [bit]		
	 CONSTRAINT [prkColumn] PRIMARY KEY CLUSTERED 
	(
		[keyColumn] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkMappingColumn]') AND parent_object_id = OBJECT_ID(N'[metadata].[Mapping]'))
	ALTER TABLE [metadata].[Column]  WITH NOCHECK ADD  CONSTRAINT [frkColumnSource] FOREIGN KEY([keySource])
	REFERENCES [metadata].[Source] ([keySource])
	NOT FOR REPLICATION 
GO

ALTER TABLE [metadata].[Column] NOCHECK CONSTRAINT [frkColumnSource]
GO

-- Mapping
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'Mapping'  AND b.name='metadata')
	CREATE TABLE [metadata].[Mapping](
		[keyMapping] [int] IDENTITY(1,1) NOT NULL,
		[keyColumn] [int] NULL,
		[keyAttribute] [int] NULL,
		[Type] [varchar](2) NULL,
		[keyJoinAttribute] [int] NULL,
	 CONSTRAINT [prkMapping] PRIMARY KEY CLUSTERED 
	(
		[keyMapping] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkMappingAttribute]') AND parent_object_id = OBJECT_ID(N'[metadata].[Mapping]'))
	ALTER TABLE [metadata].[Mapping]  WITH NOCHECK ADD  CONSTRAINT [frkMappingAttribute] FOREIGN KEY([keyAttribute])
	REFERENCES [metadata].[Attribute] ([keyAttribute])
GO

ALTER TABLE [metadata].[Mapping] NOCHECK CONSTRAINT [frkMappingAttribute]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkMappingColumn]') AND parent_object_id = OBJECT_ID(N'[metadata].[Mapping]'))
	ALTER TABLE [metadata].[Mapping]  WITH NOCHECK ADD  CONSTRAINT [frkMappingColumn] FOREIGN KEY([keyColumn])
	REFERENCES [metadata].[Column] ([keyColumn])
GO

ALTER TABLE [metadata].[Mapping] NOCHECK CONSTRAINT [frkMappingColumn]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkMappingJoinAttribute]') AND parent_object_id = OBJECT_ID(N'[metadata].[Mapping]'))
	ALTER TABLE [metadata].[Mapping]  WITH NOCHECK ADD  CONSTRAINT [frkMappingJoinAttribute] FOREIGN KEY([keyJoinAttribute])
	REFERENCES [metadata].[Attribute] ([keyAttribute])
GO

ALTER TABLE [metadata].[Mapping] NOCHECK CONSTRAINT [frkMappingJoinAttribute]
GO

-- FlowPlan
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'FlowPlan'  AND b.name='metadata')
	CREATE TABLE [metadata].[FlowPlan](
		[keyFlowPlan] [int] IDENTITY(1,1) NOT NULL,
		[FlowPlanName] [varchar](128) NULL,
		[FullName] [varchar](256) NULL,
		[Type] [varchar](2) NULL
	 CONSTRAINT [prkFlowPlan] PRIMARY KEY CLUSTERED 
	(
		[keyFlowPlan] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- FlowTask
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'FlowTask'  AND b.name='metadata')
	CREATE TABLE [metadata].[FlowTask](
		[keyFlowTask] [int] IDENTITY(1,1) NOT NULL,
		[keyFlowPlan] [int] NULL,
		[keySource] [int] NULL,
		[TaskName] [varchar](128) NULL,
		[FullName] [varchar](256) NULL,
		[Type] [varchar](2) NULL,
		[OrderNo] [int] NULL
	 CONSTRAINT [prkFlowTask] PRIMARY KEY CLUSTERED 
	(
		[keyFlowTask] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkFlowTaskFlowPlan]') AND parent_object_id = OBJECT_ID(N'[metadata].[FlowTask]'))
	ALTER TABLE [metadata].[FlowTask]  WITH NOCHECK ADD  CONSTRAINT [frkFlowTaskFlowPlan] FOREIGN KEY([keyFlowPlan])
	REFERENCES [metadata].[FlowPlan] ([keyFlowPlan])
GO

ALTER TABLE [metadata].[FlowTask] NOCHECK CONSTRAINT [frkFlowTaskFlowPlan]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkFlowTaskSource]') AND parent_object_id = OBJECT_ID(N'[metadata].[FlowTask]'))
	ALTER TABLE [metadata].[FlowTask]  WITH NOCHECK ADD  CONSTRAINT [frkFlowTaskSource] FOREIGN KEY([keySource])
	REFERENCES [metadata].[Source] ([keySource])
GO

ALTER TABLE [metadata].[FlowTask] NOCHECK CONSTRAINT [frkFlowTaskSource]
GO

-- Procedure
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'Procedure'  AND b.name='metadata')
	CREATE TABLE [metadata].[Procedure](
		[keyProcedure] [int] IDENTITY(1,1) NOT NULL,
		[keyDataMart] [int] NULL,
		[keyParentProcedure] [int] NULL,
		[ProcedureName] [varchar](128) NULL,
		[FullName] [varchar](256) NULL,
		[Type] [varchar](2) NULL,
		[Description] NVARCHAR(MAX)
	 CONSTRAINT [prkProcedure] PRIMARY KEY CLUSTERED 
	(
		[keyProcedure] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO	

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkParentProcedure]') AND parent_object_id = OBJECT_ID(N'[metadata].[Procedure]'))
	ALTER TABLE [metadata].[Procedure]  WITH NOCHECK ADD  CONSTRAINT [frkParentProcedure] FOREIGN KEY([keyParentProcedure])
	REFERENCES [metadata].[Procedure] ([keyProcedure])
	NOT FOR REPLICATION 
GO

ALTER TABLE [metadata].[Procedure] NOCHECK CONSTRAINT [frkParentProcedure]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[metadata].[frkProcedureDataMart]') AND parent_object_id = OBJECT_ID(N'[metadata].[Procedure]'))
	ALTER TABLE [metadata].[Procedure]  WITH NOCHECK ADD  CONSTRAINT [frkProcedureDataMart] FOREIGN KEY([keyDataMart])
	REFERENCES [metadata].[DataMart] ([keyDataMart])
	NOT FOR REPLICATION 
GO

ALTER TABLE [metadata].[Procedure] NOCHECK CONSTRAINT [frkProcedureDataMart]
GO

-- Load Control
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'LoadControl'  AND b.name='metadata')
	CREATE TABLE [metadata].[LoadControl](
		[keyLoadControl] [int] IDENTITY(1,1) NOT NULL,
		[Status] [int] NULL,
		[LoadStartDateTime] [datetime] NULL,
		[LoadEndDateTime] [datetime] NULL,
		[LoadUserID] [varchar](50) NULL
	)
GO

-- Load Control Log
IF NOT EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'U' AND a.name = 'LoadControlLog'  AND b.name='metadata')
	CREATE TABLE [metadata].[LoadControlLog](
		[keyLoadControlLog] [int] IDENTITY(1,1) NOT NULL,
		[keyLoadControl] [int] NULL,
		[Type] [varchar] (2) NULL,
		[keySource] [int] NULL,
		[SourceShortName] [nvarchar] (128) NULL,
		[keyColumn] [int] NULL,
		[ColumnFieldName] [nvarchar] (128) NULL,
		[Value] [varchar] (128) NULL,
		[Narration] [varchar] (256) NULL,
	)
GO


