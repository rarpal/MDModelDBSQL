IF EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE type = 'P' AND a.name = 'LoadMetaDataRepository' AND b.name='metadata')
	BEGIN
		DROP PROCEDURE metadata.LoadMetaDataRepository
	END

GO

CREATE PROCEDURE metadata.LoadMetaDataRepository

/*
Creation Date	: 05/08/2013
Author			: Ravi Palihena
Purpose			: To load or refresh the Meta Data Repository
				: This procedure retrieves SQL Server Meta Data from the INFORMATION_SCHEMA and other system tables

Revision history -
	02/10/2013 RP:- Added DimContractClassification
	26/12/2013 RP:- Foreign key attributes are now identified entirely from foreign key constraints

exec metadata.LoadMetaDataRepository
*/
AS

-- Populate DataMart
MERGE [metadata].DataMart tgt
USING (
		SELECT 1 keyDataMart, 'SALES' DataMartName, 'Sales Data Mart' FullName
		) src
ON (src.DataMartName = tgt.DataMartName)
WHEN NOT MATCHED BY TARGET THEN
	INSERT (keyDataMart,DataMartName,FullName)
	VALUES (src.keyDataMart,src.DataMartName,src.FullName)
WHEN MATCHED AND src.FullName <> tgt.FullName THEN
	UPDATE SET 
		FullName = src.FullName
WHEN NOT MATCHED BY SOURCE THEN
	DELETE		
;

-- Populate Entity with Facts
MERGE metadata.Entity tgt
USING (
	SELECT 
		 1 keyDataMart
		,a.TABLE_NAME EntityName
		,a.TABLE_NAME FullName
		,[Type] = CASE 
				WHEN a.TABLE_NAME LIKE 'Fact%' THEN 'F' 
				ELSE NULL 
			END
	FROM INFORMATION_SCHEMA.TABLES a
	WHERE a.TABLE_NAME LIKE 'Fact%'
	) src
ON (src.EntityName = tgt.EntityName)
WHEN NOT MATCHED BY TARGET THEN
	INSERT (keyDataMart,EntityName,FullName,[Type],CreateDateTime,UpdateUser)
	VALUES (src.keyDataMart,src.EntityName,src.FullName,src.[Type],getdate(),suser_name())
WHEN MATCHED AND src.keyDataMart <> tgt.keyDataMart OR src.FullName <> tgt.FullName THEN
	UPDATE SET
		 keyDataMart = src.keyDataMart
		,FullName = src.FullName
		,[Type] = src.[Type]
		,UpdateDateTime = getdate()
WHEN NOT MATCHED BY SOURCE AND tgt.[Type] = 'F' THEN
	DELETE
;			

-- Populate Entity with Dimensions
MERGE metadata.Entity tgt
USING (
	SELECT 
		 1 keyDataMart
		,a.TABLE_NAME EntityName
		,a.TABLE_NAME FullName
		,[Type] = CASE 
				WHEN a.TABLE_NAME LIKE 'Dim%' THEN 'D' 
				ELSE NULL 
			END
	FROM INFORMATION_SCHEMA.TABLES a
	WHERE a.TABLE_NAME LIKE 'Dim%'
	) src
ON (src.EntityName = tgt.EntityName)
WHEN NOT MATCHED BY TARGET THEN
	INSERT (keyDataMart,EntityName,FullName,[Type],CreateDateTime,UpdateUser)
	VALUES (src.keyDataMart,src.EntityName,src.FullName,src.[Type],getdate(),suser_name())
WHEN MATCHED AND src.keyDataMart <> tgt.keyDataMart OR src.FullName <> tgt.FullName THEN
	UPDATE SET
		 keyDataMart = src.keyDataMart
		,FullName = src.FullName
		,[Type] = src.[Type]
		,UpdateDateTime = getdate()
WHEN NOT MATCHED BY SOURCE AND tgt.[Type] = 'D' THEN
	DELETE
;			

-- Populate Attribute
WITH UCIndex AS(
SELECT
    TableName = t.name, 
    ClusteredIndexName = i.name,
    ColumnName = c.Name
FROM
    sys.tables t
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.index_columns ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id
INNER JOIN 
    sys.columns c ON ic.column_id = c.column_id AND ic.object_id = c.object_id
WHERE
    i.index_id = 1  -- clustered index
),
FKColumns AS(
SELECT 
	TableName = t.name,
	FKPartNo = fk.constraint_column_id,
	ColumnName = c.name 
FROM sys.foreign_key_columns as fk
INNER JOIN sys.tables as t on fk.parent_object_id = t.object_id
INNER JOIN sys.columns as c on fk.parent_object_id = c.object_id and fk.parent_column_id = c.column_id
)
MERGE metadata.Attribute tgt
USING (
	SELECT 
		b.keyEntity,
		a.COLUMN_NAME AttributeName,
		a.DATA_TYPE + coalesce('(' + convert(varchar,a.CHARACTER_MAXIMUM_LENGTH) + ')','') DataType,
		[Type] = CASE 
					--WHEN LEFT(a.COLUMN_NAME,3) = 'key' AND b.[Type] = 'D' THEN 'S'
					--WHEN LEFT(a.COLUMN_NAME,3) = 'key' AND b.[Type] = 'F' THEN 'F'
					WHEN isnull(UCIndex.ColumnName,'')<>'' AND b.[Type] = 'D' THEN 'S'
					WHEN isnull(UCIndex.ColumnName,'')<>'' AND b.[Type] = 'F' THEN 'P'
					WHEN isnull(FKColumns.ColumnName,'')<>'' THEN 'F'
					ELSE 'N'
				END,
		UCIndex.TableName,
		UCIndex.ColumnName,
		UCIndex.ClusteredIndexName				
		FROM INFORMATION_SCHEMA.COLUMNS a
		JOIN metadata.Entity b ON a.table_name = b.EntityName
		LEFT JOIN UCIndex ON a.COLUMN_NAME = UCIndex.ColumnName AND a.TABLE_NAME = UCIndex.TableName
		LEFT JOIN FKColumns ON a.COLUMN_NAME = FKColumns.ColumnName AND a.TABLE_NAME = FKColumns.TableName
	) src
ON (src.AttributeName = tgt.AttributeName AND src.keyEntity = tgt.keyEntity)	
WHEN NOT MATCHED BY TARGET THEN
	INSERT (keyEntity, AttributeName, DataType, [Type], CreateDateTime, UpdateUser)
	VALUES (src.keyEntity, src.AttributeName, src.DataType, src.[Type], getdate(), suser_name())
WHEN MATCHED AND src.keyEntity <> tgt.keyEntity OR src.DataType <> tgt.DataType OR src.[Type] <> tgt.[Type] THEN
	UPDATE SET
		 keyEntity = src.keyEntity
		,DataType = src.DataType
		,[Type] = src.[Type]
		,UpdateDateTime = getdate()
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;

-- Populate Relationship
MERGE metadata.Relationship tgt
USING (
	SELECT
		--tp.name tpname,
		--cp.name cpname, 
		--cp.column_id cpcolumnid,
		--tr.name trname,
		--cr.name crname,
		--cr.column_id crcolumnid,
		fatt.keyAttribute keyJoinAttribute,
		datt.keyAttribute keyReferenceAttribute,
		fk.name RelationshipName
	FROM sys.foreign_keys fk
		INNER JOIN 
			sys.tables tp ON fk.parent_object_id = tp.object_id
		INNER JOIN 
			sys.tables tr ON fk.referenced_object_id = tr.object_id
		INNER JOIN 
			sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
		INNER JOIN 
			sys.columns cp ON fkc.parent_column_id = cp.column_id AND fkc.parent_object_id = cp.object_id
		INNER JOIN 
			sys.columns cr ON fkc.referenced_column_id = cr.column_id AND fkc.referenced_object_id = cr.object_id
		INNER JOIN
			metadata.Attribute fatt ON cp.name = fatt.AttributeName
		INNER JOIN
			metadata.Entity fent ON fatt.keyEntity = fent.keyEntity AND tp.name = fent.EntityName
		INNER JOIN
			metadata.Attribute datt ON cr.name = datt.AttributeName
		INNER JOIN
			metadata.Entity dent ON datt.keyEntity = dent.keyEntity AND tr.name = dent.EntityName
	) src
ON (src.RelationshipName = tgt.RelationshipName)
WHEN NOT MATCHED BY TARGET THEN
	INSERT (keyJoinAttribute, keyReferenceAttribute, RelationshipName, CreateDateTime, UpdateUser)
	VALUES (src.keyJoinAttribute, src.keyReferenceAttribute, src.RelationshipName, getdate(), suser_name())
WHEN MATCHED AND src.keyJoinAttribute <> tgt.keyJoinAttribute OR src.keyReferenceAttribute <> tgt.keyReferenceAttribute THEN
	UPDATE SET
		 keyJoinAttribute = src.keyJoinAttribute
		,keyReferenceAttribute = src.keyReferenceAttribute
		,UpdateDateTime = getdate()
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;

-- Populate Procedure
MERGE metadata.[Procedure] tgt
USING (
	SELECT
		SPECIFIC_NAME ProcedureName
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE SPECIFIC_SCHEMA='dbo' AND SPECIFIC_NAME NOT LIKE 'sp_%' AND ROUTINE_TYPE='PROCEDURE'
	) src
ON (src.ProcedureName = tgt.ProcedureName)
WHEN NOT MATCHED BY TARGET THEN
	INSERT (ProcedureName)
	VALUES (src.ProcedureName)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;

/*
;
-- Populate Column
MERGE metadata.[Column] tgt
USING (
	SELECT 
		b.keySource,
		a.COLUMN_NAME ColumnName,
		a.DATA_TYPE + coalesce('(' + convert(varchar,a.CHARACTER_MAXIMUM_LENGTH) + ')','') DataType
		FROM INFORMATION_SCHEMA.COLUMNS a
		JOIN metadata.Source b ON a.table_name = b.SourceName AND a.table_schema='staging'
	) src
ON (src.ColumnName = tgt.ColumnName AND src.keySource = tgt.keySource)	
WHEN NOT MATCHED BY TARGET THEN
	INSERT (keySource, ColumnName, DataType)
	VALUES (src.keySource, src.ColumnName, src.DataType)
WHEN MATCHED AND src.keySource <> tgt.keySource OR src.DataType <> tgt.DataType THEN
	UPDATE SET
		 keySource = src.keySource
		,DataType = src.DataType
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
;

-- This code can be used to sync metadata from another database
--
begin tran
update metadata.Entity set [description]=a.[Description]
from ClarityReportingDW.metadata.entity a join metadata.Entity b on a.EntityName=b.EntityName
--where a.EntityName is null
commit

begin tran
update metadata.Attribute set [description]=a.[Description]
from ClarityReportingDW.metadata.Attribute a join metadata.Attribute b on a.AttributeName=b.AttributeName
commit

begin tran
;
with cte
as(
select a.RelationshipName, b.AttributeName joinattribute, d.EntityName joinentity, c.AttributeName refattribute, e.EntityName refentity
from ClarityReportingDW.metadata.Relationship a
join ClarityReportingDW.metadata.Attribute b on a.keyJoinAttribute = b.keyAttribute
join ClarityReportingDW.metadata.Entity d on b.keyEntity = d.keyEntity
join ClarityReportingDW.metadata.Attribute c on a.keyReferenceAttribute = c.keyAttribute
join ClarityReportingDW.metadata.Entity e on c.keyEntity = e.keyEntity
)
insert metadata.Relationship(RelationshipName,keyJoinAttribute,keyReferenceAttribute)
select cte.RelationshipName,a.keyAttribute keyJoinAttribute,c.keyAttribute keyReferenceAttribute
from cte 
join metadata.Attribute a on cte.joinattribute = a.AttributeName
join metadata.Entity b on a.keyEntity = b.keyEntity and cte.joinentity = b.EntityName
join metadata.Attribute c on cte.refattribute = c.AttributeName
join metadata.Entity d on c.keyEntity = d.keyEntity and cte.refentity = d.EntityName
commit

*/
