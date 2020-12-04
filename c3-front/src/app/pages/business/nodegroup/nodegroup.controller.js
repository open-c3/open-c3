(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('NodeGroupController', NodeGroupController);

    function NodeGroupController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.createuser = data.email;
            });
        };

        vm.getMe2 = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.edituser = data.email;
            });
        };
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

        vm.Reset = function () {
            vm.groupname = "";
            vm.pluginname = "";
            vm.jobname = "";
            vm.createuser = "";
            vm.edituser = "";
            vm.createStart = "";
            vm.createEnd = "";
            vm.editStart = "";
            vm.editEnd = "";
            vm.reload();
        };

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.groupname){
                get_data.name=vm.groupname
            }
            if (vm.pluginname){
                get_data.plugin=vm.pluginname
            }
            if (vm.jobname){
                get_data.jobname=vm.jobname
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
                url:'/api/job/nodegroup/' + vm.treeid,
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.group_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        vm.loadover = true
                    }else {
                        toastr.error( "获取列表失败:" + response.data.info )
                    }
                },
                function errorCallback(response) {
                    toastr.error( "获取列表失败:" + response.status )
                }
            );

        };

        vm.createGroup = function () {
            $uibModal.open({
                templateUrl: 'app/pages/business/nodegroup/createGroup.html',
                controller: 'CreateGroupController',
                controllerAs: 'createGroup',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    homereload : function () { return vm.reload}
                }
            });

        };

        vm.delete = function(id){
            resoureceService.group.delete([vm.treeid,id],null, null).finally(function(){
                vm.reload();

            });
        };
        vm.edit = function(id){
            $uibModal.open({
                templateUrl: 'app/pages/business/nodegroup/editGroup.html',
                controller: 'EditGroup',
                controllerAs: 'edit',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    groupId: function () { return id},
                    homereload: function () { return vm.reload}
                }
            });
        };

        vm.reload();
    }

})();
