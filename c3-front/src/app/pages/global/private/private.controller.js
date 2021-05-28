(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('PrivateController', PrivateController);

    /** @ngInject */
    function PrivateController( $state, $http, $scope, $uibModal, ngTableParams ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/connector/private').then(
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

        vm.createPrivate = function () {
            $uibModal.open({
                templateUrl: 'app/pages/global/private/create.html',
                controller: 'PrivateCreateController',
                controllerAs: 'privatecreate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reload}
                }
            });
        };

    }

})();
