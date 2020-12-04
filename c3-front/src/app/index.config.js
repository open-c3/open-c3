(function() {
    'use strict';

    angular
        .module('openc3')
        .config(config);

    /** @ngInject */
    function config($logProvider, $httpProvider, toastrConfig, $sceDelegateProvider, env) {

        $sceDelegateProvider.resourceUrlWhitelist([
          // Allow same origin resource loads.
          'self',
          // Allow loading from our assets domain.  Notice the difference between * and **.
          'http://docker.open-c3.org:8000/**'
        ]);

        // Enable log
        if(env == 'debug')
        {
            $logProvider.debugEnabled(true);
        }else{
            $logProvider.debugEnabled(false);
        }

        // interceptor
        $httpProvider.interceptors.push('authInterceptor');

        // Set options third-party lib
        toastrConfig.allowHtml = true;
        toastrConfig.timeOut = 4000;
        toastrConfig.positionClass = 'toast-top-right';
//        toastrConfig.preventDuplicates = true;
        toastrConfig.progressBar = true;

    }

})();
