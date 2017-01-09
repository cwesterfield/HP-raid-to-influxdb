#!/bin/bash
#Create table of output for Influxdb

HPACUCLI=`which hpacucli`
CURL==`which curl`
HPACUCLI_RAW=/tmp/hpacucli.raw
HPACUCLI_CLN=/tmp/hpacucli.log
HPACUCLI_IMP=/tmp/influx.import
TIME=`date`

##Create flat file
echo "@LOGICALDRIVEINFO@" > $HPACUCLI_RAW
$HPACUCLI ctrl slot=0 ld all show >> $HPACUCLI_RAW
echo "@PHYSICALDRIVEINFO@" >> $HPACUCLI_RAW
$HPACUCLI ctrl slot=0 pd all show status >> $HPACUCLI_RAW
echo "@CONTROLLERINFO@" >> $HPACUCLI_RAW
$HPACUCLI ctrl all show status >> $HPACUCLI_RAW

##Insert Date for testing
#echo $TIME

##Clean up spacing
awk 'NF' $HPACUCLI_RAW | sed -e 's/^[ \t]*//' | grep -v 410i > $HPACUCLI_CLN

##Empty old import file
rm $HPACUCLI_IMP

##Split Flat file into chunks
#Logical Drives

for i in $HPACUCLI_CLN
 do
  cat $i | grep logicaldrive | tr -d '()' | sed 's/\,/:/g' | awk -F  ": " '{print "logical,Host=hp_380_g6,log_num="$1," Raid=\""$2"\",Status=\""$3"\""}' | sed 's/ "/"/g; s/ /\\ /1; s/ /\\ /2; s/ /\\ /3; s/ /\\ /4' >> $HPACUCLI_IMP
 done

#Physical Drives
for j in $HPACUCLI_CLN
 do
  cat $j | grep physicaldrive | cut -c 37- | tr -d ')' | sed 's/\,/:/g' | awk -F  ": " '{print "physical,Host=hp_380_g6,Bay="$1," Size=\""$2,"\",Status=\""$3,"\""}'| sed 's/ "/"/g; s/ /\\ /1' >> $HPACUCLI_IMP
 done

#Controller
for k in $HPACUCLI_CLN
 do
  cat $k | sed -e '1,/CONTROLLERINFO/d' | awk -F  ": " '{print "controller,Host=hp_380_g6,Item="$1," Status=\""$2,"\""}' | sed 's/ "/"/g; s/ /\\ /1; s/ /\\ /2' >> $HPACUCLI_IMP
 done

#IMPORT!

curl -i -XPOST 'http://10.0.1.100:8086/write?db=hp' --data-binary @$HPACUCLI_IMP