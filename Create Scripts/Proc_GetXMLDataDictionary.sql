IF EXISTS (SELECT * FROM sysobjects a JOIN sys.schemas b ON a.uid=b.schema_id WHERE a.type = 'P' AND a.name = 'GetXMLDataDictionary' AND b.name='metadata')
	BEGIN
		DROP  Procedure  metadata.GetXMLDataDictionary
	END

GO

CREATE Procedure metadata.GetXMLDataDictionary

	(
		@Option int = 0
	)
/*
Creation Date	: 08/08/2013
Author			: Ravi Palihena
Purpose			: To extract the Meta Data Repository as XML
Parameters		: @Option = 0: Generate XML; 1: Load Meta Data and Generate XML

Revision history -

15/10/2013	DW	Added new code to add Relationship details to end of entity.

*/
AS

IF @Option = 1
BEGIN
	EXECUTE metadata.LoadMetaDataRepository
END

SELECT * FROM (
	SELECT 
      dm.keyDataMart AS '@keyDataMart',
      dm.DataMartName AS '@DataMartName',
      dm.FullName AS '@FullName',
      (
      SELECT
            en.keyDataMart AS '@keyDataMart',
            en.keyEntity AS '@keyEntity',
            en.EntityName AS '@EntityName',
            en.FullName AS '@FullName',
            en.[Type] AS '@Type',
            en.[Description] AS 'Description',
            (
            SELECT 
                  at.keyEntity AS '@keyEntity',
                  at.keyAttribute AS '@keyAttribute',
                  at.AttributeName AS '@AttributeName',
                  at.FullName AS '@FullName',
                  at.DataType AS '@DataType',
                  at.[Type] AS '@Type',
                  at.[Description] AS 'Description',
                  (
                  SELECT
                        rlj.keyRelationship AS '@keyRelationship',
                        rlj.RelationshipName AS '@RelationshipName',
                        rlj.Fullname AS '@FullName',
                        rlj.keyJoinAttribute AS '@keyJoinAttribute',
                        enr.keyEntity AS '@keyReferenceEntity',
                        enr.EntityName AS '@ReferenceEntityName'
                  FROM metadata.Relationship rlj, metadata.Attribute atr, metadata.Entity enr
                  WHERE rlj.keyJoinAttribute = at.keyAttribute 
                        AND rlj.keyReferenceAttribute = atr.keyAttribute
                        AND atr.keyEntity = enr.keyEntity
                  FOR XML PATH('Relationship'), TYPE
                  ) AS 'Relationships'
            FROM metadata.Attribute at
            WHERE at.keyEntity = en.keyEntity
            FOR XML PATH('Attribute'), TYPE
            ) AS 'Attributes',
            (
			SELECT  
				rlj.RelationshipName AS '@tblRelationshipName',
				en.EntityName AS '@tblFkeyEntity',
				atj.AttributeName AS '@tblForeignKey',
				enr.EntityName AS '@tblReferenceEntityName',
				atr.AttributeName AS '@tblSurrogateKey'
			FROM metadata.Relationship rlj, metadata.Attribute atj, metadata.Attribute atr, metadata.Entity enr
			WHERE rlj.keyJoinAttribute = atj.keyAttribute
				  AND rlj.keyReferenceAttribute = atr.keyAttribute
				  AND atr.keyEntity = enr.keyEntity
				  AND atj.keyEntity = en.keyEntity
			FOR XML PATH('tblRelationship'), TYPE
			) AS 'tblRelationships'
      FROM metadata.Entity en
      WHERE en.keyDataMart = dm.keyDataMart
      FOR XML PATH('Entity'), TYPE
      ) AS 'Entities'
	FROM metadata.DataMart dm
	FOR XML PATH('DataMart'), ROOT('DataMarts')
) XMLData(XMLData)
GO
