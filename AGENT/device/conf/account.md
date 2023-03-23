# CMDB/云账号导入

---
## 标准配置如下
### 阿里云
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 区域编码(比如 cn-beijing)
  ```
### Aws
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 区域编码(比如 us-east-1)
  ```
### 谷歌云
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) credentials.json(该文件是从谷歌云导出的json格式的凭证文件) 区域编码(比如 europe-west4)
  ```
### 华为云
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 项目ID 区域编码(比如 cn-east-2) iam_user_id(华为云iam用户id,询价的时候要用)
  ```
### 金山云
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 区域编码(比如 cn-beijing-6) 
  ```
### 腾讯云
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 区域编码(比如 ap-hongkong) cloud_account_id(腾讯云主账号, 在腾讯云控制台的位置：账号中心 -> 账号信息 -> 账号权限 -> 所属主账号)
  ```
---

## 开发手册
### 目录说明

#### 目录
* `/data/Software/mydan/AGENT/device/conf/account/`
* `/data/Software/mydan/AGENT/device/conf/accountx/`

#### 区别
1. `account` 目录下文件有两种格式
    * `aws`、`qcloud`、`aliyun`这种格式。
        这种格式的文件，在同步云资源时，会使用文件的每一行，同步对应云资源的每一种 (openc3所支持的云资源类型)。
    * `aws.ec2`、`qcloud.cvm`、`aliyun.ecs`这种格式。
        这种格式的文件，在同步云资源时，只会同步文件对应的云资源。比如对于 `aws.ec2` 只会同步 `aws` 的 `ec2` 资源。
2. `accountx` 目录下文件为 `awsx`、`qcloudx`、`aliyunx`这种格式。这些文件不会直接用来同步资源，而是根据这些文件生成 `account` 目录中的 `aws.ec2` 、`qcloud.cvm` 这种格式的文件。之所以要这样做，是因为有的云不同资源支持的区域可能不一样，另外 `aws` 的账号不一定开通了全部区域。
3. 可以不需要配置 `accountx` 目录下的文件。只是配置了更加方便，后面在新的区域开通了资源，不需要修改 `account` 目录下的云账号配置文件，系统会自动更新文件比如`aws.ec2`的内容添加新区域对应的配置。


### 配置文件说明

#### 阿里云
* `/data/Software/mydan/AGENT/device/conf/account/aliyun`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 区域编码(比如 cn-beijing)
  ```
* `/data/Software/mydan/AGENT/device/conf/account/aliyunx`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk
  ```
#### Aws
* `/data/Software/mydan/AGENT/device/conf/account/aws`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 区域编码(比如 us-east-1)
  ```
* `/data/Software/mydan/AGENT/device/conf/account/awsx`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk
  ```
#### 谷歌云
* `/data/Software/mydan/AGENT/device/conf/account/google`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) credentials.json(该文件是从谷歌云导出的json格式的凭证文件) 区域编码(比如 europe-west4)
  ```
* `/data/Software/mydan/AGENT/device/conf/account/googlex`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) credentials.json(该文件是从谷歌云导出的json格式的凭证文件)
  ```
#### 华为云
* `/data/Software/mydan/AGENT/device/conf/account/huawei`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 项目ID 区域编码(比如 cn-east-2) iam_user_id(华为云iam用户id,询价的时候要用)
  ```
* `/data/Software/mydan/AGENT/device/conf/account/huaweix`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk iam_user_id(华为云iam用户id,询价的时候要用)
  ```
#### 金山云
* `/data/Software/mydan/AGENT/device/conf/account/ksyun`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 区域编码(比如 cn-beijing-6) 
  ```
* `/data/Software/mydan/AGENT/device/conf/account/ksyunx`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk
  ```
#### 腾讯云
* `/data/Software/mydan/AGENT/device/conf/account/qcloud`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk 区域编码(比如 ap-hongkong) cloud_account_id(腾讯云主账号, 在腾讯云控制台的位置：账号中心 -> 账号信息 -> 账号权限 -> 所属主账号)
  ```
* `/data/Software/mydan/AGENT/device/conf/account/qcloudx`
  文件内容格式为:
  ```
  账号(或者别名, 这个信息将会在资源详情中展示) ak sk cloud_account_id(腾讯云主账号, 在腾讯云控制台的位置：账号中心 -> 账号信息 -> 账号权限 -> 所属主账号)
  ```

