#!/bin/bash
#Create table of output for Influxdb

HPACUCLI=`which hpacucli`
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

##Clean up spacing
awk 'NF' $HPACUCLI_RAW | sed -e 's/^[ \t]*//' | grep -v 410i > $HPACUCLI_CLN

##Split Flat file into chunks
#Logical Drives

for i in $HPACUCLI_CLN
do
#  cat $i | grep logicaldrive | tr -d '()' | sed 's/\,/:/g' | awk -F  ": " '{print "logical,host=hp_380_g6,log_num="$1,",raid="$2,",status="$3}' | sed 's/ ,/,/g'
#Test for quotes
cat $i | grep logicaldrive | tr -d '()' | sed 's/\,/:/g' | awk -F  ": " '{print "logical,host=hp_380_g6,log_num=""'\''"$1,"'\''"",raid=""'\''"$2,"'\''"",status=""'\''"$3"'\''"}' | sed 's/ '\'',/'\'',/g'
#  cat $i | grep logicaldrive | tr -d '()' | sed 's/\,/:/g' | awk -F  ": " '{print "logical,host=hp_380_g6,log_num="$1,",status="$3}' | sed 's/ ,/,/g'
done

#Physical Drives
for j in $HPACUCLI_CLN
do
  cat $j | grep physicaldrive | cut -c 37- | tr -d ')' | sed 's/\,/:/g' | awk -F  ": " '{print "physical,host=hp_380_g6,bay=""'\''"$1,"'\''"",size=""'\''"$2,"'\''"",status=""'\''"$3"'\''"}' | sed 's/ '\'',/'\'',/g'
#  cat $j | grep physicaldrive | cut -c 37- | tr -d ')' | sed 's/\,/:/g' | awk -F  ": " '{print "physical,host=hp_380_g6,bay="$1,",status="$3}' | sed 's/ ,/,/g'
done

#Controller
#cat $HPACUCLI_CLN | sed -e '1,/CONTROLLERINFO/d'
for k in $HPACUCLI_CLN
do
  cat $k | sed -e '1,/CONTROLLERINFO/d' | awk -F  ": " '{print "controller,host=hp_380_g6,item=""'\''"$1,"'\''"",status=""'\''"$2"'\''"}' | sed 's/ '\'',/'\'',/g'

done
