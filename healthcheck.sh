#!/bin/bash

OUT_FILE=~/resource.log
TMP_FILE1=~/tmp/dockerps.out
TMP_FILE2=~/tmp/dockerps.out.tmp
TMP_FILE3=~/tmp/dockerstream.out
TMP_FILE4=~/tmp/dockerstream.out.tmp

while true
do
	DATESTAMP=`date +"%Y%m%d%H%M%S"`
	sudo docker ps > ${TMP_FILE1}
        sed -i '1d' ${TMP_FILE1}
        sed -e 's/ \s\+/,/g' ${TMP_FILE1} > ${TMP_FILE2}	
        CONTAINER_ID=`cat ${TMP_FILE2} | cut -d ',' -f 1`
        IMAGE=`cat ${TMP_FILE2} | cut -d ',' -f 2`
        STATUS=`cat ${TMP_FILE2} | cut -d ',' -f 5`
        NAME=`cat ${TMP_FILE2} | cut -d ',' -f 8`
        sudo docker stats --no-stream > ${TMP_FILE3}
        sed -i '1d' ${TMP_FILE3}
        sed -e 's/ \s\+/,/g' ${TMP_FILE3} > ${TMP_FILE4}
        CPUPER=`cat ${TMP_FILE4} | cut -d ',' -f 3`
        MEMPER=`cat ${TMP_FILE4} | cut -d ',' -f 5`
        NETIO=`cat ${TMP_FILE4} | cut -d ',' -f 6`
        MEMLIMIT=`cat ${TMP_FILE4} | cut -d ',' -f 4`	
	echo "$DATESTAMP,$CONTAINER_ID,$NAME,$IMAGE,$STATUS,$CPUPER,$MEMPER,$MEMLIMIT,$NETIO" >> ${OUT_FILE}
	sleep 10
done
