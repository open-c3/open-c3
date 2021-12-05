(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConfigController', ConfigController);

    function ConfigController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, projectid, $scope, name, $injector, treeid ) {

        var vm = this;

//        vm.treeid = $state.params.treeid;  // 不要通过params获取服务树ID，在k8s管理中，可能在A节点打开B节点的配置
        vm.treeid = treeid;

        vm.siteaddr = window.location.protocol + '//' + window.location.host;
        vm.projectid = projectid
        vm.groupid = {}
        vm.name = name
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });


        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/ci/project/' + vm.treeid + '/' + projectid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.project = data.data;

                    vm.loadks8info();
                    vm.reloadticket();

                    if ( vm.project.rely == 1 ) { vm.rely = true; } else { vm.rely = false; }
                    if ( vm.project.autobuild == 1 ) { vm.autobuild = true; } else { vm.autobuild = false; }
                    if ( vm.project.webhook == 1 ) { vm.webhook = true; } else { vm.webhook = false; }
                    if ( vm.project.status == 1 ) { vm.status = true; } else { vm.status = false; }
                    if ( vm.project.autofindtags == 1 ) { vm.autofindtags = true; } else { vm.autofindtags = false; }
                    if ( vm.project.callonlineenv == 1 ) { vm.callonlineenv = true; } else { vm.callonlineenv = false; }
                    if ( vm.project.calltestenv == 1 ) { vm.calltestenv = true; } else { vm.calltestenv = false; }

                    vm.loadover = true;
                } else { 
                    toastr.error("加载配置失败:" + data.info)
                }
            });
        };

        vm.reload();

        vm.reloadimage = function(){
            $http.get('/api/ci/images').success(function(data){
                if( data.stat )
                {
                     vm.dockerimage = [ {id: '', name: '' }, { id: 'centos:5', name: 'centos:5' }, { id: 'centos:6', name: 'centos:6' }, { id: 'centos:7', name: 'centos:7' } ];
                     angular.forEach(data.data, function (value, key) {
                         vm.dockerimage.push(value)
                     });
                }
                else
                {
                    toastr.error( "加载镜像列表失败:" + data.info )
                }
            });
        };

        vm.reloadimage();

        vm.reloadticket = function(){
            var typestr = "";
            if( vm.project.ci_type === 'kubernetes'  )
            {
                typestr = "&type=Harbor";
            }
            $http.get('/api/ci/ticket?projectid=' + vm.projectid + typestr ).success(function(data){
                if( data.stat)
                {
                    vm.ticketinfo = data.data;
                    vm.ticketinfo.unshift({ id: '', name: '' })
                }
                else
                {
                    toastr.error( "加载票据列表失败:" + data.info )
                }
            });
        };


        vm.setcitype = function(type) {
            vm.project.ci_type = type;
            if( type = 'kubernetes' )
            {
                 vm.project.ci_type_kind = "deployment";
                 vm.project.follow_up = "harbor_push_image.pl";
                 vm.project.ci_type_dockerfile = "dockerfile";
            }
            vm.reloadticket();
        }

        vm.show_help = function () {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/detail/config/add_image.html',
                controller: 'CiAddImageController',
                controllerAs: 'add_image',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                }
            });
        };

        vm.save =function() {
          swal({
            title: "保存配置",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
             vm.project.rely = 0;
             if ( vm.rely )
             {
                 vm.project.rely = 1;
             }
             vm.project.autobuild = 0;
             if( vm.autobuild )
             {
                vm.project.autobuild = 1;
             }
             vm.project.webhook = 0;
             if( vm.webhook )
             {
                vm.project.webhook = 1;
             }
             vm.project.status = 0;
             if( vm.status )
             {
                vm.project.status = 1;
             }
             vm.project.autofindtags = 0;
             if( vm.autofindtags )
             {
                vm.project.autofindtags = 1;
             }
             vm.project.callonlineenv = 0;
             if( vm.callonlineenv )
             {
                vm.project.callonlineenv = 1;
             }
             vm.project.calltestenv = 0;
             if( vm.calltestenv )
             {
                vm.project.calltestenv = 1;
             }
 
 
             $http.post('/api/ci/project/' + vm.treeid + '/' + projectid , vm.project ).success(function(data){
                 if(data.stat == true) 
                 { 
                     toastr.success( "保存成功!" )
                     vm.reload();
                 } else { 
                     toastr.error( "保存失败:" + data.info )
                 }
             });
          });
        }

        vm.editrely = function(){
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/detail/config/editrely.html',
                controller: 'ConfigEditRelyController',
                controllerAs: 'editrely', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    projectid: function () { return projectid }
                }
            });
        };

        vm.editgroup = function(grouptype){
            $uibModal.open({
                templateUrl: 'app/pages/business/nodebatch/create.html',
                controller: 'CreateJobGroupController',
                controllerAs: 'createjobgroup',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    groupid: function () { return vm.groupid[grouptype] },
                    ciid: function () { return projectid },
                    grouptype: function () { return grouptype },
                    reloadhome: function () { return vm.editreload },
                }
            });
        };

        vm.editreload = function(t)
        {
            vm.getGroupInfo()
            vm.loadNodeInfo(t)
        }
        vm.getGroupInfo = function () {
            $http.get('/api/jobx/group/' + vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        angular.forEach(response.data.data, function (data, index) {
                            if( data.name == '_ci_test_' + projectid + '_' )
                            {
                                vm.groupid['test'] = data.id
                            }
                            if( data.name == '_ci_online_' + projectid + '_' )
                            {
                                vm.groupid['online'] = data.id
                            }
 
                        });
                    }else {
                        toastr.error("获取分组信息失败:"+response.data.info)
                    }
                },
                function errorCallback (response){
                    toastr.error("获取分组信息失败:"+response.status)
                });
        };
        vm.getGroupInfo(vm.treeid);


        vm.setjobuuid = function( uuid ){  vm.jobuuid = uuid};
        vm.editjob = function(){

            if( ! vm.jobuuid )
            {
                $uibModal.open({
                    templateUrl: 'app/pages/quickentry/flowline/detail/editjob.html',
                    controller: 'EditJob2CiController',
                    controllerAs: 'editjob2ci',
                    backdrop: 'static',
                    size: 'lg',
                    keyboard: false,
                    bindToController: true,
                    resolve: {
                        treeid: function () {return vm.treeid},
                        editjobuuid: function () { return vm.editjobuuid },
                        editdata: function () { return vm.editJobDatas },
                        jobtypes: function () { return vm.jobTypes },
                        mon_ids: function () { return vm.mon_ids },
                        mon_status: function () { return vm.mon_status },
                        setjobuuid: function () { return vm.setjobuuid },
                        editjobname: function () { return '_ci_' + projectid + '_' },
                        reloadhome: function () { return vm.loadJobInfo },
                    }
                });
                return;
            }

            $http.get('/api/job/jobs/'  + vm.treeid+"/"+ vm.jobuuid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.jobDetail = response.data.data;
                        vm.editjobuuid = vm.jobDetail.uuid;
                        vm.editJobDatas = vm.jobDetail.data;
                        vm.editJobName = vm.jobDetail.name;
                        vm.mon_ids = vm.jobDetail.mon_ids;
                        vm.mon_status = vm.jobDetail.mon_status;
                        vm.jobTypes = vm.jobDetail.uuids;
                        if (vm.editjobuuid){
                            $uibModal.open({
                                templateUrl: 'app/pages/quickentry/flowline/detail/editjob.html',
                                controller: 'EditJob2CiController',
                                controllerAs: 'editjob2ci',
                                backdrop: 'static',
                                size: 'lg',
                                keyboard: false,
                                bindToController: true,
                                resolve: {
                                    treeid: function () {return vm.treeid},
                                    editjobuuid: function () { return vm.editjobuuid },
                                    editdata: function () { return vm.editJobDatas },
                                    jobtypes: function () { return vm.jobTypes },
                                    mon_ids: function () { return vm.mon_ids },
                                    mon_status: function () { return vm.mon_status },
                                    setjobuuid: function () { return vm.setjobuuid },
                                    editjobname: function () { return vm.editJobName },
                                    reloadhome: function () { return vm.loadJobInfo },
                               }
                            });
 
                    //        $state.go('home.work.editjob', {
                    //            treeid:vm.treeid,
                    //            editjobuuid:vm.editjobuuid,
                    //            editdata:vm.editJobDatas,
                    //            jobtypes:vm.jobTypes,
                    //            mon_ids:vm.mon_ids,
                    //            mon_status:vm.mon_status,
                    //            editjobname:vm.editJobName,
                    //        });
                        }else {
                            toastr.error("获取作业请求成功，但获取作业详细信息失败。请检查！")
                        }
                    }else {
                        toastr.error( "获取作业详细信息失败:"+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取作业详细信息失败:"+response.status );
                });
        };

        vm.getJobInfo = function (treeId) {
            $http.get('/api/job/jobs/' + treeId).then(
                function successCallback(response) {
                    if (response.data.stat){
                        angular.forEach(response.data.data, function (data, index) {
                            if( data.name == '_ci_' + projectid + '_' )
                            {
                                vm.jobuuid = data.uuid
                            }
                        });
                    }else {
                        toastr.error("获取分组信息失败："+response.data.info)
                    }
                },
                function errorCallback (response){
                    toastr.error("获取分组信息失败："+response.status)
                });
        };
        vm.getJobInfo(vm.treeid);


    $scope.showIPstr = { 'test': [], 'online': [] };
    vm.loadNodeInfo = function(envname)
    {
        $scope.showIPstr[envname] = [];
        $http.get('/api/jobx/group/' + vm.treeid+"/"+'_ci_' + envname + '_' + projectid + '_'+"/node/byname").then(
            function successCallback(response) {
                if (response.data.stat){
                    vm.groupData = response.data.data;
                    angular.forEach(vm.groupData, function (subip, i) {
                        var suball = [];
                        var onelen = subip.length;
                        if (onelen >0){
                            var ss = 0;
                            var group_num = 0;
                            var ipstr = [];
                            angular.forEach(subip, function (ip, n) {
                                if (ss === 8){
                                    suball.push(ipstr.join());
                                    ss = 0;
                                    ipstr = []
                                }
                                ipstr.push(ip);
                                if(onelen === n+1){
                                    suball.push(ipstr.join());
                                }
                                ss +=1;
                                group_num += 1;
                            });
                            var infos = {"num": group_num, "infos": suball};
                            $scope.showIPstr[envname].push(infos);
                        }
                    })
                }else {
                    toastr.error("获取项目机器信息失败："+response.data.info)
                }
           },
           function errorCallback (response ){
                toastr.error("获取项目机器信息失败："+response.status)
       });

    }

    vm.loadNodeInfo('test');
    vm.loadNodeInfo('online');


    vm.jobStep = []
    vm.loadJobInfo = function()
    {
        vm.jobStep = []
        $http.get('/api/job/jobs/' + vm.treeid+"/byname?name="+'_ci_' + projectid + '_' ).then(
            function successCallback(response) {
                if (response.data.stat){
                    vm.jobData = response.data.data;
                    if( vm.jobData.data )
                    {
                        angular.forEach(vm.jobData.data, function (d) {
                                vm.jobStep.push(d.name);
                        });
                    }
                }else {
                    toastr.error( "获取作业信息失败" + response.data.info );
                }
           },
           function errorCallback (response ){
                toastr.error( "获取作业信息失败" + response.status );
       });
    }

    vm.loadJobInfo();
 

//k8s 相关
    //集群
    vm.clusterlist = [];
    vm.getClusterList = function()
    {
        $http.get('/api/ci/ticket/KubeConfig' ).then(
            function successCallback(response) {
                if (response.data.stat){
                    vm.clusterlist = response.data.data;
                }else {
                    toastr.error( "获取作业信息失败" + response.data.info );
                }
           },
           function errorCallback (response ){
                toastr.error( "获取作业信息失败" + response.status );
       });
    }

    vm.addCluster = function () {
        $uibModal.open({
            templateUrl: 'app/pages/global/ticket/createTicket.html',
            controller: 'CreateTicketController',
            controllerAs: 'createticket',
            backdrop: 'static',
            size: 'lg',
            keyboard: false,
            bindToController: true,
            resolve: {
                ticketid: function () {},
                homereload: function () { return vm.getClusterList },
                type: function () { return 'create' },
                title: function () { return '添加kubernetes集群' },
                point: function () { return 'KubeConfig' },
            }
        });

    };

    //命名空间

    vm.getNamespaceList = function(){
        if( vm.project.ci_type_ticketid === "" )
        {
            return;
        }
        $http.get("/api/ci/v2/kubernetes/namespace?ticketid=" +vm.project.ci_type_ticketid ).then(
            function successCallback(response) {
                if (response.data.stat){

                    vm.namespacelist = response.data.data;
                }else {
                    vm.namespacelist = [];
                }
            },
            function errorCallback (response){
                vm.namespacelist = [];
            });

    };

    vm.addNamespace = function () {
        var selecteCluster = {};
         angular.forEach(vm.clusterlist, function (value, key) {
             if(value.id == vm.project.ci_type_ticketid )
             {
                 selecteCluster = value;
             }
        });
 
        $uibModal.open({
            templateUrl: 'app/pages/kubernetesmanage/createnamespace.html',
            controller: 'KubernetesCreateNamespaceController',
            controllerAs: 'kubernetescreatenamespace',
            backdrop: 'static',
            size: 'lg',
            keyboard: false,
            bindToController: true,
            resolve: {
                treeid: function () {return vm.treeid},
                ticketid: function () {return vm.project.ci_type_ticketid},
                clusterinfo: function () {return selecteCluster},
                homereload: function () { return vm.getNamespaceList },
            }
        });
    };


//deployment
    vm.getDeploymentList = function(){
        if( vm.project.ci_type_ticketid === "" )
        {
            return;
        }
        $http.get("/api/ci/v2/kubernetes/deployment?ticketid=" +vm.project.ci_type_ticketid + "&namespace=" + vm.project.ci_type_namespace ).then(
            function successCallback(response) {
                if (response.data.stat){

                    vm.deploymentlist = response.data.data;
                }else {
                    vm.deploymentlist = [];
                }
            },
            function errorCallback (response){
                vm.deploymentlist = [];
            });

    };

    vm.createDeployment = function () {
        var selecteCluster = {};
         angular.forEach(vm.clusterlist, function (value, key) {
             if(value.id == vm.project.ci_type_ticketid )
             {
                 selecteCluster = value;
             }
        });
 
        $uibModal.open({
            templateUrl: 'app/pages/kubernetesmanage/createdeployment.html',
            controller: 'KubernetesCreateDeploymentController',
            controllerAs: 'kubernetescreatedeployment',
            backdrop: 'static',
            size: 'lg',
            keyboard: false,
            bindToController: true,
            resolve: {
                treeid: function () {return vm.treeid},
                ticketid: function () {return vm.project.ci_type_ticketid},
                clusterinfo: function () {return selecteCluster},
                namespace: function () {return vm.project.ci_type_namespace},
                name: function () {return ''},
                homereload: function () {return vm.getDeploymentList},
            }
        });
    };

//Container
    vm.getContainerList = function(){
        if( vm.project.ci_type_ticketid === "" )
        {
            return;
        }
        $http.get("/api/ci/v2/kubernetes/app/flowlineinfo?ticketid=" +vm.project.ci_type_ticketid + "&type=deployment&namespace=" + vm.project.ci_type_namespace + "&name=" + vm.project.ci_type_name ).then(
            function successCallback(response) {
                if (response.data.stat){

                    vm.containerlist = response.data.data;
                }else {
                    vm.containerlist = [];
                }
            },
            function errorCallback (response){
                vm.containerlist = [];
            });

    };

    vm.loadks8info = function(){
        vm.getClusterList();
        vm.getNamespaceList();
        vm.getDeploymentList();
        vm.getContainerList();
    };


    vm.changeCluster = function() {
        vm.project.ci_type_namespace = "";
        vm.project.ci_type_name = "";
        vm.project.ci_type_container = "";
        vm.getNamespaceList();
    };

    vm.changeNamespace = function() {
        vm.project.ci_type_name = "";
        vm.project.ci_type_container = "";
        vm.getDeploymentList();
    };
    vm.changeDeployment = function() {
        vm.project.ci_type_container = "";
        vm.getContainerList();
    };


    vm.addImageAddr = function() {
        var matched = false; 
        angular.forEach(vm.containerlist, function (value, key) {
            if( value.name === vm.project.ci_type_container )
            {
                vm.project.ci_type_repository = value.repository;
                matched = true;
            }
        });
 
        if( matched )
        {
            swal({title: "提取成功", text: vm.project.ci_type_repository, type: 'success'});
        }
        else
        {
            swal({title: "提取失败", text: "没有找到镜像仓库信息", type: 'error'});
        }

    };

    vm.addImageAddrByTicket_set = function(repo) {
        vm.project.ci_type_repository = repo
    }
    vm.addImageAddrByTicket = function () {

        $uibModal.open({
            templateUrl: 'app/pages/kubernetesmanage/harborimage.html',
            controller: 'KubernetesHarborImageController',
            controllerAs: 'kubernetesharborimage',
            backdrop: 'static',
            size: 'lg',
            keyboard: false,
            bindToController: true,
            resolve: {
                treeid: function () {return vm.treeid},
                ticketid: function () {return vm.project.follow_up_ticketid},
                homereload: function () {return vm.addImageAddrByTicket_set},
            }
        });
    };

    vm.addHarbor = function () {
        $uibModal.open({
            templateUrl: 'app/pages/global/ticket/createTicket.html',
            controller: 'CreateTicketController',
            controllerAs: 'createticket',
            backdrop: 'static',
            size: 'lg',
            keyboard: false,
            bindToController: true,
            resolve: {
                ticketid: function () {},
                homereload: function () { return vm.reloadticket },
                type: function () { return 'create' },
                title: function () { return '创建Harbor镜像仓库票据' },
                point: function () { return 'Harbor' },
            }
        });

    };


    }
})();
