(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('SmallApplicationController', SmallApplicationController);

    /** @ngInject */
    function SmallApplicationController( $state, $http, $scope ) {

        var vm = this;

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/job/environment').then(
                function successCallback(response) {
                    if (response.data.stat){
                        var data_dict = response.data.data;
                         vm.loadover = true

                        angular.forEach(data_dict, function (v, k) {
                            if (v == "true"){
                                v =true
                            }else {
                                v = false;
                            }
                            $scope[k] = Boolean(v);
                        });
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
