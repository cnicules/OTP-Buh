<!-- Add attribute stop_name_sans_diacritics="[@stop_name without diacritics]" 
  to each stop where stop_name contains letters with Romanian diacritic marks.
  (For example, 'ă' [a-with-brev] is translated to plain 'a'.)
  The stop_name_sans_diacritics is used when matching stop names in the
  RATB schedule, which have no diacritics.

  Input document:
    <stops>
      <stop stop_id="[osmNodeId]" stop_lat="[latitude]" stop_lon="[longitude]"
            stop_name="[stopName]"/>
      ...
    </stops>

  Output document:
    <stops>
      <stop stop_id="[osmNodeId]" stop_lat="[latitude]" stop_lon="[longitude]"
            stop_name="[stopNameWithNoDiacritics]"/>
      <stop stop_id="[osmNodeId]" stop_lat="[latitude]" stop_lon="[longitude]"
            stop_name="[stopNameWithDiacritics]"
            stop_name_sans_diactrics="[stopNameWithDiacriticsRemoved]"/>
      ...
    </stops>

-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <!-- -->
  <xsl:template match="/stops">
    <xsl:text>&#xA;</xsl:text>
    <stops>
      <xsl:for-each 
        select="stop[position() = 1 or
                     @stop_id != preceding-sibling::stop[1]/@stop_id]">

        <xsl:text>&#xA;  </xsl:text>
        <stop>

          <xsl:attribute name="stop_id">      
            <xsl:value-of select="@stop_id"/>
          </xsl:attribute>

          <xsl:attribute name="stop_lat">
            <xsl:value-of select="@stop_lat"/>
          </xsl:attribute>

          <xsl:attribute name="stop_lon">
            <xsl:value-of select="@stop_lon"/>
          </xsl:attribute>

          <xsl:attribute name="stop_name">
            <xsl:value-of select="@stop_name"/>
          </xsl:attribute>

          <xsl:variable name="nameSansRomanianDiacritics"
            select="
              translate(@stop_name,
                        'ĂăÂâÉéĔĕÎîĬĭÓóŞşŢţŬŭ&#x218;&#x219;&#x21a;&#x21b;',
                        'AaAaEeEeIiIiOoSsTtUuSsTt')"/>
          <xsl:if test="not(@stop_name = $nameSansRomanianDiacritics)">
            <xsl:attribute name="stop_name_sans_diacritics">
              <xsl:value-of select="$nameSansRomanianDiacritics" />
            </xsl:attribute>
          </xsl:if>

        </stop>
      </xsl:for-each>
      <xsl:text>&#xA;</xsl:text>
    </stops>
  </xsl:template>

</xsl:transform>
