<!-- Convert *-routes.xml to GTFS routes.txt

  Input document: *-routes.xml (xml form of routes.txt)
    <routes>
      <route route_id="[osmRouteId]" agency_id="[agencyId]"
             route_short_name="[routeNumber]"
             route_long_name="[beginStopName] - [endStopName]"
             route_type="3"
             route_color="888888"
             route_text_color="FFFFFF"/>
       ...
    </routes>

  Output document:
    route_id,agency_id,route_short_name,route_long_name,route_type,route_color,route_text_color

    [osmRouteId],[agencyId],[routeNumber],[routeLongName],3,888888,FFFFFF
    [osmRouteId],[agencyId],[routeNumber],[routeLongName],3,888888,FFFFFF
    ...

-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <!-- output csv lines in format for GTFS routes.txt -->

  <xsl:template match="/routes">
    <xsl:text>route_id,agency_id,route_short_name,route_long_name,route_type,route_color,route_text_color&#xA;&#xA;</xsl:text>

    <xsl:for-each select="route">
      
      <!-- route_id -->
      <xsl:value-of select="@route_id"/>
      <xsl:text>,</xsl:text>

      <!-- agency_id -->
      <xsl:value-of select="@agency_id"/>
      <xsl:text>,</xsl:text>

      <!-- route_short_name -->
      <xsl:value-of select="@route_short_name"/>
      <xsl:text>,</xsl:text>

      <!-- route_long_name -->
      <xsl:text>&quot;</xsl:text>
      <xsl:value-of select="@route_long_name"/>
      <xsl:text>&quot;</xsl:text>
      <xsl:text>,</xsl:text>

      <!-- route_type: 1=subway (future: 401=metro) -->
      <xsl:value-of select="@route_type"/>
      <xsl:text>,</xsl:text>

      <!-- route_color: match map from Metrorex site -->
      <xsl:value-of select="@route_color"/>
      <xsl:text>,</xsl:text>

      <!-- route_text_color: white  -->
      <xsl:value-of select="@route_text_color"/>
      <xsl:text>&#xA;</xsl:text>

    </xsl:for-each>

  </xsl:template>

</xsl:transform>
