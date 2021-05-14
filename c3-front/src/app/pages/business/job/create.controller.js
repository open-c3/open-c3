(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('BusinessJobCreateController', BusinessJobCreateController);

    function BusinessJobCreateController($timeout, $state, $http,$stateParams, $uibModal, $scope, treeService,resoureceService, $injector) {
        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        $scope.saveHide = false;
        $scope.saveOK = true;
        $scope.globalVar = true;
        $scope.mon_status = false;
        $scope.monVar = true;
        vm.newJobuuid = null;
        vm.allNewJob = [];
        vm.allVar = [];
        $scope.var = {
            "jobuuid":"",
            "name":"",
            "value":"",
            "describe":" "
        };
        vm.treeid = $state.params.treeid;

        treeService.sync.then(function(){           // when the tree was success.
            vm.nodeStr = treeService.selectname();  // get tree name
        });
        vm.hideGlobalVar = function () {
            $scope.globalVar = !$scope.globalVar;
        };
        vm.hideMonVar = function () {
            $scope.monVar = !$scope.monVar;
        };
        vm.delVar = function (idx) {
            vm.allVar.splice(idx,1)
        };
        vm.addVar = function () {
            vm.allVar.push(angular.copy($scope.var));
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
                    editData : function () {return ""}
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
                    editData : function () {return ""}
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
                    editData : function () {return editData}
                }
            });

            openEdit.result.then(
                function (result) {
                    vm.allNewJob.splice(id, 1, result);
                },function (reason) {
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
                    editData : function () {return ""}
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
                    editData : function () {return editData}
                }
            });

            openEdit.result.then(
                function (result) {
                    vm.allNewJob.splice(id, 1, result);
                },function (reason) {
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
                    editData : function () {return editData}
                }
            });

            openChoice.result.then(
                function (result) {
                    vm.allNewJob.splice(id, 1, result);
                },function (reason) {
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
                        "mon_status":$scope.mon_status,
                        "mon_ids":$scope.mon_ids,
                        "data":vm.allNewJob,
                        "permanent":"permanent",
                    };
                    resoureceService.job.createJob(vm.treeid, post_data, null)
                        .then(function (repo) {
                            if (repo.stat){
                                $scope.newjobname = "";
                                $scope.saveHide = true;
                                $scope.saveOK = false;
                                $scope.jobuuid = repo.uuid;

                                var saveVar = {};
                                saveVar.jobuuid = $scope.jobuuid;
                                saveVar.data = vm.allVar;
                                $http.post('/api/job/variable/'+ vm.treeid+'/update', saveVar).then(
                                    function successCallback(response) {
                                        if (response.data.stat){
                                        }else {
                                            swal("加载数据失败", response.data.info, 'error');
                                        }
                                    },
                                    function errorCallback (response ){
                                        swal("加载数据失败", response.status, 'error');
                                    }
                                );
                            }
                            else
                            {
                                toastr.error("出错啦" + repo.info );
                            }

                        }, function (repo) {
                            toastr.error("出错啦" + repo);
                        })

                }
            }else {
                swal({ title:"数据不全", type:'error' });
            }
        };

        vm.runJob = function () {
            $http.get('/api/job/variable/' + vm.treeid +"/"+$scope.jobuuid + "?empty=1").then(
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
                                    resoureceService.work.runJob(vm.treeid, {"jobuuid":$scope.jobuuid,"variable":variableDict})
                                        .then(function (repo) {
                                            if (repo.stat){
                                                $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:repo.uuid});
                                            }
                                            else
                                            {
                                                toastr.error("出错啦" + repo.info );
                                            }

                                        }, function (repo) {
                                            toastr.error("出错啦" + repo );
                                        });
                                },function (reason) {
                                }
                            ); 
                        }else {
                            resoureceService.work.runJob(vm.treeid, {"jobuuid":$scope.jobuuid})
                                .then(function (repo) {
                                    if (repo.stat){
                                        $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:repo.uuid});
                                    }
                                    else
                                    {
                                        toastr.error("出错啦" + repo.info );
                                    }

                                }, function (repo) {
                                    toastr.error("出错啦" + repo);
                                });
                        }
                    }else {
                        swal({ title:"检测变量失败", type:'error', text:response.data.info });
                    }
                },
                function errorCallback (response){
                    swal({ title:"检测变量失败", type:'error', text:response.message });
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
    }

})();
