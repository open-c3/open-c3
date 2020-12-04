(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('variateQueryController', variateQueryController);

    /** @ngInject */
    function variateQueryController($timeout,$filter, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService) {

        var vm = this;
        $scope.dataready = true;
        $scope.heads = [];
        vm.treeid = $state.params.treeid;
        vm.getVariateData = function () {
            $http.get('/api/job/vv/' + vm.treeid + '/table').then(
                function successCallback(response) {
                    console.log(JSON.stringify(response.data.data[0]));
                    if (response.data.stat) {
                        if (response.data.data) {
                            $scope.heads = response.data.data.shift();
                        };
                        vm.data_Table = new ngTableParams({count:10}, {count:[], data:response.data.data});
                    } else {
                        $scope.dataready = false;
                        $scope.dataerror = "获取变量信息失败：" + response.data.info;
                    }
                },
                function errorCallback (response){
                    $scope.dataready = false;
                    $scope.dataerror =  "获取变量信息失败： " + response.status
                });
        };
        treeService.sync.then(function(){      // when the tree was success.

            vm.nodeStr = treeService.selectname();  // get tree name
            vm.getVariateData();
        });
        vm.delete = function (info) {
            resoureceService.variate.delVV([vm.treeid,info[0]],null, null).finally(function(){
                vm.getVariateData();
            });
        }
        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.startuser = data.email;
            });
        };

    }

})();
