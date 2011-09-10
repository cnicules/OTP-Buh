<!-- Transform stop-times.xml to GTFS stop-times.txt 

  Input document: *-stop-times.xml
    <stop-times>
      <stop-time trip_id="[tripId1]" stop_id="[osmNodeId1.0]"
                 arrival_time="[HH:mm:ss]" departure_time="[HH:mm:ss]"
                 stop_sequence="00" stop_headsign="[endStopName]"/>
      <stop-time trip_id="[tripId1]" stop_id="[osmNodeId1.1]"
                 arrival_time="[HH:mm:ss]" departure_time="[HH:mm:ss]"
                 stop_sequence="01" stop_headsign="[endStopName]"/>
      ...                 
      <stop-time trip_id="[tripId2]" stop_id="[osmNodeId2.0]"
                 arrival_time="[HH:mm:ss]" departure_time="[HH:mm:ss]"
                 stop_sequence="00" stop_headsign="[endStopName]"/>
      <stop-time trip_id="[tripId2]" stop_id="[osmNodeId2.1]"
                 arrival_time="[HH:mm:ss]" departure_time="[HH:mm:ss]"
                 stop_sequence="01" stop_headsign="[endStopName]"/>
      ...                 
    </stop-times>    

  Output document: stop_times.txt
    trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign    

    [tripId1],[HH:mm:ss],[HH:mm:ss],[stopId1.0],00,[endStopName1]
    [tripId1],[HH:mm:ss],[HH:mm:ss],[stopId1.1],01,[endStopName1]
    ...
    [tripId2],[HH:mm:ss],[HH:mm:ss],[stopId2.0],00,[endStopName2]
    [tripId2],[HH:mm:ss],[HH:mm:ss],[stopId2.1],01,[endStopName2]
    ...
-->
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/stop-times">
    <xsl:text>trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign&#xA;&#xA;</xsl:text>

    <xsl:for-each select="stop-time">
      <xsl:value-of select="@trip_id"/>
      <xsl:text>,</xsl:text>
      
      <xsl:value-of select="@arrival_time"/>
      <xsl:text>,</xsl:text>

      <xsl:value-of select="@departure_time"/>
      <xsl:text>,</xsl:text>

      <xsl:value-of select="@stop_id"/>
      <xsl:text>,</xsl:text>

      <xsl:value-of select="@stop_sequence"/>
      <xsl:text>,</xsl:text>

      <xsl:text>&quot;</xsl:text>
      <xsl:value-of select="@stop_headsign"/>
      <xsl:text>&quot;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:transform>
