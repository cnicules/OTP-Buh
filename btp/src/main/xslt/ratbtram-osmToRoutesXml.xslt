<!-- Extract tram route ids, names, and types from OSM route relations.
  Warn if tram route relation in OSM data has no or empty "ref" tag.
  Warn if [routeNumber] in OSM data is not found in stop-sequences.

  Input document: OpenStreetMap .osm map file.
    <osm>
      <node>...</node>
      ...
      <way>...</way>
      ...
      <relation id="[osmRouteId]">
        <tag k="route" v="tram"/>
        <tag k="ref" v="[routeNumber]"/>
        <tag k="operator" v="[agency]"/>
        <tag k="name" v="[routeLongName]"/>
        <nd ... />
        ...
        <way ... />
        ...
      </relation>
      ...
    </osm>
  
  Param stopSeqsXml: ratbtram-stopsequences.xml
    <stop-sequences>
      <route short_name="[routeNumber]">
        <stop-sequence dir="forward">
          <stop number="0" street="[rdName]" name="[begStopName]"/>
          <stop number="1" street="[rdName]" name="[stopName]"/>
          ...
          <stop number="?" street="[rdName]" name="[endStopName]"/>
        </stop-sequence>
        <stop-sequence dir="backward">
          <stop number="0" street="[rdName]" name="[endStopName]"/>
          <stop number="1" street="[rdName]" name="[stopName]"/>
          ...
          <stop number="?" street="[rdName]" name="[begStopName]"/>
        </stop-sequence>
      </route>
      ...
    </stop-sequences>

  Output document: xml form of GTFS routes.txt 
    <routes>
      <route route_id="[osmRouteId]" agency_id="[agencyId]"
             route_short_name="[routeNumber]"
             route_long_name="[beginStopName] - [endStopName]"
             route_type="0"
             route_color="FF0000"
             route_text_color="FFFFFF"/>
       ...
    </routes>
-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:param name="stopSeqsXml"/>
  <xsl:param name="stopSeqs" select="document($stopSeqsXml)/stop-sequences"/>

  <xsl:template match="/">
    <xsl:text>&#xA;</xsl:text>
    <routes>  

      <xsl:for-each select="osm/relation/tag[@k='route' and @v='tram']">
        <xsl:sort select="../tag[@k='ref']/@v" data-type="number"/>
        <xsl:variable name="routeShortName" select="../tag[@k='ref']/@v"/>
        <xsl:variable name="routeStopSeq"
          select="$stopSeqs/route[@short_name = $routeShortName]
                                 /stop-sequence[@dir='forward']"/>

        <xsl:text>&#xA;  </xsl:text>
        <xsl:choose>
          <xsl:when test="'' = normalize-space($routeShortName)">
            <xsl:comment>
              <xsl:text>OSM tram route id=</xsl:text>
              <xsl:value-of select="@id"/>
              <xsl:text> has no 'ref' tag (containing RATB route number).</xsl:text>
            </xsl:comment>
            <xsl:message>
              <xsl:text>OSM tram route id=</xsl:text>
              <xsl:value-of select="@id"/>
              <xsl:text> has no 'ref' tag (containing RATB route number).</xsl:text>
            </xsl:message>
          </xsl:when>
          <xsl:when test="count($routeStopSeq) = 0">
            <xsl:comment>
              <xsl:text>OSM tram route id=</xsl:text>
              <xsl:value-of select="@id"/>
              <xsl:text> has unknown RATB route number: </xsl:text>
              <xsl:value-of select="$routeShortName"/>
            </xsl:comment>
            <xsl:message>
              <xsl:text>OSM tram route id=</xsl:text>
              <xsl:value-of select="@id"/>
              <xsl:text> has unknown RATB route number: </xsl:text>
              <xsl:value-of select="$routeShortName"/>
            </xsl:message>
          </xsl:when>
          <xsl:otherwise>
            <route>
              <!-- route_id -->
              <xsl:attribute name="route_id">
                <xsl:value-of select="../@id"/>
              </xsl:attribute>

              <!-- agency_id -->
              <xsl:attribute name="agency_id">
                <xsl:value-of select="../tag[@k='operator']/@v"/>
              </xsl:attribute>

              <!-- route_short_name -->
              <xsl:attribute name="route_short_name">
                <xsl:value-of select="$routeShortName"/>
              </xsl:attribute>

              <!-- route_long_name -->
              <xsl:attribute name="route_long_name">
                <!-- <xsl:value-of select="../tag[@k='name']/@v"/> -->
                <xsl:variable name="beginStop"
                  select="$routeStopSeq/stop[1]/@name"/>
                <xsl:variable name="endStop"
                  select="$routeStopSeq/stop[last()]/@name"/>
                <xsl:value-of select="concat($beginStop, ' - ', $endStop)"/>
              </xsl:attribute>

              <!-- route_type: 0=tram (future: 900=tram) -->
              <xsl:attribute name="route_type">
                <xsl:text>0</xsl:text>
              </xsl:attribute>

              <!-- route_color: red (not yet used by OTP) -->
              <xsl:attribute name="route_color">
                <xsl:text>FF0000</xsl:text>
              </xsl:attribute>

              <!-- route_text_color: white (not yet used by OTP) -->
              <xsl:attribute name="route_text_color">
                <xsl:text>FFFFFF</xsl:text>
              </xsl:attribute>

            </route>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>

      <xsl:text>&#xA;</xsl:text>
    </routes>
  </xsl:template>

</xsl:transform>
