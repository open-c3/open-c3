(function() {
    'use strict';

    angular
        .module('openc3')
        .service('postService', postService);

    /** @ngInject */
    function postService($http, $q, toastr) {

        var service = {

            add: function(path, newObj, showResult){

                showResult = showResult == undefined ? 1 : 0;

                var deferred = $q.defer();

                if(!angular.equals({}, newObj)){

                    $http.post('/api/tt/' + path, newObj).success(function(data){
                        if (data.code == 200){
                            if(showResult){
                                toastr.success(data.data);
                            }
                            deferred.resolve(data);
                        }

                    });
                }else{
                    if(showResult){
                        toastr.warning('nothing to add!');
                    }
                }

                return deferred.promise;
            }

        }

        return service;

    }

    angular
        .module('openc3')
        .service('delService', delService);

    /** @ngInject */
    function delService($http, $q, toastr) {

        var service = {

            del: function(path, id){

                var deferred = $q.defer();

                if(id > 0){

                    $http.delete('/api/tt/' + path + '/' + id).success(function(data){
                        if (data.code == 200){
                            toastr.success(data.data);
                            deferred.resolve(data);
                        }

                    });
                }else{
                    toastr.warning('nothing to delete!');
                }

                return deferred.promise;
            }

        }

        return service;

    }

    angular
        .module('openc3')
        .service('putService', putService);

    /** @ngInject */
    function putService($http, $q, toastr) {

        var service = {

            update: function(path, newObj){

                var deferred = $q.defer();

                if(!angular.equals({}, newObj)){

                    $http.put('/api/tt/' + path, newObj).success(function(data){
                        if (data.code == 200){
                            toastr.success(data.data);
                            deferred.resolve(data);
                        }

                    });
                }else{
                    toastr.warning('nothing to update!');
                }

                return deferred.promise;
            }

        }

        return service;

    }

    angular
        .module('openc3')
        .service('getService', getService);

    /** @ngInject **/
    function getService($q, $http) {

        var service = {

            getData: function(path, key, val){

                var deferred = $q.defer();

                var apiPath = '/api/tt/' + path;

                if(key && val){

                    apiPath += '/' + key + '/' + val;

                }
                $http.get(apiPath).success(function(data){

                    deferred.resolve(data.data);

                });

                return deferred.promise;

            }

        };

        return service;

    }


})();
