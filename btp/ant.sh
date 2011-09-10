#!/bin/sh
# Need large memory for xslt transforms with key indexes on .osm files
ANT_OPTS=-Xmx512M
export ANT_OPTS
ant $*
