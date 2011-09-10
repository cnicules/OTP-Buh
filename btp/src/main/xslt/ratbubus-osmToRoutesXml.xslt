<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:param name="stopSeqsXml"/>
  <xsl:param name="stopSeqs" select="document($stopSeqsXml)/stop-sequences"/>

  <xsl:template match="/">
    <xsl:text>&#xA;</xsl:text>
    <routes>  

      <xsl:for-each select="osm/relation[tag[@k='route' and @v='bus']]">
        <xsl:sort select="tag[@k='ref']/@v" data-type="number"/>
        <xsl:variable name="routeShortName" select="tag[@k='ref']/@v"/>
        <xsl:variable name="routeStopSeq"
          select="$stopSeqs/route[@short_name = $routeShortName]
                                 /stop-sequence[@dir='forward']"/>

        <xsl:text>&#xA;  </xsl:text>
        <xsl:choose>
          <xsl:when test="'' = normalize-space($routeShortName)">
            <xsl:comment>
              <xsl:text>OSM bus route id=</xsl:text>
              <xsl:value-of select="@id"/>
              <xsl:text> has no 'ref' tag (containing RATB route number).</xsl:text>
            </xsl:comment>
            <xsl:message>
              <xsl:text>OSM bus route id=</xsl:text>
              <xsl:value-of select="@id"/>
              <xsl:text> has no 'ref' tag (containing RATB route number).</xsl:text>
            </xsl:message>
          </xsl:when>
          <xsl:when test="count($routeStopSeq) = 0">
            <xsl:comment>
              <xsl:text>OSM bus route id=</xsl:text>
              <xsl:value-of select="@id"/>
              <xsl:text> has unknown RATB urbanbus route number: </xsl:text>
              <xsl:value-of select="$routeShortName"/>
            </xsl:comment>
            <xsl:message>
              <xsl:text>OSM bus route id=</xsl:text>
              <xsl:value-of select="@id"/>
              <xsl:text> has unknown RATB urbanbus route number: </xsl:text>
              <xsl:value-of select="$routeShortName"/>
            </xsl:message>
          </xsl:when>
          <xsl:otherwise>
            <route>
              <!-- route_id -->
              <xsl:attribute name="route_id">
                <xsl:value-of select="@id"/>
              </xsl:attribute>

              <!-- agency_id -->
              <xsl:attribute name="agency_id">
                <xsl:value-of select="tag[@k='operator']/@v"/>
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

              <!-- route_type: 3=bus (future: 704 Local bus service) -->
              <xsl:attribute name="route_type">
                <xsl:text>3</xsl:text>
              </xsl:attribute>

              <!-- route_color: gray (not yet used by OTP) -->
              <xsl:attribute name="route_color">
                <xsl:text>888888</xsl:text>
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
