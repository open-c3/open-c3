(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('EditJob2CiController', EditJob2CiController);

    function EditJob2CiController($timeout, $state, $http,editdata,editjobuuid,jobtypes,editjobname,mon_ids,mon_status,treeid, $uibModal, $scope, treeService,resoureceService, $uibModalInstance, setjobuuid, reloadhome, $injector ) {
        var vm = this;

        vm.cancel = function(){ $uibModalInstance.dismiss(); reloadhome();};

        var toastr = toastr || $injector.get('toastr');

        $scope.dataready = true;
        $scope.searchShow = true;
        $scope.nosearch = true;
        $scope.saveHide = false;
        $scope.saveOK = true;
        $scope.editState = false;
        $scope.newjobname = editjobname;
        vm.allNewJob = [];
        vm.treeid = treeid;
        vm.editJobData = editdata;
        vm.editjobuuid = editjobuuid;
        vm.editjobtypes = jobtypes;
        vm.editjobname = editjobname;
        vm.mon_ids = 0;
        vm.mon_status = mon_status;
        vm.cloneNodes = [];
        $scope.monVar = true;
        vm.allVar = [];
        $scope.var = {
            "jobuuid":"",
            "name":"",
            "value":"",
            "describe":" "
        };
//        if (!vm.editJobData){
//            $state.go('home.business.job', {
//                treeid:vm.treeid,
//            });
//        }
        treeService.sync.then(function(){           // when the tree was success.
            vm.nodeStr = treeService.selectname();  // get tree name
        });
        vm.hideMonVar = function () {
            $scope.monVar = !$scope.monVar;
        };
        vm.delVar = function (idx, item) {
            vm.allVar.splice(idx,1)
        };
        vm.addVar = function () {
            vm.allVar.push(angular.copy($scope.var));
        };
        vm.getVar = function () {
            $http.get('/api/job/variable/' + vm.treeid + "/" +vm.editjobuuid).then(
                function successCallback (response) {
                    if (response.data.stat){
                        vm.allVar = response.data.data;
                    }else {
                        toastr.error( "获取变量失败:" + response.data.info )
                    }
                },
                function errorCallback (response) {
                    toastr.error( "获取变量失败:" + response.status )
                }
            );
        };

        if(vm.editjobuuid){
            vm.getVar();
        }

        vm.saveVar = function () {
            var Var = {};
            Var.jobuuid = vm.editjobuuid;
            Var.data = vm.allVar;
            $http.post('/api/job/variable/'+ vm.treeid+'/update', Var).then(
                function successCallback(response) {
                    if (!response.data.stat){
                        toastr.error( "保存变量失败:" + response.data.info )
                    }
                },
                function errorCallback (response ){
                    toastr.error( "保存变量失败:" + response.status )
                }
            );

        };

        vm.count = function(pluginType){
            var count = 0;
            for(var i = 0; i < vm.allNewJob.length; i++) {
                if (vm.allNewJob[i].plugin_type == pluginType){
                    count = count + 1;
                }
            }
            return count;
        };

        vm.createScriptJob = function (idx) {
            var count = vm.count("cmd");
            var seq = count + 1;
            var openChoice = $uibModal.open({
                templateUrl: 'app/pages/business/job/plugin/cmd.html',
                controller: 'scriptJobController',
                controllerAs: 'scriptjob',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    editData : function () {return ""},
                    seq : function () {return seq}
                }
            });

            openChoice.result.then(
                function (result) {
                    if (idx >= 0){
                        vm.allNewJob.splice(idx, 0, result);
                    }else {
                        vm.allNewJob.push(result)
                    }

                },function (reason) {
                    console.log("createScriptJob error reason", reason)
                }
            );
        };

        vm.createScpJob = function (idx) {
            var count = vm.count("scp");
            var seq = count + 1;
            var openChoice = $uibModal.open({
                templateUrl: 'app/pages/business/job/plugin/scp.html',
                controller: 'scpJobController',
                controllerAs: 'scpjob',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    editData : function () {return ""},
                    seq : function () {return seq}
                }
            });

            openChoice.result.then(
                function (result) {
                    if (idx >= 0){
                        vm.allNewJob.splice(idx, 0, result);
                    }else {
                        vm.allNewJob.push(result)
                    }

                },function (reason) {
                    console.log("createScpJob error reason", reason)
                }
            );
        };

        vm.createApprovalJob = function (idx) {
            var count = vm.count("approval");
            var seq = count + 1;
            var openChoice = $uibModal.open({
                templateUrl: 'app/pages/business/job/plugin/approval.html',
                controller: 'approvalJobController',
                controllerAs: 'approvaljob',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    editData : function () {return ""},
                    seq : function () {return seq}
                }
            }); 

            openChoice.result.then(
                function (result) {
                    if (idx >= 0){
                        vm.allNewJob.splice(idx, 0, result);
                    }else {
                        vm.allNewJob.push(result)
                    }

                },function (reason) {
                    console.log("createScpJob error reason", reason)
                }
            );
        };

        vm.copyScp = function (id) {
            var d = vm.allNewJob[id]
            var tempdata = {
                'chmod': d.chmod,
                'chown': d.chown,
                'dp': d.dp,
                'dst': d.dst,
                'dst_type': d.dst_type,
                'scp_delete': d.scp_delete,
                'sp': d.sp,
                'src': d.src,
                'src_type':d.src_type,
                'plugin_type':'scp',
                'name': d.name + '_copy',
                'user': d.user,
                'timeout': d.timeout,
                'pause': d.pause,
                'deployenv' : d.deployenv,
                'action' : d.action,
                'batches' : d.batches
            }
            vm.allNewJob.splice(id + 1, 0, tempdata);
        };

        vm.editScp = function (id) {
            var editData = vm.allNewJob[id];
            var openEdit= $uibModal.open({
                templateUrl: 'app/pages/business/job/plugin/scp.html',
                controller: 'scpJobController',
                controllerAs: 'scpjob',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    editData : function () {return editData},
                    seq : function () {return 0}
                }
            }); 

            openEdit.result.then(
                function (result) {
                    vm.allNewJob.splice(id, 1, result);
                },function (reason) {
                    console.log("editScp error reason", reason)
                }
            ); 
        };

         vm.copyApproval = function (id) {
            var d = vm.allNewJob[id]
            var tempdata = {
                'plugin_type':'approval',
                'name': d.name + '_copy',
                'approver': d.approver,
                'cont': d.cont,
                'everyone': d.everyone,
                'timeout': d.timeout,
                'deployenv' : d.deployenv,
                'action' : d.action,
                'batches' : d.batches
            }
            vm.allNewJob.splice(id + 1, 0, tempdata);
        };

        vm.editApproval = function (id) {
            var editData = vm.allNewJob[id];
            var openEdit= $uibModal.open({
                templateUrl: 'app/pages/business/job/plugin/approval.html',
                controller: 'approvalJobController',
                controllerAs: 'approvaljob',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    editData : function () {return editData},
                    seq : function () {return 0}
                }
            }); 

            openEdit.result.then(
                function (result) {
                    vm.allNewJob.splice(id, 1, result);
                },function (reason) {
                    console.log("editScp error reason", reason)
                }
            );
        };

        vm.copyScript = function (id) {
            var d = vm.allNewJob[id]
            var tempdata = {
                'plugin_type':'cmd',
                'name': d.name + '_copy',
                'user': d.user,
                'node_type':d.node_type,
                'node_cont':d.node_cont,
                'scripts_type':d.scripts_type,
                'scripts_cont': d.scripts_cont,
                'scripts_argv': d.scripts_argv,
                'timeout': d.timeout,
                'pause': d.pause,
                'deployenv' : d.deployenv,
                'action' : d.action,
                'batches' : d.batches
            }
            vm.allNewJob.splice(id + 1, 0, tempdata);
        };

        vm.editScript = function (id) {
            var editData = vm.allNewJob[id];
            var openChoice = $uibModal.open({
                templateUrl: 'app/pages/business/job/plugin/cmd.html',
                controller: 'scriptJobController',
                controllerAs: 'scriptjob',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () {return vm.treeid},
                    editData : function () {return editData},
                    seq : function () {return 0}
                }
            });

            openChoice.result.then(
                function (result) {
                    vm.allNewJob.splice(id, 1, result);
                },function (reason) {
                    console.log("editScript error reason", reason)
                }
            ); 
        };

        vm.deljobdata = function (id) {
            vm.allNewJob.splice(id, 1);
        };

        vm.saveCreateData = function () {
            if (vm.allNewJob.length >0){
                if (!$scope.newjobname){
                    swal({
                        title:"作业名称为空",
                        type:'error'
                    });
                }
                else {
                    var post_data = {
                        "name":$scope.newjobname,
                        "mon_ids":$scope.mon_ids,
                        "mon_status":$scope.mon_status,
                        "data":vm.allNewJob,
                        "permanent":"permanent",
                    };
                    // {stat: true, uuid: "PAApw1VP7LhK", data: true}
                    if ($scope.editState){

                        resoureceService.job.updateJob([vm.treeid,vm.editjobuuid], post_data, null)
                            .then(function (repo) {
                                if (repo.stat){
                                    // vm.allNewJob.splice(0, vm.allNewJob.length);
                                    $scope.newjobname = "";
                                    $scope.saveHide = true;
                                    $scope.saveOK = false;
                                    $scope.jobuuid = $scope.editjobuuid;
                                    vm.saveVar();
                                }

                            }, function (repo) {
                                console.log("update job error:", repo);
                            })
                    }else {
                        resoureceService.job.createJob(vm.treeid, post_data, null)
                            .then(function (repo) {
                                if (repo.stat){
                                    // vm.allNewJob.splice(0, vm.allNewJob.length);
                                    $scope.newjobname = "";
                                    $scope.saveHide = true;
                                    $scope.saveOK = false;
                                    $scope.jobuuid = repo.uuid;
                                    setjobuuid( repo.uuid );
                                }

                            }, function (repo) {
                                console.log("post error result", repo);
                            })
                    }
                }
            }else {
                toastr.error("数据不全")
            }
        };

        vm.up = function (idx){
            if (idx>0){
                [vm.allNewJob[idx-1], vm.allNewJob[idx]] = [vm.allNewJob[idx], vm.allNewJob[idx-1]]
            }
        };

        vm.down = function (idx){
            if (idx<vm.allNewJob.length-1){
                [vm.allNewJob[idx+1], vm.allNewJob[idx]] = [vm.allNewJob[idx], vm.allNewJob[idx+1]]
            }
        };

        if (vm.editjobuuid && vm.editJobData){
            $scope.newjobname = vm.editjobname;
            if (vm.mon_status) {
                $scope.mon_status=true;
            }else{
                $scope.mon_status=false;
            }
            $scope.mon_ids = vm.mon_ids;
            var jobTypesList = [];
            angular.forEach(vm.editjobtypes.split(","), function (jtype, i) {
                jobTypesList.push(jtype.split("_")[0])
            });
            angular.forEach(vm.editJobData, function (data, index) {
                data.plugin_type = jobTypesList[index];
                vm.allNewJob.push(data);
            });
            $scope.editState = true;
        }else if(vm.copyjob){
            var jobTypesList = [];
            angular.forEach(vm.editjobtypes.split(","), function (jtype, i) {
                jobTypesList.push(jtype.split("_")[0])
            });
            angular.forEach(vm.editJobData, function (data, index) {
                data.plugin_type = jobTypesList[index];
                vm.allNewJob.push(data);
            });
        }

    }

})();
