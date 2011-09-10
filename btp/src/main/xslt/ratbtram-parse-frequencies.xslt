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

