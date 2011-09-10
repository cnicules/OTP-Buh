<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <!-- emit one path per line -->
  <xsl:template match="/gtfs-files">
    <xsl:for-each select="gtfs-file">
      <xsl:value-of select="@path"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:transform>