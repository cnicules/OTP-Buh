Bucharest Trip Planner

Prepares data needed by OpenTripPlanner to plan trips including metro
and tram lines in Bucharest, Romania.

* Downloads and merges OSM (Open Street Map) file for Bucharest, Romania
  from api.openstreetmap.org.
* Downloads trip frequency pages from Metrorex.ro and builds 
  GTFS (General Transit Feed Specification) files.
* Downloads trip frequency and stop-sequence pages from RATB.ro
  and builds GTFS (General Transit Feed Specification) files.
* Generates OpenTripPlanner graph-builder.xml and Graph.obj.

Tested with:
  Java JDK 1.6.0_26

  Apache Ant 1.8.0
    Ant-contrib 1.0b3
    Apache Commons HttpClient 3.0.1
    Commons-logging 1.1.1
    Apache Commons Codec 1.5

  osmosis-0.39
  
  OpenTripPlanner 0.4.2 2011-10-30
  
INSTALLATION

0. Libraries

0.1 Java SE JDK (Java development kit: virtual machine, libs, and compiler)
 * Via apt: sudo apt-get install openjdk-6-jdk
 * alternative: Oracle's Java SE JDK installer is downloadable from
   http://www.oracle.com/technetwork/java/javase/downloads/index.html

0.2 Apache Ant (cross-platform build tool)
0.2.1 Apache Ant 1.8 distribution
 * Via apt: sudo apt-get install ant1.8
 * Or direct: Downloadable from
   http://ant.apache.org/
   (binary distribution with dependencies is sufficient)
 ** Installation instructions
    http://ant.apache.org/manual/index.html
    (be sure to define ANT_HOME to installation directory)

0.2.2 Ant-contrib 1.0b3 (extensions to Apache Ant)
 * Via apt: sudo apt-get install ant-contrib
 ** cd /usr/share/ant/lib
 ** sudo ln -s ../../java/ant-contrib-1.0b3.jar
 * Or direct: Downloadable from http://ant-contrib.sourceforge.net/
 ** Copy ant-contrib-0.3.jar to ${ANT_HOME}/lib/

0.2.3 Commons HttpClient 3.x
 * via apt: sudo apt-get install libcommons-httpclient-java 
 ** cd /usr/share/ant/lib
 ** sudo ln -s ../../java/commons-httpclient.jar
 * Or direct: Downloadable from http://hc.apache.org/httpclient-3.x/
 ** copy commons-httpclient-3.0.1.jar to ${ANT_HOME}/lib/

0.2.4 Commons logging 1.1.1
 * (skip: Commons logging 1.8.0 already installed)
 * Or direct: Downloadable from 
   http://commons.apache.org/logging/download_logging.cgi
   (binary distribution is sufficient)
 ** Copy commons-logging-1.1.1.jar to ${ANT_HOME}/lib

0.2.5 Commons Codec 1.5
 * via apt: sudo apt-get install libcommons-codec-java
 ** (may already be downloaded for httpclient, just need link)
 ** sudo ln -s ../../java/commons-codec.jar
 * direct: Downloadable from
   http://commons.apache.org/codec/download_codec.cgi
   (binary distribution is sufficient)
 ** wget http://apache.mirrors.redwire.net//commons/codec/binaries/commons-codec-1.5-bin.tar.gz
 ** tar --gunzip \
        -xvf commons-codec-1.5-bin.tar.gz \
        commons-codec-1.5/commons-codec-1.5.jar
 ** sudo cp -av commons-codec-1.5/commons-codec-1.5.jar /usr/share/ant/lib/
    (Copies commons-codec-1.5.jar to ${ANT_HOME}/lib)  

0.3 Osmosis 0.39
 * Downloadable from 
   http://wiki.openstreetmap.org/wiki/Osmosis
   (stable version)
 ** wget http://dev.openstreetmap.org/~bretth/osmosis-build/osmosis-latest.tgz
 ** tar --gunzip -xvf osmosis-latest.tgz
 ** sudo mv osmosis-0.39 /usr/local/share/

0.4 OpenTripPlanner 0.4.2 (otp)
 * Downloadable from
   https://github.com/openplans/OpenTripPlanner/wiki/
   (previously www.opentripplanner.org)
 ** wget http://maps5.trimet.org/otp-dev/otp.zip
   (Note: this zip file is updated frequently; it is not a stable release.)
 ** sudo apt-get install unzip
 ** unzip otp.zip
 ** mv otp/graph-builder.xml otp/graph-builder.xml.original
 ** sudo mv otp /

0.5 Tomcat 6.0
 * Downloadable from 
   http://tomcat.apache.org/

0.5.1 Tomcat 6 server
 * via apt: sudo apt-get install tomcat6
 * install otp webapp files in the tomcat webapps folder.
 ** sudo cp -uav /otp/webapps/*.war /var/lib/tomcat6/webapps/

0.5.2 Tomcat 6 manager webapp (used to reload webapp without restarting server)
 * via apt: sudo apt-get install tomcat6-admin
 * install the tomcat catalina-ant.jar in the ant lib folder.
 ** cd /usr/share/ant/lib
 ** sudo ln -s /usr/share/tomcat6/lib/catalina-ant.jar 

1. Unzip BucharestTripPlanner 
 - Unzip btp-YYYYMMDD-sources.zip, creating ~/btp/ directory

2. Create btp/build.properties file (or copy from an old btp directory):
    osmosis.home.dir = /PATH-TO-INSTALL-DIR/osmosis-0.39
    otp.home.dir = /PATH-TO-INSTALL-DIR/otp

    # osm.sourceType for bucharest.osm
    # 'copy'      copy bucharest.osm from file at ${bucharest.prepared.osm}
    # 'bugssy'    download bucharest.osm from osm.bugssy.net
    # 'geofabrik' download region.osm.pbf from geofabrik, extract bucharest.osm
    # 'osm-api'   download parts of bucharest from api.openstreetmap.org, merge
    osm.sourceType = copy

    # optional, for osm.sourceType copy
    bucharest.prepared.osm = ../bucuresti-20110928.osm

    # optional: if defined, merges src/main/osm fixes; 
    #           to skip fixes, comment it out.
    # osm.use-fixes = true

    # tomcat
    tomcat.webapps.dir: /PATH-TO-TOMCAT/webapps

    # optional, for Tomcat manager to reload webapp/graph
    tomcat.username: otp-buh
    tomcat.password: 1PassC0de

  ** Example:
    osmosis.home.dir = /usr/local/share/osmosis-0.39
    otp.home.dir = /otp

    # osm.sourceType for bucharest.osm
    # 'copy'      copy bucharest.osm from file at ${bucharest.prepared.osm}
    # 'bugssy'    download bucharest.osm from osm.bugssy.net
    # 'geofabrik' download region.osm.pbf from geofabrik, extract bucharest.osm
    # 'osm-api'   download parts of bucharest from api.openstreetmap.org, merge
    osm.sourceType = copy

    # optional, for osm.sourceType copy
    bucharest.prepared.osm = ../bucuresti-20110928.osm

    # optional: if defined, merges src/main/osm fixes; 
    #           to skip fixes, comment it out.
    # osm.use-fixes = true

    # tomcat (for dir created with "tomcat6-instance-create /otp-buh-tomcat")
    tomcat.webapps.dir: /otp-buh-tomcat/webapps

    # optional, for Tomcat manager to reload webapp/graph
    tomcat.username: otp-buh
    tomcat.password: 1PassC0de

3. (optional) To reuse previously downloaded schedule and map files,
   copy them to new directory:
     cp -r PATH-TO-OLD/btp/downloads PATH-TO-NEW/btp

4. Build Graph.obj for OpenTripPlanner:
     cd btp/
     chmod 775 ./ant.sh
     ./ant.sh clean build

   (ant.sh runs Apache Ant on build.xml with 512MB memory.
    Alternatively, define
      ANT_OPTS=-Xmx512m
      export ANT_OPTS
    then normal
      ant clean build
    should work.)
   
   (Note: on some machines, the Osmosis merge may produce the following error:
    java.lang.LinkageError:
      loader (instance of org/codehaus/plexus/classworlds/realm/ClassRealm):
        attempted  duplicate class definition for name:
	  "org/apache/xerces/jaxp/datatype/DatatypeFactoryImpl"
    In many cases, this may be a timing error [maybe caused by a slow disk].
    Simply run ant.sh immediately again.  Then it usually works.)

5. (Re)Start local OpenTripPlanner

    Winstone server started as application:
      To stop (if started): 
	control-C (in shell where Winstone was started)
      To start:
	cd ${otp.home.dir}
	bin/start-server
    Tomcat server started as application:
      To stop (if started):
	cd TOMCAT_HOME
	bin/shutdown
      To start:
	cd TOMCAT_HOME
	bin/startup
    Tomcat server started as Unix daemon:
      To start (if not running):
	sudo /etc/init.d/tomcat6 start
      To restart (if already running):
	sudo /etc/init.d/tomcat6 restart

6. Open web browser
     http://localhost:8080/opentripplanner-webapp/index.html
   This causes web server to unpack opentripplanner-webapp.war file.

7. Stop OpenTripPlanner

   Winstone server started as application: 
     control-C in shell where bin/start-server.sh is running
   Tomcat6 server started as application:
     cd TOMCAT_HOME
     bin/shutdown
   Tomcat server started as Unix daemon:
     sudo /etc/init.d/tomcat6 stop

8. Patch index.html with JS script that converts English UI to SI units (m, km).
   Patch index.html with JS script that sets defaultExtent to downtown Bucarest.
   Winstone server: (otp.home.dir/webapps)
     cd /otp/webapps/
     sudo patch -l -p 1 -i ~/btp/src/main/otp/p01-webapp-englishToSIUnits.patch
     sudo patch -l -p 1 -i ~/btp/src/main/otp/p02-webapp-mapDefaultExtent.patch
     sudo patch -l -p 1 -i ~/btp/src/main/otp/p03-webapp-localeDateTime.patch
     sudo patch -l -p 1 -i ~/btp/src/main/otp/p04-webapp-englishIntlTime.patch

   Tomcat6 server: (CATALINA_BASE/webapps)
     cd /var/lib/tomcat6/webapps/
     sudo patch -l -p 1 -i ~/btp/src/main/otp/p01-webapp-englishToSIUnits.patch
     sudo patch -l -p 1 -i ~/btp/src/main/otp/p02-webapp-mapDefaultExtent.patch
     sudo patch -l -p 1 -i ~/btp/src/main/otp/p03-webapp-localeDateTime.patch
     sudo patch -l -p 1 -i ~/btp/src/main/otp/p04-webapp-englishIntlTime.patch

   (If your version of the patch command is picky, the -l option may
    not ignore the carriage-returns at the ends of some source lines.
    In that case you may need to remove the carriage returns before
    applying the patches.  One way is to use the gnu sed command:
      cd opentripplanner-webapp
      sudo sed -i 's/\r$//' index.html js/otp/planner/Forms.js js/otp/planner/TripTab.js js/otp/planner/Templates.js 
      cd ..
    Now apply the patches as above.)

9. Restart OpenTripPlanner (see step 5).

10. Edit Tomcat users to add otp-buh.
    This is needed to restart webapp (to reload graph) via "ant otp-api-reload".
  * file: 
    TOMCAT_HOME/conf/tomcat-users.xml
    /var/lib/tomcat6/conf/tomcat-users.xml
  * Add user otp-buh with same password as in build.properties:
    <tomcat-users>
      ...
      <user name="otp-buh" password="1PassC0de" roles="manager" />
      ...
    </tomcat-users>

11. (optional, for development) If using Tomcat, create cron job to update map
    periodically from downloaded data.
    Command may be something like one of the following.
    Overwrite same build.log:
     cd /home/uname/btp; ./ant.sh -logfile build.log build-reload
    Or write log named with datetime, build-YYYY-MM-DD-HHMM.log:
     cd /home/uname/btp; ./ant.sh -logfile build-`date +\%F-\%H\%M`.log build-reload

12. (optional, for development) If using Tomcat, create stops-matched pages
    from stop name matching log.
      ant stops-matched
    Deploys pages in a warfile (web archive file) to ${tomcat.webapps.dir}.
    If Tomcat is running it will automatically delete old directory
    and unpack warfile of new files.  URL path is "/stops-matched/index.html".
