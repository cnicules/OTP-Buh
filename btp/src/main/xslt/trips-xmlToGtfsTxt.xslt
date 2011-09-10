<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <!-- output csv lines in format for GTFS trips.txt -->

  <xsl:template match="/trips">
    <xsl:text>trip_id,route_id,direction_id,service_id&#xA;&#xA;</xsl:text>

    <xsl:for-each select="trip">
      
      <!-- trip_id -->
      <xsl:value-of select="@trip_id"/>
      <xsl:text>,</xsl:text>

      <!-- route_id -->
      <xsl:value-of select="@route_id"/>
      <xsl:text>,</xsl:text>

      <!-- direction -->
      <xsl:value-of select="@direction_id"/>
      <xsl:text>,</xsl:text>

      <!-- service_id -->
      <xsl:value-of select="@service_id"/>
      <xsl:text>&#xA;</xsl:text>

    </xsl:for-each>

  </xsl:template>

</xsl:transform>
