<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/route-stops">
    <xsl:text>&#xA;</xsl:text>
    <stops>

      <xsl:for-each select="route/stop">
        <!-- sort by id to group duplicates -->
        <xsl:sort select="@stop_id" data-type="number"/>
        <xsl:text>&#xA;  </xsl:text>
        <stop>
          <xsl:for-each select="@*">
            <xsl:copy/>
          </xsl:for-each>
        </stop>
      </xsl:for-each>

      <xsl:text>&#xA;</xsl:text>
    </stops>
  </xsl:template>
</xsl:transform>