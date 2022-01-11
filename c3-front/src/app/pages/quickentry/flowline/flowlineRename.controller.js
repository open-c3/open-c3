(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('FlowlineRenameController', FlowlineRenameController);

    function FlowlineRenameController($http, $uibModalInstance, $state, $scope, resoureceService, treeid, reload, sourceid, sourcename, $injector ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        $scope.projectname = sourcename

        vm.cancel = function(){ $uibModalInstance.dismiss()};
        var toastr = toastr || $injector.get('toastr');

        vm.add = function(){
            $http.post('/api/ci/project/' + vm.treeid + '/' + sourceid + '/rename', { name: $scope.projectname } ).success(function(data){
                    if(data.stat == true) {
                        vm.cancel();
                        reload();
                    } else { toastr.error( "提交失败:" + data.info ); }
            });
        };
    }
})();

