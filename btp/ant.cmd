@ECHO OFF
@REM Need large memory for xslt transforms with key indexes on .osm files
SET ANT_OPTS=-Xmx512M
"%ANT_HOME%\bin\ant" %*


