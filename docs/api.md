# API/1.接口规范

## 数据返回

```
如没有特殊情况,返回的数据都是如下结构:

{
    stat: 1
    data: [ "foo", "bar" ]
    info: "ok"
}

字段说明:

stat: 必须存在，只有两个状态，0或者1. 为1时表示接口返回正常。
data: 如有返回数据，通过data字段携带, 格式可以是数组，hash，字符串或数字。
info: 当stat为0时说明服务后端错误，通过info返回错误的原因。
```

V2版本接口:
```
#下面的请求支持v2版本，如"/api/ci/c3mc/foo", 可以调用 "/api/ci/v2/c3mc/foo", 数据返回的内容一致。
#V2版本支持更高的并发和更好的超时处理。

ci:
    [ qw( GET POST DELETE ) ] => '/kubernetes/*'
    [ qw( GET POST DELETE ) ] => '/c3mc/*'
agent:
    GET => '/cloudmonmetrics/*'
```
