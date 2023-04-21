(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('LoginController', LoginController);

    function LoginController($scope, $state, $http, $injector, $location ) {
        var vm = this;
        var toastr = toastr || $injector.get('toastr');

        vm.callback = $location.search()['callback'];
        vm.post
        vm.logining
        vm.login = function()
        {
            vm.logining = 1;
            vm.post.domain = window.location.host;
            $http.post('/api/connector/default/user/login', vm.post ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        if( vm.callback == undefined )
                        {
                            $state.go('home.dashboard', {treeid:-1});
                        }
                        else
                        {
                            window.open(vm.callback, '_self')
                        }
                    }else {
                        toastr.error('Login Fail!!!' + response.data.info);
                    }
                    vm.logining = 0;
                },
                function errorCallback (response){
                    toastr.error('API Error!');
                    vm.logining = 0;
                }
            );
 
        }
    }
})();
