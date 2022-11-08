(function() {
    'use strict';

    angular
        .module('cmdb')
        .factory('ssoService', ssoService);

    /** @ngInject */
    function ssoService() {
        var sso =
        {
            'main': '/',
            'login': '/api/connector/connectorx/sso/loginredirect',
            'chpasswd': '/api/connector/connectorx/sso/chpasswdredirect',
            'logout': '#'
        };

        return sso;
    }

    // 获取当前登陆用户
    angular
        .module('cmdb')
        .factory('oauserService', oauserService);

    /** @ngInject */
    function oauserService($q, $http) {

        var service = {

            returnedData : {},

            getData: function(force){

                var deferred = $q.defer();

                if(angular.equals({}, service.returnedData) || force){

                    $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
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
    
    // 是否有tt_admin权限
    angular
        .module('cmdb')
        .factory('adminService', adminService);

    /** @ngInject */
    function adminService($q, $http) {

        var service = {

            returnedData : {},

            getData: function(force){

                var deferred = $q.defer();

                if(angular.equals({}, service.returnedData) || force){

                    $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                        var isadmin = false;
                        if( data.admin == "1" )
                        {
                            isadmin = true;
                        }
                        angular.copy(isadmin, service.returnedData);
                        deferred.resolve(isadmin);
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
