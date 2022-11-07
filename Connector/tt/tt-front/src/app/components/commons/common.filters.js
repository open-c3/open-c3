(function(){
    'use strict';

    angular
        .module('cmdb')
        .filter('baseDataMap', baseDataMap);

    /** @ngInject */
    function baseDataMap() {
        var f = function(input, baseData, type, column){
            if (input && type && baseData){
                var result = '';
                var find = false;
                angular.forEach(baseData, function(v, k){
                    if (k == type){
                        angular.forEach(v, function(val){
                            if (val.id == input){
                                if (column != undefined){
                                    result = val[column]
                                }else{
                                    result = val.name;
                                }
                                return false;
                            }
                        });
                        find = true;
                        return false;
                    }
                    if (find){
                        return false;
                    }
                });
                return result;
            }
        };
        return f;
    }

    angular
        .module('cmdb')
        .filter('splitStr', splitStr);

    /** @ngInject */
    function splitStr() {

        var f = function(input, s ,index){

            var dArray = input.split(s);
            return dArray[index];

        };

        return f;
    }

    angular
        .module('cmdb')
        .filter('floor', floor);

    /** @ngInject */
    function floor() {

        var f = function(input){
            return Math.floor(input + 0)
        };

        return f;
    }

})();
