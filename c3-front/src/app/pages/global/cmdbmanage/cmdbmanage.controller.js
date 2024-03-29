(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CmdbManageController', CmdbManageController);

    /** @ngInject */
    function CmdbManageController( $state, $http, $scope, $uibModal, ngTableParams ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.mem = {};

        vm.illustrateLink = function () {
          window.open(' https://open-c3.github.io/open-c3-code/AGENT/device/conf/authorization.html')
        };

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/cmdbmanage').then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.dataTable   = new ngTableParams({count:20}, {counts:[],data:response.data.data});
                        vm.loadover = true
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response ){
                    swal('获取信息失败', response.status, 'error' );
                });
        };

        vm.reload()

        vm.create = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/create.html',
                controller: 'CmdbManageCreateController',
                controllerAs: 'cmdbmanagecreate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
            });
        };

        vm.editaws = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/aws/aws.html',
                controller: 'CmdbManageAWSController',
                controllerAs: 'cmdbmanageaws',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
            });
        };

        vm.edithuawei = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/huawei/huawei.html',
                controller: 'CmdbManageHuaweiController',
                controllerAs: 'cmdbmanagehuawei',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
            });
        };
 
        vm.editqcloud = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/qcloud/qcloud.html',
                controller: 'CmdbManageQcloudController',
                controllerAs: 'cmdbmanageqcloud',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
            });
        };
 
        vm.editaliyun = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/aliyun/aliyun.html',
                controller: 'CmdbManageAliyunController',
                controllerAs: 'cmdbmanagealiyun',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
            });
        };

        vm.editibm = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/ibm/ibm.html',
                controller: 'CmdbManageIBMController',
                controllerAs: 'cmdbmanageibm',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
            });
        };

 
        vm.editksyun = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/ksyun/ksyun.html',
                controller: 'CmdbManageKsyunController',
                controllerAs: 'cmdbmanageksyun',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
            });
        };

        vm.editgoogle = function (name) {
            $uibModal.open({
                templateUrl: 'app/pages/global/cmdbmanage/google/google.html',
                controller: 'CmdbManageGoogleController',
                controllerAs: 'cmdbmanagegoogle',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload: function () { return vm.reload},
                    name: function () { return name}
                }
            });
        };

        vm.delete = function(name){
            swal({
                title: "删除",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post('/api/agent/cmdbmanage', { "name": name } ).success(function(data){
                    if(data.stat == true) {
                        vm.reload();
                    } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }

                });
            });
        };
    }

})();
