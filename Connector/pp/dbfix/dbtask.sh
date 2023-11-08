#!/bin/bash

echo  'delete  from openc3_monitor_serialcall_data where caseuuid in ( select caseuuid from openc3_monitor_serialcall_deal);' | mysql -hOPENC3_DB_IP -uroot -popenc3123456^! agent

expire=$(date +%s -d '1 day ago')

echo "delete from openc3_monitor_serialcall_data where time<=$expire;"|mysql -hOPENC3_DB_IP -uroot -popenc3123456^! agent
