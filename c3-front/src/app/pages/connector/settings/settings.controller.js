(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorSettingsController', ConnectorSettingsController);

    /** @ngInject */
    function ConnectorSettingsController($http, $scope) {

        var vm = this;

        vm.type = 'null';
        vm.link = "";
        vm.data = "";

        vm.loadover = false;
        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/connector/connectorx/mfa').success(function(data){
                if (data.stat){
                    vm.loadover = true;
                    vm.type = data.data;
                }else {
                    swal({ title:'获取数据失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

        vm.settings = function () {
                $http.post('/api/connector/connectorx/mfa', { "type": vm.type, "sitehost": window.location.host }).then(
                    function successCallback(response) {
                        if (response.data.stat){
                            document.getElementById("createok").style.display = 'block';
                            $scope.okmsg = "Settings Done!";
                            vm.link = response.data.link;
                            vm.data = response.data.data;
                            setTimeout(function () {
                                document.getElementById("createok").style.display = 'none';
                            }, 10000);
                        }else {
                            document.getElementById("createerr").style.display = 'block';
                            $scope.errmsg = "Settings Fail!" + response.data.info;
                            setTimeout(function () {
                                document.getElementById("createerr").style.display = 'none';
                            }, 10000);
                        }
                    }
                );
        };
    }

})();
