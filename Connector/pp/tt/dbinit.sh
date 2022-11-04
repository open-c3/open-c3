#!/bin/bash

if [ "X$1" != "Xforce" ];then
    echo \$0 force 
    exit 1;
fi

cd /data/Software/mydan/Connector/pp/tt || exit

mysql -hOPENC3_DB_IP  -uroot -popenc3123456^! --default-character-set=utf8 -f connector < delete.sql 
mysql -hOPENC3_DB_IP  -uroot -popenc3123456^! --default-character-set=utf8 -f connector < init.sql 
