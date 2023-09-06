#!/data/Software/mydan/python3/bin/python3

from __future__ import print_function
import json
import time
from alibabacloud_tea_openapi.models import Config
from alibabacloud_paistudio20220112.client import Client
import alibabacloud_paistudio20220112.models as models

import sys
from datetime import datetime, timedelta

startdate=sys.argv[1]
daycount=sys.argv[2]

access_key_id=sys.argv[3]
access_key_secret=sys.argv[4]
region_id=sys.argv[5]

clusters = sys.argv[6:]

config = Config(
    access_key_id=access_key_id,
    access_key_secret=access_key_secret,
    region_id =  region_id,
    endpoint="pai.{}.aliyuncs.com".format(region_id)
)

resourceClient =Client(config)

def calculate_dates(input_date, days):
    input_date = datetime.strptime(input_date, "%Y-%m-%d")
    previous_day = input_date - timedelta(days=1)
    future_day = input_date + timedelta(days=days-1)
    return previous_day.strftime("%Y-%m-%d"), future_day.strftime("%Y-%m-%d")

date1, date2 = calculate_dates(startdate, int(daycount))
start_time=date1+"T16:00:00.000Z"
end_time=date2+"T15:59:59.000Z"

instantRequest = models.GetNodeMetricsRequest(verbose=True, start_time=start_time, end_time=end_time)

timelist = []
def getData(resourceClient,instantRequest,metric_type,resource_group_id):
    instantResponse=resourceClient.get_node_metrics(
        resource_group_id=resource_group_id,
        metric_type=metric_type, 
        request=instantRequest, 
    )

    res = {}
    responseHist=instantResponse
    resourceGroupID = responseHist.body.resource_group_id
    nodeMetrics = responseHist.body.nodes_metrics

    cluster = {}
    for i in nodeMetrics:
        nodeID = i.node_id
        metrics = i.metrics
        for metric in metrics:
            seconds = int( int( metric.time ) / 1000 )
            timelist.append(seconds)
            if not res.get(nodeID):
                res[nodeID] = []
            if not cluster.get(metric.time):
                cluster[metric.time] = []
 
            res[nodeID].append(metric.value)
            cluster[metric.time].append(metric.value)

    clusterstatistics = []
    sorted_cluster = sorted(cluster.items(), key=lambda item: item[0])

    for time,values in sorted_cluster:
        avgv = round(sum(values)/ len(values), 1 )
        clusterstatistics.append(avgv)
    return res, clusterstatistics

def getRes(resourceClient,instantRequest,metric_type,resource_group_id):
    nodedata, clusterdata  = getData(resourceClient,instantRequest, metric_type, resource_group_id)

    metric_type_alias = metric_type
    if metric_type == 'GpuUsageRate':
        metric_type_alias = 'U'

    if metric_type == 'GpuMemoryUsageRate':
        metric_type_alias = 'M'

    noderes = {}
    clusterres = {};
    clusterres[ metric_type_alias + ".min"] = round( min(clusterdata), 1 )
    clusterres[ metric_type_alias + ".avg"] = round(sum(clusterdata)/len(clusterdata), 1)
    clusterres[ metric_type_alias + ".max"] = round( max(clusterdata), 1 )

    for nodename, values in nodedata.items():
        if not noderes.get(nodename):
            noderes[nodename] = {}

        noderes[nodename][ metric_type_alias + ".min"] = round( min(values), 1)
        noderes[nodename][ metric_type_alias + ".avg"] = round( sum(values)/ len(values), 1 )
        noderes[nodename][ metric_type_alias + ".max"] = round( max(values), 1)

    return noderes, clusterres


def getClusterRes(resourceClient,instantRequest,resource_group_id):
    clusterdata = {}
    nodedata = {}
    for metricname in [ 'GpuUsageRate', 'GpuMemoryUsageRate' ]:
        nodedatarrr, clusterdatarrr  = getRes(resourceClient,instantRequest, metricname, resource_group_id)
        clusterdata.update( clusterdatarrr )
        for node in nodedatarrr.keys():
            if nodedata.get(node):
                nodedata[node].update( nodedatarrr[node] )
            else:
                nodedata[node] = nodedatarrr[node]

    return nodedata, clusterdata


def printTable(data):
    column_widths = [max(len(str(item)) for item in column) + 2 for column in zip(*data)]

    header = ["{:<{w}}".format(column, w=width) for column, width in zip(data[0], column_widths)]
    print(" | ".join(header))

    separator = "+".join("-" * width for width in column_widths)
    print(separator)

    for row in data[1:]:
        formatted_row = ["{:<{w}}".format(str(item), w=width) for item, width in zip(row, column_widths)]
        print(" | ".join(formatted_row))

def printCluster(resourceClient,instantRequest,resource_group_id, clustername):
    nodedatarrr, clusterdatarrr  = getClusterRes(resourceClient,instantRequest, resource_group_id)

    data = []

    title = list( clusterdatarrr.keys() )
    data.append( [ clustername ] + title )

    cluster = [ "Cluster" ]
    for i in title:
        cluster.append( clusterdatarrr[i] )
    data.append(cluster)


    node = nodedatarrr.keys()
    for nodename in node:
        nodelist = [ nodename ]
        for i in title:
            nodelist.append( nodedatarrr[nodename][i] )
        data.append(nodelist)

    printTable(data)

for l in clusters:
    x = l.split(":")
    printCluster(resourceClient,instantRequest, x[0], x[1])
    print("\n")

print( "Time: {} ~ {}".format( datetime.fromtimestamp(min( timelist )), datetime.fromtimestamp(max(timelist ))))
