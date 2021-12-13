(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryJobxDetailController', HistoryJobxDetailController)
        .filter('shownode', function () {
            return function (text) {
                var node_str = '';
                var ss = text.split(",");
                if (ss.length >3){
                    node_str = ss.slice(0, 3).join(",") + "..."
                }else {
                    node_str = text;
                }
                return node_str;
            }
        });

    function HistoryJobxDetailController($location, $window, $timeout, $interval,$stateParams,$state, $http, $uibModal, $scope, resoureceService, $injector, genericService) {

        var vm = this;
        vm.chuuid2deploy = function ( uuid ) {

            var u = uuid.slice(uuid.length - 1);
            if (64 < u.charCodeAt(0) && u.charCodeAt(0) < 91) {
                return vm.changeUuid(uuid);
            } else {
                return uuid
            }
        };
        vm.seftime = genericService.seftime

        vm.rollbackexpire = function( starttime )
        {
            var S = new Date()

            var sec =   (S.getTime() - starttime * 1000)  /1000;
            if( sec > 604800 )
            {
                return 1
            }
            else
            {
                return 0
            }
        }

        vm.firstload = true
        vm.changeUuid = function (uuid) {
            var endC = uuid.slice(uuid.length - 1);
            uuid = uuid.slice(0,uuid.length-1);
            if (64 < endC.charCodeAt(0) && endC.charCodeAt(0) < 91) {
                endC  = endC.toLowerCase();
            }else if (96 < endC.charCodeAt(0) && endC.charCodeAt(0) < 123) {
                endC = endC.toUpperCase();
            }
            uuid = uuid + endC;
            return uuid
        }

        vm.getVersionByV = function (text) {
            var w = '';
            var re=/\bversion:.*/;
            if (re.test(text)){
                var reStr = re.exec(text)[0];
                w = reStr.split(":")[1]
            }
         
            return w
        };
 
        vm.getRollbackByV = function (text) {
            var w = '';
            var re=/\b_rollbackVersion_:.*/;
            if (re.test(text)){
                var reStr = re.exec(text)[0];
                w = reStr.split(":")[1]
            }
         
            return w
        };
 



        vm.taskuuid = vm.chuuid2deploy($stateParams.taskuuid);

        vm.accesspage = $stateParams.accesspage;        // 访问方式是否为页面，决定是否显示返回按钮
        vm.treeid = $state.params.treeid;
        vm.rollbackExist = false;
        vm.rollbackName = "_skip_";
        vm.jobinfobyuuid = {}
        vm.mainjobinfobyuuid = {}
        var toastr = toastr || $injector.get('toastr');

        $scope.panelcolor = { "success": "success", "fail": "danger", "refuse": "danger", "running": "info", "decision": "warning", "ignore": "danger" }
        vm.statuszh = { null: "准备","": "等待", "init": "就绪", "success": "成功", "fail": "失败", "refuse": "拒绝", "decision": "待定", "running": "运行中", "ignore": "忽略" }
        vm.backid;
        vm.backidcalled = false;

        vm.cprojectid = function(text) {
            var w = text.split("_");
            if(w[1] == 'ci' && w[0] == '' && w[3] == '' )
            {
                return w[2]
            }
            else
            {
                return ''
            }
        }

        vm.versiondetail = function (id) {
            $state.go('home.quickentry.flowlinedetail', {treeid:vm.treeid, projectid: id});
        };

        if(vm.taskuuid){
            vm.tasklogShow = true;
        }
        vm.jobReloadStatus = {}

        vm.projectinfo = {};
        vm.reload = function(){
            vm.loadover = false
            vm.k8sname = [];
            $http.get('/api/jobx/task/'+ vm.treeid +"/" + vm.taskuuid).then(
                function successCallback(response) {
                    if (response.data.stat){

                        vm.dversion = vm.getVersionByV(response.data.data.variable)
                        vm.rversion = vm.getRollbackByV(response.data.data.variable)

                        $scope.taskDetail = response.data.data;
                        vm.backid = vm.cprojectid($scope.taskDetail.name)
                        if( vm.backid && ! vm.backidcalled )
                        {
                            $http.get('/api/ci/project/'+ vm.treeid + "/" + vm.backid ).then(
                                function successCallback(response) {
                                   if (response.data.stat){
                                       vm.backname  = response.data.data.name;
                                       vm.projectinfo  = response.data.data;
                                       if( vm.projectinfo.ci_type == 'kubernetes' )
                                       {
                                           vm.k8sname = vm.projectinfo.ci_type_name.split(",");
                                       }
                                   } else{ toastr.error("获取流水线信息失败" + response.data.info);}
                                }, function errorCallback (response){ 
                                toastr.error("获取流水线信息失败" + response.status);
                            });
 
                            vm.backidcalled = true
                        }
                        if (response.data.data.status != "running" && response.data.data.status != "init") {
                            $interval.cancel(F5);
                        }

                        if (vm.rollbackExist) {
                            vm.rollbackLinkShow = true;
                            vm.rollbackShow = false;
                        } else {
                            vm.rollbackLinkShow = false;
                            vm.rollbackShow = true;
                        }
                    }else {
                        toastr.error("获取jobx信息失败" + response.data.info);
                    }
                },
                function errorCallback (response){
                    toastr.error("获取jobx信息失败" + response.status);
                });

                $http.get('/api/jobx/subtask/'+ vm.treeid +"/" + vm.taskuuid).then(
                    function successCallback(response) {
                        if (response.data.stat){
                            $scope.subtaskDetail = response.data.data;

                            vm.loadover = true
                            angular.forEach($scope.subtaskDetail, function (jobinfo, index) {

                               if( ! vm.jobinfobyuuid[jobinfo.uuid] && vm.jobinfobyuuid.default )
                               {
                                   vm.jobinfobyuuid[jobinfo.uuid] = vm.jobinfobyuuid.default
                               }

                               if( jobinfo.status != 'init' && ! vm.jobReloadStatus[jobinfo.uuid] ) {
                                   vm.loadover = false
                                   $http.get('/api/job/subtask/'+ vm.treeid + "/" + jobinfo.uuid).then(
                                       function successCallback(response) {
                                           if (response.data.stat){
                                               vm.jobinfobyuuid[jobinfo.uuid] = response.data.data

                                               if(! vm.jobinfobyuuid.default ) {
                                                    var xxxx = []

                                                    angular.forEach( response.data.data, function (data, index) {
                                                       xxxx.push({ "status": null, "extended": { "name":  data.extended.name} })
                                                    });
                                    
                                               vm.jobinfobyuuid.default = xxxx
                                               }
                                                vm.loadover = true
                                           }else{ toastr.error("获取job信息失败" + response.data.info);}
                                      }, function errorCallback (response){
                                          toastr.error("获取job信息失败" + response.data.info);
                                      });

                                   $http.get('/api/job/task/'+ vm.treeid + "/" + jobinfo.uuid).then(
                                      function successCallback(response) {
                                          if (response.data.stat){
                                              vm.mainjobinfobyuuid[jobinfo.uuid] = response.data.data
                                              if( response.data.data.status == 'success' || response.data.data.status == 'fail' )
                                              {
                                                  vm.jobReloadStatus[jobinfo.uuid] = true
                                              }
                                          } else{ toastr.error("获取job信息失败" + response.data.info);}
                                      }, function errorCallback (response){ 
                                          toastr.error("获取job信息失败" + response.status);
                                      });
                                }
                            });
                        }
                        else
                        {
                            toastr.error("获取jobx信息失败" + response.data.info);
                        }
                    },
                    function errorCallback (response){
                         toastr.error("获取jobx信息失败" + response.status);
                    });
        };




        vm.reloaXd = function(){
            vm.loadoveXr = false
            $http.get('/api/jobx/task/'+ vm.treeid +"/" + vm.taskuuiXd).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.taskDetaiXl = response.data.data;
                        vm.backiXd = vm.cprojectid($scope.taskDetail.name)
                        if (response.data.data.status != "running" && response.data.data.status != "init") {
                            $interval.cancel(FX5);
                        }

                    }else {
                        toastr.error("获取jobx信息失败" + response.data.info);
                    }
                },
                function errorCallback (response){
                    toastr.error("获取jobx信息失败" + response.status);
                });

                $http.get('/api/jobx/subtask/'+ vm.treeid +"/" + vm.taskuuiXd).then(
                    function successCallback(response) {
                        if (response.data.stat){
                            $scope.subtaskDetaiXl = response.data.data;

                            vm.loadoveXr = true
                            vm.firstload = false
                            angular.forEach($scope.subtaskDetaiXl, function (jobinfo, index) {

                               if( ! vm.jobinfobyuuid[jobinfo.uuid] && vm.jobinfobyuuid.default )
                               {
                                   vm.jobinfobyuuid[jobinfo.uuid] = vm.jobinfobyuuid.default
                               }
                               if( jobinfo.status != 'init' && ! vm.jobReloadStatus[jobinfo.uuid] ) {
                                   vm.loadoveXr = false
                                   $http.get('/api/job/subtask/'+ vm.treeid + "/" + jobinfo.uuid).then(
                                       function successCallback(response) {
                                           if (response.data.stat){
                                               vm.jobinfobyuuid[jobinfo.uuid] = response.data.data
                                                vm.loadoveXr = true
                                           }else{ toastr.error("获取job信息失败" + response.data.info);}
                                      }, function errorCallback (response){
                                          toastr.error("获取job信息失败" + response.data.info);
                                      });

                                   $http.get('/api/job/task/'+ vm.treeid + "/" + jobinfo.uuid).then(
                                      function successCallback(response) {
                                          if (response.data.stat){
                                              vm.mainjobinfobyuuid[jobinfo.uuid] = response.data.data
                                              if( response.data.data.status == 'success' || response.data.data.status == 'fail' )
                                              {
                                                  vm.jobReloadStatus[jobinfo.uuid] = true
                                              }
                                          } else{ toastr.error("获取job信息失败" + response.data.info);}
                                      }, function errorCallback (response){ 
                                          toastr.error("获取job信息失败" + response.status);
                                      });
                                }
                            });
                        }
                        else
                        {
                            toastr.error("获取jobx信息失败" + response.data.info);
                        }
                    },
                    function errorCallback (response){
                         toastr.error("获取jobx信息失败" + response.status);
                    });
        };




        vm.runDetail = function (item,jobuuid) {
            var runjobdata = item;
            $uibModal.open({
                templateUrl: 'app/pages/history/job/detail/sublog.html',
                controller: 'HistoryJobDetailSublogController',
                controllerAs: 'historyjobdetailsublog',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    repoData : function () {return runjobdata},
                    subtaskuuid:function () {return runjobdata.uuid},
                    taskuuid:function () {return jobuuid},
                    salve:function () {return vm.mainjobinfobyuuid[jobuuid].slave}
                }
            });
        };
 
        vm.runJobConfirm = function (item,jobuuid) {
            var d = {
                "taskuuid":jobuuid,
                "subtaskuuid":item.uuid,
                "subtasktype":item.subtask_type,
                "control":"next"
            };
            $uibModal.open({
                templateUrl: 'app/pages/history/job/detail/confirm.html',
                controller: 'HistoryJobDetailConfirmController',
                controllerAs: 'historyjobdetailconfirm',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId :function () {return vm.treeid},
                    msg : function () {return item.pause},
                    postdata : function () {return d}
                }
            });// end open
        };

        vm.Runnigs = function (item,jobuuid) {
            var d = {
                "taskuuid":jobuuid,
                "subtaskuuid":item.uuid,
                "subtasktype":item.subtask_type,
                "control":"running"
            };
            resoureceService.task.runRunnings(vm.treeid,  d, null)
                .then(function () {
                })
                .finally(function(){
                });
        };
 
        vm.runIgnore = function (item,jobuuid) {
            var d = {
                "taskuuid":jobuuid,
                "subtaskuuid":item.uuid,
                "subtasktype":item.subtask_type,
                "control":"ignore"
            };
            resoureceService.task.runIgnore(vm.treeid,  d, null)
                .then(function () {
                })
                .finally(function(){
                });
        };
 
        vm.runShutTask = function (item,jobuuid) {
            var d = {
                "taskuuid":jobuuid,
                "subtaskuuid":item.uuid,
                "subtasktype":item.subtask_type,
                "control":"fail"
            };
            resoureceService.task.runShutTask(vm.treeid,  d, null)
                .then(function () {
                })
                .finally(function(){
                });
        };
 
        vm.isRollback = function () {
            var uuid = vm.changeUuid(vm.taskuuid);
            $http.get('/api/jobx/task/' + vm.treeid + "/" + uuid).then(
                function successCallback(response) {
                    if (response.data.stat && response.data.data) {
                        vm.rollbackExist = true;
                        vm.rollbackName = response.data.data.name
                    } else {
                        vm.rollbackExist = false;
                    }
                    vm.reload();
                },
                function errorCallback(response) {
                });
        };
        vm.killTask = function (taskuuid) {
            resoureceService.task.stoptask([vm.treeid,taskuuid],null, null).finally(function(){});
        };
        vm.killTaskByJs = function () {
            var promise =  $http.delete('/api/jobx/task/' + vm.treeid + '/' + vm.taskuuid)
            return promise.then(function (data) {
                var response = data.data;
                return response.data
            });
        };
        vm.runConfirm = function (subuuid) {
            resoureceService.task.confirmtask([vm.treeid,subuuid],null, null)
                .then(function (repo) {
                })
                .finally(function(){});
        };


        vm.sleep = function (sec){
            var tt = new Date().getTime();
            while(new Date().getTime() - tt <= sec);
        };

        vm.rollbackJudge = function (rollbackType) {
            if (rollbackType == "rollback" && $scope.taskDetail.status == "running") {
                swal({
                    title: '操作中...',
                    showConfirmButton: false
                });
                var Kill = $interval(function () {
                    if ($scope.taskDetail.status != "running"){
                        vm.rollback(rollbackType);
                        $interval.cancel(Kill);
                    }
                    vm.killTaskByJs();
                    vm.reload();
                }, 3000);
            }else {
                vm.rollback(rollbackType);
            }

        };
        vm.rollback = function (rollbackType) {
            $http.put('/api/jobx/task/' + vm.treeid + '/' + vm.taskuuid + '/' + rollbackType).then(
                function successCallback(response) {
                    // if (JSON.stringify(response.data)) {
                    //     swal("执行成功");
                    // } else {
                    //     swal("执行失败");
                    // }
                    $window.location.reload();
                },
                function errorCallback(response) {
                });
            return
        }
        vm.taskuuiXd = vm.changeUuid(vm.taskuuid);
        vm.rollbackLink = function () {
            var curUrl = $location.absUrl();
            var uuid = vm.changeUuid(vm.taskuuid);
            $state.go('home.history.jobxdetail', {treeid:vm.treeid, taskuuid:uuid, accesspage:true});
        }
        vm.showRollbackInfo = function () {
            if (vm.rollbackName == "_skip_") {
                return '不回滚'
            } else {
                return '已回滚'
            }
        };
        vm.runtaskDetail = function (subuuid) {
            window.open('/#/history/jobdetail/' + vm.treeid +"/"+ subuuid, '_blank')
        };
        $scope.setStatuColor = function (tag) {
            var c = "";

            if(!tag){
                c = "#aaa";
            }
            else if (tag == "success"){
                c = "green";
            }else if (tag == "fail"){
                c = "red";
            }else if (tag == "refuse"){
                c = "red";
            }else if (tag == "init"){
                c = "#473e3e"
            }else if(tag == "running"){
                c = "#ff6211"
            }else if(tag == "WaitConfirm"){
                c = "#089fb8";
            }
            return {"color" : c ,"font-weight": "bold"}

        };
        vm.taskLogDetail = function () {
            $uibModal.open({
                templateUrl: 'app/pages/history/jobx/detail/log.html',
                controller: 'HistoryJobxDetailLogController',
                controllerAs: 'historyjobxdetaillog',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                clickOutsideToClose:false,
                resolve: {
                    taskuuid:function () {return vm.taskuuid},
                    slave:function () {return $scope.taskDetail.slave},
                }
            });
        };
        vm.taskLogDetaiXl = function () {
            $uibModal.open({
                templateUrl: 'app/pages/history/jobx/detail/log.html',
                controller: 'HistoryJobxDetailLogController',
                controllerAs: 'historyjobxdetaillog',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                clickOutsideToClose:false,
                resolve: {
                    taskuuid:function () {return vm.taskuuiXd},
                    slave:function () {return $scope.taskDetaiXl.slave},
                }
            });
        };

        vm.describedeployment = function (type,name) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describedeployment.html',
                controller: 'KubernetesDescribeDeploymentController',
                controllerAs: 'kubernetesdescribedeployment',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return vm.projectinfo.ci_type_kind},
                    name: function () {return name},
                    namespace: function () {return vm.projectinfo.ci_type_namespace},
                    ticketid: function () {return vm.projectinfo.ci_type_ticketid}, 
                }
            });
        };



        vm.showNode = function (nods) {
            $uibModal.open({
                templateUrl: 'app/pages/history/jobx/detail/shownode.html',
                controller: 'showNodeController',
                controllerAs: 'shownode',
                backdrop: 'static',
                size: 'lg',
                keyboard:true,
                bindToController: true,
                resolve: {
                    nodes:function () {return nods},
                }
            });
        };
        vm.isRollback(); 

        var F5 = $interval(function () {
            vm.reload();
        }, 5000);
        var FX5 = $interval(function () {
            if( vm.rversion )
            {
                 vm.reloaXd();
            }
        }, 5000);

 
        $scope.$on('$destroy', function(){
            $interval.cancel(F5);
            $interval.cancel(FX5);
        });
    }

})();
