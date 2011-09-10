<!-- Create a txt file with one gtfs zip file per line.
     (Used as a list of source files in build-otp.xml target otp-build-graph.)

  Input document: gtfs-inputs.xml
    <gtfs-files>
      <gtfs-file defaultAgencyId="Metrorex" path="[filePathToSubwayGtfsZip]"/>
      <gtfs-file defaultAgencyId="RATB" path="[filePathToTramGtfsZip]"/>
      <gtfs-file defaultAgencyId="RATB" path="[filePathToTrolleybusGtfsZip]"/>
      <gtfs-file defaultAgencyId="RATB" path="[filePathToUrbanbusGtfsZip]"/>
      ...
    </gtfs-files>
  
  Output document: gtfs-inputs.txt
    [filePathToSubwayGtfsZip]    
    [filePathToTramGtfsZip]
    [filePathToTrolleybusGtfsZip]
    [filePathToUrbanbusGtfsZip]
    ...
-->
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