(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('BusinessJobEditController', BusinessJobEditController);

    function BusinessJobEditController($timeout, $state, $http,$stateParams, $uibModal, $scope, treeService,resoureceService) {
        var vm = this;
        $scope.saveHide = false;
        $scope.saveOK = true;
        $scope.editState = false;
        vm.allNewJob = [];
        vm.treeid = $state.params.treeid;
        vm.editJobData = $stateParams.editdata;
        vm.editjobuuid = $stateParams.editjobuuid;
        vm.editjobtypes = $stateParams.jobtypes;
        vm.editjobname = $stateParams.editjobname;
        vm.mon_ids = $stateParams.mon_ids;
        vm.mon_status = $stateParams.mon_status;
        vm.copyjob = $stateParams.copyjob;
        vm.cloneNodes = [];
        $scope.globalVar = true;
        $scope.monVar = true;
        vm.allVar = [];
        $scope.var = {
            "jobuuid":"",
            "name":"",
            "value":"",
            "describe":" "
        };
        if (!vm.editJobData){
            $state.go('home.business.job', {
                treeid:vm.treeid,
            });
        }
        treeService.sync.then(function(){           // when the tree was success.
            vm.nodeStr = treeService.selectname();  // get tree name
        });
        vm.hideGlobalVar = function () {
            $scope.globalVar = !$scope.globalVar;
        };
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
                        swal({
                            title:"获取变量失败",
                            type:'error',
                            text:response.data.message
                        });
                    }
                },
                function errorCallback (response) {
                    swal({
                        title:"获取变量失败",
                        type:'error',
                        text:response.message
                    });
                }
            );
        };
        if(vm.editjobuuid){
            vm.getVar();
        }
        vm.cloneToNode = function () {
            var openClone = $uibModal.open({
                templateUrl: 'app/pages/business/job/edit/cloneJob.html',
                controller: 'cloneJobController',
                controllerAs: 'clonejob',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,

            });

            openClone.result.then(
                function (result) {
                   if (JSON.stringify(result) != '{}'){
                       vm.hashCloneNodes = result;
                       angular.forEach(result, function (node, i) {
                           vm.cloneNodes.push(i)
                       })
                   }

                },function (reason) {
                    console.log("cloneToNode error reason", reason)
                }
            );

        };

        vm.saveMonVar = function () {
            var Var = {};
            Var.jobuuid = vm.editjobuuid;
            Var.status = vm.monStatus;
            Var.mon_ids = vm.monIds;
            $http.post('/api/job/variable/'+ vm.treeid+'/update_mon', Var).then(
                function successCallback(response) {
                    if (response.data.stat){
                    }else {
                        swal({
                            title:"保存监控节点数据失败",
                            type:'error',
                            text:response.data.message
                        });
                    }
                },
                function errorCallback (response ){
                }
            );

        };
        vm.saveVar = function () {
            var Var = {};
            Var.jobuuid = vm.editjobuuid;
            Var.data = vm.allVar;
            $http.post('/api/job/variable/'+ vm.treeid+'/update', Var).then(
                function successCallback(response) {
                    if (response.data.stat){
                    }else {
                        swal({
                            title:"保存变量失败",
                            type:'error',
                            text:response.data.message
                        });
                    }
                },
                function errorCallback (response ){
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
        vm.saveCloneData = function () {
            if(vm.cloneNodes.length <1){
                swal({
                    title:"克隆目标节点不能为空",
                    type:'error'
                });
                return
            }
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
                    swal({
                        title: "确定克隆作业?",
                        type: "warning", showCancelButton: true,
                        confirmButtonColor: "#DD6B55",
                        closeOnConfirm: true,
                        showLoaderOnConfirm: true

                    }, function () {
                        var openResult = $uibModal.open({
                            templateUrl: 'app/pages/business/job/edit/postClone.html',
                            controller: 'postCloneController',
                            controllerAs: 'postclone',
                            backdrop: 'static',
                            size: 'lg',
                            keyboard: false,
                            bindToController: true,
                            resolve: {
                                cloneNodes: function () { return vm.hashCloneNodes},
                                jobInfo: function () { return post_data},
                            }

                        });
                        openResult.result.then(
                            function (result) {
                                if (result){
                                    $scope.newjobname = "";
                                    $scope.saveHide = true;
                                    $scope.saveOK = false;
                                    $scope.jobuuid = result;
                                    vm.editjobuuid = result;
                                    vm.saveVar()
                                    $state.go('home.business.job',{treeid:vm.treeid})
                                }

                            },function (reason) {
                                console.log("saveCloneData error reason", reason)
                            }
                        );

                    });
                }
            }else {
                swal({
                    title:"数据不全",
                    type:'error',
                });
            }
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
                                }

                            }, function (repo) {
                                console.log("post error result", repo);
                            })
                    }
                }
            }else {
                swal({
                    title:"数据不全",
                    type:'error',
                });
            }
        };

        vm.runJob = function () {
            $http.get('/api/job/variable/' + vm.treeid +"/"+vm.editjobuuid + "?empty=1").then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.emptyVar = response.data.data;
                        if (vm.emptyVar.length >0){
                            var emptyVartab = $uibModal.open({
                                templateUrl: 'app/components/emptyvar/emptyVar.html',
                                controller: 'EmptyVarController',
                                controllerAs: 'emptyvars',
                                backdrop: 'static',
                                size: 'lg',
                                keyboard: false,
                                bindToController: true,
                                resolve: {
                                    emptyData : function () { return vm.emptyVar}
                                }
                            });
                            emptyVartab.result.then(
                                function (result) {
                                    var variableDict = {};
                                    angular.forEach(result, function (data, index) {
                                        variableDict[data.name] = data.value;
                                    });
                                    resoureceService.work.runJob(vm.treeid, {"jobuuid":vm.editjobuuid ,"variable":variableDict})
                                        .then(function (repo) {
                                            if (repo.stat){
                                                $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:repo.uuid});
                                            }

                                        }, function (repo) {
                                            console.log("run job error", repo);
                                        });
                                },function (reason) {
                                    console.log("runjob error reason", reason)
                                }
                            );
                        }else {
                            resoureceService.work.runJob(vm.treeid, {"jobuuid":vm.editjobuuid })
                                .then(function (repo) {
                                    if (repo.stat){
                                        $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:repo.uuid});
                                    }

                                }, function (repo) {
                                    console.log("run job error", repo);
                                });
                        }
                    }else {
                    }
                },
                function errorCallback (response){
                    swal({
                        title:"检测变量失败",
                        type:'error',
                        text:response.message
                    });
                });
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
