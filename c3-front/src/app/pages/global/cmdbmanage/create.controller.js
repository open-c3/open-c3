(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CmdbManageCreateController', CmdbManageCreateController);

    function CmdbManageCreateController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, $injector, treeid, reload, name ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');

        vm.name = name;
        vm.postdata = '';

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            vm.postdata.name = vm.name;
            $http.post('/api/agent/cmdbmanage', vm.postdata ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }

            });
        };

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/cmdbmanage/' + name ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.postdata = response.data.data
                        vm.loadover = true
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response ){
                    swal('获取信息失败', response.status, 'error' );
                });
        };
        vm.reload();

    }
})();

