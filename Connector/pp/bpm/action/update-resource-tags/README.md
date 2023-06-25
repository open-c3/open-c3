# 脚本调用说明

调用脚本的命令为:
```
echo '{"filepath": "./data.txt"}' | c3mc-bpm-action-update-resource-tags
```


data.txt的内容格式为:
```
lb-xxxxxxx	[{"TagKey": "OpsOwner", "TagValue": "aaaa@example.com"}, {"TagKey": "ProductOwner", "TagValue": "dddd@example.com"}]
lb-wwwwwww	[{"TagKey": "OpsOwner", "TagValue": "bbbb@example.com"}, {"TagKey": "ProductOwner", "TagValue": "eeee@example.com"}]
lb-eeeeeee	[{"TagKey": "OpsOwner", "TagValue": "cccc@example.com"}, {"TagKey": "ProductOwner", "TagValue": "ffff@example.com"}]
```
第一列和第二列使用制表符"\t"连接。"TagKey"字段后指定标签键名，"TagKey"固定和"TagValue"固定。


至于data.txt的名字随意，只要在命令中指定正确就行。
