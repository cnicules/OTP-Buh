<!-- Extract list of logged routeIds from ...-stop-matching-log.html .
     Used only for Metrorex, which does not previously list subway lines.

  Input file: ...-stop-matching-log.html
    <html>
      <head>
        <title>...</title>
        <style>...</style>
      </head>
      <body>
        <div id="summary-counts">
          ...
        </div>
        <div id="routes-list">
          ...
        </div>
        <div class="route-log" id="Metrorex-subway-M1">
          ...
        </div>
        <div class="route-log" id="Metrorex-subway-M2">
          ...
        </div>
        <div class="route-log" id="Metrorex-subway-M3">
          ...
        </div>
        <div class="route-log" id="Metrorex-subway-M4">
          ...
        </div>
      </body>
    </html>

  Output file:
    M1
    M2
    M3
    M4    
-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:template match="/html/body/div[@class='route-log']">
    <xsl:value-of select="substring-after(substring-after(@id,'-'),'-')"/>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="text()">
  </xsl:template>
</xsl:transform>
