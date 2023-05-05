(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryBpmDetailController', HistoryBpmDetailController);

    function HistoryBpmDetailController($interval, $location, $state, $http, $uibModal, $stateParams, $scope, $injector, genericService) {

        var vm = this;
        vm.seftime = genericService.seftime
        vm.treeid = $state.params.treeid;
        vm.taskuuid = $state.params.taskuuid;
        vm.jobuuid = $stateParams.jobuuid;
        vm.jobtype = $stateParams.jobtype;
        vm.tasklength = 0;
        vm.advancedinfo = 1;
        vm.allRuningData = [];
        vm.statuszh = { "": "等待执行", "success": "执行成功", "fail": "执行失败","refuse":"审批拒绝", "decision": "执行失败", "running": "执行中", "ignore": "忽略" }
        vm.statuscolor = { "": "#aaa", "success": "green", "fail": "red", "refuse": "orange", "decision": "red", "running": "orange" }

        $scope.setStatuColor = function (stat) {
            if(!stat){ stat = "" }
            return {"color" : vm.statuscolor[stat] ,"font-weight": "bold"}
        };

        var toastr = toastr || $injector.get('toastr');

        vm.getScpCmdTaskLoaded = false;
        vm.getScpCmdTask = function () {
            $http.get('/api/job/task/' + vm.treeid + "/" + vm.taskuuid  ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        var quickData = response.data.data;
                        var serverCount = response.data.data.slave.split(",").length;
                        quickData.count = serverCount;
                        vm.allRuningData.splice(0, vm.allRuningData.length);
                        vm.allRuningData.push(quickData);

                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response){
                    swal('获取信息失败', response.status, 'error' );
                });
        };
        vm.show = {}
        vm.HideMsg = function (id) {
            if( ! vm.show[id] )
            {
                vm.show[id] = 0
            }
            if( vm.show[id] )
            {
                vm.show[id] = 0
            }
            else
            {
                vm.show[id] = 1
            }
        };

        vm.getsubTaskDetails = function () {
            $http.get('/api/job/subtask/' + vm.treeid+ "/" + vm.taskuuid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.allRuningData = response.data.data;
                        vm.tasklength = vm.allRuningData.length -1;
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response){
                    swal('获取信息失败', response.status, 'error' );
                });

        };
        vm.runDetail = function (idx) {
            var runjobdata = vm.allRuningData[idx];
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
                    taskuuid:function () {return vm.taskuuid},
                    salve:function () {return $scope.salve}
                }
            });
            vm.reload();
        };

        vm.killTask = function(){
            swal({
                title: "终止任务",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete( '/api/job/slave/' + $scope.salve + "/killtask/" + vm.taskuuid ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        swal({ title:'终止任务失败', text: data.info, type:'error' });
                    }
 
                });
              });
        };

        vm.taskLogDetail = function () {
            $uibModal.open({
                templateUrl: 'app/pages/history/job/detail/log.html',
                controller: 'HistoryJobDetailLogController',
                controllerAs: 'historyjobdetaillog',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    taskuuid:function () {return vm.taskuuid},
                    slave:function () {return $scope.salve},
                    errormsg:function () {return $scope.errorreason}
                }
            });
        };

        vm.Runnigs = function (idx, item) {
            var d = {
                "taskuuid":vm.taskuuid,
                "subtaskuuid":item.uuid,
                "subtasktype":item.subtask_type,
                "control":"running"
            };

            swal({
                title: "重试任务",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.put( '/api/job/subtask/' + vm.treeid, d ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        toastr.error("操作失败"+data.info);
                    }
                });
              });
        };

        vm.runIgnore = function (idx, item) {
            var d = {
                "taskuuid":vm.taskuuid,
                "subtaskuuid":item.uuid,
                "subtasktype":item.subtask_type,
                "control":"ignore"
            };
            swal({
                title: "忽略错误",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post( '/api/job/subtask/' + vm.treeid, d ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        toastr.error("操作失败"+data.info);
                    }
                });
              });
  
        };

        vm.runShutTask = function (idx, item) {
            var d = {
                "taskuuid":vm.taskuuid,
                "subtaskuuid":item.uuid,
                "subtasktype":item.subtask_type,
                "control":"fail"
            };

            swal({
                title: "终止整个任务",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post( '/api/job/subtask/' + vm.treeid, d ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        toastr.error("操作失败"+data.info);
                    }
                });
              });

        };

        vm.runConfirm = function (idx, item,runmsg) {
            var d = {
                "taskuuid":vm.taskuuid,
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
                    msg : function () {return runmsg},
                    postdata : function () {return d}
                }
            });
            vm.reload();
        };

        vm.bpmuuid = '';
        vm.reload =  function () {
            vm.loadover = false
            $http.get('/api/job/task/' + vm.treeid + "/" + vm.taskuuid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        var task_msg = response.data.data;
                        $scope.taskname = task_msg.name;
                        $scope.runuser = task_msg.user;
                        $scope.starttime = task_msg.starttime;
                        $scope.errreason = task_msg.reason;
                        $scope.finishtime = task_msg.finishtime;
                        $scope.runtime = task_msg.runtime;
                        $scope.status = task_msg.status;
                        $scope.loguuid = task_msg.uuid+task_msg.jobuuid+task_msg.jobtype.split("_")[1];
                        $scope.jobuuid = task_msg.uuid;
                        $scope.salve = task_msg.slave;
                        $scope.errorreason = task_msg.reason;
                        $scope.variable = task_msg.variable;
                        vm.bpmuuid = task_msg.extid;

                        vm.loadbpmlog();
                        vm.loadbpmprotect();
                        if ($scope.status == "fail" || $scope.status == "success"){
                            $interval.cancel(reRun);
                        }
                        if (task_msg.jobtype){
                            vm.jobtype = task_msg.jobtype;
                        }
                        if(vm.jobtype =='jobs') {
                            vm.getsubTaskDetails();
                        }else if (vm.jobtype){
                            if( vm.getScpCmdTaskLoaded == false )
                            {
                                vm.getScpCmdTask();
                            }
                            vm.getScpCmdTaskLoaded = true;
                        }

                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response){
                    swal('获取信息失败', response.status, 'error' );
                });

            };

        vm.bpmprotect = {};
        vm.loadbpmprotect =  function () {
            $http.get('/api/job/bpm/protect/' + vm.bpmuuid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.bpmprotect = response.data.data
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response){
                    swal('获取信息失败', response.status, 'error' );
                });
        };
 
        vm.setProtect = function (opt) {
            var d = {
                "opinion": opt,
            };
            swal({
                title: "对保护进行判断:" + opt,
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post( '/api/job/bpm/protect/' + vm.bpmuuid, d ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        toastr.error("操作失败"+data.info);
                    }
                });
              });
  
        };

        vm.loadbpmlog =  function () {
            $http.get('/api/job/bpm/log/' + vm.bpmuuid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.bpmlog = response.data.data
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response){
                    swal('获取信息失败', response.status, 'error' );
                });
        };
        vm.bpmlog = [];
        vm.reload();

        vm.editForm = function(){
            window.open('/#/bpm/0/' + vm.bpmuuid, '_blank')
        };

        var reRun = $interval(function () {
            if (vm.taskuuid){ vm.reload(); }
        }, 5000);

        $scope.$on('$destroy', function(){
            $interval.cancel(reRun);
        });
    }

})();
