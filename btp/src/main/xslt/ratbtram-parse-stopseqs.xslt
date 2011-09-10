<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8" indent="true"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/stop-sequence-inputs">
    <xsl:variable name="dir" select="@dir"/>

    <xsl:text>&#xA;</xsl:text>
    <stop-sequences>
      <xsl:for-each select="./filename">
        <xsl:variable name="filename" select="string(.)"/>
        <xsl:variable name="path" select="concat($dir, '/', $filename)"/>
        <xsl:variable name="tbody"
          select="document($path)/html/body/table"/>

        <xsl:call-template name="file-to-stop-sequences">
          <xsl:with-param name="tbody" select="$tbody"/>
          <xsl:with-param name="routeName"
            select="substring-before(substring-after($filename,'-'),'-')"/>
        </xsl:call-template>

      </xsl:for-each>
      <xsl:text>&#xA;</xsl:text>
    </stop-sequences><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="file-to-stop-sequences">
    <xsl:param name="tbody"/>
    <xsl:param name="routeName"/>

    <xsl:variable name="TUR"
      select="$tbody/tr[preceding-sibling::tr[string(.) = 'TUR'] and
                        following-sibling::tr[string(.) = 'RETUR']]"/>
    <xsl:variable name="RETUR"
      select="$tbody/tr[preceding-sibling::tr[string(.) = 'RETUR']]"/>
    
    <xsl:text>&#xA;  </xsl:text>
    <route>
      <xsl:attribute name="short_name">
        <xsl:value-of select="number($routeName)"/>
      </xsl:attribute>

      <xsl:text>&#xA;    </xsl:text>
      <stop-sequence dir="forward">
        <xsl:for-each select="$TUR">
          <xsl:text>&#xA;      </xsl:text>
          <stop>
            <xsl:attribute name="number">
              <xsl:value-of select="normalize-space(td[1])"/>
            </xsl:attribute>
            <xsl:attribute name="street">
              <xsl:value-of select="normalize-space(td[4])"/>
            </xsl:attribute>
            <xsl:attribute name="name">
              <xsl:value-of select="normalize-space(td[2])"/>
            </xsl:attribute>
          </stop>
        </xsl:for-each>
        <xsl:text>&#xA;    </xsl:text>
      </stop-sequence>

      <xsl:text>&#xA;    </xsl:text>
      <stop-sequence dir="backward">
        <xsl:for-each select="$RETUR">
          <xsl:text>&#xA;      </xsl:text>
          <stop>
            <xsl:attribute name="number">
              <xsl:value-of select="normalize-space(td[1])"/>
            </xsl:attribute>
            <xsl:attribute name="street">
              <xsl:value-of select="normalize-space(td[4])"/>
            </xsl:attribute>
            <xsl:attribute name="name">
              <xsl:value-of select="normalize-space(td[2])"/>
            </xsl:attribute>
          </stop>
        </xsl:for-each>
        <xsl:text>&#xA;    </xsl:text>
      </stop-sequence>

      <xsl:text>&#xA;  </xsl:text>
    </route>    
  </xsl:template>

</xsl:transform>

