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
        var openc3DefaultLang="en"; // en or zh_CN
        $translateProvider
            .useCookieStorage()
            .useLoader('langAsyncLoader');
        $translateProvider.useSanitizeValueStrategy('escape')
            .fallbackLanguage(openc3DefaultLang)
            .preferredLanguage(openc3DefaultLang)
            .registerAvailableLanguageKeys(['en', 'zh_CN'], {
                'en_*': 'en',
                'zh_*': 'zh_CN'
            });
            //.determinePreferredLanguage(); //自动选择一个默认的语言

        // Set options third-party lib
        toastrConfig.allowHtml = true;
        toastrConfig.timeOut = 4000;
        toastrConfig.positionClass = 'toast-top-right';
//        toastrConfig.preventDuplicates = true;
        toastrConfig.progressBar = true;

    }

})();
