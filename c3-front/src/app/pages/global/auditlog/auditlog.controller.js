(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AuditLogController', AuditLogController);

    /** @ngInject */
    function AuditLogController( $state, $http, $scope, ngTableParams ) {

        var vm = this;

        vm.Reset = function () {
            vm.time = "";
            vm.user = "";
            vm.title = "";
            vm.content = "";
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

            if( vm.title )
            {
                get_data.title = vm.title
            }

            if( vm.content )
            {
                get_data.content = vm.content
            }

            vm.loadover = false;
            $http({
                method:'GET',
                url: '/api/connector/connectorx/auditlog',
                params:get_data
            }).then(
                function successCallback(response) {
                    vm.loadover = true;
                    if (response.data.stat){
                        vm.auditlogTable = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
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
