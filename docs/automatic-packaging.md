# 1代码提交/自动构建

## 代码自动打包

### 原因说明
```
C3系统使用了多个语言进行编写，包括perl、python、golang等

在不同的部署环境下，可能会因为网络问题导致依赖的模块下载失败。

所以在C3系统中，会把perl、python等依赖的包提前打包，对于golang的程序会提前编译。
在真正发布的时候会在C3镜像中获取已提前编译好的程序和依赖包。

```
### 处理方式

```
在提交代码时，在commit中描述需要进行自动打包的部分，格式：c3autopkg(模块名)。

如: 您在python3中使用了一个新的模块,在代码中您已经描述了依赖的模块和版本，
在您提交代码的时候，在commit内容中包含字符串 "c3autopkg(python3)"

当你的代码被合并进来后，C3的自动构建程序会发现该提交是需要重新构建python3的。
C3会选择一个时间进行自动构建，保证构建出来的最新python3的时间是您这个commit的时间之后。

```
### 模块范围

```
当前涉及到的模块如下:
perl
python3
mysql
install-cache
dev-cache
book
trouble-ticketing
jumpserver
```
