(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('VersionLogController', VersionLogController);

    /** @ngInject */
    function VersionLogController( $state, $http, $scope, ngTableParams ) {

        var vm = this;
        vm.versionname = 'null'
        vm.versionuuid = 'null'
        vm.versiontime = 'null'
        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/connector/version/log').success(function(data){
                if (data.stat){
                    vm.versionlogTable = new ngTableParams({count:100}, {counts:[],data:data.data});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取数据失败', text: data.info, type:'error' });
                }
            });
            $http.get('/api/connector/version/name').success(function(data){
                if (data.stat){
                    vm.versionname = data.data.name
                    vm.versionuuid = data.data.uuid
                    vm.versiontime = data.data.time
                }else {
                    swal({ title:'获取数据失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();
    }

})();
