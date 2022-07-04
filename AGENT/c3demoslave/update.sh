#!/bin/bash

function updatedb()
{
    ID=$1
    LEN=$2
    c3mc-base-db-exe -t openc3_job_nodelist "delete from openc3_job_nodelist where projectid=$ID and inip like \"172%\""

    docker ps \
    | grep c3demoslave_openc3-demo-slave \
    | awk '{print $NF}' \
    | sort | head -n $LEN \
    | xargs  -i{} docker inspect  {} \
    | grep IPAddress \
    | grep 172 \
    | awk -F'"' '{print $4}' \
    | xargs -i{} c3mc-base-db-ins -t openc3_job_nodelist projectid $ID name {} inip {} exip {} create_user open-c3 edit_user open-c3  edit_time '2022-07-01 17:00:00' create_time '2022-07-01 17:00:00' 

}
updatedb 7  10
updatedb 8  8
updatedb 9  5
updatedb 10 2

function updateslave()
{
    docker ps \
    | grep c3demoslave_openc3-demo-slave \
    | awk '{print $NF}' \
    | xargs  -i{} docker exec {} bash -c 'curl -L $OPEN_C3_ADDR/api/scripts/installAgent.sh | bash ; curl -L $OPEN_C3_ADDR/api/scripts/installAgentMon.sh | bash'
}
updateslave

function updatenginx()
{
    cp /data/Software/mydan/AGENT/c3demoslave/api.demoslave.open-c3.org.conf /etc/nginx/conf.d/
    nginx -s reload
}
updatenginx

function http()
{
    docker ps \
    | grep c3demoslave_openc3-demo-slave \
    | awk '{print $NF}' \
    | xargs -i{} docker cp /data/Software/mydan/AGENT/c3demoslave/python.http {}:/opt/mydan/dan/bootstrap/exec/python.http
}
http
