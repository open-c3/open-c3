# BPM/插件配置说明

## 概述

关键字: name 、option 、template_argv

每个插件都会包含如下配置，name为插件的名称， option数组最终会显示在bpm前端的表单上。

template_argv中的数据，经过变量替换后，在bpm执行阶段，会转换成一个json数据从标准输入传递给插件代码进行执行。

```
name: 插件名称
option:
  - name: domain
    describe: 域名
    type: input

template_argv:
  domain: ${domain}
```

## 配置详情

### 普通输入框

关键字: input

说明:
```
普通输入框是一种最简单的格式，type类型为input。
```

例子:
```
name: 插件名称
option:
  - name: domain
    describe: 域名
    type: input

template_argv:
  domain: ${domain}
```

### 下拉框/列表固定

关键字: select 、option

说明:
```
下拉列表是一个固定的内容, type 为select， option为一个数组，数组的内容就是下拉列表的内容.
```

例子:
```
name: 插件名称
option:
  - name: domain
    describe: 域名
    type: select
    option: ["HTTP", "HTTPS", "TRPC"]

template_argv:
  domain: ${domain}
```

### 下拉框/列表通过命令获取/单选

说明:
```
下拉列表通过命令可以获取到的内容, type 为selectx.
command为在c3容器中可以执行的命令。
命令从标准输入获取到rely中依赖的字段，会已json的格式从标准输入传递给command。
命令输出内容为下拉框的内容，有两种格式，一列或者两列，中间用“;”号分隔。
两列的情况下，第二列为下拉框内容的别名。
```

关键字: selectx 、 command 、rely

例子:
```
name: 插件名称
option:
  - name: data1
    describe: 数据1
    type: input
  - name: domain
    describe: 域名
    rely:
      - data1
    type: selectx
    command: c3mc-qcloud-clb-describe-cvm-list | c3mc-bpm-display-field-values InstanceId,InstanceName,PrivateIp,PublicIp,VirtualPrivateCloud[VpcId]

template_argv:
  domain: ${domain}
```

### 下拉框内建命令

关键词: command为数组格式

说明:
```
上述描述中，通过command字段，通过执行命令获取到下拉框的内容。

但是有的下拉框内容的数据是需要解析当前表单的数据来实现的，所以这里设置了几个内置的命令。
当command为数组形式时，为内建命令的方式。

当前存在的内置命令：

list: 获取表单中某个名字的列表，该名字在表单中多次出现，或者它是运行多个执行.
      如果已经选择的字段的内容变化了，前端上会自动清空当前数据项。
point: 把自己当前的下拉框的内容，去获取本插件同名的“参数1”，然后在那个插件上找到“参数2”的值作为自己下拉框的内容。
      如果已经选定的数据项的值发生变化，前端也会自动清空当前数据项。
```

例子:
```
name: 插件名称
option:
  - name: listener_name
    describe: 监听器名字
    type: selectx
    command: [ 'list', 'listener_name' ]

  - name: protocol
    describe: 协议
    rely:
      - listener_name
      - x.protocol
    command: ["point", "listener_name", "protocol" ]
    type: selectx
    value: ""

template_argv:
  domain: ${domain}
```

### 下拉框/列表通过命令获取/多选

关键字: selectxm
说明:
```
和单选的情况一样，只是把单选中的selectx修改成selectxm。

```
注: 多选的情况下，后端插件获取到的选项的值是逗号分隔。

### 默认选项

关键字: value

说明:
```
输入框或者下拉框等，如果在页面展示的时候想要一个默认的值，可以配置上value字段。
```

例子:
```
name: 插件名称
option:
  - name: domain
    describe: 域名
    type: input
    value: "按权重轮询"

template_argv:
  domain: ${domain}
```

### 控制隐藏或者展示/简单

关键字: show

说明:
```
默认情况下所有的选项都是展示在bpm的表单中的。

如果需要做选项依赖的时候，可以通过show字段开进行控制。

比如A和B两个选项，当A是某些值的时候，B才展示出来。

```

例子:
```
name: 插件名称
option:
  - name: dataA
    describe: 描述A
    type: select
    option: ["abc", "foo", "bar", "123" ]

  - name: dataB
    describe: 描述B
    type: input
    value: "按权重轮询"
    show: ["dataA", "foo", "bar"]

template_argv:
  domain: ${domain}
```

### 控制隐藏或者展示/复杂

关键字: show

说明:
```
和简单形式一样，都是用show进行控制，复杂情况下，show为数组形式，每个数组是一个HASH的内容。

数组内是“与”的关系，数组之间是“或”的关系。
如下例子中，show数组有两个元素，满足其中一个它就会显示出来。

（（ dataA 为 foo 或者 bar ）&& （dataB 为 789 ））|| ( dataD 为 456 )

```

例子:
```
name: 插件名称
option:
  - name: dataA
    describe: 描述A
    type: select
    option: ["abc", "foo", "bar", "123" ]

  - name: dataB
    describe: 描述B
    type: input
    value: "按权重轮询"
    show:
    - dataA: [ "foo", "bar"]
      dataC: [ "789" ]
    - dataD: [ "456" ]

template_argv:
  domain: ${domain}
```

### 运维代填

关键字: fromops

说明:
```
bpm流程中有的信息是比较复杂的，提交人可能不知道怎么填写，

插件可以通过定义fromops来控制是不是允许运维代填。

流程中所有的插件，只要有一个插件有fromops为1的情况，前端会展示“运维代填”的按钮，点击该按钮后，fromops为1的插件的所有选项框会隐藏。

```

例子:
```
name: 插件名称
fromops: 1
option:
  - name: dataA
    describe: 描述A
    type: select
    option: ["abc", "foo", "bar", "123" ]

template_argv:
  domain: ${domain}
```

### 插件步骤多选

关键字: multi

说明:
```
有的插件可能需要进行多选，比如创建负载均衡器的时候，监听器的插件是可以多选的。

在监听器的插件上配置 multi 为1. 当multi为1时，前端在插件的步骤下面会显示添加和删除按钮，
```

例子:
```
name: 插件名称
multi: 1
option:
  - name: dataA
    describe: 描述A
    type: select
    option: ["abc", "foo", "bar", "123" ]

template_argv:
  domain: ${domain}
```

### 插件步骤多选/一次性全部调用

关键字: _sys_multi_

说明:
```
当插件是可以多选的情况下，默认情况下，在bpm流程启动后，插件是多次进行接收和调用数据的，
如上一步描述的内容，如果监听器是多个的情况下，会多次进行监听器插件的调用。

但是在某些情况下，你的插件如果想一次接收所有的数据，那就在template_argv数据中添加上_sys_multi_为1

```

例子:
```
name: 插件名称
multi: 1
option:
  - name: dataA
    describe: 描述A
    type: select
    option: ["abc", "foo", "bar", "123" ]

template_argv:
  domain: ${domain}
  _sys_multi_: 1 
```

### 获取其它插件内容

说明:

```
template_argv中的内容，在插件执行时，系统会把格式为“${变量名}”的用本插件option中的内容进行替换。替换完后在调用插件，
这样插件就可以获取到表单中真实选择的内容。

但是某些情况下，可能需要获取其它插件的内容，比如申请服务器权限的流程是先审批后通过插件添加权限。
如果在审批的时候，希望审批内容中显示申请的机器的ip列表，那么通过“{x.变量名}”的方式获取到其它插件的参数。
如果名字重复,系统会随机找出一个。

特别说明： 插件中每个变量都有一个唯一的名字，也可以通过唯一名字来指定变量的名 通过“x.”是为了让系统自己找到变量。
           比如插件1中有变量abc，在系统内部，其实该变量的准确名字是 "1.abc"

```

例子:
```
name: 插件名称
multi: 1
option:
  - name: dataA
    describe: 描述A
    type: select
    option: ["abc", "foo", "bar", "123" ]

template_argv:
  domain: ${domain}
  foo: ${x.abc}
```

### 获取前面已运行插件的结果

关键值: LOG.xxx VAR.key:value

说明:
```
有的情况下，后一步的插件需要获取到前一步插件的执行结果。
比如某个流程中需要同时创建负载均衡器和服务器。创建完成后，负载均衡器下面自动配置上了该服务器。

这时候是需要先创建服务器，服务器创建出来后会得到ip。负载均衡器的插件需要得到上一步服务器创建的时候的ip。
就可以在创建负载均衡器的插件中的template_argv字段，通过var.xxx的格式获取到上一步的ip。

特别说明:
    插件在执行的过程中，可能会输出很多内容，插件可以通过两种特殊的格式，把数据反馈给流程。
    格式1: LOG.要显示的内容 ，插件如果以“LOG.”开头输出内容，bpm流程执行时会把这个内容显示在前端
    格式2: VAR.变量名:变量的值 ， 插件如果以该格式输出内容，该信息会反馈到bpm流程中，其它后续插件可以通过${var.key的名称}获取到对应的内容.
           当输出的变量名重复时候，通过${var.xxx}获取时，得到的是一个用逗号分隔的字符串。
```

例子:
```
name: 插件名称
multi: 1
option:
  - name: dataA
    describe: 描述A
    type: select
    option: ["abc", "foo", "bar", "123" ]

template_argv:
  domain: ${domain}
  ip: ${var.ip}
```

### 依赖说明

关键值: rely

说明:
```
在文档的上半部分我们描述过rely，用来控制下拉框插件的。
除了这个功能之外，在前端上，如果做了依赖的配置，依赖的选项变动后自己的选项空会被清空。
同时如果依赖的选项如果还没有值，点击当前选项的时候，会进行红色提醒，也不会发起请求到后端，因为依赖还没有赋值完成。

注: 当前清空操作不识别 x.xxx 的格式
```

例子:
```
name: 插件名称
multi: 1
option:
  - name: dataA
    describe: 描述A
    type: select
    option: ["abc", "foo", "bar", "123" ]

template_argv:
  domain: ${domain}
```
