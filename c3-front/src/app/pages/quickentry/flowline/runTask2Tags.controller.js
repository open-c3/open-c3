(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('RunTask2TagsController', RunTask2TagsController);

    function RunTask2TagsController($state, $uibModalInstance, $uibModal,$http, $scope, ngTableParams,resoureceService, $timeout, projectid, $injector ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');

        vm.tags = '';
        vm.loadover = false;
	vm.tagslist = [];
        vm.reload = function () {
            $http.get('/api/ci/v2/c3mc/citags/' + projectid ).success(function(data){
                if(data.stat == true) {
                    vm.loadover = true;
	            vm.tagslist = data.data;
                } else { toastr.error( "获取列表失败:" + data.info ); }
            });
        };

	vm.reload();
        vm.runTask = function(){
            $http.post('/api/ci/v2/c3mc/citags/' + projectid + '/' + vm.tags ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                } else { toastr.error( "创建新版本失败:" + data.info ); }
            });
        };
        vm.cancel = function(){ $uibModalInstance.dismiss()};
    }
})();

