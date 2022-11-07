(function() {
  'use strict';

  angular
    .module('cmdb')
    .factory('authInterceptor', authInterceptor);

  /** @ngInject */
  function authInterceptor($q, $window, $location, $injector, ssoService) {

      var tt = {

          'response': function(res){

              var toastr = toastr || $injector.get('toastr');

              if (res.config.url.match(/^\/api.*$/)) {

                  if(res.data){
                      if(res.data.hasOwnProperty('code')){
                          // not login
                          if(res.data.code == 10000){
                              var currentUrl = $window.location.href;
                              var siteaddr = $window.location.protocol + '//' + $window.location.host;
                              $window.location.href=ssoService.login + '?siteaddr=' + siteaddr + '&callback=' + currentUrl;
                              return null;
                          }
                          // custom error
                          if(res.data.code != 200){
                              toastr.error(res.data.data + ' ('+res.data.code+')');
                          }
                      }
                  }
              }
              return res;
          },

          'responseError': function(res){
              if(res.status >= 500){
                  $location.path('error/500');
                  return $q.reject(res);
              }
              var toastr = toastr || $injector.get('toastr');
              toastr.error(res.statusText+' ('+res.status+')');
              return $q.reject(res);
          }
      
      };

      return tt;
  }

})();
