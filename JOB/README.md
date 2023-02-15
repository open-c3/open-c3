# JOB模块API





                         API 说明


=================================== crontab [定时任务]  =====================================


:projectid 为项目编号

:crontabid 为crontab 编号



1. 获取某个项目下所有的定时任务信息:

    get '/crontab/:projectid'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #name  定时任务名称包涵的字符
        #create_user  创建者
        #edit_user    最后编辑者
        #create_time_start  创建时间开始日期 (日期格式如:2018-01-01)
        #create_time_end    创建时间结束日期
        #edit_time_start    最后编辑开始日期
        #edit_time_end      最后编辑结束日期


2. 获取定时任务数量：

    get '/crontab/:projectid/count' 

3. 获取某个项目下某个定时任务的详细信息:
    
    get /crontab/:projectid/:crontabid


4. 新建一个定时任务:

    post '/crontab/:projectid'
    
    其它参数：

        #name   定时任务名称

        #jobuuid  作业uuid

        #cron    定时规则

        #mutex  ? 是否需要互斥,如果需要写上互斥名，如果不需要可以为空, 互斥名的作用域是项目

5. 修改一个定时任务:

    post /crontab/:projectid/:crontabid

    其它参数：

        同上
    
6. 修改状态

    post '/crontab/:projectid/:crontabid/status'

    其它参数：

        #status = available,unavailable

7. 删除一个定时任务:

    del /crontab/:projectid/:crontabid


=================================== jobs [作业] =====================================

:projectid
:jobuuid

1. 获取某个项目下的作业列表:

    get '/jobs/:projectid'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #name  作业名称包涵的字符
        #create_user  创建者
        #edit_user    最后编辑者
        #create_time_start  创建时间开始日期 (日期格式如:2018-01-01)
        #create_time_end    创建时间结束日期
        #edit_time_start    最后编辑开始日期
        #edit_time_end      最后编辑结束日期

2. 获取作业数量

    get '/jobs/:projectid/count' 

3. 获取某个项目下某个作业的详细信息:

    get '/jobs/:projectid/:jobuuid'

4. 新建一个作业:

    post '/jobs/:projectid'

    其它参数：

        #name 作业名称

        #permanent# permanent ? 'permanent' : 'transient' ,有这个参数说明是永久的
        #data 作业内容, 作业内容是一个数组,每个数组中是一个hash，每个hash中必须包涵key名为plugin_type的字段

            当 plugin_type 等于cmd 时,hash中还需要的key如下：

            ##name 步骤名称
            ##user 指定脚本的账户
            ##node_type  节点类型
            ##node_cont  节点内容
            ##scripts_type  脚本类型
            ##scripts_cont  脚本内容
            ##scripts_argv  脚本参数
            ##timeout       超时时间，为空时默认为60秒
            ##pause         执行结束后是否需要暂停


            当 plugin_type 等于scp 时,hash中还需要的key如下：

            ##name 步骤名称
            ##user 执行用户
            ##src_type 源机器类型
            ##src      源机器内容
            ##dst_type  目标机器类型
            ##dst       目标机器内容
            ##sp        源路径
            ##dp        目标路径
            ##chown     拷贝完成后需要把文件的所有者修改成什么用户，可以为空
            ##chmod     拷贝完成后把文件权限属性修改， 可以为空
            ##timeout   拷贝超时时间，单位秒，为空时默认60秒
            ##pause     执行结束后是否需要暂停

            


5. 修改一个作业：

    post '/jobs/:projectid/:jobuuid'

    其它参数：

        同上

6. 删除一个作业：

    del '/jobs/:projectid/:jobuuid'


=================================== nodegroup [分组管理] =====================================


1. 获取某个项目下的分组列表信息：

    get '/nodegroup/:projectid'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #name  定时任务名称包涵的字符
        #plugin  插件名
        #jobname 被作业引用的名字包涵的字符
        #create_user  创建者
        #edit_user    最后编辑者
        #create_time_start  创建时间开始日期 (日期格式如:2018-01-01)
        #create_time_end    创建时间结束日期
        #edit_time_start    最后编辑开始日期
        #edit_time_end      最后编辑结束日期



2. 获取某个项目下的某个分组详细信息：

    get '/nodegroup/:projectid/:id'

3. 获取分组机器列表：

    get '/nodegroup/:projectid/:id/nodelist'

4. 新建一个分组：

    post '/nodegroup/:projectid' 

    其它参数：

        #name 分组名称

        #plugin  解析分组用的插件

        #params  分组参数


5. 修改分组信息:

    post '/nodegroup/:projectid/:id' 

    其它参数：

        同上

6. 删除一个分组：

    del '/nodegroup/:projectid/:id' 



=================================== scripts [脚本管理] =====================================

1. 获取某个项目下的脚本：

    get '/scripts/:projectid'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #name  脚本名称包涵的字符
        #create_user  创建者
        #edit_user    最后编辑者
        #create_time_start  创建时间开始日期 (日期格式如:2018-01-01)
        #create_time_end    创建时间结束日期
        #edit_time_start    最后编辑开始日期
        #edit_time_end      最后编辑结束日期
        #jobname    被作业引用的作业名称包涵字符


2. 获取某个项目下的某个脚本：

    get '/scripts/:projectid/:scriptsid'

3. 新建一个脚本：

    post '/scripts/:projectid'

    其它参数:

        #name 脚本名称

        #type 脚本类型

        #cont 脚本内容

4. 修改脚本

    post '/scripts/:projectid/:scriptsid' 

    其它参数：

        同上

5. 删除脚本:

    del '/scripts/:projectid/:scriptsid' 


=================================== slave [slave api] =====================================

:slave  任务被分配到哪个机器上运行的
:uuid   任务的uuid (查看日志时可以是 任务uuid+插件uuid+插件类型)
1. 查看一个日志

    get '/slave/:slave/tasklog/:uuid'

2. 停止一个正在运行的任务

    del '/slave/:slave/killtask/:uuid'



=================================== task [任务] =====================================

1. 获取任务列表：

    get '/task/:projectid'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #name 任务名称包涵的字符
        #user  执行人
        #status  任务状态
        #time_start  执行开始时间
        #time_end    执行结束时间
        #taskuuid    任务uuid


2. 获取本月任务数：

    get '/task/:projectid/count'

3. 获取任务的详细信息：

    get '/task/:projectid/:uuid'

4. 重做任务：

    post '/task/:projectid/redo'

    其它参数：

        #taskuuid  任务的uuid


5. 提交一个作业任务：

    post '/task/:projectid/job'

    其它参数：

        #jobuuid  作业的uuid
        #variable 私有变量，是个hash

6. 提交一个作业任务：

    post '/task/:projectid/job/byname'

    其它参数：

        #jobname  作业的名
        #variable 私有变量，是个hash
        #uuid 可有可无，如果有uuid则使用该uuid作为任务uuid


7. 提交一个批量脚本任务

    post '/task/:projectid/plugin_cmd'

    其它参数：

        #name 批量命令名称
        #user 执行账户
        #node_type 机器节点类型
        #node_cont 机器内容
        #scripts_type 脚本类型
        #scripts_cont 脚本内容
        #scripts_argv 脚本参数
        #timeout  超时
        #variable 私有变量，是个hash


8. 提交一个拷贝任务

    post '/task/:projectid/plugin_scp'

    其它参数：

        #name 同步任务名称
        #user 执行账户
        #src_type 源机器类型
        #src  源机器内容
        #dst_type 目标机器类型
        #dst  目标机器内容
        #sp 源路径
        #dp 目标路径
        #chown 修改同步后的文件归属者
        #chmod 修改同步后的文件权限
        #timeout 超时
        #variable 私有变量，是个hash

9. 获取项目下最后的执行记录

    get '/task/:projectid/analysis/last'

    其它参数：

        #count  默认为10

10. 获取任务最近30天的日期统计：

    get '/task/:projectid/analysis/date'

    其他参数：
        #all  如果为真，表示获取所有项目的统计

11. 获取任务最近30天的小时分布统计：

    get '/task/:projectid/analysis/hour'

12. 获取任务最近30天的运行时间统计：

    get '/task/:projectid/analysis/runtime' 

13. 获取任务最近30天的运行任务次数统计：

    get '/task/:projectid/analysis/statistics' 

=================================== userlist [帐号管理] =====================================

1. 获取账户列表：

    get '/userlist/:projectid'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #name  账户包涵的字符
        #create_user  创建者
        #edit_user    最后编辑者
        #create_time_start  创建时间开始日期 (日期格式如:2018-01-01)
        #create_time_end    创建时间结束日期

2. 新建一个账户：

    post '/userlist/:projectid' 

3. 删除账户

    del '/userlist/:projectid/:id' 

=================================== nodelist [机器管理] =====================================

1. 获取机器列表：

    get '/nodelist/:projectid'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #name  机器名包涵的字符
        #inip  内网ip包涵的字符
        #exip  外网ip包涵的字符
        #create_user  创建者
        #edit_user    最后编辑者
        #create_time_start  创建时间开始日期 (日期格式如:2018-01-01)
        #create_time_end    创建时间结束日期

2. 添加一个机器：

    post '/userlist/:projectid' 

3. 删除机器

    del '/userlist/:projectid/:id' 


=================================== fileserver [文件服务] =====================================

1. 获取文件列表：

    get '/fileserver/:projectid'

2. 上传文件：

    post '/fileserver/:projectid' 

    其它参数：

        上传的文件， 可以是多个

3. 通过token方式上传文件:

    post '/fileserver/:projectid/upload'

        #token

4. 删除文件

    del '/fileserver/:projectid/:fileserverid' 

=================================== token [TOKEN] =====================================

1. 获取token列表：

    get '/token/:projectid/info'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #token  token
        #create_user  创建者
        #edit_user    最后编辑者
        #create_time_start  创建时间开始日期 (日期格式如:2018-01-01)
        #create_time_end    创建时间结束日期

2. 添加一个token：

    post '/token/:projectid' 
        #token token
        #describe 描述 

3. 删除token:

    del '/token/:projectid/:id' 


=================================== nodeinfo [节点信息] =====================================

1. 获取项目机器信息：

    get '/nodeinfo/:projectid' 

2. 检查机器是否属于某个项目：

    get '/nodeinfo/:projectid/check'

    其它参数：

        node : 机器列表，如  node1,node2,node3

3. 获取机器数量信息：

    get '/nodeinfo/:projectid/count'

=================================== variable [作业全局变量] =====================================

1. 获取某个作业的变量列表:

    get '/variable/:projectid/:jobuuid'

    其它参数:

        #empty 当empty等于1时只返回空变量
        #exclude 过滤掉不显示的变量，用英文逗号分隔多个变量名

2. 新建或修改变量：

    post '/variable/:projectid'

    其它参数：

        #jobuuid
        #name
        #value
        #describe

        #id 指定变量id，修改变量

3. 批量更新:
    post '/variable/:projectid/update'

    其它参数:

         #jobuuid
         #data 数组：[  +{ name => '', value => '', describe => '' }, ... ]
    
4. 删除变量:

    del '/variable/:projectid'

    其它变量：

        #jobuuid
        #name

=================================== subtask [作业子任务] =====================================

1. 获取作业任务的子任务状态

    get '/subtask/:projectid/:taskuuid' 

2. 获取作业任务的单独一个子任务状态

    get '/subtask/:projectid/:taskuuid/:subtaskuuid' 

3. 控制子任务

    post '/subtask/:projectid'

    其它参数：

        #taskuuid   任务uuid
        #subtaskuuid  子任务插件uuid
        #subtasktype  子任务类型， cmd或者 scp
        #control  控制子任务，可能的值为：（ next：下一步,fail：停止,running：失败的机器再重试,ignore：忽略失败的机器 ）

4. 控制子任务(同上，区别是权限点不一样，只能操作next)

    put '/subtask/:projectid'

    其它参数：

        #taskuuid   任务uuid
        #subtaskuuid  子任务插件uuid
        #subtasktype  子任务类型， cmd或者 scp
        #control  控制子任务，可能的值为：（ next：下一步 ）

=================================== environment [作业平台环境] =====================================

1. 获取所有环境变量

    get '/environment'

2. 添加或者修改环境变量

    post '/environment'

    其它参数：

        #变量名1: 变量值1
        #变量名2: 变量值2
        #isApiFailEmail:false
        #isApiFailSms:false
        #isApiSuccessEmail:false
        #isApiSuccessSms:false
        #isApiWaitingEmail:false
        #isApiWaitingSms:false
        #isCrontabFailEmail:false
        #isCrontabFailSms:false
        #isCrontabSuccessEmail:false
        #isCrontabSuccessSms:false
        #isCrontabWaitingEmail:false
        #isCrontabWaitingSms:false
        #isPageFailEmail:false
        #isPageFailSms:false
        #isPageSuccessEmail:false
        #isPageSuccessSms:false
        #isPageWaitingEmail:false
        #isPageWaitingSms:false

        #notifyTemplateEmailTitle  #邮件标题模版
        #notifyTemplateEmailContent  #邮件内容模版
        #notifyTemplateSmsContent    #短信模版

3. 删除变量

    del '/environment'

    其它参数：

        #变量1: 1
        #变量2: 1

=================================== notify [通知人列表] =====================================

1. 获取通知人列表：

    get '/notify/:projectid' 

2. 添加通知人

    post '/notify/:projectid'

    其它参数：

        #user  通知人名称 （当通知人名为"_"时，表示触发该任务的人）

3. 删除通知人

    del '/notify/:projectid/:id' 

=================================== cmd [命令行中断] =====================================

1. 打开命令行中断

    get '/cmd/:projectid'

    其它参数:

        #node 机器列表，ip或者机器名,用逗号分隔 （如：10.10.10.10,10.10.10.11 ）
        #sudo sudo到的用户
        #bash 获取单个机器bash

2. 查询日志：

    get '/cmd/:projectid/log'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #user  执行人   (模糊匹配)
        #node  节点     (模糊匹配)
        #usr   执行账户 (模糊匹配)
        #cmd   执行命令 (模糊匹配)

        #time_start  执行开始时间
        #time_end    执行结束时间

=================================== third [第三方接口] =====================================

1. 查询作业列表

    post '/third/option/jobname'
    参数:
        #project_id 项目id

2. 获取需要补充的变量

    post '/third/option/variable' 
    参数:
        #project_id 项目id
        #jobname 作业名

3. dry-run 接口:

    post '/third/interface/dry-run'
    参数:
        #project_id 项目id
        #uuid 任务唯一编号
        #params 参数,hash
            #jobname 作业名
            #variable 变量，hash

4. invoke 接口:

    post '/third/interface/invoke'
    参数:
        同上

5. query接口:

    post '/third/interface/query'
    参数:
        #uuid 任务唯一编号

6. stop接口:

    post '/third/interface/stop'
    参数:
        #uuid 任务唯一编号

=================================== vv [版本变量接口] =====================================

1. 获取变量列表：

    get '/vv/:projectid'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #node 机器
        #name 变量名
        #time_start  执行开始时间
        #time_end    执行结束时间

2. 获取变量表格：

    get '/vv/:projectid/table'

    其它参数(以下参数可以为空，存在值时用该值进行过滤)：

        #node 机器
        #name 变量名
        #time_start  执行开始时间
        #time_end    执行结束时间

3. 获取VERSION变量统计：

    get '/vv/:projectid/analysis/version' 

