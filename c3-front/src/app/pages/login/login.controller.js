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
        vm.mfakey = '';
        vm.mfa    = '';

        vm.login = function(mfa)
        {
            vm.logining = 1;
            vm.post.domain = window.location.host;
            vm.type = 'login';
            if(mfa)
            {
                vm.post.keys = vm.mfakey;
                vm.type = 'mfa';
            }

            $http.post('/api/connector/default/user/' + vm.type , vm.post ).then(
                function successCallback(response) {

                    vm.mfakey    = '';
                    vm.mfa       = '';
                    vm.post.keys = '';
                    vm.post.code = '';

                    if (response.data.stat){
                        if( response.data.mfa != undefined )
                        {
                            vm.mfa      = response.data.mfa;
                            vm.mfakey   = response.data.mfakey;
                            vm.logining = 0;
                            return;
                        }

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
