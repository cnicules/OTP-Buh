<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/stop-times">
    <xsl:text>trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign&#xA;&#xA;</xsl:text>

    <xsl:for-each select="stop-time">
      <xsl:value-of select="@trip_id"/>
      <xsl:text>,</xsl:text>
      
      <xsl:value-of select="@arrival_time"/>
      <xsl:text>,</xsl:text>

      <xsl:value-of select="@departure_time"/>
      <xsl:text>,</xsl:text>

      <xsl:value-of select="@stop_id"/>
      <xsl:text>,</xsl:text>

      <xsl:value-of select="@stop_sequence"/>
      <xsl:text>,</xsl:text>

      <xsl:text>&quot;</xsl:text>
      <xsl:value-of select="@stop_headsign"/>
      <xsl:text>&quot;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:transform>
