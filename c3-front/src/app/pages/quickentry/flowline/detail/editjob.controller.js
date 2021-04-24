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

        vm.createScriptJob = function (idx) {
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
                    jobName: function () {return "流水线"}
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
                    jobName: function () {return "流水线"}
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
                    jobName: function () {return "流水线"}
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
                    jobName: function () {return ""}
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
                    jobName: function () {return ""}
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
                    jobName: function () {return ""}
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
