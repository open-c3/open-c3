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

                        if( response.data.pwperiod < 15 )
                        {
                            swal({
                                 title: "Change Password",
                                 text: 'Your password is valid for ' + response.data.pwperiod  + ' days, please change it in a timely manner',
                                 type: "warning",
                                 showCancelButton: true,
                                 confirmButtonColor: "green",
                                 confirmButtonText: "Modify now",
                                 cancelButtonText: "skip",
                                 closeOnConfirm: false,
                                 showLoaderOnConfirm: true
                            }, function( result ){

                                if( result )
                                {
                                    window.open('/#/connector/chpasswd', '_self');
                                }
                                else
                                {
                                    if( vm.callback == undefined )
                                    {
                                        $state.go('home.dashboard', {treeid:-1});
                                    }
                                    else
                                    {
                                        window.open(vm.callback, '_self')
                                    }
                                 }
                                 swal.close();
                           });
                       }
                       else
                       {

                            if( vm.callback == undefined )
                            {
                                $state.go('home.dashboard', {treeid:-1});
                            }
                            else
                            {
                                window.open(vm.callback, '_self')
                            }

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
