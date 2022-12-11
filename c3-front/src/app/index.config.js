(function() {
    'use strict';

    angular
        .module('openc3')
        .config(config);

    /** @ngInject */
    function config($logProvider, $translateProvider, $httpProvider, toastrConfig, $sceDelegateProvider, env) {

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

        // translate
        $translateProvider
            .useCookieStorage()
            .useLoader('langAsyncLoader')
            .useSanitizeValueStrategy('escape')
            .fallbackLanguage('zh_CN')
            .registerAvailableLanguageKeys(['en', 'zh_CN'], {
                'en_*': 'en',
                'zh_*': 'zh_CN'
            })
            .determinePreferredLanguage();

        // Set options third-party lib
        toastrConfig.allowHtml = true;
        toastrConfig.timeOut = 4000;
        toastrConfig.positionClass = 'toast-top-right';
//        toastrConfig.preventDuplicates = true;
        toastrConfig.progressBar = true;

    }

})();
