#!/bin/bash

mysql="docker exec -i openc3-mysql mysql -uroot -popenc3123456^!"
cat /data/open-c3/Installer/upgrade/v2.0.0/cleandata.sql | $mysql
