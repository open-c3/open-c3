# C3的pkg打包说明

## 自动处理
```
# 系统升级后，可以进行自动打包处理，添加定时任务，定时的进行构建
# 系统会识别哪个模块需要构建
*/3 * * * * flock -n /var/c3autopkg.lock /data/open-c3/Installer/C3/pkg/autopkg.sh > /tmp/autopkg.log 2> /tmp/autopkg.err
```

## 手动处理

### 全量构建

```
#对所有模块打包, 模块的范围在文件 "module"中有描述。
./build.sh 版本号
#例: 对所有模块打包，版本为2301101
./build.sh 2301101
```

### 单个构建

```
#对单个模块进行构建.
./build-module.sh 模块名 版本号
#例: 对perl模块进行构建，构建版本为2301101
./build-module.sh perl 2301101
```

### 上传

```
./upload.sh
#上传脚本会把“module”中已经构建的模块都进行上传，上传后自动做了git commit。
#查看没问题后手动 git push 即可。
#注：上传脚本只会处理有重新构建过的模块，未被重新构建的模块不进行处理。

```

## 提取

```
#提取所有pkg中的文件，该命令在OpenC3安装和更新的时候都会自动调用。
./extract.sh
```

