<!-- Format stop-matching log as html tables with horizontal stacked barcharts
     showing relative number of matched, substituted, missing stops.

  Input document: ...-frequencies.xml
    <frequencies>
      <route operator="RATB" short_name="1">
        <service serviceType="Lucru" beginStop="PIATA VITAN" endStop="POSTA VITAN">
          <frequency ...> ...
        </service>
        ...
      </route>
      ...
    </frequencies>

  Param osmRoutesXml: ...-routes.xml
    <routes>
      <route route_id="1274386" agency_id="RATB" route_short_name="1" route_long_name="PIATA VIATA - POSTA VITAN" route_type="0"/>
      ...
    </routes>

  Param stopSeqsXml: ...-stopsequences.xml
    <stop-sequences>
      <route short_name="1">
        <stop-sequence dir="forward">
          <stop number="0" street="CAL. VITAN" name="PIATA VITAN"/>
          <stop number="1" street="CAL. VITAN" name="BUCURESTI-MALL"/>
          ...
          <stop number="41" street="BD. OCTAVIAN GOGA" name="POSTA VITAN"/>
        </stop-sequence>
        <stop-sequence dir="backward">
          <stop number="0" street="BD. OCTAVIAN GOGA" name="POSTA VITAN"/>
          <stop number="1" street="BD. OCTAVIAN GOGA" name="NERVA TRAIAN"/>
          ...
          <stop number="42" street="CAL. VITAN" name="PIATA VITAN"/>
        </stop-sequence>
      </route>
      <route short_name="4">
        ...
      </route>
      ...
    </stop-sequences>

  Param logXml: ...-stop-matching-log.xml
    Emitted by java.util.logging.XMLFormatter with additional <param> elements.
     <log>
       <record>
         <date>2011-11-19T21:20:31</date>
         <millis>1321755631010</millis>
         <sequence>0</sequence>
         <logger>GenerateStopTimesWithConstantInterval</logger>
         <level>FINE</level>
         <class>GenerateStopTimesWithConstantInterval</class>
         <method>categorizeMissingStop</method>
         <thread>1</thread>
         <message>"PIATA VITAN" not in map tram routes; ...</message>
         <param>SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_LATER</param>
         <param>tram</param>
         <param>1</param>
         <param>1274386</param>
         <param>forward</param>
         <param>0</param>
         <param>41</param>
         <param>0</param>
       </record>
       <record>
         ...
       </record>
       ... (many records, not all the same params) ...
     </log>
    See "names of indices for $log/record/param[index]" below for
    params of route and stops log records, type summary log records, and
    route summary log records.
  
  Output document:
   Summary counts (2011-11-19 21:20-0500)

   Agency|Routes w/>=2 stops  |Sched stop names    |Map stop names|MatchedStops
   Type  |All=Match+Subst+Miss|All=Match+Subst+Miss|All=Match+Miss|Misplace Ambig
   ~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~+~~~~~~~~~~~~~~
   RATB  | 25=  21 +  0  +  4 |1033=402 + 39  + 592|519= 402 + 117|  21     55
   Tram  |    GGGGGGGGGGGGRRR |     GGGGGGORRRRRRRR|    GGGGGGGGRR|

   Routes

   1 4 5 7 8 11 14 16 20 21 23 24 25 27 32 35 36 40 41 42 45 46 47 55 56

   N.|Dir|Begin->End     |Sched Stops    |Map Stops   |Map Stops|Relation
     |   |               |All=Mat+Sub+Mis|All=Mat+Mis |Misplaced|
   ~~+~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~+~~~~~~~~~+~~~~~~~~
    1| F |PIATA VITAN -> |42=31 + 1 + 10 |42= 31 + 11 |   1     | 1274386
     |   |POSTA VITAN    |               |            |         |
     |   |RGGRGGGGOG...  |   GGGGGGGGORRR|   GGGGGGRR |         |
     +~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~+~~~~~~~~~+~~~~~~~~
     | R |POSTA VITAN->  |43=29 + 0 + 14 |40= 29 + 11 |   0     | 1274386
     |   |PIATA VITAN    |               |            |         |
     |   |GRGGRGGGRR...  |   GGGGGGGGRRRR|   GGGGGGRR |         |
   ~~+~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~+~~~~~~~~~+~~~~~~~~
    2| F |SOS. GIURGUILUI|11= 1 + 0 + 10 | 2=  1 +  1 |   0     | 1270363
     |   |-> ZETARILOR   |               |            |         |
     |   |RRRRGRRRRRRR...|   GRRRRRRRRRRR|   GGGGRRRR |         |
     +~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~+~~~~~~~~~+~~~~~~~~
     | R |ZETARILOR ->   |12= 2 + 0 + 10 | 3=  2 +  1 |   0     | 1270363
     |   |SOS. GUIRGUILUI|               |            |         |
     |   |RRRRRRGRRRGR...|   GGRRRRRRRRRR|   GGGGGGRRR|         |
   ~~+~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~+~~~~~~~~~+~~~~~~~~
    3| F |
    ...

   Tram 1 (OSM relation 1274386)

   N.|Dir|Begin->End   |Sched Stops    |Map Stops   |Map Stops|Relation
     |   |             |All=Mat+Sub+Mis|All=Mat+Mis |Misplaced|
   ~~+~~~+~~~~~~~~~~~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~+~~~~~~~~~+~~~~~~~~
    1| F |PIATA VITAN->|42=31 + 1 + 10 |42= 31 + 11 |   1     | 1274386
     |   |POSTA VITAN  |               |            |         |
     |   |RGGRGGGGOG...|   GGGGGGGGORRR|   GGGGGGRR |         |
     +~~~+~~~~~~~~~~~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~+~~~~~~~~~+~~~~~~~~
     | R |POSTA VITAN->|43=29 + 0 + 14 |40= 29 + 11 |   0     | 1274386
     |   |PIATA VITAN  |               |            |         |
     |   |GRGGRGGGRR...|   GGGGGGGGRRRR|   GGGGGGRR |         |
   ~~+~~~+~~~~~~~~~~~~~+~~~~~~~~~~~~~~~+~~~~~~~~~~~~+~~~~~~~~~+~~~~~~~~

   Misspelled/Unmatched Map Stops
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ? |                 |Timpuri Noi 419026857    | Map route has unmatched stop
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ? |                 |                         | Map route has unmatched stop
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ? |                 |Facultatea de Electronica| Map route has unmatched stop
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ... (continue for all unmatched map stops)

   N.|  Schedule Stop  |   Map Stop              | Message
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    0|PIATA VITAN      |                         | Not in map tram routes
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    1|BUCURESTI-MALL   | Bucuresti Mall          | Matched
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    2|ZINZIN           | Zinzin                  | Matched
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ...
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    8|PIATA HURMAZACHI | Piata Hurmuzachi        | Substituted from other route
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ...
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   24|BD. TIMISOARA    | Bd. Timisoara           | Matched  
     |                 +~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     |                 | Bd. Timisoara           | Further from neighbors than
     |                 |                         | distance between them
   ~~+~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ...(continue for all stops in schedule.)

   ...(similar tables for every route of same type, tram in this case)
-->

<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:param name="dateTime" select="'1999-12-31 23:59'"/>  
  <xsl:param name="agency" select="'RATB'"/>
  <xsl:param name="routeType" select="'urbanbus'"/>
  <xsl:param name="osmRoutesXml"
    select="'../../../build/ratbubus/ratbubus-routes.xml'"/>
  <xsl:param name="stopSeqsXml"
    select="'../../../build/ratbubus/ratbubus-stopsequences.xml'"/>
  <xsl:param name="logXml"
    select="'../../../build/ratbubus/ratbubus-stop-matching-log.xml'"/>

  <xsl:variable name="osmRoutes" select="document($osmRoutesXml)/routes"/>
  <xsl:variable name="stopSeqs" select="document($stopSeqsXml)/stop-sequences"/>
  <xsl:variable name="log" select="document($logXml)/log"/>
  <!-- names of indices for $log/record/param[index] -->
  <xsl:variable name="iMsgType"     select="1"/>
  <xsl:variable name="iRteType"     select="2"/>
  <xsl:variable name="iRteNr"       select="3"/>
  <xsl:variable name="iRteOsmId"    select="4"/>
  <xsl:variable name="iDir"         select="5"/>
  <xsl:variable name="iBeginSeqNr"  select="6"/>
  <xsl:variable name="iEndSeqNr"    select="7"/>
  <xsl:variable name="iStopSeqNr"   select="8"/>
  <xsl:variable name="iStopMapName" select="9"/>
  <xsl:variable name="iStopMapId"   select="10"/>
  <!-- names of indices for summary count log records -->
  <xsl:variable name="iSummaryCount" select="3"/>
  <xsl:variable name="iSummaryTotal" select="4"/>
  <!-- names of indices for route count log records -->
  <xsl:variable name="iRouteCount"   select="5"/>
  <xsl:variable name="iRouteTotal"   select="6"/>
  <xsl:variable name="TitleRouteType"
    select="concat(translate(substring($routeType,1,1),
                             'abcdefghijklmnopqrstuvwxyz',
                             'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                   substring($routeType, 2))"/>
  <xsl:variable name="firstService"
    select="/frequencies/route[1]/service[1]/@serviceType"/>

  <xsl:template match="/frequencies">
    <xsl:text>&#xA;</xsl:text>
    <html><xsl:text>&#xA;</xsl:text>
    <head>
    <title><xsl:value-of select="$TitleRouteType"/>-stop Name Matching Log</title>
    <xsl:text>&#xA;</xsl:text>
    <xsl:call-template name="style"/>
    </head><xsl:text>&#xA;</xsl:text>
    <body><xsl:text>&#xA;</xsl:text>

    <xsl:call-template name="title-heading"/>
    <xsl:call-template name="summary-counts"/>
    <xsl:call-template name="routes-list"/>
    <hr/><xsl:text>&#xA;</xsl:text>

    <xsl:for-each select="./route[service/@serviceType = $firstService]">
      <hr/>
      <xsl:call-template name="route-log">
        <xsl:with-param name="routeShortName" select="@short_name"/>
      </xsl:call-template>
    </xsl:for-each>
    </body><xsl:text>&#xA;</xsl:text>
    </html>    
  </xsl:template>

  <xsl:template name="title-heading">
    <h1>
      <xsl:value-of select="$TitleRouteType"/>
      <xsl:text>-stop Name Matching Log</xsl:text>
    </h1><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="style">
    <style>
    body { background: white; }
    pre { white-space: pre-wrap; }
    ul { margin: 0; }
    table { border-collapse: collapse; border: 1px solid gray;}
    th { background: lavender; }
    table.summary-counts tr[id] { border-top: 1px solid gray; }
    table.summary-counts th[rowspan] { border-left: 1px solid gray; }
    table.routesList tr[id] { border-top: 1px solid gray; }
    table.routesList td[rowspan] { border-left: 1px solid gray; }
    table.stopsList tr { border-top: 1px solid gray; }
    /** horizontally-stacked bar graph, bars are each kind of status */
    table.stopBars { border-style: none; empty-cells: show; margin: auto; }
    table.stopBars td { border-style: none; height: 5px; }
    /** line of dots colored for each stop status in order **/
    table.stopDots { border-style: none; border-collapse: separate; border-spacing: 0; empty-cells: show; margin: auto;}
    table.stopDots td { border-width: 2px; border-style: solid;
                        padding: 1px; background-color: black;}

    .topBorder { border-top: 1px solid gray; }
    .leftBorder { border-left: 1px solid gray; }
    .textCenter { text-align: center; }
    .dir            { text-align: center; border-left: 1px solid gray;}
    .beginEnd       { text-align: center; border-left: 1px solid gray;}
    .stopsCount     { }
    .stopsTotal     { }

    .stopsMatch     { color: green; }
    .matchBar       { background-color: green; }
    .matchDot       { border-color: green; }

    .stopsSubst     { color: darkorange; }
    .substBar       { background-color: darkorange; }
    .substDot       { border-color: darkorange; }

    .stopsMissed    { color: red; font-weight: bold; }
    .missedBar      { background-color: red; }
    .missedDot      { border-color: red; }

    .stopsMisspelled{ color: magenta; }
    .misspelledBar   { background-color: magenta; }
    .misspelledDot   { border-color: magenta; }

    .stopsMisplaced { color: purple; }
    .misplacedBar   { background-color: purple; }
    .misplacedDot   { border-color: purple; }

    .routeId { text-align: right; border-left: 1px solid gray; }

    .stopNo      { text-align: right; }
    .schedStopName,
    .mapStopName { border-left: 1px solid gray; }
    .stopMessage { border-left: 1px solid gray; white-space: pre-wrap; }
    </style><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <!-- Table summarizing total counts on all routes with Agency routeType -->
  <xsl:template name="summary-counts">

   <div id="summary-counts"><xsl:text>&#xA;</xsl:text>
    <h3>Summary Counts (<xsl:value-of select="$dateTime"/>)</h3>
    <xsl:text>&#xA;</xsl:text>

    <table class="summary-counts">
      <xsl:attribute name="id">
        <xsl:value-of select="$agency"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$routeType"/>
        <xsl:text>-summary-table</xsl:text>
      </xsl:attribute>
      <xsl:text>&#xA;  </xsl:text>
      <thead><xsl:text>&#xA;    </xsl:text>
        <tr><xsl:text>&#xA;      </xsl:text>
          <th rowspan="2">Agency<br/>Type</th><xsl:text>&#xA;      </xsl:text>
          <th colspan="7" class="leftBorder">Schedule Routes with &#x2265;2 Stops</th><!--&ge;--><xsl:text>&#xA;      </xsl:text>
          <th colspan="7" class="leftBorder">Schedule Stop Names</th><xsl:text>&#xA;      </xsl:text>
          <th colspan="5" class="leftBorder">Map Stop Names</th><xsl:text>&#xA;      </xsl:text>
          <th colspan="2" class="leftBorder">Matched or Substituted Stops</th><xsl:text>&#xA;      </xsl:text>
        </tr><xsl:text>&#xA;    </xsl:text>
        <tr><xsl:text>&#xA;      </xsl:text>

          <th class="textCenter leftBorder"><abbr title="total schedule routes">#Total</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>=</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMatch"><abbr title="matching routes, where map route name matched a schedule name">#Match</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>+</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsSubst"><abbr title="substituted routes, with no matched stops but some stops substituted from other map route relation(s)">#Subst</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>+</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMissed"><abbr title="schedule routes that are unmatched or that have &lt; 2 stops">#Missed</abbr></th><xsl:text>&#xA;      </xsl:text>

          <th class="textCenter leftBorder"><abbr title="total schedule stops">#Total</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>=</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMatch"><abbr title="matching stops, where schedule name matched a map route stop name">#Match</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>+</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsSubst"><abbr title="subsitituted stops, where schedule stop name matches a map route stop name from a different route relation">#Subst</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>+</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMissed"><abbr title="unmatched schedule stops, may be spelled differently">#Missed</abbr></th><xsl:text>&#xA;      </xsl:text>

          <th class="textCenter leftBorder"><abbr title="total map stops">#Total</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>=</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMatch"><abbr title="matching stops, where map route stop name matched a schedule name">#Match</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>+</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMisspelled"><abbr title="unmatched map stops, may be spelled differently">#Misspelled</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th class="textCenter leftBorder stopsMisplaced"><abbr title="Likely misplaced stops (not between neighboring stops)">#Misplaced</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th class="textCenter"><abbr title="Ambiguous stops (chosen from multiple stops with same name)">#Ambig</abbr></th><xsl:text>&#xA;      </xsl:text>
        </tr><xsl:text>&#xA;  </xsl:text>
      </thead><xsl:text>&#xA;  </xsl:text>

      <xsl:variable name="barWidthEx" select="36"/>

      <xsl:variable name="skippedRouteRec"
        select="$log/record[param[$iMsgType] = 'COUNT_OF_SKIPPED_ROUTE']"/>
      <xsl:variable name="schedRoutesSkipped"
                    select="$skippedRouteRec/param[$iSummaryCount]"/>
      <xsl:variable name="schedRoutesTotal"
                    select="$skippedRouteRec/param[$iSummaryTotal]"/>

      <xsl:variable name="substRouteRec"
        select="$log/record[param[$iMsgType] = 'COUNT_OF_SUBST_ROUTE']"/>
      <xsl:variable name="schedRoutesSubst"
                    select="$substRouteRec/param[$iSummaryCount]"/>
      <xsl:variable name="schedRoutesMatched"
        select="$schedRoutesTotal - $schedRoutesSkipped - $schedRoutesSubst"/>

      <xsl:variable name="skippedDirRec"
        select="$log/record[param[$iMsgType] = 'COUNT_OF_SKIPPED_ROUTE_DIR']"/>
      <xsl:variable name="schedDirSkipped"
                    select="$skippedDirRec/param[$iSummaryCount]"/>
      <xsl:variable name="schedDirTotal"
                    select="$skippedDirRec/param[$iSummaryTotal]"/>

      <xsl:variable name="skippedStopsRec"
        select="$log/record[param[$iMsgType] =
                            'COUNT_OF_SCHED_STOP_NAMES_MISSED_IN_MAP']"/>
      <xsl:variable name="schedStopsMissed"
                    select="$skippedStopsRec/param[$iSummaryCount]"/>
      <xsl:variable name="schedStopsTotal"
                    select="$skippedStopsRec/param[$iSummaryTotal]"/>

      <xsl:variable name="substStopsRec"
        select="$log/record[param[$iMsgType] =
                           'COUNT_OF_SCHED_STOPS_SUBST_FROM_OTHER_MAP_ROUTE']"/>
      <xsl:variable name="schedStopsSubst"
                    select="$substStopsRec/param[$iSummaryCount]"/>
      <xsl:variable name="schedStopsMatched"
        select="$schedStopsTotal - $schedStopsSubst - $schedStopsMissed"/>

      <xsl:variable name="misspelledStopsRec"
        select="$log/record[param[$iMsgType] =
                            'COUNT_OF_MAP_ROUTE_STOPS_NOT_MATCHED']"/>
      <xsl:variable name="mapStopsMisspelled"
                    select="$misspelledStopsRec/param[$iSummaryCount]"/>
      <xsl:variable name="mapStopsTotal"
                    select="$misspelledStopsRec/param[$iSummaryTotal]"/>
      <xsl:variable name="mapStopsMatched"
                    select="$mapStopsTotal - $mapStopsMisspelled"/>

      <xsl:variable name="misplacedStopsRec"
        select="$log/record[param[$iMsgType] =
                            'COUNT_OF_MAP_ROUTE_STOPS_NOT_BETWEEN_NEIGHBORS']"/>
      <xsl:variable name="mapStopsMisplaced"
                    select="$misplacedStopsRec/param[$iSummaryCount]"/>

      <xsl:variable name="ambigStopsRec"
        select="$log/record[param[$iMsgType] =
                            'COUNT_OF_SCHED_STOPS_AMBIGUOUS_IN_MAP']"/>
      <xsl:variable name="mapStopsAmbig"
                    select="$ambigStopsRec/param[$iSummaryCount]"/>

      <tbody><xsl:text>&#xA;    </xsl:text>
        <tr>
          <xsl:attribute name="id">
            <xsl:value-of select="$agency"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$routeType"/>
            <xsl:text>-summary-row</xsl:text>
          </xsl:attribute>
          
          <xsl:text>&#xA;      </xsl:text>
          <th rowspan="3">
            <xsl:value-of select="$agency"/><br/>
            <xsl:value-of select="$TitleRouteType"/>
          </th>
          <xsl:text>&#xA;      </xsl:text>
          <!-- route matches: data -->
          <td class="stopsTotal leftBorder textCenter">
            <xsl:value-of select="$schedRoutesTotal"/>
          </td><xsl:text>&#xA;      </xsl:text>

          <td>=</td><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$schedRoutesMatched"/>
            <xsl:with-param name="classIfNonZero" select="'stopsMatch'"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <td>+</td><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$schedRoutesSubst"/>
            <xsl:with-param name="classIfNonZero" select="'stopsSubst'"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <td>+</td><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$schedRoutesSkipped"/>
            <xsl:with-param name="classIfNonZero" select="'stopsMissed'"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <!-- sched stop matches -->
          <td class="stopsTotal leftBorder textCenter">
            <xsl:value-of select="$schedStopsTotal"/>
          </td><xsl:text>&#xA;          </xsl:text>

          <td>=</td><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$schedStopsMatched"/>
            <xsl:with-param name="classIfNonZero" select="'stopsMatch'"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <td>+</td><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$schedStopsSubst"/>
            <xsl:with-param name="classIfNonZero" select="'stopsSubst'"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <td>+</td><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$schedStopsMissed"/>
            <xsl:with-param name="classIfNonZero" select="'stopsMissed'"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <!-- map stop matches -->
          <td class="stopsTotal leftBorder textCenter">
            <xsl:value-of select="$mapStopsTotal"/>
          </td><xsl:text>&#xA;          </xsl:text>

          <td>=</td><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$mapStopsMatched"/>
            <xsl:with-param name="classIfNonZero" select="'stopsMatch'"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <td>+</td><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$mapStopsMisspelled"/>
            <xsl:with-param name="classIfNonZero" select="'stopsMisspelled'"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$mapStopsMisplaced"/>
            <xsl:with-param name="classIfNonZero" select="'stopsMisplaced'"/>
            <xsl:with-param name="staticClass" select="'leftBorder' "/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

          <xsl:call-template name="count-td">
            <xsl:with-param name="value" select="$mapStopsAmbig"/>
          </xsl:call-template><xsl:text>&#xA;          </xsl:text>

        </tr>
        <tr>
          <!-- route matches: graphs -->
          <td colspan="2" class="leftBorder"/>
          <td colspan="5">
            <xsl:variable name="routeScale"
                          select="$barWidthEx div $schedRoutesTotal"/>
            <xsl:call-template name="sched-bars">
              <xsl:with-param name="matchCount"
                              select="$schedRoutesMatched * $routeScale"/>
              <xsl:with-param name="substCount"
                              select="$schedRoutesSubst * $routeScale"/>
              <xsl:with-param name="missedCount"
                              select="$schedRoutesSkipped * $routeScale"/>
            </xsl:call-template>
          </td>
          <!-- sched stop matches: graphs -->
          <td colspan="2" class="leftBorder"/>
          <td colspan="5">
            <xsl:variable name="schedStopScale"
                          select="$barWidthEx div $schedStopsTotal"/>
            <xsl:call-template name="sched-bars">
              <xsl:with-param name="matchCount"
                              select="$schedStopsMatched * $schedStopScale"/>
              <xsl:with-param name="substCount"
                              select="$schedStopsSubst * $schedStopScale"/>
              <xsl:with-param name="missedCount"
                              select="$schedStopsMissed * $schedStopScale"/>
            </xsl:call-template>
          </td>
          <!-- map stop matches: graphs -->
          <td colspan="2" class="leftBorder"/>
          <td colspan="3">
            <xsl:variable name="mapStopScale"
                          select="$barWidthEx div $mapStopsTotal"/>
            <xsl:call-template name="map-bars">
              <xsl:with-param name="matchCount"
                              select="$schedStopsMatched * $mapStopScale"/>
              <xsl:with-param name="misspelledCount"
                              select="$mapStopsMisspelled * $mapStopScale"/>
            </xsl:call-template>
          </td>
          <td colspan="2" class="leftBorder"/>
        </tr>
        <tr>
          <!-- route matches: messages -->
          <td colspan="7" class="leftBorder">
            <xsl:call-template name="summaryCountMessageBullets">
              <xsl:with-param name="summaryCountLogRecords"
                select="$log/record[(param[$iMsgType]='COUNT_OF_SKIPPED_ROUTE' or
                                     param[$iMsgType]='COUNT_OF_SUBST_ROUTE') and
                                    param[$iSummaryCount] &gt; 0]"/>
            </xsl:call-template>
          </td>
          <!-- sched stop matches: messages -->
          <td colspan="7" class="leftBorder">
            <xsl:call-template name="summaryCountMessageBullets">
              <xsl:with-param name="summaryCountLogRecords"
                select="$log/record
                        [(param[$iMsgType] = 
                          'COUNT_OF_SCHED_STOPS_SUBST_FROM_OTHER_MAP_ROUTE' or
                          param[$iMsgType] =
                          'COUNT_OF_SCHED_STOP_NAMES_MISSED_IN_MAP') and
                         param[$iSummaryCount] &gt; 0]"/>
            </xsl:call-template>
          </td>
          <!-- map stop matches: messages -->
          <td colspan="5" class="leftBorder">
            <xsl:call-template name="summaryCountMessageBullets">
              <xsl:with-param name="summaryCountLogRecords"
                select="$log/record[param[$iMsgType] =
                                    'COUNT_OF_MAP_ROUTE_STOPS_NOT_MATCHED' and
                                    param[$iSummaryCount] &gt; 0]"/>
            </xsl:call-template>
          </td>
          <td colspan="2" class="leftBorder">
            <!-- misplaced count before ambiguous count -->
            <xsl:call-template name="summaryCountMessageBullets">
              <xsl:with-param name="summaryCountLogRecords"
                select="$log/record
                        [param[$iMsgType] =
                         'COUNT_OF_MAP_ROUTE_STOPS_NOT_BETWEEN_NEIGHBORS' and
                         param[$iSummaryCount] &gt; 0]"/>
            </xsl:call-template>
            <xsl:call-template name="summaryCountMessageBullets">
              <xsl:with-param name="summaryCountLogRecords"
                select="$log/record
                        [param[$iMsgType] =
                         'COUNT_OF_SCHED_STOPS_AMBIGUOUS_IN_MAP' and
                         param[$iSummaryCount] &gt; 0]"/>
            </xsl:call-template>
          </td>
        </tr>
      </tbody><xsl:text>&#xA;</xsl:text>
    </table>
   </div><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="summaryCountMessageBullets">
    <xsl:param name="summaryCountLogRecords"/>
    <xsl:if test="$summaryCountLogRecords">
      <xsl:text>&#xA;        </xsl:text>
      <ul>
        <xsl:for-each select="$summaryCountLogRecords">
          <xsl:text>&#xA;          </xsl:text>
          <li><xsl:value-of select="./message"/></li>
        </xsl:for-each>
        <xsl:text>&#xA;        </xsl:text>
      </ul>
    </xsl:if>
  </xsl:template>

  <!-- A table summarizing counts on each route,
       preceded by list of links to each route row -->
  <xsl:template name="routes-list">
    <div id="routes-list"><xsl:text>&#xA;</xsl:text>
      <h3>Routes</h3><xsl:text>&#xA;</xsl:text>
      <p>
        <xsl:for-each select="$stopSeqs/route">
          <xsl:if
            test="position()=1 or
                  @short_name!=string(preceding-sibling::route[1]/@short_name)">
            <xsl:text>&#xA;  </xsl:text>
            <a>
              <xsl:attribute name="href">
                <xsl:value-of
                  select="concat('#', $agency, '-', $routeType, '-',
                                 @short_name, '-row')"/>
              </xsl:attribute>
              <xsl:value-of select="@short_name"/>
            </a>
          </xsl:if>
        </xsl:for-each><xsl:text>&#xA;</xsl:text>
      </p><xsl:text>&#xA;</xsl:text>
      <hr/><xsl:text>&#xA;</xsl:text>

      <xsl:call-template name="routes-list-table">
        <xsl:with-param name="stopSequences"
          select="$stopSeqs/route/stop-sequence"/>
      </xsl:call-template>
    </div><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <!-- For each route+direction, a table of stops -->
  <xsl:template name="route-log">
    <xsl:param name="routeShortName"/>

    <div class="route-log">
      <xsl:attribute name="id">
        <xsl:value-of
          select="concat($agency, '-', $routeType, '-', $routeShortName)"/>
      </xsl:attribute>

      <xsl:text>&#xA;  </xsl:text>
      <h3>
        <xsl:value-of select="$TitleRouteType"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$routeShortName"/><xsl:text> </xsl:text>
        <xsl:for-each
          select="$osmRoutes/route[@route_short_name=$routeShortName]">
          <xsl:text>(OSM relation </xsl:text>
          <a>
            <xsl:attribute name="href">
              <xsl:text>http://www.openstreetmap.org/browse/relation/</xsl:text>
              <xsl:value-of select="@route_id"/>
            </xsl:attribute>
            <xsl:value-of select="@route_id"/>
          </a>
          <xsl:text>) </xsl:text>
        </xsl:for-each>
      </h3><xsl:text>&#xA;  </xsl:text>

      <xsl:choose>
        <xsl:when test="$log/record[param[$iRteNr]=$routeShortName]">
          <xsl:call-template name="routes-list-table">
            <xsl:with-param name="stopSequences"
              select="$stopSeqs/route[@short_name=$routeShortName]/stop-sequence"/>
          </xsl:call-template>

          <table class="stopsList"><xsl:text>&#xA;  </xsl:text>
            <tbody><xsl:text>&#xA;    </xsl:text>
              <!-- unmatched map stops -->
              <xsl:call-template name="log-map-stops-unmatched-group">
                <xsl:with-param name="routeShortName" select="$routeShortName"/>
              </xsl:call-template>
              <!-- schedule route stops -->
              <xsl:for-each
                select="$stopSeqs/route[@short_name=$routeShortName]">
                <xsl:call-template name="log-route-and-stop-msg-rows">
                  <xsl:with-param name="routeShortName" select="$routeShortName"/>
                  <xsl:with-param name="stopSequence"
                    select="stop-sequence[@dir='forward']"/>
                  <xsl:with-param name="dir">forward</xsl:with-param>
                  <xsl:with-param name="titleDir">Forward</xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="log-route-and-stop-msg-rows">
                  <xsl:with-param name="routeShortName" select="$routeShortName"/>
                  <xsl:with-param name="stopSequence"
                    select="stop-sequence[@dir='backward']"/>
                  <xsl:with-param name="dir">backward</xsl:with-param>
                  <xsl:with-param name="titleDir">Reverse</xsl:with-param>
                </xsl:call-template>
              </xsl:for-each>
            </tbody>
          </table>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>OK: No &quot;</xsl:text>
          <xsl:value-of select="concat($routeType, ' ', $routeShortName)"/>
          <xsl:text>&quot; messages logged.</xsl:text>
        </xsl:otherwise>
      </xsl:choose>        
    </div><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="log-route-and-stop-msg-rows">
    <xsl:param name="stopSequence"/>
    <xsl:param name="routeShortName"/>
    <xsl:param name="dir"/><!-- uncapitalized -->
    <xsl:param name="titleDir"/><!-- capitalized -->

    <xsl:variable name="beginStop" select="$stopSequence/stop[1]"/>
    <xsl:variable name="endStop" select="$stopSequence/stop[last()]"/>

    <!-- titleDir row -->
    <tr>
      <xsl:attribute name="id">
        <xsl:value-of
          select="concat($agency, '-', $routeType, '-',
                         $routeShortName, '-', $titleDir, '-',
                         $beginStop/@number, '-', $endStop/@number)"/>
      </xsl:attribute>
      <th colspan="4">
        <xsl:value-of select="$beginStop/@name"/>
        <xsl:text> &#x2192; </xsl:text><!-- &rarr; -->
        <xsl:value-of select="$endStop/@name"/>
        <xsl:text> (</xsl:text>
        <xsl:value-of select="$titleDir"/>
        <xsl:text>)</xsl:text>
      </th>
    </tr><xsl:text>&#xA;      </xsl:text>

    <!-- non-stop-related messages -->
    <xsl:for-each
      select="$log/record[param[$iRteNr]=$routeShortName and
                          param[$iDir]=$dir and
                          ((starts-with(param[$iMsgType],'SCHED_ROUTE') and
                            param[$iMsgType] != 'SCHED_ROUTE_SUMMARY') or
                           starts-with(param[$iMsgType],'TRIP_ROUTE') or
                           starts-with(param[$iMsgType],'MAP_ROUTE_ID'))]">
      <tr class="topBorder"><xsl:text>&#xA;      </xsl:text>
        <td colspan="4" class="routeMessage">
          <xsl:value-of select="message"/>
        </td><xsl:text>&#xA;      </xsl:text>
      </tr><xsl:text>&#xA;    </xsl:text>
    </xsl:for-each>

    <!-- stop-related header -->
    <tr class="topBorder"><xsl:text>&#xA;      </xsl:text>
      <th>&#x2116;</th><!--N<sup><u>o</u></sup>--><xsl:text>&#xA;      </xsl:text>
      <th class="leftBorder">Schedule Stop</th><xsl:text>&#xA;      </xsl:text>
      <th class="leftBorder">Map Stop</th><xsl:text>&#xA;      </xsl:text>
      <th class="leftBorder">Message</th><xsl:text>&#xA;    </xsl:text>
    </tr><xsl:text>&#xA;  </xsl:text>

    <!-- stop-related messages sorted and grouped by stopSeqNr-->
    <xsl:for-each select="$stopSequence/stop">
      <xsl:call-template name="log-stop-msg-group">
        <xsl:with-param name="routeShortName" select="$routeShortName"/>
        <xsl:with-param name="dir" select="$dir"/>
        <xsl:with-param name="titleDir" select="$titleDir"/>
        <xsl:with-param name="beginSeqNr" select="$beginStop/@number"/>
        <xsl:with-param name="endSeqNr" select="$endStop/@number"/>
        <xsl:with-param name="stopSeqNr" select="@number"/>
        <xsl:with-param name="stopSchedName" select="@name"/>
       </xsl:call-template>
     </xsl:for-each>

    <!-- stop-related messages with no stopSeqNr -->
    <xsl:call-template name="log-stop-msg-group">
      <xsl:with-param name="routeShortName" select="$routeShortName"/>
      <xsl:with-param name="dir" select="$dir"/>
      <xsl:with-param name="titleDir" select="$titleDir"/>
      <xsl:with-param name="beginSeqNr" select="$beginStop/@number"/>
      <xsl:with-param name="endSeqNr" select="$endStop/@number"/>
      <xsl:with-param name="stopSeqNr" select="'???'"/>
      <xsl:with-param name="stopSchedName" select="''"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="log-stop-msg-group">
    <xsl:param name="routeShortName"/>
    <xsl:param name="dir"/>
    <xsl:param name="titleDir"/>
    <xsl:param name="beginSeqNr"/>
    <xsl:param name="endSeqNr"/>
    <xsl:param name="stopSeqNr"/>
    <xsl:param name="stopSchedName"/>

    <xsl:for-each
      select="$log/record[param[$iRteNr]=$routeShortName and
                          param[$iDir]=$dir and
                          param[$iBeginSeqNr]=$beginSeqNr and
                          param[$iEndSeqNr]=$endSeqNr and
                          param[$iStopSeqNr]=$stopSeqNr and
                          (starts-with(param[$iMsgType],'SCHED_STOP') or
                           starts-with(param[$iMsgType],'MAP_ROUTE_STOP'))]">
      <xsl:call-template name="log-stop-msg-row">
        <xsl:with-param name="dir" select="$dir"/>
        <xsl:with-param name="titleDir" select="$titleDir"/>
        <xsl:with-param name="stopSchedName" select="$stopSchedName"/>
        <xsl:with-param name="record" select="."/>
        <xsl:with-param name="stopRecordPosition" select="position()"/>
        <xsl:with-param name="stopRecordCount" select="last()"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="log-map-stops-unmatched-group">
    <xsl:param name="routeShortName"/>

    <!-- titleDir row (if any map stops were unmatched) -->
    <xsl:if test="$log/record[param[$iRteNr]=$routeShortName and
                              param[$iMsgType]='MAP_ROUTE_STOP_NOT_MATCHED']">
      <tr>
        <xsl:attribute name="id">
          <xsl:value-of
            select="concat($agency, '-', $routeType, '-', 
                           $routeShortName, '-', 'MapStopsUnmatched')"/>
        </xsl:attribute>
        <th colspan="4">Misspelled/Unmatched Map Stops</th>
      </tr>
    </xsl:if>
    
    <!-- unmatched stops -->
    <xsl:for-each
      select="$log/record[param[$iRteNr]=$routeShortName and
                          param[$iMsgType]='MAP_ROUTE_STOP_NOT_MATCHED']">
      <xsl:call-template name="log-stop-msg-row">
        <xsl:with-param name="dir" select="'all'"/>
        <xsl:with-param name="titleDir" select="'All'"/>
        <xsl:with-param name="stopSchedName" select="''"/>
        <xsl:with-param name="record" select="."/>
        <xsl:with-param name="stopRecordPosition" select="position()"/>
        <xsl:with-param name="stopRecordCount" select="last()"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="log-stop-msg-row">
    <xsl:param name="dir"/><!-- lowercase -->
    <xsl:param name="titleDir"/><!-- capitalized -->
    <xsl:param name="stopSchedName"/>
    <xsl:param name="record"/>
    <xsl:param name="stopRecordPosition"/> <!-- position in msgs for this stop -->
    <xsl:param name="stopRecordCount"/>    <!-- number of msgs for this stop -->

    <xsl:variable name="msgType" select="$record/param[$iMsgType]"/>
    <xsl:variable name="shortName" select="$record/param[$iRteNr]"/>
    <xsl:variable name="stopSeqNr" select="$record/param[$iStopSeqNr]"/>
    <xsl:variable name="mapStopName" select="$record/param[$iStopMapName]"/>
    <xsl:variable name="mapStopId" select="$record/param[$iStopMapId]"/>

    <tr>
      <xsl:if test="$stopRecordPosition=1">
        <xsl:attribute name="id">
          <xsl:value-of
            select="concat($agency, '-', $routeType, '-',
                           $shortName, '-', $titleDir, '-',
                           'SchedStop', '-', $stopSeqNr)"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:text>&#xA;      </xsl:text>

      <xsl:if test="$stopRecordPosition=1">

        <th>
          <xsl:if test="$stopRecordCount &gt; 1">
            <xsl:attribute name="rowspan">
              <xsl:value-of select="$stopRecordCount"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:value-of select="$stopSeqNr"/>
        </th><xsl:text>&#xA;      </xsl:text>

        <td>
          <xsl:if test="$stopRecordCount &gt; 1">
            <xsl:attribute name="rowspan">
              <xsl:value-of select="$stopRecordCount"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:attribute name="class">
            <xsl:text>schedStopName </xsl:text>
            <xsl:choose>
              <xsl:when test="$msgType='MAP_ROUTE_STOP_MATCHED' or
                              $msgType='MAP_ROUTE_STOP_NAME_NOT_UNIQUE'">
                <xsl:text>stopsMatch</xsl:text>
              </xsl:when>
              <xsl:when
                test="$msgType='SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_PRIOR' or
                      $msgType='SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_LATER'">
                <xsl:text>stopsMissed</xsl:text>
              </xsl:when>
              <xsl:when
                test="$msgType='SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE' or
                      $msgType='SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE_NOT_UNIQUE'">
                <xsl:text>stopsSubst</xsl:text>
              </xsl:when>
              <xsl:when test="$msgType='MAP_ROUTE_STOP_NOT_BETWEEN_NEIGHBORS'">
                <xsl:text>stopsMisplaced</xsl:text>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="$stopSchedName"/>
        </td><xsl:text>&#xA;      </xsl:text>
      </xsl:if>

      <td>
        <xsl:attribute name="class">
          <xsl:text>mapStopName </xsl:text>
          <xsl:choose>
            <xsl:when test="$msgType='MAP_ROUTE_STOP_MATCHED' or
                            $msgType='MAP_ROUTE_STOP_NAME_NOT_UNIQUE'">
              <xsl:text>stopsMatch</xsl:text>
            </xsl:when>
            <xsl:when
              test="$msgType='MAP_ROUTE_STOP_NOT_MATCHED' or
                    $msgType='SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_PRIOR' or
                    $msgType='SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_LATER'">
              <xsl:text>stopsMisspelled</xsl:text>
            </xsl:when>
            <xsl:when
              test="$msgType='SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE' or
                    $msgType='SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE_NOT_UNIQUE'">
              <xsl:text>stopsSubst</xsl:text>
            </xsl:when>
            <xsl:when test="$msgType='MAP_ROUTE_STOP_NOT_BETWEEN_NEIGHBORS'">
              <xsl:text>stopsMisplaced</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:attribute>
        <xsl:value-of select="$mapStopName"/>
        <xsl:if test="$mapStopId">
          <xsl:text> </xsl:text>
          <a>
            <xsl:attribute name="href">
              <xsl:text>http://www.openstreetmap.org/browse/node/</xsl:text>
              <xsl:value-of select="$mapStopId"/>
            </xsl:attribute>
            <xsl:value-of select="$mapStopId"/>
          </a>
        </xsl:if>
      </td><xsl:text>&#xA;      </xsl:text>

      <td class="stopMessage">
        <xsl:call-template name="link-stop-ids">
          <xsl:with-param name="msg" select="$record/message"/>
        </xsl:call-template>
      </td><xsl:text>&#xA;      </xsl:text>

    </tr><xsl:text>&#xA;    </xsl:text>
  </xsl:template>

  <xsl:template name="link-stop-ids">
    <xsl:param name="msg"/>
    <xsl:variable name="idPrologue" select="'Stop(id='"/>
    <xsl:variable name="idEpilogue" select="','"/>

    <xsl:choose>
      <xsl:when test="contains($msg, $idPrologue)">
        <xsl:variable name="begin"
          select="substring-before($msg, $idPrologue)"/>
        <xsl:variable name="id"
          select="substring-before(substring-after($msg, $idPrologue),
                                   $idEpilogue)"/>
        <xsl:variable name="end"
          select="substring-after($msg, concat($idPrologue,$id,$idEpilogue))"/>
        <xsl:value-of select="$begin"/>
        <xsl:value-of select="$idPrologue"/>
        <a>
          <xsl:attribute name="href">
            <xsl:text>http://www.openstreetmap.org/browse/node/</xsl:text>
            <xsl:value-of select="$id"/>
          </xsl:attribute>
          <xsl:value-of select="$id"/>
        </a>
        <xsl:value-of select="$idEpilogue"/>
        <xsl:call-template name="link-stop-ids">
          <xsl:with-param name="msg" select="$end"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$msg"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- A table summarizing counts on each route -->
  <xsl:template name="routes-list-table">
    <xsl:param name="stopSequences"/>

    <table class="routesList"><xsl:text>&#xA;  </xsl:text>
      <thead><xsl:text>&#xA;    </xsl:text>
        <tr><xsl:text>&#xA;      </xsl:text>
          <th rowspan="2">&#x2116;</th><!--N<sup><u>o</u></sup>--><xsl:text>&#xA;      </xsl:text>
          <th rowspan="2" class="leftBorder">Dir</th><xsl:text>&#xA;      </xsl:text>
          <th rowspan="2" class="leftBorder">Begin &#x2192; End&#xA0;&#xA0;</th><!-- &rarr; &nbsp;&nbsp;--><xsl:text>&#xA;      </xsl:text>
          <th colspan="7" class="leftBorder">Schedule Stop Names</th><xsl:text>&#xA;      </xsl:text>
          <th colspan="5" class="leftBorder">Map Stop Names</th><xsl:text>&#xA;      </xsl:text>
          <th class="leftBorder">Map Stops</th><xsl:text>&#xA;      </xsl:text>
          <th rowspan="2" class="leftBorder">Map<br/>Relation</th><xsl:text>&#xA;      </xsl:text>
        </tr><xsl:text>&#xA;    </xsl:text>
        <tr><xsl:text>&#xA;      </xsl:text>
          <th class="textCenter leftBorder"><abbr title="total schedule stops">#Total</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>=</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMatch"><abbr title="matching stops, where schedule name matched a map route stop name">#Match</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>+</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsSubst"><abbr title="subsitituted stops, where schedule stop name matches a map route stop name from a different route relation">#Subst</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>+</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMissed"><abbr title="unmatched schedule stops, may be spelled differently">#Missed</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th class="textCenter leftBorder"><abbr title="total map stops">#Total</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>=</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMatch"><abbr title="matching stops, where map route stop name matched a schedule name">#Match</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th>+</th><xsl:text>&#xA;      </xsl:text>
          <th class="stopsMisspelled"><abbr title="unmatched map stops, may be spelled differently">#Misspelled</abbr></th><xsl:text>&#xA;      </xsl:text>
          <th class="textCenter leftBorder stopsMisplaced"><abbr title="Other warnings, such as likely misplaced stops">#Misplaced</abbr></th><xsl:text>&#xA;      </xsl:text>
        </tr><xsl:text>&#xA;    </xsl:text>
      </thead><xsl:text>&#xA;  </xsl:text>
      <tbody><xsl:text>&#xA;    </xsl:text>
        <xsl:for-each select="$stopSequences">
          <xsl:variable name="shortName" select="../@short_name"/>
          <xsl:variable name="dir" select="@dir"/>
          <xsl:variable name="titleDir">
            <xsl:if test="$dir='forward'">Forward</xsl:if>
            <xsl:if test="$dir='backward'">Reverse</xsl:if>
          </xsl:variable>
          <xsl:variable name="beginStop" select="stop[1]"/>
          <xsl:variable name="endStop" select="stop[last()]"/>
          <xsl:variable name="stopCount" select="count(stop)"/>
          <xsl:variable name="summaryRecord" 
            select="$log/record[param[$iMsgType]='SCHED_ROUTE_SUMMARY' and
                                param[$iRteNr]=$shortName and
                                param[$iDir]=$dir]"/>
          <xsl:variable name="routeId"
            select="$summaryRecord/param[4]"/>
          <xsl:variable name="schedStopsUnmatchedCount"
            select="$summaryRecord/param[6]"/>
          <xsl:variable name="schedStopsSubstCount"
            select="$summaryRecord/param[7]"/>
          <xsl:variable name="stopsNotBetweenNeighborsCount"
            select="$summaryRecord/param[8]"/>
          <xsl:variable name="mapStopsUnmatchedCountRecord"
            select="$log/record[param[$iMsgType]=
                                'MAP_ROUTE_STOPS_NOT_MATCHED_COUNT' and
                                param[$iRteNr]=$shortName]"/>
          <xsl:variable name="mapStopsUnmatchedCount"
            select="$mapStopsUnmatchedCountRecord/param[5]"/>
          <xsl:variable name="matchedStopsCount">
            <xsl:if test="$stopCount and $schedStopsUnmatchedCount and $schedStopsSubstCount">
              <xsl:value-of select="$stopCount - $schedStopsUnmatchedCount - $schedStopsSubstCount"/>
            </xsl:if>
          </xsl:variable>
          <xsl:variable name="mapStopsCount">
            <xsl:if test="$matchedStopsCount and $mapStopsUnmatchedCount">
              <xsl:value-of select="$matchedStopsCount + $mapStopsUnmatchedCount"/>
            </xsl:if>
          </xsl:variable>
          <tr>
            <xsl:if test="$dir!='backward'">
              <xsl:attribute name="id">
                <xsl:value-of
                  select="concat($agency, '-', $routeType, '-',
                                 $shortName, '-row')"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:text>&#xA;      </xsl:text>

            <xsl:if test="not($dir='backward' and preceding-sibling::stop-sequence/@dir='forward')">
              <th>
                <xsl:if test="$dir='forward' and following-sibling::stop-sequence/@dir='backward'">
                  <xsl:attribute name="rowspan">4</xsl:attribute>
                </xsl:if>
                <a>
                  <xsl:attribute name="href">
                    <xsl:value-of
                      select="concat('#', $agency, '-', $routeType, '-',
                                     $shortName)"/>
                  </xsl:attribute>
                  <xsl:value-of select="concat($TitleRouteType, ' ', $shortName)"/>
                </a>
              </th><xsl:text>&#xA;      </xsl:text>
            </xsl:if>

            <td class="dir">
              <a>
                <xsl:attribute name="href">
                  <xsl:value-of
                    select="concat('#', $agency, '-', $routeType, '-',
                                   $shortName, '-', $titleDir, '-',
                                   $beginStop/@number, '-', $endStop/@number)"/>
                </xsl:attribute>
                <xsl:value-of select="substring($titleDir, 1, 1)"/>
              </a>
            </td><xsl:text>&#xA;      </xsl:text>

            <td class="beginEnd">
              <xsl:value-of select="$beginStop/@name"/>
              <xsl:text> &#x2192; </xsl:text> <!-- 2192 -->
              <xsl:value-of select="$endStop/@name"/>
            </td><xsl:text>&#xA;      </xsl:text>

            <td class="stopsTotal leftBorder textCenter">
              <xsl:value-of select="$stopCount"/>
            </td><xsl:text>&#xA;      </xsl:text>

            <td>=</td><xsl:text>&#xA;      </xsl:text>

            <xsl:call-template name="count-td">
              <xsl:with-param name="value" select="$matchedStopsCount"/>
              <xsl:with-param name="classIfNonZero" select="'stopsMatch'"/>
            </xsl:call-template><xsl:text>&#xA;      </xsl:text>

            <td>+</td><xsl:text>&#xA;      </xsl:text>

            <xsl:call-template name="count-td">
              <xsl:with-param name="value" select="$schedStopsSubstCount"/>
              <xsl:with-param name="classIfNonZero" select="'stopsSubst'"/>
            </xsl:call-template><xsl:text>&#xA;      </xsl:text>

            <td>+</td><xsl:text>&#xA;      </xsl:text>

            <xsl:call-template name="count-td">
              <xsl:with-param name="value" select="$schedStopsUnmatchedCount"/>
              <xsl:with-param name="classIfNonZero" select="'stopsMissed'"/>
            </xsl:call-template><xsl:text>&#xA;      </xsl:text>

            <td class="stopsTotal leftBorder textCenter">
              <xsl:value-of select="$mapStopsCount"/>
            </td><xsl:text>&#xA;      </xsl:text>

            <td>=</td><xsl:text>&#xA;      </xsl:text>

            <xsl:call-template name="count-td">
              <xsl:with-param name="value" select="$matchedStopsCount"/>
              <xsl:with-param name="classIfNonZero" select="'stopsMatch'"/>
            </xsl:call-template><xsl:text>&#xA;      </xsl:text>

            <td>+</td><xsl:text>&#xA;      </xsl:text>

            <xsl:call-template name="count-td">
              <xsl:with-param name="value" select="$mapStopsUnmatchedCount"/>
              <xsl:with-param name="classIfNonZero" select="'stopsMisspelled'"/>
            </xsl:call-template><xsl:text>&#xA;      </xsl:text>

            <xsl:call-template name="count-td">
              <xsl:with-param name="value" select="$stopsNotBetweenNeighborsCount"/>
              <xsl:with-param name="classIfNonZero" select="'stopsMisplaced'"/>
              <xsl:with-param name="staticClass" select="'leftBorder' "/>
            </xsl:call-template><xsl:text>&#xA;      </xsl:text>

            <td class="routeId">
              <xsl:value-of select="$routeId"/>
            </td><xsl:text>&#xA;    </xsl:text>
          </tr><xsl:text>&#xA;    </xsl:text>
          <tr>
            <td class="leftBorder"/>
            <td class="leftBorder">
              <xsl:call-template name="sched-stops-dots">
                <xsl:with-param name="stopSeq" select="."/>
              </xsl:call-template>
            </td>
            <td colspan="7" class="leftBorder">
              <xsl:call-template name="sched-bars">
                <xsl:with-param name="matchCount" select="$matchedStopsCount"/>
                <xsl:with-param name="substCount" select="$schedStopsSubstCount"/>
                <xsl:with-param name="missedCount" select="$schedStopsUnmatchedCount"/>
              </xsl:call-template>
            </td>
            <td colspan="5" class="leftBorder">
              <xsl:call-template name="map-bars">
                <xsl:with-param name="matchCount" select="$matchedStopsCount"/>
                <xsl:with-param name="misspelledCount" select="$mapStopsUnmatchedCount"/>
              </xsl:call-template>
            </td>
            <td class="leftBorder"/>
            <td class="leftBorder"/>
          </tr><xsl:text>&#xA;    </xsl:text>
        </xsl:for-each>
      </tbody><xsl:text>&#xA;  </xsl:text>
    </table><xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="count-td">
    <xsl:param name="value"/>
    <xsl:param name="classIfNonZero" select="''"/>
    <xsl:param name="staticClass" select="''"/>
    <td>
      <xsl:attribute name="class">
        <xsl:if test="$value &gt; 0 and string-length($classIfNonZero) &gt; 0">
          <xsl:value-of select="$classIfNonZero"/>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:if test="string-length($staticClass) &gt; 0">
          <xsl:value-of select="$staticClass"/>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:text>textCenter</xsl:text>
      </xsl:attribute>
      <xsl:value-of select="$value"/>
    </td>
  </xsl:template>

  <xsl:template name="sched-bars">
    <xsl:param name="matchCount"/>
    <xsl:param name="substCount"/>
    <xsl:param name="missedCount"/>

    <table class="stopBars">
      <tr>
        <xsl:call-template name="td-bar">
          <xsl:with-param name="class" select="'matchBar'"/>
          <xsl:with-param name="count" select="$matchCount"/>
        </xsl:call-template>
        <xsl:call-template name="td-bar">
          <xsl:with-param name="class" select="'substBar'"/>
          <xsl:with-param name="count" select="$substCount"/>
        </xsl:call-template>
        <xsl:call-template name="td-bar">
          <xsl:with-param name="class" select="'missedBar'"/>
          <xsl:with-param name="count" select="$missedCount"/>
        </xsl:call-template>
      </tr>
    </table>
  </xsl:template>

  <xsl:template name="map-bars">
    <xsl:param name="matchCount"/>
    <xsl:param name="misspelledCount"/>

    <table class="stopBars">
      <tr>
        <xsl:call-template name="td-bar">
          <xsl:with-param name="class" select="'matchBar'"/>
          <xsl:with-param name="count" select="$matchCount"/>
        </xsl:call-template>
        <xsl:call-template name="td-bar">
          <xsl:with-param name="class" select="'misspelledBar'"/>
          <xsl:with-param name="count" select="$misspelledCount"/>
        </xsl:call-template>
      </tr>
    </table>
  </xsl:template>

  <xsl:template name="td-bar">
    <xsl:param name="class"/>
    <xsl:param name="count"/>
    <xsl:if test="$count &gt; 0">
      <td>
        <xsl:attribute name="class">
          <xsl:value-of select="$class"/>
        </xsl:attribute>
        <xsl:attribute name="style">
          <xsl:value-of select="concat('width:', $count, 'ex;')"/>
        </xsl:attribute>
      </td>
    </xsl:if>
  </xsl:template>
    
  <xsl:template name="sched-stops-dots">
    <xsl:param name="stopSeq"/>

    <xsl:variable name="routeNr" select="$stopSeq/parent::route/@short_name"/>
    <xsl:variable name="dir" select="$stopSeq/@dir"/>
    <xsl:variable name="titleDir">
      <xsl:if test="$dir='forward'">Forward</xsl:if>
      <xsl:if test="$dir='backward'">Reverse</xsl:if>
    </xsl:variable>

    <table class="stopDots">
      <xsl:attribute name="onclick">
        <xsl:text>if (event.target) {</xsl:text>
        <xsl:text>  var n = event.target.getAttribute('n');</xsl:text>
        <xsl:text>  if (n != null) {</xsl:text>
        <xsl:text>    document.location = </xsl:text>
        <xsl:text>      this.getAttribute('href') + n;</xsl:text>
        <xsl:text>  }</xsl:text>
        <xsl:text>}</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="href">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="$agency"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$routeType"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$routeNr"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$titleDir"/>
        <xsl:text>-SchedStop-</xsl:text>
      </xsl:attribute>
      <tr>
        <xsl:variable name="routeDirRecords"
          select="$log/record[param[$iRteNr]=$routeNr and param[$iDir]=$dir]"/>
        <xsl:for-each select="stop">
          <xsl:variable name="seqNr" select="@number"/>
          <xsl:variable name="stopRecords"
            select="$routeDirRecords[param[$iStopSeqNr]=$seqNr]"/>
          <td>
            <xsl:attribute name="n">
              <xsl:value-of select="@number"/>
            </xsl:attribute>
            <xsl:attribute name="class">
              <xsl:choose>
                <!-- Misplaced stop must also be either matched or substituted.
                     So test in severity order: misplaced, subst, matched. -->
                <xsl:when
                  test="$stopRecords[param[$iMsgType]='MAP_ROUTE_STOP_NOT_BETWEEN_NEIGHBORS']">
                  <xsl:text>misplacedDot</xsl:text>
                </xsl:when>
                <xsl:when
                  test="$stopRecords[param[$iMsgType]='SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE' or
                                     param[$iMsgType]='SCHED_STOP_SUBST_FROM_OTHER_MAP_ROUTE_NOT_UNIQUE']">
                  <xsl:text>substDot</xsl:text>
                </xsl:when>
                <xsl:when
                  test="$stopRecords[param[$iMsgType]='MAP_ROUTE_STOP_MATCHED' or
                                     param[$iMsgType]='MAP_ROUTE_STOP_NAME_NOT_UNIQUE']">
                  <xsl:text>matchDot</xsl:text>
                </xsl:when>
                <xsl:when
                  test="$stopRecords[param[$iMsgType]='SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_PRIOR' or
                                     param[$iMsgType]='SCHED_STOP_NAME_MISSED_IN_MAP_SUBST_LATER']">
                  <xsl:text>missedDot</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="title">
              <xsl:value-of select="@number"/>
              <xsl:text>: </xsl:text>
              <xsl:value-of select="@name"/>
            </xsl:attribute>
          </td>
        </xsl:for-each>
      </tr>
    </table>

  </xsl:template>

</xsl:transform>
