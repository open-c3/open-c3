(function() {
    'use strict';

    angular
        .module('cmdb')
        .config(config);

    /** @ngInject */
    function config($logProvider, $translateProvider, $httpProvider, toastrConfig, env) {

        // Enable log
        if (env == 'debug'){
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
        toastrConfig.timeOut = 3000;
        toastrConfig.positionClass = 'toast-top-right';
        //toastrConfig.preventDuplicates = true;
        toastrConfig.progressBar = true;
    }

})();
