#!/bin/bash

version=$1

if [ "X$version" == "X" ];then
    echo nofind version
    exit
fi

cp data/mysql/openc3.${version}.sql /data/open-c3-data/backup/mysql/

/data/open-c3/Installer/scripts/databasectrl.sh recovery $version

docker exec -it openc3-server  bash -c "c3mc-base-db-exe -t openc3_job_task   'update openc3_job_task   set slave=\"openc3-srv-docker\"'"
docker exec -it openc3-server  bash -c "c3mc-base-db-exe -t openc3_jobx_task  'update openc3_jobx_task  set slave=\"openc3-srv-docker\" where slave!=\"_null_\"'"
docker exec -it openc3-server  bash -c "c3mc-base-db-exe -t openc3_ci_version 'update openc3_ci_version set slave=\"openc3-srv-docker\" where slave!=\"\"'"
docker exec -it openc3-server  bash -c "c3mc-base-db-exe -t openc3_ci_project 'update openc3_ci_project set slave=\"openc3-srv-docker\" where slave is not NULL'"
