(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('SmallApplicationController', SmallApplicationController);

    /** @ngInject */
    function SmallApplicationController( $state, $http, $scope, ngTableParams ) {

        var vm = this;

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/job/smallapplication').then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:100}, {counts:[],data:response.data.data});
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
    }

})();
