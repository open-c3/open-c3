(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('BusinessJobController', BusinessJobController);

    function BusinessJobController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, scriptId, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        $('#createstart').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createStart = result;
            $scope.$apply();
        });

        $('#createend').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createEnd= result;
            $scope.$apply();
        });

        $('#editstart').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.editStart = result;
            $scope.$apply();
        });

        $('#editend').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.editEnd= result;
            $scope.$apply();
        });

        vm.addJob = function(){
            $state.go('home.business.jobcreate', { treeid: vm.treeid } );
        }

        vm.deleteJob = function(uuid){
            swal({
                title: "删除作业",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete( '/api/job/jobs/' + vm.treeid + "/" + uuid  ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        swal({ title:'删除作业失败', text: data.info, type:'error' });
                    }
 
                });
              });
        };

        vm.copyJob = function (jobuuid) {
            $http.get('/api/job/jobs/'  + vm.treeid + "/" + jobuuid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.jobDetail = response.data.data;
                        vm.copyJobDatas = vm.jobDetail.data;
                        vm.jobTypes = vm.jobDetail.uuids;

                        if (vm.copyJobDatas){
                            $state.go('home.business.jobedit', {
                                treeid:vm.treeid,
                                editjobuuid:vm.jobDetail.uuid,
                                editdata:vm.copyJobDatas,
                                jobtypes:vm.jobTypes,
                                copyjob:true,
                            });
                        }else {
                            swal({ title:'出错啦', text: "获取作业请求成功，但获取作业详细信息失败。请检查！", type:'error' });
                        }

                    }else {
                        swal({ title:'获取作业详细信息失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'获取作业详细信息失败', text: response.status, type:'error' });
                });

        };
        vm.editJob = function(jobuuid){
            $http.get('/api/job/jobs/' + vm.treeid+ "/"+ jobuuid ).then(
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
                            $state.go('home.business.jobedit', {
                                treeid:vm.treeid,
                                editjobuuid:vm.editjobuuid,
                                editdata:vm.editJobDatas,
                                jobtypes:vm.jobTypes,
                                mon_ids:vm.mon_ids,
                                mon_status:vm.mon_status,
                                editjobname:vm.editJobName,
                            });
                        }else {
                            swal({ title:'出错啦', text: "获取作业请求成功，但获取作业详细信息失败。请检查！", type:'error' });
                        }

                    }else {
                        swal({ title:'获取作业详细信息失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'获取作业详细信息失败', text: response.status, type:'error' });
                });
        };

        vm.saveCron = function(jobdata){
            $uibModal.open({
                templateUrl: 'app/pages/business/crontab/create.html',
                controller: 'BusinessCrontabCreateController',
                controllerAs: 'businesscrontabcreate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    reloadhome: function () {return null},
                    cronData : function () {return null},
                    edit : function () {return null},
                    jobData : function () {return jobdata},
                }
            });
        };

        vm.runJob = function(jobuuid){
            $http.get('/api/job/variable/' + vm.treeid +"/"+jobuuid + "?empty=1").then(
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
                                    emptyData : function () { return vm.emptyVar }
                                }
                            }); 
                            emptyVartab.result.then(
                                function (result) {
                                    var variableDict = {};
                                    angular.forEach(result, function (data, index) {
                                        variableDict[data.name] = data.value;
                                    });
                                    resoureceService.work.runJob(vm.treeid, {"jobuuid":jobuuid,"variable":variableDict})
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
                            resoureceService.work.runJob(vm.treeid, {"jobuuid":jobuuid})
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
                    swal({ title:"检测变量失败", type:'error', text:response.status });
                });
        };

        vm.getMe = function (type) {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                if(type == 'create'){
                    vm.createuser = data.email;
                }else if(type == 'edit'){
                    vm.edituser = data.email;
                }
            });
        };

        vm.Reset = function () {
            $scope.searchShow = true;
            $scope.nosearch = true;
            vm.createuser = "";
            vm.edituser = "";
            vm.jobname = "";
            vm.createStart = "";
            vm.createEnd = "";
            vm.editStart = "";
            vm.editEnd = "";
            vm.reload()
        };

        vm.ciinfo = {}
        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.jobname){
                get_data.name=vm.jobname
            }
            if(vm.createuser){
                get_data.create_user=vm.createuser
            }
            if(vm.edituser){
                get_data.edit_user=vm.edituser
            }
            if(vm.createStart){
                get_data.create_time_start=vm.createStart
            }
            if(vm.createEnd){
                get_data.create_time_end=vm.createEnd
            }
            if(vm.editStart){
                get_data.edit_time_start=vm.editStart
            }
            if(vm.editEnd){
                get_data.edit_time_end=vm.editEnd
            }
            $http({
                method:'GET',
                url:'/api/job/jobs/' + vm.treeid,
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        vm.dataTable = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                    }else {
                        swal('获取列表失败', response.data.info, 'error');
                    }
                },
                function errorCallback(response) {
                    swal('获取列表失败', response.status, 'error');
                }
            );

            $http.get('/api/ci/group/' + vm.treeid).success(function(data){
                if(data.stat)
                {
                    angular.forEach(data.data, function (value, key) {
                        vm.ciinfo['_ci_'+value.id+'_'] = value.name
                    });
                }
                else
                {
                    toastr.error( "加载流水线名称失败:" + data.info )
                }
            });
 
        };

        vm.reload();

    }

})();
