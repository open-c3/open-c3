(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('RunTask2BranchController', RunTask2BranchController);

    function RunTask2BranchController($state, $uibModalInstance, $uibModal,$http, $scope, ngTableParams,resoureceService, $timeout, projectid, $injector ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');

        vm.branch = '';
        vm.loadover = false;
	vm.branchlist = [];
        vm.reload = function () {
            $http.get('/api/ci/v2/c3mc/cibranch/' + projectid ).success(function(data){
                if(data.stat == true) {
                    vm.loadover = true;
	            vm.branchlist = data.data;
                } else { toastr.error( "获取列表失败:" + data.info ); }
            });
        };

	vm.reload();
        vm.runTask = function(){
            $http.post('/api/ci/v2/c3mc/cibranch/' + projectid + '/' + vm.branch ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                } else { toastr.error( "创建新版本失败:" + data.info ); }
            });
        };
        vm.cancel = function(){ $uibModalInstance.dismiss()};
    }
})();

