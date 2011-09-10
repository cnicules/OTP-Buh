<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/stops">
    <xsl:text>stop_id,stop_lat,stop_lon,stop_name&#xA;&#xA;</xsl:text>
    <!-- omit duplicate stop_ids -->
    <xsl:for-each
      select="stop[position() = 1 or
                   @stop_id != preceding-sibling::stop[1]/@stop_id]">
      <!-- keep original order so most neighbors will be nearby in memory -->

      <!-- stop_id -->
      <xsl:value-of select="@stop_id"/>
      <xsl:text>,</xsl:text>
      
      <xsl:value-of select="@stop_lat"/>
      <xsl:text>,</xsl:text>
      
      <xsl:value-of select="@stop_lon"/>
      <xsl:text>,</xsl:text>
      
      <xsl:text>&quot;</xsl:text>
      <xsl:choose>
        <xsl:when test="string-length(@stop_name) &gt; 0">
          <xsl:value-of select="@stop_name"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('(unnamed stop ', @stop_id, ')')"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&quot;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
      
    </xsl:for-each>
  </xsl:template>

</xsl:transform>