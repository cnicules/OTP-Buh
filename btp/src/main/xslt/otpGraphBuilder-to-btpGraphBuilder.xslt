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
  <xsl:param name="metrorexGtfsZip" select="'target/metrorex-gtfs.zip'"/>
  <xsl:param name="ratbTramGtfsZip" select="'target/ratb-tram-gtfs.zip'"/>

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
              <xsl:text>&#xA;                        </xsl:text>
              <bean class="org.opentripplanner.graph_builder.model.GtfsBundle">
                <xsl:text>&#xA;                            </xsl:text>
                <property name="path">
                  <xsl:attribute name="value">
                    <xsl:value-of select="$metrorexGtfsZip"/>
                  </xsl:attribute>
                </property>
                <xsl:text>&#xA;                            </xsl:text>
                <property name="defaultAgencyId" value="Metrorex"/>
                <xsl:text>&#xA;                        </xsl:text>
              </bean>
              <xsl:text>&#xA;                        </xsl:text>
              <bean class="org.opentripplanner.graph_builder.model.GtfsBundle">
                <xsl:text>&#xA;                            </xsl:text>
                <property name="path">
                  <xsl:attribute name="value">
                    <xsl:value-of select="$ratbTramGtfsZip"/>
                  </xsl:attribute>
                </property>
                <xsl:text>&#xA;                            </xsl:text>
                <property name="defaultAgencyId" value="RATB"/>
                <xsl:text>&#xA;                        </xsl:text>
              </bean>
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
      <xsl:apply-templates select="property[name != 'provider']"/>

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