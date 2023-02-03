# 前端开发环境说明

## 说明

> 该项目是新运维平台前端的一个雏形，基于[AngularJS](https://angularjs.org/)。

> 基于AngularJS的 架构 有很多种，我们这里只是使用了其中[某一种](https://github.com/Swiip/generator-gulp-angular)。核心是 AngularJS，主要不同在于所用的工具（package.json）有差别。代码的写作方式基本一致。

## Pre-work

- npm `JS包管理工具`
- Gulp `构建工具`

  > $ npm install -g gulp

- Bower `前端(HTML, CSS, JS) 包管理工具`

  > $ npm install -g bower 

#### 我本地的版本(参考1)

```
$ npm -v
2.15.1

$ node -v
v4.4.3

$ gulp -v
[17:20:03] CLI version 3.9.1
[17:20:03] Local version 3.9.1

$ bower -v
1.7.9
```

#### 我本地的版本(参考2)

```
$ npm -v
6.13.4

$ node -v
v8.17.0

$ gulp -v
[17:20:03] CLI version 2.3.0
[17:20:03] Local version 3.9.1

$ bower -v
1.8.2
```
#### 我本地的版本(参考3)

```
# 2023-02-02

$ npm -v
6.13.4

$ node -v
v10.2.0

$ gulp -v
[17:20:03] CLI version 2.3.0
[17:20:03] Local version 3.9.1

$ bower -v
1.8.2
```

## 克隆项目

`$ git clone https://github.com/open-c3/open-c3.git`
`cd c3-front`

`$ npm install`
`$ bower install`

#### 目录结构

```
├── bower.json  > bower 主配置文件
├── custom  > 非bower管理的包，如ztree，然后在index.html中引用
├── gulp  > gulp 配置文件
│   ├── server.js  > 可修改代理等信息，开发过程中本地server的配置
├── gulpfile.js  > gulp 主配置，一般不需改动
├── package.json  > npm 包信息，一般不需改动
└── src  > 开发代码
    ├── app
    │   ├── components  > 自定义公共组件，如 tree， auth认证， 菜单栏 等
    │   │   ├── tree
    │   │   │   ├── tree.directive.js
    │   │   │   ├── tree.html
    │   │   │   ├── tree.scss
    │   │   │   └── tree.service.js
    │   ├── index.config.js  > 全局配置，如 debug，interceptor等
    │   ├── index.constants.js  > 常量配置
    │   ├── index.module.js > 模块加载配置
    │   ├── index.route.js  > 路由配置
    │   ├── index.run.js  > 启动AngularJS
    │   ├── index.scss
    │   ├──  main > 首页 main page
    │   │   ├── main.controller.js
    │   │   ├── main.html
    │   │   ├── main.scss
    │   │   └── demo
    │   │       └── main.html
    │   └── pages  > 二级子页面
    │       ├── detail
    │       │   ├── detail.controller.js
    │       │   ├── detail.html
    │       └── others > 其他特殊页面
    │           ├── 404.html
    │           └── 500.html
    ├── assets > 一些静态资源信息，如图片等
    │   └── images
    └── index.html > WEB入口
```

## Usage

* $ gulp serve

 > 本地开发测试用

 > 包括 代码修改自动reload，镜像同步等功能

 > 默认为 3000 端口

* $ gulp build

 > 打包到 dist 目录，dist目录为 发布目录

 > 注入js/css到index.html，字体fonts，压缩等
 
* $ bower list

 > 查看当前已经安装的前端包（库）

* $ bower install ng-table --save 

* $ bower uninstall ng-table --save 

 > 安装卸载ng-table
 
* $ npm list

 > 查看当前已经安装的npm包

* $ npm install xxx --save-dev

## 注意点

1. `/** @ngInject */` 不是普通注释 [ng-annotate](https://github.com/olov/ng-annotate), 每个service/filter/controller/directive/provider 都需要

## 规范 & 建议
1. 子页面在app/pages/ 下，以目录为单位，每个目录下建立相应的 html/scss/service/directive/controller 等。可以认为是 一个目录对应一个路由
2. `$ gulp serve` 后，在终端能看到debug信息，可以根据提示信息，检查一些基本的 js语法错误，或语法建议信息，尽量按照语法建议的来修改。
3. 前端的库（包）尽量用bower来安装，并且能 `gulp serve` 后自动加载对应库的js/css等文件。如果不能正确加载（如zTree），非特殊情况，尽量避免使用。

 > zTree 之所以不能自动加载，是因为zTree的bower.json配置问题

## 其他

* URL中的`#`，ui-router - html5mode

* 前端模板样式参考

  > http://demo.pixelcave.com/appui/index.php

* 几个主要（常用）前端插件

  1. [zTree](http://www.treejs.cn/v3/main.php#_zTreeInfo), 树
  2. [sweetalert](http://t4t5.github.io/sweetalert/)，alert插件
  3. [angular-toastr](http://foxandxss.github.io/angular-toastr/)，提示框插件
  4. [ng-table](http://ng-table.com/)， 表格插件
  5. [angular-bootstrap](https://angular-ui.github.io/bootstrap/), bootstrap的AngularJS版
  6. [font-awesome](http://fontawesome.io/)，字体图标

* 一些AngularJS基础技术点说明

  1. 路由，这是基本，要知道怎么定义路由，怎么实现路由跳转。本项目是基于[ui-router](https://angular-ui.github.io/ui-router/site/#/api/ui.router)
  2. 加载模块，模块需要手动来指定加载。`index.module.js`
  3. `$http`, 这个是使用频率最高的服务，用来发起http请求。其他常用服务如：$log, $state

