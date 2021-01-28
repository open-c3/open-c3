(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CreateTicketController', CreateTicketController);

    function CreateTicketController($uibModalInstance, $state, $http, $scope, homereload, ticketid, title, type ) {

        var vm = this;
        vm.title = title
        vm.type = type
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.postData = { type: 'SSHKey', share: 'false' };

        if( ticketid )
        {
            var detail = '';
            if( type == 'edit' )
            {
                detail = '?detail=1'
            }
            $http.get('/api/ci/ticket/' + ticketid + detail ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.postData = response.data.data
                    }else {
                        swal({ title:'获取票据详情失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'获取票据详情失败', text: response.status, type:'error' });
                });
        }

        vm.saveTicket = function(){
            var uri = '/api/ci/ticket';
            if( ticketid )
            {
                uri = '/api/ci/ticket/' + ticketid;
            }
            $http.post(uri, vm.postData ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        homereload();
                        vm.cancel();
                    }else {
                        swal({ title:'保存票据失败', text: response.data.info, type:'error' });
                    }
                }
            );
        };
    }
})();
