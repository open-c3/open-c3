(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('SystemstatusController', SystemstatusController);

    /** @ngInject */
    function SystemstatusController( $state, $http, $scope, $uibModal, ngTableParams ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/connector/systemstatus').then(
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

        vm.showlog = function(item) {
           console.log(item)
           $uibModal.open({
               templateUrl: 'app/pages/global/systemstatus/showlog.html',
               controller: 'SystemstatusShowlogController',
               controllerAs: 'systemstatusshowlog',
               backdrop: 'static',
               size: 'lg',
               keyboard: false,
               bindToController: true,
               resolve: {
                   treeid: function () { return vm.treeid},
                   item: function () { return item},
                   reload : function () { return vm.reload}
               }
           });
        };

    }

})();
