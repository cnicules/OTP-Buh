<!-- Parse snippets from RATB schedule tables into frequency xml data.

  Input document:  type is tram, trob, or ubus, ...
    <frequency-inputs dir="build/ratb[type]/html">
      <filepath>ratb[type]-01-freq.html</filepath>
      <filepath>ratb[type]-04-freq.html</filepath>
      ...
    </frequency-inputs>

  Referenced html snippets:
  (TUR is forward direction.  RETUR is return (backward) direction. 
   [1stRun] is time of first run of day (prima).
   [lastRun] is time of last run of day (ultima).
   [m] is minutes headway between runs.  Lucru is workday service schedule.
   Sambata is Saturday service schedule.  Duminica is Sunday service schedule.)
    <html>
    <body>
    <table>
    <tr><td/>
        <td colspan="2">Plecari TUR</td><td colspan="2">Plecari RETUR</td>
        <td colspan="5">Interval</td></tr>
    <tr><td/>
        <td>Prima</td><td>Ultima</td><td>Prima</td><td>Ultima</td>
        <td>5-8</td><td>8-13</td><td>13-18</td><td>18-21</td><td>21-24</td></tr>
    <tr><td>Lucru</td>
        <td>[1stRun]</td><td>[lastRun]</td><td>[1stRun]</td><td>[lastRun]</td>
        <td>[m]</td><td>[m]</td><td>[m]</td><td>[m]</td><td>[m]</td></tr>
    <tr><td>Sambata</td>
        <td>[1stRun]</td><td>[lastRun]</td><td>[1stRun]</td><td>[lastRun]</td>
        <td>[m]</td><td>[m]</td><td>[m]</td><td>[m]</td><td>[m]</td></tr>
    <tr><td>Duminica</td>
        <td>[1stRun]</td><td>[lastRun]</td><td>[1stRun]</td><td>[lastRun]</td>
        <td>[m]</td><td>[m]</td><td>[m]</td><td>[m]</td><td>[m]</td></tr>
    </table>
    </body>
    </html>

  Param stopSeqsXml: stop sequences parsed from another table on same page.
    <stop-sequences>
      <route short_name="[routeNumber]">
        <stop-sequence dir="forward">
          <stop number="0" street="[streetName]" name="[beginStopName]"/>
          <stop number="1" street="[streetName]" name="[stopName]"/>
          <stop number="2" street="[streetName]" name="[stopName]"/>
          ...
          <stop number="?" street="[streetName]" name="[endStopName]"/>
        </stop-sequence>
        <stop-sequence dir="backward">
          <stop number="0" street="[streetName]" name="[endStopName]"/>
          <stop number="1" street="[streetName]" name="[stopName]"/>
          <stop number="2" street="[streetName]" name="[stopName]"/>
          ...
          <stop number="?" street="[streetName]" name="[beginStopName]"/>
        </stop-sequence>
      </route>
      ...
    </stop-sequences>

  Output document:
  One frequency for each (route, service, beginStop, endStop).
    <frequencies>
      <route short_name="[routeNumber]">
        <service operator="[agencyName]" serviceType="[serviceId]"
                 beginStop="[fowardBeginStopName]"
                 endStop="[fowardEndStopName]"/>
          <frequency dir="forward"
                     beginTime="[HH:mm:ss]" endTime="[HH:mm:ss]"
                     headwayMinutes="[minutes]"/>
          <frequency dir="backward"
                     beginTime="[HH:mm:ss]" endTime="[HH:mm:ss]"
                     headwayMinutes="[minutes]"/>
        </service>
        ...
      </route>
      ...
    </frequencies>

-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8" indent="true"/>
  <xsl:strip-space elements="*"/>

  <xsl:param name="stopSeqsXml"/>
  <xsl:variable name="stopSeqs" select="document($stopSeqsXml)/stop-sequences"/>

  <xsl:template match="/frequency-inputs">
    <xsl:variable name="dir" select="@dir"/>

    <xsl:text>&#xA;</xsl:text>
    <frequencies>
      <xsl:for-each select="./filename">
        <!-- 'RATB-tram-01-freq.html' -->
        <xsl:variable name="filename" select="string(.)"/>
        <xsl:variable name="path" select="concat($dir, '/', $filename)"/>
        <xsl:variable name="tbody"
          select="document($path)/html/body/table"/>

        <xsl:call-template name="column-to-service">
          <xsl:with-param name="tbody" select="$tbody"/>
          <xsl:with-param name="routeName"
            select="substring-before(substring-after($filename,'-'),'-')"/>
        </xsl:call-template>

      </xsl:for-each>
      <xsl:text>&#xA;</xsl:text>
    </frequencies><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="column-to-service">
    <xsl:param name="tbody"/>
    <xsl:param name="routeName"/>

    <xsl:variable name="headRow" select="$tbody/tr[2]"/>
    <xsl:variable name="routeStopSeq"
      select="$stopSeqs/route[@short_name = number($routeName)]
                             /stop-sequence[@dir='forward']"/>

    <xsl:text>&#xA;  </xsl:text>
    <route operator="RATB">
      <xsl:for-each select="$tbody/tr[position() &gt; 2]">
        <xsl:variable name="row" select="."/>
        <xsl:attribute name="short_name">
          <xsl:value-of select="number($routeName)"/>
        </xsl:attribute>
        <xsl:text>&#xA;    </xsl:text>
        <service>
          <xsl:attribute name="serviceType">
            <xsl:value-of select="string($row/td[1])"/>
          </xsl:attribute>
          <xsl:attribute name="beginStop">
            <xsl:value-of select="$routeStopSeq/stop[1]/@name"/>
          </xsl:attribute>
          <xsl:attribute name="endStop">
            <xsl:value-of select="$routeStopSeq/stop[last()]/@name"/>
          </xsl:attribute>

          <xsl:for-each select="td[position() > 5]">
            <xsl:text>&#xA;      </xsl:text>
            <frequency dir="forward"> <!-- tur -->

              <xsl:attribute name="beginTime">
                <xsl:choose>
                  <xsl:when test="position() = 1">      <!-- 1st run of day -->
                    <xsl:call-template name="extractCellHH_MM">
                      <xsl:with-param name="cell" select="$row/td[2]"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="extractColHeadBeginTime">
                      <xsl:with-param name="headRow" select="$headRow"/>
                      <xsl:with-param name="colNum" select="5 + position()"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>

              <xsl:attribute name="endTime"> 
                <xsl:choose>
                  <xsl:when test="position() = last()"> <!-- last run of day -->
                    <xsl:call-template name="extractCellHH_MM">
                      <xsl:with-param name="cell" select="$row/td[3]"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="extractColHeadEndTime">
                      <xsl:with-param name="headRow" select="$headRow"/>
                      <xsl:with-param name="colNum" select="5 + position()"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>

              <xsl:attribute name="headwayMinutes">
                <xsl:call-template name="extractHeadwayMinutes">
                  <xsl:with-param name="cell" select="."/>
                </xsl:call-template>
              </xsl:attribute>

            </frequency>
            <xsl:text>&#xA;      </xsl:text>
            <frequency dir="backward"> <!-- retur -->

              <xsl:attribute name="beginTime">
                <xsl:choose>
                  <xsl:when test="position() = 1">       <!-- first run of day -->
                    <xsl:call-template name="extractCellHH_MM">
                      <xsl:with-param name="cell" select="$row/td[4]"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="extractColHeadBeginTime">
                      <xsl:with-param name="headRow" select="$headRow"/>
                      <xsl:with-param name="colNum" select="5 + position()"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>

              <xsl:attribute name="endTime">
                <xsl:choose>
                  <xsl:when test="position() = last()"> <!-- last run of day -->
                    <xsl:call-template name="extractCellHH_MM">
                      <xsl:with-param name="cell" select="$row/td[5]"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="extractColHeadEndTime">
                      <xsl:with-param name="headRow" select="$headRow"/>
                      <xsl:with-param name="colNum" select="5 + position()"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>

              <xsl:attribute name="headwayMinutes">
                <xsl:call-template name="extractHeadwayMinutes">
                  <xsl:with-param name="cell" select="."/>
                </xsl:call-template>
              </xsl:attribute>

            </frequency>
          </xsl:for-each>
          <xsl:text>&#xA;    </xsl:text>
        </service>
      </xsl:for-each>
      <xsl:text>&#xA;  </xsl:text>
    </route>
  </xsl:template>

  <xsl:template name="extractCellHH_MM">
    <xsl:param name="cell"/>
    <xsl:variable name="cellText"
      select="normalize-space($cell)"/>
    <xsl:variable name="cellTextFixedSep"
      select="translate($cellText,'.',':')"/>
    <xsl:value-of select="concat($cellTextFixedSep, ':00')"/>
  </xsl:template>
  <xsl:template name="extractColHeadBeginTime">
    <xsl:param name="headRow"/>
    <xsl:param name="colNum"/>
    <xsl:variable name="colHead" select="$headRow/td[number($colNum)]"/>
    <xsl:variable name="hourRange" select="string($colHead)"/>
    <xsl:variable name="beginHour" select="substring-before($hourRange,'-')"/>
    <xsl:value-of select="concat($beginHour,':00:00')"/>
  </xsl:template>
  <xsl:template name="extractColHeadEndTime">
    <xsl:param name="headRow"/>
    <xsl:param name="colNum"/>
    <xsl:variable name="colHead" select="$headRow/td[number($colNum)]"/>
    <xsl:variable name="hourRange" select="string($colHead)"/>
    <xsl:variable name="endHour" select="substring-after($hourRange, '-')"/>
    <xsl:value-of select="concat($endHour,':00:00')"/>
  </xsl:template>
  <xsl:template name="extractHeadwayMinutes">
    <xsl:param name="cell"/>
    <xsl:variable name="n" select="number($cell)"/>
    <xsl:choose>
      <xsl:when test="$n &gt; 0">
        <xsl:value-of select="$n"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="number(24 * 60)"/> <!-- once/day, no repeat -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:transform>

