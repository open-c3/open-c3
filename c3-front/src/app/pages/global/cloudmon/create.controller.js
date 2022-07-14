(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CloudMonCreateController', CloudMonCreateController);

    function CloudMonCreateController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, $injector, treeid, reload, id ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');

        vm.postdata = {};

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            $http.post('/api/agent/cloudmon', vm.postdata ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "添加失败!", text: data.info, type:'error' }); }

            });
        };

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/cloudmon/' + id ).then(
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

        if( id > 0 )
        {
            vm.reload();
        }

        vm.exporter = [];
        vm.reloadexporter = function () {
            $http.get('/api/agent/cloudmon/exporter' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.exporter = response.data.data
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response ){
                    swal('获取信息失败', response.status, 'error' );
                });
        };

        vm.reloadexporter();
    }
})();

