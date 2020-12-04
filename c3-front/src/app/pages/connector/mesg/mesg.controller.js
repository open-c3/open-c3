(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorMesgController', ConnectorMesgController);

    function ConnectorMesgController($state, $http, $scope, ngTableParams) {
        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/connector/default/mesg').success(function(data){
                if (data.stat){
                    vm.mesgTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取用户列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

    }
})();
