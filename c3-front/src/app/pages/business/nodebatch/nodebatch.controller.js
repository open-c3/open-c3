(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('GroupIndexController', GroupIndexController);

    function GroupIndexController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');
        vm.showEditLog = function () {
            $uibModal.open({
                templateUrl: 'app/pages/business/nodebatch/log.html',
                controller: 'OperationLogController',
                controllerAs: 'operation',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    groupid: function () {},
                }
            });

        };

        vm.createJobGroup = function () {
            $uibModal.open({
                templateUrl: 'app/pages/business/nodebatch/create.html',
                controller: 'CreateJobGroupController',
                controllerAs: 'createjobgroup',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    groupid: function () {},
                    ciid: function () {},
                    grouptype: function () {},
                    reloadhome: function () { return vm.reload },
                }
            });

        };

        vm.deleteGroup = function(id){
            resoureceService.group.deletegroup([vm.treeid,id],null, null).finally(function(){
                vm.reload();
            });
        };

        vm.editGroup = function(id){

            $uibModal.open({
                templateUrl: 'app/pages/business/nodebatch/create.html',
                controller: 'CreateJobGroupController',
                controllerAs: 'createjobgroup',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    groupid: function () { return id},
                    ciid: function () { return 0},
                    grouptype: function () { return 0},
                    reloadhome: function () { return vm.reload },
                }
            });
        };

        vm.showIPlist = function (idx) {
            $uibModal.open({
                templateUrl: 'app/pages/business/nodebatch/shownode.html',
                controller: 'ShowIplistController',
                controllerAs: 'showip',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    groupid: function () { return idx},
                }
            });
        };

        vm.ciinfo = {}
        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/jobx/group/' + vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        vm.group_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data});
                    }else {
                        toastr.error( "获取分组信息失败："+response.data.info)
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取分组信息失败："+response.status)
                });

            $http.get('/api/ci/group/' + vm.treeid).success(function(data){
                if(data.stat)
                {
                    angular.forEach(data.data, function (value, key) {
                        vm.ciinfo['_ci_test_'+value.id+'_'] = value.name
                        vm.ciinfo['_ci_online_'+value.id+'_'] = value.name
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
