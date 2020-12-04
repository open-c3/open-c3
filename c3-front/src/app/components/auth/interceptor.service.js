(function() {
  'use strict';

  angular
    .module('openc3')
    .factory('authInterceptor', authInterceptor);

  function authInterceptor($log, $q,$window, $location, $injector, ssoService) {

      var ai = {

          'response': function(res){

              var toastr = toastr || $injector.get('toastr');

              if (res.config.url.match(/^\/api.*$/)) {

                  if(res.data){
                      if(res.data.hasOwnProperty('code')){
                          if(res.data.code == 10000){
                              $log.debug('data   ', res.data);
                              var currentUrl = $window.location.href;
                              var siteaddr = window.location.host;
                              $window.location.href=ssoService.login + '?siteaddr=' + siteaddr + '&callback=' + currentUrl;
                              return null;
                          }
                          if(res.data.code != 200){
                              $log.debug(res.data.code, res);
                              toastr.error(res.data.msg);
                          }
                      }
                  }
              }
              return res;
          },

          'responseError': function(res){
              $log.debug(res);
              //if(res.status >= 500){
              //    //$location.path('error/500');
              //    //TODO alarm message
              //    return $q.reject(res);
              //}
              $log.debug("error interceptor!!");
              var toastr = toastr || $injector.get('toastr');
              toastr.error(res.config.url, res.data);
              //toastr.error(res.data);
              return $q.reject(res);
          }
      
      };

      return ai;
  }

})();
