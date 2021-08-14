# OPEN-C3

<div align="center">
  <img width="100" style="max-width:100%" src="./c3-front/src/assets/images/open-c3-logo.jpeg" title="open-c3">
  <br><br>
  <p><b>OPEN-C3</b>为解决CI/CD/CO而生。</p>	
</div>

# Documentations

[book](https://open-c3.github.io)

# Getting Started

```
docker run -p 8080:88 openc3/allinone:latest
```

# Q&A

- Any issue or question is welcome, Please feel free to open [github issues](https://github.com/open-c3/open-c3/issues) :)
- [FAQ](https://open-c3.github.io/FAQ/)


# 介绍

在整个的运维环节中，对产品的持续构建（CI）持续部署（CD）伴随着产品的整个生命周期。
一个运行良好的运维系统可以辅助提升运营效率，达到持续运营（CO）的效果。OPEN-C3为解决CI/CD/CO而生。

可以把OPEN-C3当作CI/CD平台来使用。安装部署后便可以独立使用。根据文档中的描述可以方便的完成[体验版](https://open-c3.github.io/体验版安装/)、[单机版](https://open-c3.github.io/单机版安装/)和[集群版](https://open-c3.github.io/集群版安装/)的安装。同时可以根据实际情况，给OPEN-C3提供指定接口后，可以在不修改任何OPEN-C3代码的情况下对接公司的登录系统、服务树、权限系统、OA审批。

可以简单看一下OPEN-C3的[设计理念](https://open-c3.github.io/设计理念/)。安装一个[体验版](https://open-c3.github.io/体验版安装/)试试吧。点击查看[视频教程](https://open-c3.github.io/视频教程/)。

# 社区

点击查看[社区](https://open-c3.github.io/社区/)情况，可以扫描二维码添加open-c3微信。

![微信二维码](https://open-c3.github.io/社区/images/open-c3-微信二维码.jpeg)
<!-- 点击查看[社区](/社区/README.md)情况，点击进入[聊天室](https://webchat.freenode.net/?channels=#open-c3)。
点击查看[聊天历史](http://open-c3.cmcloud.org/irclog/index.php)。 -->

# 特点

* 高效的文件传输协议，在面对服务器数量庞大的情况下效果明显。
* 强大的网络代理方式，可以方便的管理分布在全球各地区的服务器。
* 高可用，系统没有核心单点，易运维，易部署，可以水平扩展。
* 独立性，系统可以独立使用，也可以根据公司环境对接登录系统、服务树OA审批。
* 插件性，可以方便的添加插件已满足对流程编排的不同的需求。
* 支持作业叠加，支持流水线中调用流水线，作业中调用作业，从满足更复杂的编排要求。

# 架构

![架构图](https://open-c3.github.io/介绍/images/架构图.png)

## 连接器
```
OPEN-C3系统内置登录管理、用户管理、权限管理、服务树、审批功能。
但考虑到企业环境中该部分功能需要和公司的基础架构进行联动。
OPEN-C3内部把这部分功能全部集中到了系统中的连接器模块。可以通过修改配置把这部分接口指向外部系统。
```
## 输入

以下几种动作可以操控OPEN-C3系统。他们影响着OPEN-C3的运行逻辑。

* 人为操作
   * 用户在控制台上进行操作，可以配置流水线、作业、定时任务、可以批量操作服务器、批量传输文件等。
   * 用户的审批操作，审批操作可以通过移动端完成，审批的结果（通过或者拒绝）会影响OPEN-C3的流程。


* 代码仓库触发

    代码的变化可以触发构建操作，同时构建操作可以和发布进行联动。

   * SVN: 通过打tag的方式进行触发。
   * GIT：支持tag方式和webhook方式触发（webhook方式可以做到每次git push操作都触发一次构建）
   * FILE: 支持通过上传文件触发构建。


* 故障自愈系统触发

   * 如果有故障自愈系统，可以把自愈操作对接到OPEN-C3中。


* 文件上传

    * 上传文件除了在控制台页面中直接上传，同时也可以通过命令来进行上传，可以配置成文件上传后触发某个流程，达到上传后立即发布的效果。


* 定时任务

    * 可以在控制台中把一个作业流程配置成定时执行。

## 输出

* 生成程序包

   * 构建成功后会保存构建好的压缩包，压缩包会保存在OPEN-C3的文件系统中等待发布时使用。


* 上传镜像到镜像仓库

    * 如果是容器发布，可以配置成构建容器镜像，上传到镜像仓库中。


* 控制服务器

    * 批量操作服务器，同时内置了部分指令用于发布程序。
    * 批量同步文件，文件同步可以跨区域，文件传输过程支持多对多传输。


* 通过内建插件控制其他服务

    * 可以方便的添加插件，内置了terraform（可以用于资源编排）和kubectl（可以用于发布kubernetes应用）等插件。


# 控制台界面

前端有两种样式可以进行选择，可以在连接器中进行切换。

## 默认样式

![仪表盘](https://open-c3.github.io/介绍/images/仪表盘.png)

## 聚云样式

![聚云样式](https://open-c3.github.io/介绍/images/juyun样式.png)

