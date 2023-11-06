#!/data/Software/mydan/python3/bin/python3

import re
import os
import subprocess;
import datetime
import time

date2 = datetime.date.today()
date2_datetime = datetime.datetime(date2.year, date2.month, date2.day)

( status, output ) = subprocess.getstatusoutput( "cat mount_info.txt" );
if status != 0:
    raise Exception("err")

def todb( time, uuid, tree ):
    os.system(f"c3mc-base-db-ins -t openc3_device_bindtree type compute subtype huawei-ecs uuid '{uuid}' tree '{tree}'")

def record( ctime, uuid, tree ):

    if not re.match(r"^\d+$", ctime):
        return

    if int(ctime ) + 86400 < int(time.time()):
        return

    if not re.match(r"[a-zA-Z0-9][a-zA-Z0-9\-_]*$", uuid):
        return

    if not re.match(r"[a-zA-Z0-9][a-zA-Z0-9\-_,\.]*$", tree):
        return

    basepath = '/data/open-c3-data/bind-tree-from-outside'
    if not os.path.exists(basepath):
        os.system(f"mkdir -p '{basepath}'")

    mark = f"{basepath}/{uuid}"

    if os.path.exists( mark ):
        return

    print(f"time:{ctime} uuid:{uuid} tree:{tree}")
    todb( ctime, uuid, tree )

    os.system( f"touch {mark}" )

for x in output.split("\n"):
    xx = re.split(r" ", x)
    if len(xx) != 3:
        continue

    record( *xx )
