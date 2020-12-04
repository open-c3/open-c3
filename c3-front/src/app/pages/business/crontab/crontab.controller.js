(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('BusinessCrontabController', BusinessCrontabController);

    function BusinessCrontabController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, scriptId, $injector) {

        var vm = this;
        $scope.searchStatus = "";
        var toastr = toastr || $injector.get('toastr');
        vm.treeid = $state.params.treeid;

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

        vm.deleteCronJob = function(cronid){

            resoureceService.work.delCron([vm.treeid,cronid],null, null).finally(function(){
                vm.reload();
            });
        };

        vm.editCronJob = function(cronid){
            $http.get('/api/job/crontab/'  + vm.treeid+"/"+ cronid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.cronDetail = response.data.data;
                        vm.openCronHtml(vm.cronDetail, true);
                    }else {
                        $scope.dataready = false;
                        toastr.error( "获取信息失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取信息失败: " + response.status )
                });

        };

        vm.runCronJob = function(cronid){
            resoureceService.work.runCron([vm.treeid, cronid], {"status":"available"})
                .then(function (repo) {
                    if (repo.stat){
                        vm.reload();
                    }
                    else
                    {
                        toastr.error( "操作失败:" + repo.info );
                    }
                }, function (repo) {
                    toastr.error( "操作失败:" + repo );
                });

        };

        vm.stopCronJob = function(cronid){
            resoureceService.work.stopCron([vm.treeid, cronid], {"status":"unavailable"})
                .then(function (repo) {
                    if (repo.stat){
                        vm.reload();
                    }
                    else
                    {
                        toastr.error( "操作失败:" + repo.info );
                    }
                }, function (repo) {
                    toastr.error( "操作失败:" + repo );
                });

        };

        vm.createCron = function(){
            vm.openCronHtml(null, false)

        };

        vm.openCronHtml = function(data, edit){
            $uibModal.open({
                templateUrl: 'app/pages/business/crontab/create.html',
                controller: 'BusinessCrontabCreateController',
                controllerAs: 'businesscrontabcreate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    reloadhome: function () {return vm.reload},
                    cronData : function () {return data},
                    edit : function () {return edit},
                    jobData : function () {return null},
                }
            });
            vm.reload();
        };

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.createuser = data.email;
            });
        };

        vm.Reset = function () {
            vm.createuser = "";
            vm.edituser = "";
            vm.cronname = "";
            vm.createStart = "";
            vm.createEnd = "";
            vm.editStart = "";
            vm.editEnd = "";
            vm.reload()
        };

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.cronname){
                get_data.name=vm.cronname
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
                url:'/api/job/crontab/' + vm.treeid,
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.data_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        vm.loadover = true
                    }else {
                        toastr.error( "搜索失败:" + response.data.info );
                    }
                },
                function errorCallback(response) {
                    toastr.error( "搜索失败:" + response.status );
                }
            );
        };

        vm.reload();

    }

})();
