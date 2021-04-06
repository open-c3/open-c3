(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('VersionLogController', VersionLogController);

    /** @ngInject */
    function VersionLogController( $state, $http, $scope, ngTableParams ) {

        var vm = this;
        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/connector/version/log').success(function(data){
                if (data.stat){
                    vm.versionlogTable = new ngTableParams({count:100}, {counts:[],data:data.data});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取监控数据失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();
    }

})();
