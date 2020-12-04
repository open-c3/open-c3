(function() {
    'use strict';

    angular
        .module('openc3')
        .factory('scriptId', scriptId);

    function scriptId() {
        var scriptID = '';
        var _setter = function (data) {
            scriptID = data;
        };
        var _getter = function () {
            return scriptID;
        };
        var _del = function () {
            scriptID = null;
        };
        return {
            setter: _setter,
            getter: _getter,
            del: _del,
        }

    }
    
    
})();