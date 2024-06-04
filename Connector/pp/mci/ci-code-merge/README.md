# 发布过程中支持代码自动合并

## 准备操作

```
  # 通过下面命令，安装jq命令
  yum install epel-release
  yum install jq
```

# 准备代码合并具体操作的脚本

```
git有多个版本，每个版本的API会有差别。
不是每个公司都需要在做CICD的时候自动做代码合并，所有这里没有提供兼容所有git版本的脚本。
git目录下放了一个 "git.example.com" 例子。这个是基于GitLab写的脚本，大家可以根据自己公司的情况编写自己的脚本。
放到 git/ 目录下。
```
