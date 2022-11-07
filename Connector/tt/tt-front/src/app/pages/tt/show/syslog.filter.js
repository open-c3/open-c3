(function(){
    'use strict';
    angular
        .module('cmdb')
        .filter('historyColumnMap', historyColumnMap);

    /** @ngInject */
    function historyColumnMap() {

        var f = function(input, columnName, baseData){

            var maps = {
                'category': 'category',
                'type': 'type',
                'item': 'item',
                'workgroup': 'group',
                'group_user': 'group_user'
            };

            if (input && columnName && baseData){
                var result = input;
                angular.forEach(maps, function(v, k){
                    if (k == columnName){
                        angular.forEach(baseData[v], function(d){
                            if (d.id == input){

                                if(columnName == 'workgroup'){
                                    result = d.group_name;
                                    return;
                                }
                                if(columnName == 'group_user'){
                                    result = d.email;
                                    return;
                                }

                                result = d.name;
                                return;
                            }
                        });
                    }
                });
                return result == '<nil>' ? '' : result;
            }

        };

        return f;
    }

})();
