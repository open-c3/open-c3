(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorChpasswdController', ConnectorChpasswdController);

    /** @ngInject */
    function ConnectorChpasswdController($http, $scope) {

        var vm = this;

        vm.chpasswd = {};
        vm.new2err = 0;
        vm.change = function()
        {
            if( vm.chpasswd.new1 && vm.chpasswd.new2 && vm.chpasswd.new1 != vm.chpasswd.new2 )
            {
                vm.new2err = 1;
            }
            else
            {
                vm.new2err = 0;
            }
        }
        vm.changepasswd = function () {
                $http.post('/api/connector/default/approve/user/chpasswd', vm.chpasswd).then(
                    function successCallback(response) {
                        if (response.data.stat){
                            document.getElementById("createok").style.display = 'block';
                            $scope.okmsg = "修改密码成功!";
                            setTimeout(function () {
                                document.getElementById("createok").style.display = 'none';
                            }, 2000);
                        }else {
                            document.getElementById("createerr").style.display = 'block';
                            $scope.errmsg = "修改密码失败!" + response.data.info;
                            setTimeout(function () {
                                document.getElementById("createerr").style.display = 'none';
                            }, 2000);
                        }
                    }
                );
        };
    }

})();
