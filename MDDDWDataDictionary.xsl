<?xml version="1.0" encoding="utf-8"?>
<!-- XSL Template for converting the XML documentation to HTML -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
	<xsl:output
        method="html"
        indent="yes"
        omit-xml-declaration="yes"
        media-type="text/html"
        doctype-system="about:legacy-compat"
        encoding="utf-8" />
	<xsl:template match="/">
		<html>
			<head>
				<title>
					Data Dictionary
				</title>
				<meta http-equiv="content-type" content="text/html; charset=utf-8" />
				<style type="text/css">
					body { background-color: #fff; color: #000; font-family: Consolas, monospace}
					a:link { color: #03d; }
					a:visited { color: #039; }
					a:hover { color: #09f; }
					table { border-collapse: collapse; width: 100%; }
					table caption { color: #666; text-align: right; font-size: 65%; margin-bottom: .5ex; }
					table td, table th { border: solid 1px #666; border-collapse: collapse; padding: .3ex .5ex; vertical-align: top; }
					table tbody tr:hover { background-color: #ffc; }
					table thead th { text-align: left; background-color: #ccc; }
					table tbody th { text-align: left; white-space: nowrap; }
					.table { page-break-inside: avoid; }
					.pk { float: right; cursor: arrow; color: #999; }
					.type { white-space: nowrap; }
					.null { text-align: center; }
					.flag { white-space: nowrap; font-size: 70%; display: inline-block; border: solid 1px #ccc; padding: .25ex .5ex; background-color: #ddd; margin-right: 1ex; }
					.tocref { float: right; text-decoration: none; font-weight: normal; }
					.footer { text-align: center; margin-top: 1em; font-size: 80%;}
					li.view:before { content: "VIEW"; font-size: 70%; display: inline-block; border: solid 1px #ccc; padding: .25ex .5ex; background-color: #ddd; margin-right: 1ex; }
					@media print {
					body { font-size: .8em; }
					#toc, .tocref { display: none; }
					a:link, a:visited { color: #000; text-decoration: none; }
					}
				</style>
			</head>
			<body>
				<fo:block page-break-after="always">
					<h1>
						Meta Data Driven Datawarehouse Data Dictionary
					</h1>
					<!-- Table of contents -->
					<xsl:call-template name="TableOfContents"/>
				</fo:block>
			</body>				
			<body>
				<!-- Process all Data Marts -->
				<xsl:for-each select="/DataMarts/DataMart">
					<xsl:sort select="@keyDataMart"/>
					<xsl:variable name="keyDataMart" select="@keyDataMart"/>
					<!-- Process Facts in data mart -->
					<div>
						<xsl:for-each select="/DataMarts/DataMart/Entities/Entity[@keyDataMart=$keyDataMart and @Type='F']">
							<xsl:sort select="@EntityName"/>
							<xsl:call-template name="EntityStructure"/>
						</xsl:for-each>
					</div>
				</xsl:for-each>
			</body>
			<body>
				<!-- Process all Data Marts -->
				<xsl:for-each select="/DataMarts/DataMart">
					<xsl:sort select="@keyDataMart"/>
					<xsl:variable name="keyDataMart" select="@keyDataMart"/>
					<!-- Process Dimensions in data mart -->
					<div>
						<xsl:for-each select="/DataMarts/DataMart/Entities/Entity[@keyDataMart=$keyDataMart and @Type='D']">
							<xsl:sort select="@EntityName"/>
							<xsl:call-template name="EntityStructure"/>
						</xsl:for-each>
					</div>
				</xsl:for-each>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="TableOfContents">
		<div id="toc">
			<ul>
				<xsl:for-each select="/DataMarts/DataMart[@DataMartName!='CLARITY']">
					<xsl:sort select="@keyDataMart"/>
					<xsl:variable name="keyDataMart" select="@keyDataMart"/>
					<li>
						<b>
							<xsl:value-of select="@FullName"/>
						</b>
						<ul>
							<xsl:for-each select="/DataMarts/DataMart/Entities/Entity[@keyDataMart=$keyDataMart and @Type='F']">
								<xsl:sort select="@EntityName"/>
								<li class="table">
									<a href="#{@keyEntity}">
										<xsl:value-of select="@EntityName"/>
									</a>
								</li>
							</xsl:for-each>
						</ul>
					</li>
				</xsl:for-each>
			</ul>
		</div>
	</xsl:template>

	<xsl:template name="EntityStructure">
		<div class="table">
			<h2 id="{@keyEntity}">
				<a href="#toc" class="tocref">&#8679;</a>
				<xsl:value-of select="@EntityName"/>
			</h2>
			<xsl:variable name="keyEntity" select="@keyEntity"/>
			<xsl:if test="Description">
				<p>
					<xsl:value-of select="Description" disable-output-escaping="yes"/>
				</p>
			</xsl:if>
			<table>
				<caption>
					<xsl:value-of select="concat('Entity ID: ', @keyEntity)"/>
				</caption>
				<thead>
					<tr>
						<th style="width:20ex">Attribute Name</th>
						<th style="width:20ex">Data Type</th>
						<th style="width:20ex">Attribute Type</th>
						<th>Description</th>
					</tr>
				</thead>
				<tbody>
					<xsl:for-each select="/DataMarts/DataMart/Entities/Entity/Attributes/Attribute[@keyEntity=$keyEntity]">
						<tr>
							<xsl:variable name="keyAttribute" select="@keyAttribute" />
							<td>
								<xsl:value-of select="@AttributeName"/>
							</td>
							<td class="type">
								<xsl:value-of select="@DataType"/>
							</td>
							<td class="type">
								<xsl:choose>
									<xsl:when test="@Type='S'">Surrogate Key</xsl:when>
									<xsl:when test="@Type='P'">Primary Key</xsl:when>
									<xsl:when test="@Type='F'">
										<xsl:for-each select="/DataMarts/DataMart/Entities/Entity/Attributes/Attribute/Relationships/Relationship[@keyJoinAttribute=$keyAttribute]">
											<a href="#{@keyReferenceEntity}">
												<xsl:value-of select="concat('Foreign Key (',@ReferenceEntityName,')')"/>
											</a>
										</xsl:for-each>
										<xsl:if test="not(Relationships)">
											Foreign Key
										</xsl:if>
									</xsl:when>
									<xsl:otherwise>Normal Attribute</xsl:otherwise>
								</xsl:choose>
							</td>
							<td>
								<xsl:value-of select="Description" disable-output-escaping="yes"/>
							</td>
						</tr>
					</xsl:for-each>
				</tbody>
			</table>
			<div>
				<a>
					<xsl:attribute name="href">
						<xsl:value-of select="concat('images/', @EntityName, '.jpg')"/>
					</xsl:attribute>link to image
				</a>
			</div>
			<div>
				<img>
					<xsl:attribute name="src">
						<xsl:value-of select="concat('images/', @EntityName, '.jpg')"/>
					</xsl:attribute>
				</img>
			</div>
		</div>
	</xsl:template>

</xsl:stylesheet>
