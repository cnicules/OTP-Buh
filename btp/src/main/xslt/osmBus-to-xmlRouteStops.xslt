<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <!-- using key indexes increases speed, but uses more memory -->
  <xsl:key name="node" match="node" use="@id"/>
  <xsl:key name="way" match="way" use="@id"/>

  <xsl:template match="/osm">
    <xsl:text>&#xA;</xsl:text>
    <route-stops>
      <xsl:for-each select="relation[tag[@k='route' and @v='bus']]">
        <xsl:sort select="tag[@k='ref']/@v"/>

        <xsl:text>&#xA;  </xsl:text>
        <route>
          <xsl:attribute name="route_short_name">
            <xsl:value-of select="tag[@k='ref']/@v"/>
          </xsl:attribute>

          <!-- stops -->
          <xsl:for-each select="member">
            <xsl:variable name="ref" select="string(@ref)"/>

            <xsl:if test="@type='node'">
              <xsl:call-template name="extract-bus-stop-from-node">
                <xsl:with-param name="nodeId" select="$ref"/>
              </xsl:call-template>
            </xsl:if>

            <xsl:if test="@type='way'">
              <!-- /osm/way[@id=$ref]/nd -->
              <xsl:for-each select="key('way', $ref)[1]/nd">
                <xsl:call-template name="extract-bus-stop-from-node">
                  <xsl:with-param name="nodeId" select="@ref"/>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:if>
          </xsl:for-each>

          <xsl:text>&#xA;  </xsl:text>
        </route>
      </xsl:for-each>

      <xsl:text>&#xA;</xsl:text>
    </route-stops>
  </xsl:template>

  <xsl:template name="extract-bus-stop-from-node">
    <xsl:param name="nodeId"/>

    <!-- /osm/node[@id=$nodeId and tag[(@k='highway' and @v='bus_stop') or 
                                       (@k='railway' and (@v='station' or
                                                          @v='tram_stop'))]] -->
    <xsl:for-each
      select="key('node', $nodeId)[tag[(@k='highway' and @v='bus_stop') or 
                                       (@k='railway' and (@v='station' or
                                                          @v='tram_stop'))]]">

      <xsl:text>&#xA;    </xsl:text>
      <stop>

        <!-- stop_id -->
        <xsl:attribute name="stop_id">
          <xsl:value-of select="@id"/>
        </xsl:attribute>

        <!-- stop_lat -->
        <xsl:attribute name="stop_lat">
          <xsl:value-of select="@lat"/>
        </xsl:attribute>

        <!-- stop_lon -->
        <xsl:attribute name="stop_lon">
          <xsl:value-of select="@lon"/>
        </xsl:attribute>

        <!-- stop_name -->
        <xsl:attribute name="stop_name">
          <xsl:value-of select="tag[@k='name']/@v"/>
        </xsl:attribute>

      </stop>
    </xsl:for-each>

  </xsl:template>

</xsl:transform>
