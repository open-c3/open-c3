# 说明

是tencentcloud-exporter的cache版，tencentcloud-exporter采集数据不稳定，有丢数据的情况。

通过c3的接口进行缓存，如果拿到的数据小于之前正常数据的75%则使用旧的数据返回。

旧的数据最多使用3分钟，如果3分钟后还是不正常的，则返回不正常的数据。
