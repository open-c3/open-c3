(function() {
    'use strict';

    angular
        .module('openc3')
        .factory('ssoService', ssoService);

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

})();
