SELECT 
f.keySource SourcePKey,f.SourceName SourceShortName,f.[Type] SourceType,f.ConnectionString SourceConnection,f.SourceScript,
b.keyColumn ColumnPKey,b.ColumnName ColumnFieldName,b.DataType ColumnDataType,b.Type ColumnFieldType,
a.keyMapping MappingPKey,a.keyColumn MappingColumnFKey,a.keyAttribute MappingAttributeFKey,a.[Type] MappingType,
c.keyAttribute AttributePKey,c.AttributeName AttributeFieldName,c.DataType AttributeDataType,
g.keyEntity EntityPKey,g.EntityName EntityShortName,g.[Type] EntityType,g.PartitionSuffix,g.HistoryMode,g.PopulationMethod,
a.keyJoinAttribute JoinAttributeFKey,h.AttributeName JoinAttributeFieldName,h.DataType JoinAttributeDataType,h.keyEntity JoinEntityFKey,h.[Type] JoinFieldType,i.EntityName JoinEntityShortName,
j.keyAttribute ReferenceAttributePKey,j.AttributeName ReferenceAttributeFieldName,j.DataType ReferenceAttributeDataType
 FROM metadata.[Column] b
 INNER JOIN metadata.[Source] f ON b.keySource=f.keySource
 LEFT JOIN metadata.[Mapping] a ON a.keyColumn=b.keyColumn
 LEFT JOIN metadata.[Attribute] c ON a.keyAttribute=c.keyAttribute
 LEFT JOIN metadata.[Entity] g ON c.keyEntity=g.keyEntity
 LEFT JOIN metadata.[Attribute] h ON a.keyJoinAttribute=h.keyAttribute
 LEFT JOIN metadata.[Entity] i ON h.keyEntity=i.keyEntity
 LEFT JOIN (SELECT keyEntity,keyAttribute,AttributeName,DataType FROM metadata.Attribute WHERE [Type]='S') j ON i.keyEntity=j.keyEntity
 WHERE f.SourceName=@FactSource; 


SELECT DISTINCT 
f.keySource SourcePKey,f.SourceName SourceShortName,f.Type,f.ConnectionString,f.SourceScript,f.BatchScript
FROM metadata.[Mapping] a
INNER JOIN metadata.[Column] b ON a.keyColumn=b.keyColumn
INNER JOIN metadata.[Source] f ON b.keySource=f.keySource"