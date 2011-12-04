<!-- Parse snippets from Metrorex schedule tables into frequency xml data.

  Input document:
    <frequency-inputs>
      <filepath>[filepath-to-html-for-one-service-of-one-route]</filepath>
      ...
    </frequency-inputs>

  Referenced html snippets:  Some routes (rail lines) have 2 columns, 
  some have more if there are other (beginStop, endStop) trips.
    <html>
    <body>
    <table>
      <tbody>
        <tr><td colspan="2">[a route (rail line) long name]</td></tr>
        <tr><td>Intervalul</td><td>[beginStopName]</td></tr>
        <tr><td>[beginTime]-[endTime]</td><td>[headwayMinutes]</td></tr>
        <tr><td>[beginTime]-[endTime]</td><td>[headwayMinutes]</td></tr>
        ...
        <tr><td></td><td>[endStopName]</td></tr>
      </tbody>
    </table>
    </body>
    </html>        

  Output document:
  One frequency for each (route, service, beginStop, endStop).
    <frequencies>
      <route short_name="[routeNumber]">
        <service operator="[agencyName]" serviceType="[serviceId]"
                 beginStop="[fowardBeginStopName]"
                 endStop="[fowardEndStopName]"/>
          <frequency dir="both"
                     beginTime="[HH:mm:ss]" endTime="[HH:mm:ss]"
                     headwayMinutes="[minutes]"/>
          ...
        </service>
      </route>
      ...
    </frequencies>
-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8" indent="true"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/frequency-inputs">
    <xsl:text>&#xA;</xsl:text>
    <frequencies>
      <xsl:for-each select="./filepath">
        <!-- sort frequencies by route: route is 1st difference in filename -->
        <xsl:sort select="string(.)"/>

        <xsl:variable name="path" select="string(.)"/>
        <xsl:variable name="tbody"
          select="document($path)/html/body/table/tbody"/>
        <xsl:variable name="filename"
          select="substring($path,
                            string-length($path) -
                            string-length('M1-WD-frequency.html') + 1)"/>
        <xsl:call-template name="column-to-service">
          <xsl:with-param name="tbody" select="$tbody"/>
          <xsl:with-param name="routeName" select="substring($filename,1,2)"/>
          <xsl:with-param name="serviceType" select="substring($filename,4,2)"/>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:text>&#xA;</xsl:text>
    </frequencies><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="column-to-service">
    <xsl:param name="tbody"/>
    <xsl:param name="routeName"/>
    <xsl:param name="serviceType"/>

    <xsl:text>&#xA;  </xsl:text>
    <route>
      <xsl:attribute name="short_name">
        <xsl:value-of select="$routeName"/>
      </xsl:attribute>
      <!-- first row is title with colspan=3, so use tr[2] -->
      <xsl:for-each select="$tbody/tr[2]/td[position() &gt; 1]">
        <xsl:variable name="colNum" select="position() + 1"/>
        <xsl:text>&#xA;    </xsl:text>
        <service operator="Metrorex">
          <xsl:attribute name="serviceType">
            <xsl:value-of select="translate($serviceType,'wed','WED')"/>
          </xsl:attribute>
          <xsl:attribute name="beginStop">
            <xsl:value-of select="$tbody/tr[2]/td[$colNum]"/>
          </xsl:attribute>
          <xsl:attribute name="endStop">
            <xsl:value-of select="$tbody/tr[last()]/td[$colNum]"/>
          </xsl:attribute>
          <xsl:for-each select="$tbody/tr[position() &gt; 2 and
                                          position() &lt; last()]">
            <xsl:text>&#xA;      </xsl:text>
            <frequency dir="both">

              <xsl:attribute name="beginTime">
                <xsl:variable name="beginTimeText"
                  select="substring-before(td[1],'-')"/>

                <xsl:variable name="beginTimeTextFixed"><!--fix typo in sched-->
                  <xsl:choose>
                    <xsl:when test="$beginTimeText = '23:00'"> 
                      <xsl:text>23:30</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$beginTimeText"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>

                <xsl:value-of select="concat($beginTimeTextFixed,':00')"/>
              </xsl:attribute>

              <xsl:attribute name="endTime">
                <xsl:variable name="endTimeText"
                  select="substring-after(td[1],'-')"/>

                <xsl:variable name="endTimeTextFixed"> <!--fix typo in sched-->
                  <xsl:choose>
                    <xsl:when test="$endTimeText = '70:00'"> 
                      <xsl:text>7:00</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$endTimeText"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>

                <xsl:value-of select="concat($endTimeTextFixed,':00')"/>
              </xsl:attribute>

              <xsl:attribute name="headwayMinutes">
                <xsl:variable name="m" select="td[$colNum]"/>
                <xsl:choose>
                  <xsl:when test="contains($m,'-')">
                    <xsl:variable name="lo" select="substring-before($m,'-')"/>
                    <xsl:variable name="hi" select="substring-after($m,'-')"/>
                    <xsl:value-of select="(number($lo) + number($hi)) div 2"/>
                  </xsl:when>
                  <xsl:otherwise><xsl:value-of select="$m"/></xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>

            </frequency>
          </xsl:for-each>
          <xsl:text>&#xA;    </xsl:text>
        </service>
      </xsl:for-each>

      <xsl:text>&#xA;  </xsl:text>
    </route>
  </xsl:template>

</xsl:transform>