(function() {
    'use strict';

    angular
        .module('cmdb')
        .factory('baseService', baseService);

    /** @ngInject **/
    function baseService($q, $http) {

        var service = {

            returnedData : {},

            getData: function(force){

                var deferred = $q.defer();

                if(angular.equals({}, service.returnedData) || force){

                    $http.get('/api/tt/base/all').success(function(data){
                        angular.copy(data.data, service.returnedData);
                        deferred.resolve(data.data);
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
