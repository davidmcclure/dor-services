<?xml version="1.0" encoding="UTF-8"?>
<!-- 
     geo2mods.xsl - Transformation from ISO 19139 XML into MODS v3 
     
     Copyright 2013, Stanford University Libraries.
     
     This work is licensed under the Creative Commons 
     Attribution-ShareAlike 3.0 Unported License. 
     To view a copy of this license, visit 
     http://creativecommons.org/licenses/by-sa/3.0 
     
     Created by Kim Durante and Darren Hardy, Stanford University Libraries
     
     Requires parameters:
     * geometryType: One of Point, LineString, Polygon, Curve, or Grid (Raster). 
       see
     http://www.schemacentral.com/sc/niem21/t-gml32_GeometryPropertyType.html
     * purl - e.g., http://purl.stanford.edu/aa111bb2222
     * zipName - e.g., data.zip
     * format - e.g., MIME type application/x-esri-shapefile
     
     TODO:
     * Series statements may need work?
     -->
<xsl:stylesheet 
  xmlns="http://www.loc.gov/mods/v3" 
  xmlns:gco="http://www.isotc211.org/2005/gco" 
  xmlns:gmi="http://www.isotc211.org/2005/gmi" 
  xmlns:gmd="http://www.isotc211.org/2005/gmd" 
  xmlns:gml="http://www.opengis.net/gml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  version="1.0" exclude-result-prefixes="gml gmd gco gmi xsl">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:param name="format" select="'application/x-esri-shapefile'"/>
  <xsl:param name="geometryType"/>
  <xsl:param name="purl"/>
  <xsl:param name="zipName" select="'data.zip'"/>
  <!-- The coordinates value for MODS v3 is quite vague, 
       so we have a variety of formats: 
       GMD, WKT, WMS, GML, GeoRSS, MARC034, MARC255 (default)
       -->
  <xsl:param name="geoformat" select="'MARC255'"/>
  <xsl:param name="fileIdentifier" select="''"/>
  <xsl:template match="/">
    <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" version="3.4" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">
      <xsl:for-each select="/gmi:MI_Metadata|/gmd:MD_Metadata|//gmd:MD_Metadata">
        <xsl:if test="gmd:fileIdentifier/gco:CharacterString/text()">
          <xsl:variable name="fileIdentifier" select="."/>
        </xsl:if>
        <xsl:if test="gmd:dataSetURI/gco:CharacterString/text()">
          <xsl:variable name="purl" select="."/>
        </xsl:if>
        <titleInfo>
          <title>
            <xsl:apply-templates select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title"/>
          </title>
        </titleInfo>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:alternateTitle">
          <titleInfo>
            <title type="alternative">
              <xsl:value-of select="."/>
            </title>
          </titleInfo>
        </xsl:for-each>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:alternateTitle">
          <titleInfo>
            <title displayLabel="Alternative title">
              <xsl:value-of select="."/>
            </title>
          </titleInfo>
        </xsl:for-each>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='originator']">
          <xsl:choose>
            <xsl:when test="ancestor-or-self::*/gmd:individualName">
              <name type="personal">
                <namePart>
                  <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
                </namePart>
                <role>
                  <!-- personal author -->
                  <roleTerm type="text" authority="marcrelator">creator</roleTerm>
                </role>
              </name>
            </xsl:when>
            <xsl:when test="ancestor-or-self::*/gmd:organisationName">
              <name type="corporate">
                <namePart>
                  <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
                </namePart>
                <role>
                  <!-- corporate author -->
                  <roleTerm type="text" authority="marcrelator">creator</roleTerm>
                </role>
              </name>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
          
        <!-- typeOfResource for SW - see http://www.loc.gov/standards/mods/v3/mods-userguide-elements.html -->
        <typeOfResource>cartographic</typeOfResource>
        <typeOfResource>software, multimedia</typeOfResource>
        <genre>
          <xsl:attribute name="authority">lcgft</xsl:attribute>
          <xsl:attribute name="valueURI">http://id.loc.gov/authorities/genreForms/gf2011026297</xsl:attribute>
          <xsl:text>Geospatial data</xsl:text>
        </genre>
        <genre>
          <xsl:attribute name="authority">rdacontent</xsl:attribute>
          <xsl:attribute name="valueURI">http://rdvocab.info/termList/RDAContentType/1001</xsl:attribute>
          <xsl:text>cartographic dataset</xsl:text>
        </genre>
        <originInfo>
          <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='publisher']">
            <publisher>
              <xsl:choose>
                <xsl:when test="ancestor-or-self::*/gmd:organisationName">
                  <xsl:value-of select="ancestor-or-self::*/gmd:organisationName"/>
                </xsl:when>
                <xsl:when test="ancestor-or-self::*/gmd:individualName">
                  <xsl:value-of select="ancestor-or-self::*/gmd:individualName"/>
                </xsl:when>
              </xsl:choose>
            </publisher>
            <xsl:for-each select="ancestor-or-self::*/gmd:contactInfo">
              <place>
                <placeTerm type="text">
                  <xsl:value-of select="ancestor-or-self::*/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city"/>
                  <xsl:if test="ancestor-or-self::*/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:city">, </xsl:if>
                  <xsl:value-of select="ancestor-or-self::*/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea"/>
                  <xsl:if test="ancestor-or-self::*/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:administrativeArea">, </xsl:if>
                  <xsl:value-of select="ancestor-or-self::*/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:country"/>
                </placeTerm>
              </place>
            </xsl:for-each>
          </xsl:for-each>
          <dateIssued encoding="w3cdtf" keyDate="yes">
          <!-- strip MM-DD, oupput YYYY -->
            <xsl:choose>
              <xsl:when test="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date">
                <xsl:value-of select="substring(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date,1,4)"/>
              </xsl:when>
              <xsl:otherwise>unknown</xsl:otherwise>
            </xsl:choose>
          </dateIssued>
     
            
         <!-- kd: construct dateValid from Temporal_EX field? 
                <xsl:if test="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod">
               <dateValid>
               <xsl:attribute name="point">start</xsl:attribute>
                   
                   <xsl:value-of select="substring-before(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition, 'T')"/>
              </dateValid>  
               <dateValid>
                   <xsl:attribute name="point">end</xsl:attribute>
                   <xsl:value-of select="substring-before(gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition, 'T')"/>
               </dateValid>  
           </xsl:if> -->
            
            <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords">
                <xsl:if test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='temporal']">
                    <xsl:for-each select="gmd:keyword">
                        
                        <xsl:choose>
                            
                            <!-- 4 digit year -->
                            <xsl:when test="string-length()=4">
                               <dateValid>
                                        <xsl:attribute name="encoding">w3cdtf</xsl:attribute>
                                        <xsl:value-of select="."/>
                               </dateValid>
                            </xsl:when>
                            
                            <!-- range of dates in YYYY-YYYY format -->
                            
                            <xsl:when test="contains(./*,'-')">
                                <dateValid>
                                        <xsl:attribute name="encoding">w3cdtf</xsl:attribute>
                                        <xsl:attribute name="point">start</xsl:attribute>
                                        <xsl:value-of select="substring-before(*,'-')"/>
                                </dateValid>
                                <dateValid>
                                        <xsl:attribute name="encoding">w3cdtf</xsl:attribute>
                                        <xsl:attribute name="point">end</xsl:attribute>
                                        <xsl:value-of select="substring-after(*,'-')"/>
                                </dateValid>
                            </xsl:when> 
                            
                            <!-- other -->
                            
                            <xsl:otherwise>
                                <dateValid>
                                   <xsl:value-of select="."/>
                                </dateValid>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:if>     
            </xsl:for-each> 
            
          <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:edition">
            <edition>
              <xsl:value-of select="."/>
            </edition>
          </xsl:for-each>
        </originInfo>
        <language>
          <languageTerm authority="iso639-2b">
            <xsl:value-of select="gmd:language/gmd:LanguageCode/@codeListValue"/>
          </languageTerm>
        </language>
        <physicalDescription>
          <form>
            <xsl:apply-templates select="gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name"/>
          </form>
          <xsl:for-each select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:transferSize">
            <extent>
              <xsl:value-of select="gco:Real"/>
              <xsl:choose>
                <xsl:when test="ancestor-or-self::*/gmd:MD_DigitalTransferOptions/gmd:unitsOfDistribution">
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="ancestor-or-self::*/gmd:MD_DigitalTransferOptions/gmd:unitsOfDistribution"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text> MB</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </extent>
              
            <!-- The digitalOrigin is coded here: 
               http://www.loc.gov/standards/mods/v3/mods-userguide-elements.html#digitalorigin
            -->
          </xsl:for-each>
          <digitalOrigin>born digital</digitalOrigin>
        </physicalDescription>
        <subject>
          <cartographics>
            <xsl:choose>
              <xsl:when test="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialResolution">
                <scale>
                  <xsl:text>1:</xsl:text>
                  <xsl:value-of select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialResolution/gmd:MD_Resolution/gmd:equivalentScale/gmd:MD_RepresentativeFraction/gmd:denominator/gco:Integer"/>
                </scale>
              </xsl:when>
              <xsl:otherwise>
                <scale>
                  <xsl:text>Scale not given.</xsl:text>
                </scale>
              </xsl:otherwise>
            </xsl:choose>
            <projection>
              <!-- Use '::' since the spec requires a version here (e.g., :7.4:) but it's generally left blank -->
              <xsl:value-of select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:codeSpace/gco:CharacterString"/>
              <xsl:text>::</xsl:text>
              <xsl:value-of select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:code/gco:CharacterString"/>
            </projection>
            <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox">
              <coordinates>
                <xsl:choose>
                  <xsl:when test="$geoformat = 'GMD'">
                    <gmd:EX_GeographicBoundingBox xmlns:gmd="http://www.isotc211.org/2005/gmd">
                      <gmd:westBoundLongitude>
                        <gco:Decimal>
                          <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/>
                        </gco:Decimal>
                      </gmd:westBoundLongitude>
                      <gmd:eastBoundLongitude>
                        <gco:Decimal>
                          <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/>
                        </gco:Decimal>
                      </gmd:eastBoundLongitude>
                      <gmd:southBoundLatitude>
                        <gco:Decimal>
                          <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
                        </gco:Decimal>
                      </gmd:southBoundLatitude>
                      <gmd:northBoundLatitude>
                        <gco:Decimal>
                          <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/>
                        </gco:Decimal>
                      </gmd:northBoundLatitude>
                    </gmd:EX_GeographicBoundingBox>
                  </xsl:when>
                  <!-- WKT is x y, x y
                    
                         POLYGON((sw, nw, ne, se, sw))
                         -->
                  <xsl:when test="$geoformat = 'WKT'">
                    <xsl:text>POLYGON((</xsl:text>
                    <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
                    <xsl:text>))</xsl:text>
                  </xsl:when>
                  <xsl:when test="$geoformat = 'WMS'">
                    <!-- WMS
                         Uses min/max as attributes
                         
                         Example:
                         
                         <wms:BoundingBox xmlns:wms="http://www.opengis.net/wms" 
                                          CRS="EPSG:4326" 
                                          minx="-97.119945" miny="25.467075" 
                                          maxx="-82.307619" maxy="30.665492"/>
                      -->
                    <wms:BoundingBox xmlns:wms="http://www.opengis.net/wms">
                      <xsl:attribute name="CRS">EPSG:4326</xsl:attribute>
                      <xsl:attribute name="minx">
                        <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/>
                      </xsl:attribute>
                      <xsl:attribute name="miny">
                        <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
                      </xsl:attribute>
                      <xsl:attribute name="maxx">
                        <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/>
                      </xsl:attribute>
                      <xsl:attribute name="maxy">
                        <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/>
                      </xsl:attribute>
                    </wms:BoundingBox>
                  </xsl:when>
                  <xsl:when test="$geoformat = 'GML'">
                    <!-- GML
                       Using SW and NE corners in (x, y) coordinates
                       
                       Example:
                       
                       <gml:Envelope xmlns:gml="http://www.opengis.net/gml/3.2" srsName="EPSG:4326">
                         <gml:lowerCorner>-97.119945 25.467075</gml:lowerCorner>
                         <gml:upperCorner>-82.307619 30.665492</gml:upperCorner>
                       </gml:Envelope>
                    -->
                    <gml:Envelope xmlns:gml="http://www.opengis.net/gml/3.2">
                      <xsl:attribute name="srsName">
                        <xsl:value-of select="//gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:codeSpace/gco:CharacterString"/>
                        <xsl:text>:</xsl:text>
                        <xsl:value-of select="//gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:code/gco:CharacterString"/>
                      </xsl:attribute>
                      <gml:lowerCorner>
                        <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
                      </gml:lowerCorner>
                      <gml:upperCorner>
                        <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/>
                      </gml:upperCorner>
                    </gml:Envelope>
                  </xsl:when>
                  <xsl:when test="$geoformat = 'GeoRSS'">
                    <!-- GeoRSS:
                      Rectangular envelope property element containing two pairs of coordinates 
                      (lower left envelope corner, upper right envelope corner) representing 
                      latitude then longitude in the WGS84 coordinate reference system.
                      
                      Example:
                      
                      <georss:box>42.943 -71.032 43.039 -69.856</georss:box>
                      -->
                    <georss:box xmlns:georss="http://www.georss.org/georss">
                      <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/>
                    </georss:box>
                  </xsl:when>
                  <xsl:when test="$geoformat = 'MARC034'">
                    <!-- MARC 034
                       Subfields $d, $e, $f, and $g always appear together. The coordinates 
                       may be recorded in the form hdddmmss (hemisphere-degrees-minutes-seconds), 
                       however, other forms are also allowed, such as decimal degrees. 
                       The subelements are each right justified and unused positions contain zeros.

                       $d - Coordinates - westernmost longitude (NR)
                       $e - Coordinates - easternmost longitude (NR)
                       $f - Coordinates - northernmost latitude (NR)
                       $g - Coordinates - southernmost latitude (NR)
                       
                       Example:
                       
                       $d-097.119945$e-082.307619$f+30.665492$g+25.467075

                       See http://www.w3.org/TR/1999/REC-xslt-19991116#format-number
                    -->
                    <xsl:text>$d</xsl:text>
                    <xsl:value-of select="format-number(gmd:westBoundLongitude/gco:Decimal, '+000.000000;-000.000000')"/>
                    <xsl:text>$e</xsl:text>
                    <xsl:value-of select="format-number(gmd:eastBoundLongitude/gco:Decimal, '+000.000000;-000.000000')"/>
                    <xsl:text>$f</xsl:text>
                    <xsl:value-of select="format-number(gmd:northBoundLatitude/gco:Decimal, '+00.000000;-00.000000')"/>
                    <xsl:text>$g</xsl:text>
                    <xsl:value-of select="format-number(gmd:southBoundLatitude/gco:Decimal, '+00.000000;-00.000000')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <!-- MARC 255 $c:
                         Coordinates are recorded in the order of 
                         westernmost longitude, easternmost longitude, 
                         northernmost latitude, and southernmost latitude,
                         and separated with double-hyphen and / characters.
                         
                         XXX: Note that this leaves the coordinates in decimal
                              degrees whereas 255c suggests deg-min-sec.
                         
                         Example:
                         
                         -97.119945 &#x002D;&#x002D; -82.307619/30.665492 &#x002D;&#x002D; 25.467075
                         
                         See http://www.loc.gov/marc/bibliographic/bd255.html $c
                         -->
                    <xsl:value-of select="gmd:westBoundLongitude/gco:Decimal"/>
                    <xsl:text> -- </xsl:text>
                    <xsl:value-of select="gmd:eastBoundLongitude/gco:Decimal"/>
                    <xsl:text>/</xsl:text>
                    <xsl:value-of select="gmd:northBoundLatitude/gco:Decimal"/>
                    <xsl:text> -- </xsl:text>
                    <xsl:value-of select="gmd:southBoundLatitude/gco:Decimal"/>
                  </xsl:otherwise>
                </xsl:choose>
              </coordinates>
            </xsl:for-each>
          </cartographics>
        </subject>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract">
          <abstract displayLabel="Abstract">
            <xsl:attribute name="lang">eng</xsl:attribute>
            <xsl:value-of select="gco:CharacterString"/>
          </abstract>
        </xsl:for-each>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:purpose">
          <abstract displayLabel="Purpose">
            <xsl:attribute name="lang">eng</xsl:attribute>
            <xsl:value-of select="gco:CharacterString"/>
          </abstract>
        </xsl:for-each>
        <!-- Reports, citation, other info, etc.  -->
        <xsl:for-each select="gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:report/gmd:DQ_ConceptualConsistency/gmd:evaluationMethodDescription">
          <note displayLabel="Conceptual consistency report">
            <xsl:attribute name="lang">eng</xsl:attribute>
            <xsl:value-of select="gco:CharacterString"/>
          </note>
        </xsl:for-each>
        <xsl:for-each select="gmd:dataQualityInfo/gmd:DQ_DataQuality/gmd:report/gmd:DQ_AbsoluteExternalPositionalAccuracy/gmd:evaluationMethodDescription">
          <note displayLabel="Attribute accuracy report">
            <xsl:attribute name="lang">eng</xsl:attribute>
            <xsl:value-of select="gco:CharacterString"/>
          </note>
        </xsl:for-each>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:credit">
          <note displayLabel="Preferred citation">
            <xsl:attribute name="lang">eng</xsl:attribute>
            <xsl:value-of select="gco:CharacterString"/>
          </note>
        </xsl:for-each>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:supplementalInformation">
          <note displayLabel="Supplemental information">
            <xsl:value-of select="gco:CharacterString"/>
          </note>
        </xsl:for-each>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_Constraints">
          <xsl:for-each select="gmd:useLimitation">
            <note displayLabel="Use limitation">
              <xsl:value-of select="gco:CharacterString"/>
            </note>
          </xsl:for-each>
        </xsl:for-each>
        <!-- MODS relatedItem type='host'-->
          <xsl:choose>
        <xsl:when test="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation">
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation">
          <xsl:if test="gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='largerWorkCitation']">
            <relatedItem>
              <xsl:attribute name="type">host</xsl:attribute>
              <titleInfo>
                <title>
                  <xsl:value-of select="gmd:aggregateDataSetName/gmd:CI_Citation/gmd:title"/>
                </title>
              </titleInfo>
              <typeOfResource collection="yes"/>
              <xsl:for-each select="gmd:aggregateDataSetName/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:organisationName">
                <xsl:if test="ancestor-or-self::gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='originator']">
                  <name type="corporate">
                    <namePart>
                      <xsl:value-of select="."/>
                    </namePart>
                  </name>
                </xsl:if>
              </xsl:for-each>
              <xsl:for-each select="gmd:aggregateDataSetName/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:personalName">
                <xsl:if test="ancestor-or-self::gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='originator']">
                <name type="personal">
                  <namePart>
                    <xsl:value-of select="."/>
                  </namePart>
                </name>
                </xsl:if>
              </xsl:for-each>
              <originInfo>
                <xsl:for-each select="gmd:aggregateDataSetName/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:organisationName">
                  <xsl:if test="ancestor-or-self::gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='publisher']">
                    <publisher>
                      <xsl:value-of select="."/>
                    </publisher>
                  </xsl:if>
                </xsl:for-each>
                <dateIssued encoding="w3cdtf">
                  <!-- strip MM-DD, oupput YYYY -->
                  <xsl:choose>
                    <xsl:when test="gmd:aggregateDataSetName/gmd:CI_Citation/gmd:date">
                      <xsl:value-of select="substring(gmd:aggregateDataSetName/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date,1,4)"/>
                    </xsl:when>
                    <xsl:otherwise>unknown</xsl:otherwise>
                  </xsl:choose>
                </dateIssued>
                <xsl:for-each select="gmd:aggregateDataSetName/gmd:CI_Citation/gmd:edition">
                  <edition>
                    <xsl:value-of select="."/>
                  </edition>
                </xsl:for-each>
              </originInfo>
               <xsl:for-each select="gmd:aggregateDataSetName/gmd:CI_Citation/gmd:series/gmd:CI_Series">
                      <relatedItem>
                          <xsl:attribute name="type">host</xsl:attribute>
                        <titleInfo>
                              <title>
                                  <xsl:value-of select="gmd:name"/>
                              </title>
                         </titleInfo>
                         <originInfo>
                              <dateIssued>
                                  <xsl:value-of select="gmd:issueIdentification"/>
                              </dateIssued>
                              <issuance>continuing</issuance>
                         </originInfo>
                      </relatedItem>
                  </xsl:for-each>
             </relatedItem>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:series/gmd:CI_Series">
          <relatedItem>
              <xsl:attribute name="type">host</xsl:attribute>
              <titleInfo>
                  <title>
                      <xsl:value-of select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:series/gmd:CI_Series/gmd:name"/>
                  </title>
              </titleInfo>
              <originInfo>
                  <dateIssued>
                      <xsl:value-of select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:series/gmd:CI_Series/gmd:issueIdentification"/>
                  </dateIssued>
                  <issuance>continuing</issuance>
              </originInfo>
          </relatedItem>   
      </xsl:when>        
    </xsl:choose>
    <!-- subjects: topic, geographic, temporal, ISO19115TopicCategory -->
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords">
          <xsl:if test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='theme']">
            <xsl:for-each select="gmd:keyword">
              <subject>
                <topic>
                  <xsl:if test="ancestor-or-self::*/gmd:thesaurusName/gmd:CI_Citation/gmd:title">
                    <xsl:attribute name="authority">
                      <!-- TODO: Should be case-insenstive compare -->
                      <xsl:choose>
                        <xsl:when test="ancestor-or-self::*/gmd:thesaurusName/gmd:CI_Citation/gmd:title='Library of Congress Subject Headings (LCSH)'">
                          <xsl:text>lcsh</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="ancestor-or-self::*/gmd:thesaurusName/gmd:CI_Citation/gmd:title"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:attribute>
                  </xsl:if>
                  <xsl:if test="ancestor-or-self::*/gmd:thesaurusName/gmd:CI_Citation/gmd:identifier">
                  <xsl:attribute name="authorityURI">
                    <xsl:value-of select="ancestor-or-self::*/gmd:thesaurusName/gmd:CI_Citation/gmd:identifier/gmd:MD_Identifier/gmd:code"/>
                  </xsl:attribute>
                  </xsl:if>
                    <xsl:attribute name="lang">
                        <xsl:value-of select="../../../../../gmd:language/gmd:LanguageCode"/>
                    </xsl:attribute>
                  <xsl:value-of select="."/>
                </topic>
              </subject>
            </xsl:for-each>
          </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords">
          <xsl:if test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']">
            <xsl:for-each select="gmd:keyword">
              <subject>
                <geographic>
                  <!-- adds geonames info through external process -->
                  <xsl:attribute name="lang">
                    <xsl:value-of select="../../../../../gmd:language/gmd:LanguageCode"/>
                  </xsl:attribute>
                  <xsl:value-of select="."/>
                </geographic>
              </subject>
            </xsl:for-each>
          </xsl:if>
        </xsl:for-each>
          
       <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords">
          <xsl:if test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='temporal']">
            <xsl:for-each select="gmd:keyword">
                   
                <xsl:choose>
                    
                <!-- 4 digit year -->
                            <xsl:when test="string-length()=4">
                                <subject>
                                    <temporal>
                                        <xsl:attribute name="encoding">w3cdtf</xsl:attribute>
                                            <xsl:value-of select="."/>
                                    </temporal>
                                </subject>
                            </xsl:when>
                  
                 <!-- range of dates in YYYY-YYYY format -->
                  
                            <xsl:when test="contains(./*,'-')">
                                <subject>
                                    <temporal>
                                        <xsl:attribute name="encoding">w3cdtf</xsl:attribute>
                                 <xsl:attribute name="point">start</xsl:attribute>
                                     <xsl:value-of select="substring-before(*,'-')"/>
                                    </temporal>
                                    <temporal>
                                        <xsl:attribute name="encoding">w3cdtf</xsl:attribute>
                                        <xsl:attribute name="point">end</xsl:attribute>
                                        <xsl:value-of select="substring-after(*,'-')"/>
                                    </temporal>
                                </subject>
                            </xsl:when> 
                        
                 <!-- other -->
                    
                    <xsl:otherwise>
                        <subject>
                            <temporal>
                                <xsl:value-of select="."/>
                            </temporal>
                        </subject>
                    </xsl:otherwise>
                        
                    </xsl:choose>
              </xsl:for-each>
          </xsl:if>     
        </xsl:for-each> 
       
               
            
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode">
          <subject>
            <topic>
              <xsl:attribute name="authority">ISO19115TopicCategory</xsl:attribute>
               
             <!-- kd: do we need authorityURI? -->
               <xsl:attribute name="authorityURI">
                 <xsl:text>http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_TopicCategoryCode</xsl:text>
                </xsl:attribute>
              <xsl:choose>
                <xsl:when test="contains(.,'farming')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Farming</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'biota')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Biology and Ecology</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'climatologyMeteorologyAtmosphere')">\
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Climatology, Meteorology and Atmosphere</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'boundaries')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Boundaries</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'elevation')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Elevation</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'environment')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Environment</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'geoscientificInformation')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Geoscientific Information</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'health')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Health</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'imageryBaseMapsEarthCover')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Imagery and Base Maps</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'intelligenceMilitary')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Military</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'inlandWaters')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Inland Waters</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'location')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Location</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'oceans')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Oceans</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'planningCadastre')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Planning and Cadastral</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'structural')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Structures</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'transportation')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Transportation</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'utilitiesCommunication')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Utilities and Communication</xsl:text>
                </xsl:when>
                <xsl:when test="contains(.,'society')">
                  <xsl:attribute name="valueURI"><xsl:value-of select="."/></xsl:attribute>
                  <xsl:text>Society</xsl:text>
                </xsl:when>
              </xsl:choose>
            </topic>
          </subject>
        </xsl:for-each>
        <!-- TODO: Need a metadata practice for GIS Dataset's Online Resource. -->
        <!-- access rights to be mapped from restrictionCode/otherRestrictions/APO -->
        <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints">
          <accessCondition type="useAndReproduction">
            <xsl:value-of select=". "/>
          </accessCondition>
        </xsl:for-each>
        
        <!-- Output geo extension to MODS -->
        <xsl:if test="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox">
          <extension displayLabel="geo" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description>
                <xsl:attribute name="rdf:about">
                  <xsl:value-of select="$purl"/>
                </xsl:attribute>
                <!-- Output MIME type -->
                <dc:format>
                  <xsl:value-of select="$format"/>
                </dc:format>
                <!-- Output Dataset# point, linestring, polygon, raster, etc. -->
                <dc:type>
                  <xsl:text>Dataset#</xsl:text>
                  <xsl:value-of select="$geometryType"/>
                </dc:type>
                <!-- Output bounding box -->
                <gml:boundedBy>
                  <gml:Envelope>
                    <xsl:attribute name="gml:srsName">
                      <xsl:value-of select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:codeSpace/gco:CharacterString"/>
                      <xsl:text>:</xsl:text>
                      <xsl:value-of select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:code/gco:CharacterString"/>
                    </xsl:attribute>
                    <gml:lowerCorner>
                      <xsl:value-of select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal"/>
                    </gml:lowerCorner>
                    <gml:upperCorner>
                      <xsl:value-of select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal"/>
                    </gml:upperCorner>
                  </gml:Envelope>
                </gml:boundedBy>
                <!-- Output linked data to GeoNames: An external process will clean these up -->
                <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords">
                  <xsl:if test="gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']">
                    <xsl:for-each select="gmd:keyword">
                      <dc:coverage>
                        <xsl:attribute name="rdf:resource">
                          <xsl:value-of select="../../@xlink:href"/>
                        </xsl:attribute>
                        <xsl:attribute name="dc:language">
                          <xsl:value-of select="../../../../../gmd:language/gmd:LanguageCode"/>
                        </xsl:attribute>
                        <xsl:attribute name="dc:title">
                          <xsl:value-of select="."/>
                        </xsl:attribute>
                      </dc:coverage>
                    </xsl:for-each>
                  </xsl:if>
                </xsl:for-each>
              </rdf:Description>
            </rdf:RDF>
          </extension>
        </xsl:if>
      </xsl:for-each>
    </mods>
  </xsl:template>
</xsl:stylesheet>