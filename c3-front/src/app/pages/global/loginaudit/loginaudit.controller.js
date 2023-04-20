(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('LoginAuditController', LoginAuditController);

    /** @ngInject */
    function LoginAuditController( $state, $http, $scope, ngTableParams ) {

        var vm = this;

        vm.Reset = function () {
            vm.time   = "";
            vm.user   = "";
            vm.action = "";
            vm.ip     = "";
            vm.reload()
        };
 
        vm.reload = function () {
            var get_data = {};
            if( vm.time )
            {
                get_data.time = vm.time
            }
            if( vm.user )
            {
                get_data.user = vm.user
            }

            if( vm.action )
            {
                get_data.action = vm.action
            }

            if( vm.ip )
            {
                get_data.ip = vm.ip
            }

            vm.loadover = false;
            $http({
                method:'GET',
                url: '/api/connector/connectorx/loginaudit',
                params:get_data
            }).then(
                function successCallback(response) {
                    vm.loadover = true;
                    if (response.data.stat){
                        vm.loginauditTable = new ngTableParams({count:100}, {counts:[],data:response.data.data});
                    }else {
                        swal('获取列表失败', response.data.info, 'error');
                    }
                },
                function errorCallback(response) {
                    swal('获取列表失败', response.status, 'error');
                }
            );
        };
        vm.reload();
    }

})();
