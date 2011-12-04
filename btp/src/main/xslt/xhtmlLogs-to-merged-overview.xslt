<!-- Merge the route-type summary overviews from each route-type index into
     an overall overview table.

  Input document: src/main/xml/stops-matched-overview-skeleton.xhtml
    <html>

    <head>
    <title>Bucharest Transit-Stop Names Matched: Overview</title>
    </head>

    <body>
    <h1>Bucharest Transit-Stop Names Matched: Overview</h1>

    <table class="summary-counts">
    <thead/>
    <tbody id="metrorex-summary-counts"/>
    <tbody id="ratbtram-summary-counts"/>
    <tbody id="ratbtrob-summary-counts"/>
    <tbody id="ratbubus-summary-counts"/>
    </table>

    </body>
    </html>

  Param metrorexLogXhtml:
   Summary counts (2011-11-19 21:20-0500)

   Agency  |Routes w/>=2 stops |Sched stop names   |Map stop names|MatchedStops
    Type   |All=Match+Subst+Mis|All=Match+Subst+Mis|All=Match+Miss|Misplace Ambig
   ~~~~~~~~+~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
   Metrorex|  6=   6 +  0  +  0|128= 128 + 0   + 0 |519= 402 + 117|   0      6
    Subway |    GGGGGGGGGGGGGGG|     GGGGGGGGGGGGGG|    GGGGGGGGMM|

   Routes
   ...
  Param ratbtramLogXhtml
   Summary counts (2011-11-19 21:20-0500)

   Agency|Routes w/>=2 stops  |Sched stop names    |Map stop names|MatchedStops
    Type |All=Match+Subst+Miss|All=Match+Subst+Miss|All=Match+Miss|Misplace Ambig
   ~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
    RATB | 25=  21 +  0  +  4 |1033=402 + 39  + 592|519= 402 + 117|  21     55
    Tram |    GGGGGGGGGGGGRRR |     GGGGGGORRRRRRRR|    GGGGGGGGMM|

   Routes
   ...
  Param ratbtrobLogXhtml
   Summary counts (2011-11-19 21:20-0500)

   Agency|Routes w/>=2 stops |Sched stop names    |Map stop names|MatchedStops
    Type |All=Match+Subst+Mis|All=Match+Subst+Miss|All=Match+Miss|Misplace Ambig
   ~~~~~~+~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
    RATB | 19=  3  +  6  + 10|744=  98 +  57 + 589|108=  98 +  10|   0     74
   Tr'bus|    GGOOOORRRRRRRR |    GGORRRRRRRRRRRRR|    GGGGGGGGMM|

   Routes
   ...
  Param ratbubusLogXhtml
   Summary counts (2011-11-19 21:20-0500)

   Agency|Routes w/>=2 stops |Sched stop names    |Map stop names|MatchedStops
    Type |All=Match+Subst+Mis|All=Match+Subst+Miss|All=Match+Miss|Misplace Ambig
   ~~~~~~+~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
    RATB | 67=  21  + 29 + 17|2644= 266+ 409 +1969|361=  266+  95|  26      107
   ur'bus|    GGGGGOOOOOORRRR|     GOORRRRRRRRRRRR|    GGGGGGGMMM|

   Routes
   ...

  Output document.  Each agency type is link to agency-type/index.html
   Summary counts (2011-11-19 21:20-0500)

   Agency|Routes w/>=2 stops |Sched stop names    |Map stop names|MatchedStops
    Type |All=Match+Subst+Mis|All=Match+Subst+Miss|All=Match+Miss|Misplace Ambig
   ~~~~~~+~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~+~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
   Metr'x|  6=   6 +  0  +  0|128= 128 + 0   + 0  |519= 402 + 117|   0      6
   Subway|    GGGGGGGGGGGGGGG|     GGGGGGGGGGGGGG |    GGGGGGGGMM|
   ~~~~~~+~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
    RATB | 25=  21 +  0  +  4|1033=402 + 39  + 592|519= 402 + 117|  21     55
    Tram |    GGGGGGGGGGGGRRR|     GGGGGGORRRRRRRR|    GGGGGGGGMM|
   ~~~~~~+~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
    RATB | 19=  3  +  6  + 10|744=  98 +  57 + 589|108=  98 +  10|   0     74
   Tr'bus|    GGOOOORRRRRRRR |    GGORRRRRRRRRRRRR|    GGGGGGGGMM|
   ~~~~~~+~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
    RATB | 67=  21  + 29 + 17|2644= 266+ 409 +1969|361=  266+  95|  26      107
   ur'bus|    GGGGGOOOOOORRRR|     GOORRRRRRRRRRRR|    GGGGGGGMMM|

-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>

  <xsl:param name="metrorexLogXhtml"
             select="'build/metrorex/metrorex-stop-matching-log.html'"/>
  <xsl:param name="ratbtramLogXhtml"
             select="'build/ratbtram/ratbtram-stop-matching-log.html'"/>
  <xsl:param name="ratbtrobLogXhtml"
             select="'build/ratbtrob/ratbtrob-stop-matching-log.html'"/>
  <xsl:param name="ratbubusLogXhtml"
             select="'build/ratbubus/ratbubus-stop-matching-log.html'"/>

  <xsl:template match="html|body|table">
    <xsl:text>&#xA;</xsl:text>
    <xsl:element name="{name()}">
      <xsl:for-each select="@*">  <!--copy attributes-->
        <xsl:copy-of select="."/>
      </xsl:for-each>
      <xsl:apply-templates/> <!-- apply templates to body -->
    </xsl:element>
  </xsl:template>

  <xsl:template match="thead[parent::table[@class='summary-counts']]">
    <xsl:copy-of select="document($metrorexLogXhtml)
                         //table[@class='summary-counts']/thead"/>
  </xsl:template>

  <xsl:template match="tbody[parent::table[@class='summary-counts']]">
    <xsl:choose>
      <xsl:when test="@id='metrorex-summary-counts'">
        <xsl:call-template name="formatSummary">
          <xsl:with-param name="id" select="@id"/>
          <xsl:with-param name="logXhtml" select="$metrorexLogXhtml"/>
          <xsl:with-param name="relUrl">Metrorex/index.html</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@id='ratbtram-summary-counts'">
        <xsl:call-template name="formatSummary">
          <xsl:with-param name="id" select="@id"/>
          <xsl:with-param name="logXhtml" select="$ratbtramLogXhtml"/>
          <xsl:with-param name="relUrl">RATB-tram/index.html</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@id='ratbtrob-summary-counts'">
        <xsl:call-template name="formatSummary">
          <xsl:with-param name="id" select="@id"/>
          <xsl:with-param name="logXhtml" select="$ratbtrobLogXhtml"/>
          <xsl:with-param name="relUrl">RATB-trolleybus/index.html</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@id='ratbubus-summary-counts'">
        <xsl:call-template name="formatSummary">
          <xsl:with-param name="id" select="@id"/>
          <xsl:with-param name="logXhtml" select="$ratbubusLogXhtml"/>
          <xsl:with-param name="relUrl">RATB-urbanbus/index.html</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Unrecognized transit category id: </xsl:text>
          <xsl:value-of select="@id"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="formatSummary">
    <xsl:param name="id"/>
    <xsl:param name="logXhtml"/>
    <xsl:param name="relUrl"/>
    <xsl:for-each select="document($logXhtml)
                          //table[@class='summary-counts']/tbody">
      <tbody>
        <xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
        <xsl:call-template name="copy-attributes"/>

        <xsl:for-each select="tr[1]">
          <tr>
            <xsl:call-template name="copy-attributes"/>
            <!-- wrap content if intitial th in a link to detail -->
            <th>
              <xsl:for-each select="th[1]/@*"> <!-- copy attributes -->
                <xsl:copy-of select="."/>
              </xsl:for-each>
              <a>                       <!-- wrap content in link -->
                <xsl:attribute name="href">
                  <xsl:value-of select="$relUrl"/>
                </xsl:attribute>
                <xsl:for-each select="th[1]/node()"> <!-- copy content -->
                  <xsl:copy-of select="."/>
                </xsl:for-each>
              </a>
            </th>
            <!-- copy remaining elements -->
            <xsl:for-each select="th[1]/following-sibling::*">
              <xsl:copy-of select="."/>
            </xsl:for-each>
          </tr>
        </xsl:for-each>
        <xsl:for-each select="tr[position() > 1]">
          <xsl:copy-of select="."/>
        </xsl:for-each>
      </tbody>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="copy-attributes">
    <xsl:for-each select="@*"> <!-- copy attributes -->
      <xsl:copy-of select="."/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="tr|thead|tbody|th|td">
    <xsl:element name="{name()}">
      <xsl:for-each select="@*">  <!--copy attributes-->
        <xsl:copy-of select="."/>
      </xsl:for-each>
      <xsl:apply-templates/> <!-- apply templates to body -->
    </xsl:element>
  </xsl:template>

  <xsl:template match="head">
    <xsl:apply-templates/>
    <xsl:copy-of select="document($metrorexLogXhtml)/html/head/style"/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:transform>
