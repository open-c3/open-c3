# 常见问题

## 发布

### 同步文件出现md5错误

```

如同步过程中，出现如下错误。可以检查一下ulimit,看是否是ulimit限制了文件的大小。通过ulimit命令把文件大小的限制调大即可。

sp:/data/glusterfs/ci_repo/30044694/release-online-202306201821 => dp:/data/scripts/packages/web-gateway/release-online-202306201821
localhost => 10.10.10.100: DUMP
10.10.10.100 <= localhost: Fail: md5 nomatch--- 256

localhost => 10.10.10.100: DUMP
10.10.10.100 <= localhost: Fail: md5 nomatch--- 256

localhost => 10.10.10.100: DUMP
10.10.10.100 <= localhost: Fail: md5 nomatch--- 256

failed:
10.10.10.100
```
