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
    Commons-logging 1.1.1
    Apache Commons Codec 1.5

  osmosis-0.39
  
  OpenTripPlanner 0.4.2 2011-08-10
  
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

0.2.3 Commons logging 1.1.1
 * (skip: Commons logging 1.8.0 already installed)
 * Or direct: Downloadable from 
   http://commons.apache.org/logging/download_logging.cgi
   (binary distribution is sufficient)
 ** Copy commons-logging-1.1.1.jar to ${ANT_HOME}/lib

0.2.4 Commons Codec 1.5
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
 ** cp -uav /otp/webapps/*.war /var/lib/tomcat6/webapps/


1. Unzip BucharestTripPlanner 
 - Unzip btp-YYYYMMDD-sources.zip, creating ~/btp/ directory

2. Create btp/build.properties file (or copy from an old btp directory):
    osmosis.home.dir = /PATH-TO-INSTALL-DIR/osmosis-0.39
    otp.home.dir = /PATH-TO-INSTALL-DIR/otp
  ** Example:
    osmosis.home.dir = /usr/local/share/osmosis-0.39
    otp.home.dir = /otp

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

9. Restart OpenTripPlanner (see step 5).
