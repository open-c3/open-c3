(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorMailController', ConnectorMailController);

    function ConnectorMailController($state, $http, $scope, ngTableParams) {
        var vm = this;

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/connector/default/mail').success(function(data){
                if (data.stat){
                    vm.mailTable = new ngTableParams({count:10}, {counts:[],data:data.data});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取用户列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

    }
})();
