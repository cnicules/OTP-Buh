<!-- Create a altered copy of otpDir/graph-builder.xml.original

  Input document: graph-builder.xml.original
    <beans ...>
      <bean id="graphBundle" ...>
        <property name="path" value="/otp"/>
      </bean>
      <bean id="gtfsBuilder" ...>
        <property name="gtfsBundles">
          <bean id="gtfsBundles" ...>
            <property name="bundles">
              <list>
                <bean ...>
                  <property name="defaultAgencyId" value="TriMet"/>
                </bean>
              </list>
            </property>
          </bean>
        </property>
      </bean>
      <bean id="nedBuilder" ...>
        ...
      </bean>
      <bean id="osmBuilder" ..>
        <property name="provider">
          <bean ...>
            <property name="path" value="/otp/cache/osm/or-wa.osm"/>
          </bean>
        </property>
        <property name="defaultWayPropertySetSource">
          <bean .../>
        </property>
      </bean>
      <bean id="transitStreetLink" .../>
      <bean id="optimizeTransit" .../>
      <bean id="graphBuilderTask" ...>
        <property name="graphBundle" ref="graphBundle"/>
        <property name="graphBuilders">
          <list>
            <ref bean="gtfsBuilder"/>
            <ref bean="osmBuilder"/>
            <ref bean="transitStreetLink"/>
            <ref bean="optimizeTransit"/>
          </list> 
        </property>
      </bean>
    </beans>

  Param otpDir: file directory where OpenTripPlanner is installed.

  Param bucharestOsm: file path to bucharest.osm (open street map of city).

  Param otpGtfsInputsXml: path to gtfs zip file for each agency.
    <gtfs-files>
      <gtfs-file defaultAgencyId="Metrorex" path="[filePathToSubwayGtfsZip]"/>
      <gtfs-file defaultAgencyId="RATB" path="[filePathToTramGtfsZip]"/>
      <gtfs-file defaultAgencyId="RATB" path="[filePathToTrolleybusGtfsZip]"/>
      <gtfs-file defaultAgencyId="RATB" path="[filePathToUrbanbusGtfsZip]"/>
      ...
    </gtfs-files>

  Output document: graph-builder.xml
    <beans ...>
      <bean id="graphBundle" ...>
        <property name="path" value="[optDir]"/>
      </bean>
      <bean id="gtfsBuilder" ...>
        <property name="gtfsBundles">
          <bean id="gtfsBundles" ...>
            <property name="bundles">
              <list>
                <bean ...>
                  <property name="defaultAgencyId" value="Metrorex"/>
                  <property name="path" value="[filePathToSubwayGtfsZip]"/>
                </bean>
                <bean ...>
                  <property name="defaultAgencyId" value="RATB"/>
                  <property name="path" value="[filePathToTramGtfsZip]"/>
                </bean>
                <bean ...>
                  <property name="defaultAgencyId" value="RATB"/>
                  <property name="path" value="[filePathToTrolleybusGtfsZip]"/>
                </bean>
                <bean ...>
                  <property name="defaultAgencyId" value="RATB"/>
                  <property name="path" value="[filePathToUrbanbusGtfsZip]"/>
                </bean>
                ...
              </list>
            </property>
          </bean>
        </property>
      </bean>
      <bean id="osmBuilder" ..>
        <property name="provider">
          <bean ...>
            <property name="path" value="[bucharestOsm]"/>
          </bean>
        </property>
        <property name="defaultWayPropertySetSource">
          <bean .../>
        </property>
      </bean>
      <bean id="transitStreetLink" .../>
      <bean id="optimizeTransit" .../>
      <bean id="graphBuilderTask" ...>
        <property name="graphBundle" ref="graphBundle"/>
        <property name="graphBuilders">
          <list>
            <ref bean="gtfsBuilder"/>
            <ref bean="osmBuilder"/>
            <ref bean="transitStreetLink"/>
            <ref bean="optimizeTransit"/>
          </list> 
        </property>
      </bean>
    </beans>

-->
<xsl:transform version="1.0"
  xmlns="http://www.springframework.org/schema/beans"
  xmlns:sfb="http://www.springframework.org/schema/beans"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:context="http://www.springframework.org/schema/context"
  xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-2.5.xsd
    http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-2.5.xsd">

  <xsl:output method="xml" encoding="UTF-8" indent="true"/>

  <xsl:param name="otpDir" select="'/otp'"/>
  <xsl:param name="bucharestOsm" select="'target/bucharest.osm'"/>
  <xsl:param name="otpGtfsInputsXml" select="'build/otp/otp-gtfs-inputs.xml'"/>

  <xsl:variable name="otpGtfsFiles"
    select="document($otpGtfsInputsXml)/gtfs-files"/>

  <xsl:template match="/sfb:beans">
    <xsl:text>&#xA;</xsl:text>
    <beans>
      <xsl:apply-templates select="@*|node()"/>
      <xsl:text>&#xA;</xsl:text>
    </beans>
  </xsl:template>  

  <xsl:template match="sfb:bean[@id='graphBundle']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:text>&#xA;        </xsl:text>
      <property name="path">
        <xsl:attribute name="value">
          <xsl:value-of select="$otpDir"/>
        </xsl:attribute>
      </property>    
      <xsl:text>&#xA;    </xsl:text>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="sfb:bean[@id='gtfsBuilder']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:text>&#xA;        </xsl:text>
      <property name="gtfsBundles">
        <xsl:text>&#xA;            </xsl:text>
        <bean id="gtfsBundles" class="org.opentripplanner.graph_builder.model.GtfsBundles">
          <xsl:text>&#xA;                </xsl:text>
          <property name="bundles">
            <xsl:text>&#xA;                    </xsl:text>
            <list>

              <xsl:for-each select="$otpGtfsFiles/gtfs-file">              
                <xsl:text>&#xA;                        </xsl:text>
                <bean class="org.opentripplanner.graph_builder.model.GtfsBundle">
                  <xsl:text>&#xA;                            </xsl:text>
                  <property name="path">
                    <xsl:attribute name="value">
                      <xsl:value-of select="@path"/>
                    </xsl:attribute>
                  </property>
                  <xsl:text>&#xA;                            </xsl:text>
                  <property name="defaultAgencyId">
                    <xsl:attribute name="value">
                      <xsl:value-of select="@defaultAgencyId"/>
                    </xsl:attribute>
                  </property>
                  <xsl:text>&#xA;                        </xsl:text>
                </bean>
              </xsl:for-each>

              <xsl:text>&#xA;                    </xsl:text>
            </list>
            <xsl:text>&#xA;                </xsl:text>
          </property>
          <xsl:text>&#xA;            </xsl:text>
        </bean>
        <xsl:text>&#xA;        </xsl:text>
      </property>
      <xsl:text>&#xA;    </xsl:text>
    </xsl:copy>
  </xsl:template>

  <!-- omit ned builder bean, no ned altitude data -->
  <xsl:template match="sfb:bean[@id='nedBuilder']">
  </xsl:template>

  <xsl:template match="sfb:bean[@id='osmBuilder']">

    <xsl:copy>
      <xsl:apply-templates select="@*"/>

      <xsl:text>&#xA;        </xsl:text>
      <xsl:apply-templates select="sfb:property[@name != 'provider']"/>

      <xsl:text>&#xA;        </xsl:text>
      <property name="provider">
        <xsl:text>&#xA;            </xsl:text>
        <bean class="org.opentripplanner.graph_builder.impl.osm.StreamedFileBasedOpenStreetMapProviderImpl">
          <xsl:text>&#xA;                </xsl:text>
          <property name="path">
            <xsl:attribute name="value">
              <xsl:value-of select="$bucharestOsm"/>
            </xsl:attribute>
          </property>
          <xsl:text>&#xA;            </xsl:text>
        </bean>
        <xsl:text>&#xA;        </xsl:text>
      </property>
      <xsl:text>&#xA;    </xsl:text>
    </xsl:copy>      
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:transform>