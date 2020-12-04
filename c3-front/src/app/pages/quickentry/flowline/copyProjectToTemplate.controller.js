(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CopyProjectToTemplateController', CopyProjectToTemplateController);

    function CopyProjectToTemplateController($http, $uibModalInstance, $scope, resoureceService, treeid, reload, sourceid, sourcename, $injector ) {

        var vm = this;
        vm.status = 0
        $scope.projectname = sourcename

        vm.cancel = function(){ $uibModalInstance.dismiss()};
        var toastr = toastr || $injector.get('toastr');
        vm.add = function(){
            var s = 0
            if ( vm.status )
            {
                s = 1
            }
            $http.post('/api/ci/group/' + 0 , { name: $scope.projectname, sourceid: sourceid, status: s } ).success(function(data){
                vm.install = { username: 'root' };
                    if(data.stat == true) {
                        var toid = data.id

                        $http.post('/api/job/jobs/' + treeid  + '/copy/byname', { fromname: '_ci_' + sourceid+'_', toname: '_ci_' + toid + '_', toprojectid: 0 } ).success(function(data){
                            vm.install = { username: 'root' };
                                if(data.stat == true) {
                                    $http.post('/api/jobx/group/' + treeid  + '/copy/byname', { fromname: '_ci_test_' + sourceid+'_', toname: '_ci_test_' + toid + '_', toprojectid: 0 } ).success(function(data){
                                        vm.install = { username: 'root' };
                                            if(data.stat == true) {
                                                $http.post('/api/jobx/group/' + treeid  + '/copy/byname', { fromname: '_ci_online_' + sourceid+'_', toname: '_ci_online_' + toid + '_', toprojectid: 0 } ).success(function(data){
                                                    vm.install = { username: 'root' };
                                                        if(data.stat == true) {
                                                            vm.cancel();
                                                            reload();
                                                        } else { toastr.error("提交失败:" + data.info ); }
                                                });
                                            } else { toastr.error( "提交失败:" + data.info ); }
                                    });
                                } else { toastr.error( "提交失败:" + data.info ); }
                        });
                    } else { toastr.error( "提交失败:" + data.info ); }
            });
        };
    }
})();

