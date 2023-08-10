(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('LoginController', LoginController);

    function LoginController($scope, $state, $http, $injector, $location, genericService ) {
        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        vm.callback = sessionStorage.getItem('logoutRouter') ? sessionStorage.getItem('logoutRouter') : $location.search()['callback'];
        vm.post
        vm.logining
        vm.mfakey = '';
        vm.mfa    = '';
        vm.iconMap = {
          google: '/assets/images/google-logo.png',
          loginOa: '/assets/images/oa-login.png',
        };
        vm.disableIconMap = {
          google: '/assets/images/google-disable-logo.png',
          loginOa: '/assets/images/oa-disable-login.png',
        };
        vm.thirdPartyLoading = true;
        vm.thirdPartyWay = [];
        vm.queryParamsArr = {};
        vm.convertToQueryParams = genericService.convertToQueryParams

        vm.hasOALogin = window.location.hash.indexOf('oaaddr') > -1

        vm.thirdPartyLogin = function () {
          $http.get('/api/connector/loginext').success(function (data) {
            if (data.stat) {
              vm.thirdPartyData = data.data
              angular.forEach(vm.thirdPartyData, function (value, key) {
                if (key !== 'default') {
                  vm.thirdPartyWay.push({key, value})
                }
              })
              if (vm.thirdPartyData.default) {
                const newDefault = vm.thirdPartyData.default
                vm.handleJumpClick(vm.thirdPartyWay.filter(item=> item.key === newDefault)[0])
              } else {
                vm.thirdPartyLoading = false
              }
            }else {
              vm.thirdPartyLoading = false
              toastr.error('API Error!');
            }
          }).error(function (data) {
            vm.thirdPartyLoading = false
            toastr.error('API Error!');
          })
        };
        vm.thirdPartyLogin();

        vm.handleJumpClick = function (info) {
          angular.forEach(info.value, function (value, key) { if (key !== 'on') vm.queryParamsArr[key] = value })
          vm.queryParamsArr['callback'] = vm.callback
          window.location.href = `${window.location.origin}/loginext/${info.key}.html${vm.convertToQueryParams('?', vm.queryParamsArr)}`
        }

        vm.handleOAClick = function () {
          if (vm.hasOALogin) {
            const params = {};
            const str = window.location.hash;
            const queryString = str.substring(str.indexOf('?') + 1);
            queryString.split('&').forEach(function(item) {
              const parts = item.split('=');
              const key = parts[0];
              const value = decodeURIComponent(parts[1]);
              params[key] = value;
            });
            window.location.href = `${params['oaaddr']}${params['callback']?  `?callback=${params['callback']}`: ''}`
          }
        }

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
                                        $state.go('home.search', {treeid:4000000000});
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
                                $state.go('home.search', {treeid:4000000000});
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
