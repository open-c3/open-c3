#!/bin/bash

set -e

TEMP=/tmp/c3-cmdb-demo-$$
mkdir $TEMP
cd    $TEMP

cp -r /data/open-c3-data/device/curr .
rm -rf curr/auth curr/cache curr/conf curr/price curr/jumpserver

for file in $( ls curr/*/*/data.tsv )
do
    echo $file
    randline=$(echo $((3+$RANDOM%10)))
    sed -i "$randline,\$ d" $file
    sed -i -E 's/@[a-z]+\.[a-z]+/@openc3.org/g' $file
    while IFS= read -r line; do
        new_ip=$(echo $(($RANDOM%255)).$(($RANDOM%255)).$(($RANDOM%255)).$(($RANDOM%255)))
        echo "$line" | sed "s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/$new_ip/g"
    done < $file > $file.temp
    mv $file.temp $file

    while IFS= read -r line; do
        new_ip=$(echo $(($RANDOM%255))-$(($RANDOM%255))-$(($RANDOM%255))-$(($RANDOM%255)))
        echo "$line" | sed "s/\([0-9]\{1,3\}\-\)\{3\}[0-9]\{1,3\}/$new_ip/g"
    done < $file > $file.temp
    mv $file.temp $file
done

tar -zcf cmdb-demo.tar.gz curr

UUID=xxx
if [ "X$1" != "X" ]; then
    UUID=$1
fi

mv cmdb-demo.tar.gz /data/open-c3/c3-front/dist/cmdb-demo.$UUID.tar.gz

rm -rf $TEMP
