(function() {
    'use strict';
    angular
        .module('openc3')
        .factory('langAsyncLoader', langAsyncLoader);

    /** @ngInject */
    function langAsyncLoader($q, langService) {

        return function (options) {

            var deferred = $q.defer(), translations;

            langService.getData().then(function(data){
                var found = 0;
                angular.forEach(data, function(lang, k){
                    if (lang.langkey == options.key){
                        translations = angular.fromJson(lang.data);
                        found = 1;
                        deferred.resolve(translations);
                    }
                    if (found == 0 && k == (data.length-1)){
                        translations = angular.fromJson(lang.data);
                        deferred.resolve(translations);
                    }
                });
            });

            return deferred.promise;

        };
    }

    angular
        .module('openc3')
        .service('langService', langService);

    /** @ngInject */
    function langService($q, getService) {

        var service = {

            returnedData : [],

            getData: function(force){

                var deferred = $q.defer();

                if(service.returnedData == '' || force){

                    getService.getData('common/i18n').then(function(data){
                        angular.copy(data, service.returnedData);
                        deferred.resolve(data);
                    });

                }else{
                    deferred.resolve(service.returnedData);
                }

                return deferred.promise;
            }
        };

        return service;

    }

})();
