(function(){
    'use strict';

    angular
        .module('openc3')
        .controller('postCloneController', postCloneController);

        function postCloneController($uibModalInstance, $http, cloneNodes, jobInfo) {

            var vm = this;
            vm.cancel = function(){ $uibModalInstance.dismiss()};
            vm.cloneNodes = cloneNodes;
            vm.jobuuid = "";

            angular.forEach(vm.cloneNodes, function (node, id) {
                vm.cloneNodes[id]["status"] = null;
                vm.cloneNodes[id]["msg"] = null;
            });
            angular.forEach(vm.cloneNodes, function (node, id) {
                $http.post('/api/job/jobs/'+ id, jobInfo).then(
                    function successCallback(response) {
                        if (response.data.stat){
                            vm.cloneNodes[id]["status"] = true;
                            vm.jobuuid = response.data.uuid;
                        }else {
                            vm.cloneNodes[id]["status"] = false;
                            vm.cloneNodes[id]["msg"] = response.data.info;
                        }
                    },
                    function errorCallback (response){
                        vm.cloneNodes[id]["status"] = false;
                        vm.cloneNodes[id]["msg"] = "请求错误";
                    }
                );
            });

            vm.closeTab = function () {
                $uibModalInstance.close(
                    vm.jobuuid
                );
            };


        }

})();
