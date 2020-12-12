#!/bin/bash
set -e

mkdir -p /data/glusterfs

test "X$ENVNAME" == "X" && exit 0

test -d /data/Software/mydan/Installer/cluster/init/glusterfs/conf/$ENVNAME || exit 0

PROC=$(ps -ef|grep glusterfs[d].vol|wc -l)
test "X0" == "X$PROC" || exit 0 

cd /data/Software/mydan/Installer/cluster/init/glusterfs/rpm
ls | xargs  -i{} rpm -ivh {}  --force --nodeps

mkdir -p /data/Software/mydan/glusterfs
rsync -av /data/Software/mydan/Installer/cluster/init/glusterfs/conf/$ENVNAME/ /data/Software/mydan/glusterfs/conf/

mkdir -p /data/Software/mydan/glusterfs/data
mkdir -p /data/Software/mydan/glusterfs/logs

cp /data/Software/mydan/Installer/cluster/init/glusterfs/etc/sysconfig/* /etc/sysconfig/
cp /data/Software/mydan/Installer/cluster/init/glusterfs/etc/init.d/* /etc/init.d/

/etc/init.d/glusterfsd  restart
/etc/init.d/glusterfs restart

chkconfig glusterfsd on
chkconfig glusterfs on

mount.glusterfs  /data/Software/mydan/glusterfs/conf/glusterfs.vol  /data/glusterfs
