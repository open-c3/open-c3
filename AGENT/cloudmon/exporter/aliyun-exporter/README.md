# 监控采集器/云监控/阿里云

例子:
```
credential:
  access_key_id: YOUR_ACCESS_ID
  access_key_secret: YOUR_ACCESS_KEY
  region_id: cn-beijing

metrics:
  acs_ecs_dashboard:
  - name: CPUUtilization
    period: 60
  - name: DiskReadBPS
    period: 60
  - name: DiskReadIOPS
    period: 60
  - name: diskusage_utilization
    period: 15
  - name: DiskWriteBPS
    period: 60
  - name: DiskWriteIOPS
    period: 60
  - name: fs_inodeutilization
    period: 15
  - name: InternetIn
    period: 60
  - name: InternetOut
    period: 60
  - name: IntranetIn
    period: 60
  - name: IntranetOut
    period: 60
  - name: load_15m
    period: 15
  - name: load_1m
    period: 15
  - name: load_5m
    period: 15
  - name: memory_actualusedspace
    period: 15
  - name: memory_totalspace
    period: 15
  - name: memory_usedspace
    period: 15
  - name: memory_usedutilization
    period: 15
  - name: net_tcpconnection
    period: 15
  acs_rds_dashboard:
  - name: ConnectionUsage
    period: 60
  - name: CpuUsage
    period: 60
  - name: DataDelay
    period: 60
  - name: DiskUsage
    period: 60
  - name: IOPSUsage
    period: 60
  - name: MemoryUsage
    period: 60
  - name: MySQL_ActiveSessions
    period: 60
  - name: MySQL_NetworkInNew
    period: 60
  - name: MySQL_NetworkOutNew
    period: 60
  - name: Rt
    period: 30
  - name: TPS
    period: 30
  acs_kvstore:
  - name: ConnectionUsage
    period: 60
  - name: CpuUsage
    period: 60
  - name: FailedCount
    period: 60
  - name: IntranetIn
    period: 60
  - name: IntranetInRatio
    period: 60
  - name: IntranetOut
    period: 60
  - name: IntranetOutRatio
    period: 60
  - name: MemoryUsage
    period: 60
  - name: Rt
    period: 10
  acs_slb_dashboard:
  - name: ActiveConnection
    period: 60
  - name: DropConnection
    period: 60
  - name: DropPacketRX
    period: 60
  - name: DropPacketTX
    period: 60
  - name: DropTrafficRX
    period: 60
  - name: DropTrafficTX
    period: 60
  - name: MaxConnection
    period: 60
  - name: NewConnection
    period: 60
  - name: Qps
    period: 60
  - name: Rt
    period: 60
  - name: StatusCode2xx
    period: 60
  - name: StatusCode3xx
    period: 60
  - name: StatusCode4xx
    period: 60
  - name: StatusCode5xx
    period: 60
  - name: TrafficRXNew
    period: 60
  - name: TrafficTXNew
    period: 60
  - name: UnhealthyServerCount
    period: 60
  - name: UpstreamCode4xx
    period: 60
  - name: UpstreamCode5xx
    period: 60
  - name: UpstreamRt
    period: 60
  - name: HeathyServerCount
    period: 60
  acs_mongodb:
  - name: CPUUtilization
    period: 300
  - name: ConnectionAmount
    period: 300
  - name: ConnectionUtilization
    period: 300
  - name: DataDiskAmount
    period: 300
  - name: DiskUtilization
    period: 300
  - name: GroupCPUUtilization
    period: 300
  - name: GroupConnectionUtilization
    period: 300
  - name: GroupDiskUtilization
    period: 300
  - name: GroupIOPSUtilization
    period: 300
  - name: GroupMemoryUtilization
    period: 300
  - name: GroupShardingCPUUtilization
    period: 300
  - name: GroupShardingConnectionUtilization
    period: 300
  - name: GroupShardingDiskUtilization
    period: 300
  - name: GroupShardingIOPSUtilization
    period: 300
  - name: GroupShardingMemoryUtilization
    period: 300
  - name: IOPSUtilization
    period: 300
  - name: InstanceDiskAmount
    period: 300
  - name: IntranetIn
    period: 300
  - name: IntranetOut
    period: 300
  - name: LogDiskAmount
    period: 300
  - name: MemoryUtilization
    period: 300
  - name: NumberRequests
    period: 300
  - name: OpCommand
    period: 300
  - name: OpDelete
    period: 300
  - name: OpGetmore
    period: 300
  - name: OpInsert
    period: 300
  - name: OpQuery
    period: 300
  - name: OpUpdate
    period: 300
  - name: QPS
    period: 300
  - name: ShardingCPUUtilization
    period: 300
  - name: ShardingConnectionAmount
    period: 300
  - name: ShardingConnectionUtilization
    period: 300
  - name: ShardingDataDiskAmount
    period: 300
  - name: ShardingDataDiskAmountOriginal
    period: 300
  - name: ShardingDiskUtilization
    period: 300
  - name: ShardingIOPSUtilization
    period: 300
  - name: ShardingInstanceDiskAmount
    period: 300
  - name: ShardingIntranetIn
    period: 300
  - name: ShardingIntranetOut
    period: 300
  - name: ShardingLogDiskAmount
    period: 300
  - name: ShardingMemoryUtilization
    period: 300
  - name: ShardingNumberRequests
    period: 300
  - name: ShardingOpCommand
    period: 300
  - name: ShardingOpDelete
    period: 300
  - name: ShardingOpGetmore
    period: 300
  - name: ShardingOpInsert
    period: 300
  - name: ShardingOpQuery
    period: 300
  - name: ShardingOpUpdate
    period: 300
  - name: ShardingQPS
    period: 300
  - name: SingleNodeCPUUtilization
    period: 300
  - name: SingleNodeConnectionAmount
    period: 300
  - name: SingleNodeConnectionUtilization
    period: 300
  - name: SingleNodeDataDiskAmount
    period: 300
  - name: SingleNodeDiskUtilization
    period: 300
  - name: SingleNodeIntranetIn
    period: 300
  - name: SingleNodeIntranetOut
    period: 300
  - name: SingleNodeMemoryUtilization
    period: 300
  - name: SingleNodeNumberRequests
    period: 300
  - name: SingleNodeOpCommand
    period: 300
  - name: SingleNodeOpDelete
    period: 300
  - name: SingleNodeOpGetmore
    period: 300
  - name: SingleNodeOpInsert
    period: 300
  - name: SingleNodeOpQuery
    period: 300
  - name: SingleNodeOpUpdate
    period: 300
  - name: SingleNodeQPS
    period: 300

info_metrics:
- ecs
- rds
- redis
```
