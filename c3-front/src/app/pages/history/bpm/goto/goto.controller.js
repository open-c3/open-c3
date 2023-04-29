(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryBpmGotoController', HistoryBpmGotoController);

    function HistoryBpmGotoController($interval, $location, $state, $http, $uibModal, $stateParams, $scope, $injector, genericService) {

        var vm = this;
        vm.bpmuuid = $stateParams.bpmuuid;
        vm.loadover = true;
        vm.reload =  function () {
            vm.loadover = false
            $http.get('/api/job/bpm/taskuuid/' + vm.bpmuuid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        $state.go('home.history.bpmdetail', {treeid: '0',taskuuid: response.data.data,jobuuid:'jobuuid', jobtype:'type'});
                    }else {
                        swal('获取任务编号失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response){
                    swal('获取任务编号失败', response.status, 'error' );
                });

            };


        vm.editBpmForm = function(uuid){
            window.open('/#/bpm/0/' + uuid, '_self')
        };

        vm.editBpmForm( vm.bpmuuid );
        //vm.reload();

    }

})();
