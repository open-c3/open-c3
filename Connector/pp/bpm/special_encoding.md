# BPM/特殊编码说明

调用某些云接口创建资源时，可能标签值不允许某些特殊字符，比如 "@" 符号，导致无法在标签值中配置邮箱地址。针对这种不支持特殊符号的情况，我们使用如下编码格式对标签值中出现的特殊符号进行转码。

转码的格式如下:
```
E\d+E
```
表示以 "E" 开头，以 "E" 结尾，中间的数字是要转码的特殊字符的ascii编码的十进制表示。

比如 "@" 符号的ascii十进制为64，则编码格式为 "E64E"。
