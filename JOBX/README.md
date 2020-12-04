





                         API 说明


=================================== group [分组管理] =====================================


1. 获取某个项目下的分组列表信息：

    get '/group/:projectid'

2. 获取某个项目下的某个分组详细信息：

    get '/group/:projectid/:id'

3. 获取分组机器列表：

    get '/group/:projectid/:id/node'

4. 新建一个分组：

    post '/group/:projectid' 

    其它参数：

        #name 分组名称
        #note 备注
        #group_type 分组类型 (当前用两种类型 list \ percent )

            # list 需要如下参数
                #node 机器列表,用逗号分隔，不同的分批用分号分隔 (如: node1,node2;node3 )

            #percent 需要如下参数
                #percent 比例,用冒号分割数字或者百分比( 如: 1:2:%10:5% )



5. 修改分组信息:

    post '/group/:projectid/:id' 

    其它参数：

        同上

6. 删除一个分组：

    del '/group/:projectid/:id' 


=================================== log [日志] =====================================

1. 获取某个项目下的操作日志：

    get '/log/:projectid'

=================================== slave [slave api] =====================================

:slave  任务被分配到哪个机器上运行的
:uuid   任务的uuid (查看日志时可以是 任务uuid+插件uuid+插件类型)
1. 查看一个日志

    get '/slave/:slave/log/:uuid'

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

4. 提交一个作业任务：

    post '/task/:projectid/job/byname'

    其它参数：

        #jobname  作业的名
        #group 分组名
        #variable 私有变量，是个hash
        #uuid 可有可无，如果有uuid则使用该uuid作为任务uuid

5. 回滚

    put '/task/:projectid/:uuid/:control

    参数:
        
        # contron  只能为rollback或者norollback

6. 停止一个任务：

    del,put '/task/:projectid/:uuid'

7. 获取项目下最后的执行记录

    get '/task/:projectid/analysis/last'

    其它参数：

        #count  默认为10

8. 获取任务最近30天的日期统计：

    get '/task/:projectid/analysis/date'

9. 获取任务最近30天的小时分布统计：

    get '/task/:projectid/analysis/hour'

10. 获取任务最近30天的运行时间统计：

    get '/task/:projectid/analysis/runtime' 


=================================== subtask [作业子任务] =====================================

1. 获取作业任务的子任务状态

    get '/subtask/:projectid/:taskuuid' 

2. 确认解锁子任务

    put '/subtask/:projectid/:subtaskuuid/confirm'

=================================== third [第三方接口] =====================================

1. 查询分组列表

    post '/third/option/groupname'
    参数:
        #project_id 项目id

2. dry-run 接口:

    post '/third/interface/dry-run'
    参数:
        #project_id 项目id
        #uuid 任务唯一编号
        #params 参数,hash
            #jobname 作业名
            #group 分组名
            #variable 变量，hash

3. invoke 接口:

    post '/third/interface/invoke'
    参数:
        同上

4. query接口:

    post '/third/interface/query'
    参数:
        #uuid 任务唯一编号

5 stop接口:

    post '/third/interface/stop'
    参数:
        #uuid 任务唯一编号


