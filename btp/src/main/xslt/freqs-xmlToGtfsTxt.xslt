<!-- Output CSV lines in format for GTFS frequencies.txt 

  Input document: *-frequencies.xml
  One frequency for each route, service, direction, (beginStop/endStop).
  (Two directions may be combined into 'both' if they are otherwise the same.)
    <frequencies>
      <route short_name="[routeNumber]">
        <service operator="[agencyName]" serviceType="[serviceId]"
                 beginStop="[fowardBeginStopName]"
                 endStop="[fowardEndStopName]"/>
          <frequency dir="[both/forward/backward]"
                     beginTime="[HH:mm:ss]" endTime="[HH:mm:ss]"
                     headwayMinutes="[minutes]"/>
          ...
        </service>
      </route>
      ...
    </frequencies>

  Output document: GTFS frequencies.txt
-->


<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:param name="tripsXml"/>
  <xsl:variable name="trips" select="document($tripsXml)/trips"/>

  <xsl:template match="/frequencies">
    <xsl:text>trip_id,start_time,end_time,headway_secs&#xA;&#xA;</xsl:text>

    <xsl:for-each select="route">
      <xsl:variable name="short_name" select="@short_name"/>
      <xsl:for-each select="service">
        <xsl:variable name="serviceType" select="@serviceType"/>
        <xsl:variable name="beginStop" select="@beginStop"/>
        <xsl:variable name="endStop" select="@endStop"/>
        <xsl:for-each select="frequency">
 
          <!-- trip_id --> 
          <xsl:variable name="dir" select="@dir"/>
          <xsl:if test="$dir = 'forward' or $dir='both'">
            <xsl:call-template name="freq-row">
              <xsl:with-param name="short_name" select="$short_name"/>
              <xsl:with-param name="serviceType" select="$serviceType"/>
              <xsl:with-param name="dir" select="$dir"/>
              <xsl:with-param name="dir_id" select="'0'"/>
              <xsl:with-param name="beginStop" select="$beginStop"/>
              <xsl:with-param name="endStop" select="$endStop"/>
              <xsl:with-param name="beginTime" select="@beginTime"/>
              <xsl:with-param name="endTime" select="@endTime"/>
              <xsl:with-param name="headwayMinutes" select="@headwayMinutes"/>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$dir = 'backward' or $dir='both'">
            <xsl:call-template name="freq-row">
              <xsl:with-param name="short_name" select="$short_name"/>
              <xsl:with-param name="serviceType" select="$serviceType"/>
              <xsl:with-param name="dir" select="$dir"/>
              <xsl:with-param name="dir_id" select="'1'"/>
              <xsl:with-param name="beginStop" select="$beginStop"/>
              <xsl:with-param name="endStop" select="$endStop"/>
              <xsl:with-param name="beginTime" select="@beginTime"/>
              <xsl:with-param name="endTime" select="@endTime"/>
              <xsl:with-param name="headwayMinutes" select="@headwayMinutes"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="freq-row">
    <xsl:param name="short_name"/>
    <xsl:param name="serviceType"/>
    <xsl:param name="dir"/>
    <xsl:param name="dir_id"/>
    <xsl:param name="beginStop"/>
    <xsl:param name="endStop"/>
    <xsl:param name="beginTime"/>
    <xsl:param name="endTime"/>
    <xsl:param name="headwayMinutes"/>

    <xsl:variable name="trip_id"
       select="$trips/trip[@route_short_name = $short_name and
                           @service_id = $serviceType and
                           @direction_id = $dir_id and
                           @beginStop = $beginStop and
                           @endStop = $endStop]
                          /@trip_id">
    </xsl:variable>

    <xsl:if test="'' != normalize-space($trip_id)">

      <xsl:value-of select="$trip_id"/>
      <xsl:text>,</xsl:text>

      <!-- start_time -->
      <xsl:value-of select="$beginTime"/>
      <xsl:text>,</xsl:text>

      <!-- end_time -->
      <xsl:value-of select="$endTime"/>
      <xsl:text>,</xsl:text>

      <!-- headway_secs -->
      <xsl:value-of select="60 * $headwayMinutes"/>
      <xsl:text>&#xA;</xsl:text>

    </xsl:if>
    <!-- Else error msg was previously emitted when trips.xml was generated. -->

  </xsl:template>
  

</xsl:transform>
