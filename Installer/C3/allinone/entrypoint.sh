#!/bin/bash
set -x

if [ "X$OPEN_C3_EXIP" == "X" ];then
    echo "env OPEN_C3_EXIP undef"
    exit 1;
fi

if [ "X$OPEN_C3_NAME" == "X" ];then
    echo "env OPEN_C3_NAME undef"
    exit 1;
fi

if [ ! -f /data/Software/mydan/etc/agent/auth/c3_${OPEN_C3_NAME}.key ]; then
    cd /data/Software/mydan/etc/agent/auth && \
    ssh-keygen -f c3_${OPEN_C3_NAME} -P "" && \
    mv c3_${OPEN_C3_NAME} c3_${OPEN_C3_NAME}.key && \
    echo success
fi

nginx
crond

### STA

mysqld --user=mysql --datadir=/var/lib/mysql --log-error=/var/log/mysqld.log &
sleep 5;

TEMPMYSQLPW=$(grep 'temporary password' /var/log/mysqld.log|tail -n 1|awk '{print $NF}')

mysql --connect-expired-password -uroot -p$TEMPMYSQLPW <<EOF
  alter user 'root'@'localhost' identified by 'openc3123456^!';
  source /tmp/init.sql;
EOF


cat >> /etc/hosts <<EOF

127.0.0.1	api.agent.open-c3.org
127.0.0.1	api.job.open-c3.org
127.0.0.1	api.jobx.open-c3.org
127.0.0.1	api.ci.open-c3.org
127.0.0.1	api.connector.open-c3.org

127.0.0.1	OPENC3_DB_IP

EOF

### END

/data/Software/mydan/Connector/restart-open-c3-auto-config-change.pl
