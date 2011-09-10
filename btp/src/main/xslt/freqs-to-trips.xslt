<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:param name="routesXml"/>
  <!-- select="'../../../build/metrorex/metrorex-routes.xml'" -->

  <xsl:variable name="routes" select="document($routesXml)/routes"/>

  <xsl:template match="/frequencies">

    <xsl:text>&#xA;</xsl:text>
    <trips>
      <xsl:for-each select="route">
        <xsl:variable name="short_name" select="@short_name"/>
        <xsl:variable name="rId"
          select="$routes/route[@route_short_name = $short_name]/@route_id"/>

        <xsl:for-each select="service">
          <xsl:if test="count(frequency[@dir='forward' or @dir='both']) != 0">
            <xsl:variable name="endStopAbbr">
              <xsl:call-template name="abbreviateStop">
                <xsl:with-param name="stopName" select="@endStop"/>
              </xsl:call-template>
            </xsl:variable>
              
            <xsl:text>&#xA;  </xsl:text>
            <trip>
              <xsl:attribute name="trip_id">
                <xsl:value-of
                  select="concat($short_name, '_',
                                 substring(@serviceType, 1, 3),
                                 '_TUR_', $endStopAbbr)"/>
              </xsl:attribute>
              <xsl:attribute name="route_id">
                <xsl:value-of select="$rId"/>
              </xsl:attribute>
              <xsl:attribute name="route_short_name">
                <xsl:value-of select="$short_name"/>
              </xsl:attribute>
              <xsl:attribute name="service_id">
                <xsl:value-of select="@serviceType"/>
              </xsl:attribute>
              <xsl:attribute name="direction_id">
                <xsl:value-of select="0"/>
              </xsl:attribute>
              <xsl:attribute name="beginStop">
                <xsl:value-of select="@beginStop"/>
              </xsl:attribute>
              <xsl:attribute name="endStop">
                <xsl:value-of select="@endStop"/>
              </xsl:attribute>
            </trip>
          </xsl:if>
          <xsl:if test="count(frequency[@dir='backward' or @dir='both']) != 0">
            <xsl:variable name="beginStopAbbr">
              <xsl:call-template name="abbreviateStop">
                <xsl:with-param name="stopName" select="@beginStop"/>
              </xsl:call-template>
            </xsl:variable>
              
            <xsl:text>&#xA;  </xsl:text>
            <trip>
              <xsl:attribute name="trip_id">
                <xsl:value-of
                  select="concat($short_name, '_',
                                 substring(@serviceType, 1, 3),
                                 '_RET_', $beginStopAbbr)"/>
              </xsl:attribute>
              <xsl:attribute name="route_id">
                <xsl:value-of select="$rId"/>
              </xsl:attribute>
              <xsl:attribute name="route_short_name">
                <xsl:value-of select="$short_name"/>
              </xsl:attribute>
              <xsl:attribute name="service_id">
                <xsl:value-of select="@serviceType"/>
              </xsl:attribute>
              <xsl:attribute name="direction_id">
                <xsl:value-of select="1"/>
              </xsl:attribute>
              <xsl:attribute name="beginStop">
                <xsl:value-of select="@beginStop"/>
              </xsl:attribute>
              <xsl:attribute name="endStop">
                <xsl:value-of select="@endStop"/>
              </xsl:attribute>
            </trip>
          </xsl:if>
        </xsl:for-each>       
      </xsl:for-each>
      <xsl:text>&#xA;</xsl:text>
    </trips>
  </xsl:template>

  <xsl:template name="abbreviateStop">
    <xsl:param name="stopName"/>
    <xsl:variable name="len" select="4"/>
    <xsl:variable name="lastWord">
      <xsl:call-template name="findLastWord">
        <xsl:with-param name="words" select="normalize-space($stopName)"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="substring($lastWord, 1, 4)"/>
  </xsl:template>
    
  <!-- use last name for stops named after people
       (or after streets named after people). -->
  <xsl:template name="findLastWord">
    <xsl:param name="words"/>
    <xsl:variable name="head" select="substring-before($words, ' ')"/>
    <xsl:variable name="tail" select="substring-after($words,' ')"/>
    <xsl:choose>
      <xsl:when test="$tail = ''">
        <xsl:value-of select="$words"/>
      </xsl:when>      
      <!-- if penultimate is number, append it to last word (no space) -->
      <xsl:when test="not(contains($tail, ' ')) and number($head) &gt; 0">
        <xsl:value-of select="concat($head, $tail)"/>
      </xsl:when>
      <!-- if last word is number or abbrev, use pentultimate word -->
      <xsl:when test="not(contains($tail, ' ')) and
      	              (number($tail) &gt; 0 or contains($tail, '.'))">
        <xsl:value-of select="$head"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="findLastWord">
          <xsl:with-param name="words" select="$tail"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:transform>
