(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('CtiSearchController', CtiSearchController);

    /** @ngInject */
    function CtiSearchController($uibModalInstance, cti_search_w, baseData, cti_select) {

        var vm = this;

        vm.search_w = cti_search_w.toLowerCase();
        vm.baseData = baseData;

        vm.s_c = [];
        vm.s_t = [];
        vm.s_i = [];

        angular.forEach(vm.baseData.item, function(i){
            if (i.name.toLowerCase().indexOf(vm.search_w) !== -1){
                vm.s_i.push(i);
                angular.forEach(vm.baseData.type, function(t){
                    if (t.id == i.type_id){
                        angular.forEach(vm.baseData.category,function(c){
                            if (c.id == t.category_id){
                                var obj = angular.copy(c)
                                obj.hide = 1;
                                vm.s_c.push(obj);
                                return;
                            }
                        });
                        var obj = angular.copy(t);
                        obj.hide = 1;
                        vm.s_t.push(obj);
                        return;
                    }
                });
            }
        });

        angular.forEach(vm.baseData.type, function(t){
            if (t.name.toLowerCase().indexOf(vm.search_w) !== -1){
                vm.s_t.push(t);
                angular.forEach(vm.baseData.category,function(c){
                    if (c.id == t.category_id){
                        var obj = angular.copy(c);
                        obj.hide = 1;
                        vm.s_c.push(obj);
                        return;
                    }
                });
            }
        });

        angular.forEach(vm.baseData.category, function(c){
            if (c.name.toLowerCase().indexOf(vm.search_w) !== -1){
                var obj = angular.copy(c);
                vm.s_c.push(obj);
            }
        });

        vm.select_c = function(c){
            cti_select(c.id,0,0);
        };
        vm.select_t = function(t){
            angular.forEach(vm.baseData.category,function(c){
                if (c.id == t.category_id){
                    cti_select(c.id,t.id,0);
                    return;
                }
            });
        };
        vm.select_i = function(i){
            angular.forEach(vm.baseData.type, function(t){
                if (t.id == i.type_id){
                    angular.forEach(vm.baseData.category, function(c){
                        if (c.id == t.category_id){
                            cti_select(c.id,t.id,i.id);
                            return;
                        }
                    });
                }
            });
        };

        vm.cancel = function(){
            $uibModalInstance.close();
        };

    }

})();
