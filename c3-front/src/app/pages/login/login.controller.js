(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('LoginController', LoginController);

    function LoginController($scope, $state, $http, $injector) {
        var vm = this;
        var toastr = toastr || $injector.get('toastr');

        vm.post
        vm.logining
        vm.login = function()
        {
            vm.logining = 1;
            vm.post.domain = window.location.host;
            $http.post('/api/connector/default/user/login', vm.post ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $state.go('home.dashboard', {treeid:-1});
                    }else {
                        toastr.error('登录失败!');
                    }
                    vm.logining = 0;
                },
                function errorCallback (response){
                    toastr.error('接口错误!');
                    vm.logining = 0;
                }
            );
 
        }
    }
})();
