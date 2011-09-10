<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/">
    <xsl:text>&#xA;</xsl:text>
    <routes>
      <xsl:for-each select="osm/relation/tag[@k='route' and @v='subway']">
        <xsl:sort select="../tag[@k='ref']/@v"/>
        <xsl:variable name="routeShortName" select="../tag[@k='ref']/@v"/>

        <xsl:text>&#xA;  </xsl:text>
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
            <xsl:value-of select="../tag[@k='name']/@v"/>
          </xsl:attribute>

          <!-- route_type: 1=subway (future: 401=metro) -->
          <xsl:attribute name="route_type">
            <xsl:text>1</xsl:text>
          </xsl:attribute>

          <!-- route_color: match Metrorex map (not yet used by OTP) -->
          <xsl:attribute name="route_color">
            <xsl:choose>
              <xsl:when test="$routeShortName = 'M1'">
                <xsl:text>F7D000</xsl:text>
              </xsl:when>
              <xsl:when test="$routeShortName = 'M2'">
                <xsl:text>000080</xsl:text>
              </xsl:when>
              <xsl:when test="$routeShortName = 'M3'">
                <xsl:text>DD0000</xsl:text>
              </xsl:when>
              <xsl:when test="$routeShortName = 'M4'">
                <xsl:text>008000</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring(../tag[@k='color']/@v, 2)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>

          <!-- route_text_color: white (not yet used by OTP) -->
          <xsl:attribute name="route_text_color">
            <xsl:text>FFFFFF</xsl:text>
          </xsl:attribute>

        </route>
      </xsl:for-each>

    <xsl:text>&#xA;</xsl:text>
    </routes>
  </xsl:template>

</xsl:transform>
