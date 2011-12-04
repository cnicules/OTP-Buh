<!-- Extract a route html file from file with html for all routes of type.

  Input File: ...-stop-matching-log.html
    (contains summary counts, routes-list, individual route logs)

    <html>
      <head>
        <title>Subway-stop Name Matching Log</title>
        <style>...</style>
      </head>
      <body>
        <div id="summary-counts">
          ...
        </div>
        <div id="routes-list">
          ...
        </div>
        <div class="route-log" id="RATB-tram-1">
          ...
        </div>
        <div class="route-log" id="RATB-tram-4">
          ...
        </div>
        ... (continue to last tram route, tram-56)
      </body>
    </html>

  Param agency: Name of agency, such as Metrorex or RATB.
  Param routeType: one of subway, tram, trolleybus, urbanbus
  Param routeShortName: short name of route, such as "M1".

  Output file: ...stops-matched/RATB-tram/RATB-tram-1.html

    <html>
      <head>
        <title>Metrorex Tram-1 Subway-stop Name Matching Log</title>
        <style>...</style>
      </head>
      <body>
        <a href="..">Metrorex subway</a>
        <div class="route-log" id="RATB-tram-1">
          ...
        </div>
      </body>
    </html>

-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>

  <xsl:param name="agency" select="'Metrorex'"/>
  <xsl:param name="routeType" select="'subway'"/>
  <xsl:param name="routeShortName" select="'M1'"/>

  <xsl:template match="/html">
    <xsl:text>&#xA;</xsl:text>
    <html>
      <xsl:apply-templates/>
      <xsl:text>&#xA;</xsl:text>
    </html>
  </xsl:template>

  <xsl:template match="head">
    <xsl:text>&#xA;</xsl:text>
    <head><xsl:text>&#xA;</xsl:text>
    <title>
      <xsl:value-of select="$agency"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$routeShortName"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="title"/>
    </title>
    <xsl:text>&#xA;</xsl:text>
    <style><xsl:value-of select="style"/></style>
    <xsl:text>&#xA;</xsl:text>
                
    </head><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="body">
    <body><xsl:text>&#xA;</xsl:text>
      <p>
        <a href="index.html">
          <xsl:value-of select="concat($agency, ' ', $routeType)"/>
        </a>
      </p>
      <xsl:apply-templates/>
    </body>
  </xsl:template>  

  <xsl:template
    match="div[@id=concat($agency, '-', $routeType, '-', $routeShortName)]">
    <div>
      <xsl:for-each select="@*">
        <xsl:attribute name="{name()}">
          <xsl:value-of select="."/>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="h3">
    <h3>
      <xsl:value-of select="$agency"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$routeShortName"/>
      <xsl:text> </xsl:text>
      <xsl:copy-of select="text()"/>
    </h3>
  </xsl:template>

  <xsl:template match="h2|h3|h4|h5|abbr|p|a|table|thead|tbody|tr|th|td">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="*">
  </xsl:template>

</xsl:transform>
