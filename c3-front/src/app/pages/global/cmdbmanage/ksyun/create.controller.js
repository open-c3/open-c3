(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CmdbManageKsyunCreateController', CmdbManageKsyunCreateController);

    function CmdbManageKsyunCreateController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, $injector, treeid, reload, id ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');

        vm.id = id;
        vm.postdata = {};

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            vm.postdata.id = vm.id;
            $http.post('/api/agent/cmdbmanage/account/ksyun', vm.postdata ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }

            });
        };

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/cmdbmanage/account/ksyun/' + id ).then(
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
        if( vm.id != undefined)
        {
            vm.reload();
        }

    }
})();

