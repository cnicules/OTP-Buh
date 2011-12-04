<!-- The goal of xhtmlSplit is to split html log of routes-of-agency-type into
       - overview/index and
       - page for each route.
     This file's transform does the first part, extracting the overview page.
     Overview page contains summary counts for all routes-of-agency-type, and
     summary counts for each route, and omits route logs of stop messages.
     Converts hrefs to link to separate page for each route's stop table.

  Input File: ...-stop-matching-log.html
    (contains summary counts, routes-list, individual route logs)

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
          <h3>Routes</h3>
          <p>
            <a href="#RATB-tram-1-row">1</a>
            <a href="#RATB-tram-4-row">4</a>
            ...
            <a href="#RATB-tram-56-row">56</a>
          </p>
          <table class="routesList">
            ...
            <tbody>
              <tr id="RATB-tram-1-row">
                <th rowspan="4"><a href="#RATB-tram-1">Tram 1</a></th>
                <td class="dir"><a href="#RATB-tram-1-Forward-0-41">F</a></th>
                ...
              </tr>
              <tr><td/>
                <td><table class="stopDots"
                           href="#RATB-tram-1-Forward-SchedStop-">...</table>
                </td><td/><td/>
              </tr>
              <tr>
                <td class="dir"><a href="#RATB-tram-1-Reverse-0-42">R</a></th>
                ...
              </tr>
              <tr><td/>
                <td><table class="stopDots"
                           href="#RATB-tram-1-Reverse-SchedStop-">...</table>
                </td><td/><td/>
              </tr>

              <tr id="RATB-tram-4-row">
                <th rowspan="4"><a href="#RATB-tram-4">Tram 4</a></th>
                <td class="dir"><a href="#RATB-tram-4-Forward-0-10">F</a></th>
                ...
              </tr>
              <tr><td/>
                <td><table class="stopDots"
                           href="#RATB-tram-1-Forward-SchedStop-">...</table>
                </td><td/><td/>
              </tr>
              <tr>
                <td class="dir"><a href="#RATB-tram-4-Reverse-0-11">R</a></th>
                ...
              </tr>
              <tr><td/>
                <td><table class="stopDots"
                           href="#RATB-tram-1-Reverse-SchedStop-">...</table>
                </td><td/><td/>
              </tr>
               ... (continue to last tram route, tram-56)
            </tbody>
          </table>
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
         
  Output file: stops-matched/$routeType/index.html  
    (omits individual route logs; contains summary counts and routes-list
     with links to route logs converted to point into route log file.)

    <html>
      <head>
        <title>... Index</title>
        <style>...</style>
      </head>
      <body>
        <h1>...-stop Name Matching Log Index</h1>
        <div id="summary-counts">
          ...
        </div>
        <div id="routes-list">
          <h3>Routes</h3>
          <p>
            <a href="#RATB-tram-1-row">1</a>
            <a href="#RATB-tram-4-row">4</a>
            ...
            <a href="#RATB-tram-56-row">56</a>
          </p>
          <table class="routesList">
            ...
            <tbody>
              <tr id="RATB-tram-1-row">
                <th rowspan="4"><a href="RATB-Tram-1.html#RATB-tram-1">Tram 1</a></th>
                <td class="dir"><a href="RATB-Tram-1.html#RATB-tram-1-Forward-0-41">F</a></th>
                ...
              </tr>
              <tr><td/>
                <td><table class="stopDots"
                        href="RATB-Tram-1.html#RATB-tram-1-Forward-SchedStop-">
                      ...</table>
                </td><td/><td/>
              </tr>
              <tr>
                <td class="dir"><a href="RATB-Tram-1.html#RATB-tram-1-Reverse-0-42">R</a></th>
                ...
              </tr>
              <tr><td/>
                <td><table class="stopDots"
                        href="RATB-Tram-1.html#RATB-tram-1-Reverse-SchedStop-">
                      ...</table>
                </td><td/><td/>
              </tr>

              <tr id="RATB-tram-4-row">
                <th rowspan="4"><a href="RATB-Tram-4.html#RATB-tram-4">Tram 4</a></th>
                <td class="dir"><a href="RATB-Tram-4.html#RATB-tram-4-Forward-0-10">F</a></th>
                ...
              </tr>
              <tr><td/>
                <td><table class="stopDots"
                        href="RATB-Tram-4.html#RATB-tram-4-Forward-SchedStop-">
                      ...</table>
                </td><td/><td/>
              </tr>
              <tr>
                <td class="dir"><a href="RATB-Tram-4.html#RATB-tram-4-Reverse-0-11">R</a></th>
                ...
              </tr>
              <tr><td/>
                <td><table class="stopDots"
                        href="RATB-Tram-4.html#RATB-tram-4-Reverse-SchedStop-">
                      ...</table>
                </td><td/><td/>
              </tr>
               ... (continue to last tram route, #56)
            </tbody>
          </table>
        </div>
        [route-logs omitted]
      </body>
    </html>
-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>

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
    <title><xsl:value-of select="title"/> Index</title>
    <xsl:text>&#xA;</xsl:text>
    <style><xsl:value-of select="style"/></style>
    <xsl:text>&#xA;</xsl:text>
                
    </head><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="body">
    <body><xsl:text>&#xA;</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>&#xA;</xsl:text>
    </body><xsl:text>&#xA;</xsl:text>
  </xsl:template>  

  <xsl:template match="div[@id='summary-counts']">
    <xsl:text>&#xA;</xsl:text>
    <div id="summary-counts">
      <xsl:text>&#xA;</xsl:text>
      <xsl:copy-of select="*"/>
    </div>
  </xsl:template>

  <xsl:template match="div[@id='routes-list']">
    <div id="routes-list">
      <xsl:apply-templates/>      
    </div>
  </xsl:template>

  <xsl:template match="a[parent::p/parent::div/@id='routes-list']">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="table|thead|tbody|tr|th|td">
    <xsl:element name="{name()}">
      <xsl:for-each select="@*">  <!--copy attributes, converting href="#..."-->
        <xsl:attribute name="{name()}">
          <xsl:choose>
            <xsl:when test="name()='href' and starts-with(., '#')">
              <xsl:call-template name="to-file-href">
                <xsl:with-param name="href" select="substring-after(., '#')"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="."/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates/>       <!--copy content-->
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="a[starts-with(@href,'#') and
                         ancestor::table/@class='routesList']">
    <a>
      <xsl:attribute name="href">
        <xsl:call-template name="to-file-href">
          <xsl:with-param name="href" select="substring-after(@href, '#')"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:value-of select="string(.)"/>
    </a>
  </xsl:template>

  <xsl:template name="to-file-href">
    <xsl:param name="href"/>
    
    <xsl:choose>
      <xsl:when test="contains($href,'-Forward')">
        <xsl:value-of
          select="substring-before($href, '-Forward')"/>
        <xsl:text>.html#</xsl:text>
        <xsl:value-of select="$href"/>
      </xsl:when>
      <xsl:when test="contains($href,'-Reverse')">
        <xsl:value-of
          select="substring-before($href, '-Reverse')"/>
        <xsl:text>.html#</xsl:text>
        <xsl:value-of select="$href"/>
      </xsl:when>
      <xsl:when test="contains($href,'-MapStopsUnmatched')">
        <xsl:value-of
          select="substring-before($href, '-MapStopsUnmatched')"/>
        <xsl:text>.html#</xsl:text>
        <xsl:value-of select="$href"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$href"/>
        <xsl:text>.html</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h1">
    <h1><xsl:value-of select="."/> Index</h1>
  </xsl:template>

  <xsl:template match="h2|h3|h4|h5|abbr|p">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <xsl:template match="*">
  </xsl:template>
</xsl:transform>
