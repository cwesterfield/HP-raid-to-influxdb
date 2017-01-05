#!/bin/bash
#Create table of output for Influxdb

HPACUCLI=`which hpacucli`
HPACUCLI_RAW=/tmp/hpacucli.raw
HPACUCLI_CLN=/tmp/hpacucli.log


##Create flat file
echo "@LOGICALDRIVEINFO@" > $HPACUCLI_RAW
$HPACUCLI ctrl slot=0 ld all show >> $HPACUCLI_RAW
echo "@PHYSICALDRIVEINFO@" >> $HPACUCLI_RAW
$HPACUCLI ctrl slot=0 pd all show status >> $HPACUCLI_RAW
echo "@CONTROLLERINFO@" >> $HPACUCLI_RAW
$HPACUCLI ctrl all show status >> $HPACUCLI_RAW

##Clean up spacing
awk 'NF' $HPACUCLI_RAW | sed -e 's/^[ \t]*//' | grep -v 410i > $HPACUCLI_CLN

##Split Flat file into chunks

#Logical Drives
cat $HPACUCLI_CLN | grep logicaldrive | tr -d '()' | sed 's/\,/:/g'

##LINEBREAKS
echo ""

#Physical Drives
#cat $HPACUCLI_CLN | sed -n -e '/PHYSICALDRIVEINFO/,$p' | grep physicaldrive
cat $HPACUCLI_CLN | grep physicaldrive | cut -c 37- | tr -d ')' | sed 's/\,/:/g'

##LINEBREAKS
echo ""

#Controller
cat $HPACUCLI_CLN | sed -e '1,/CONTROLLERINFO/d'