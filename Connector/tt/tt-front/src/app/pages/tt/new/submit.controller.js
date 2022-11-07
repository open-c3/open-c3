(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('TTSubmitController', TTSubmitController);

    /** @ngInject */
    function TTSubmitController($interval, $state, $http, $uibModalInstance, ticket, uploader) {

        var vm = this;

        vm.ticket = ticket;
        vm.uploader = uploader;
        vm.tstatus = "loading";
        vm.astatus = "loading";

        // uploader
        vm.uploader.onCompleteAll = function(){
            vm.astatus = 'complete';
            vm.redirect();
        };

        // submit
        $http.post('/api/tt/ticket', ticket).success(function(data){

            if (data.code == 200){
                vm.newTT = data.data + '';
                var pad = "0000000000";
                var ans = pad.substring(0, 10 - vm.newTT.length) + vm.newTT;
                vm.newTTNo = "TT" + ans;

                vm.tstatus = 'success';
                // upload
                if (vm.uploader.queue.length > 0){
                    angular.forEach(vm.uploader.queue, function(item){
                        item.url = '/api/tt/attachment/upload/' + vm.newTT;
                    });
                    vm.uploader.uploadAll();
                }else{
                    vm.astatus = 'complete';
                    vm.redirect();
                }
            }else{
                vm.tstatus = 'error';
            }

        });

        vm.go = function(url){
            $uibModalInstance.close();
            $state.go(url);
        };

        vm.cancel = function(){
            $uibModalInstance.close();
        };

        vm.timeSec = 3;
        vm.redirect = function(){
            $interval(function(){
                vm.timeSec -=1;
                if (vm.timeSec == 0){
                    vm.cancel();
                    $state.go("home.tt.show", {id:vm.newTTNo});
                }
            }, 1000, 3);
        };

    }

})();
