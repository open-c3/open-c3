(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('ImpactController', ImpactController);

    /** @ngInject */
    function ImpactController($log, $state, $http, putService, baseService, NgTableParams, adminService) {

        var vm = this;

        adminService.getData().then(function(data){
            if (!data){
                $state.go('home.e403');
                return;
            }
        });

        baseService.getData().then(function(data){
            vm.basedata = data;
            vm.tableInit();
            vm.showTab = true;
        });

        vm.tableInit = function(){
            vm.impactTable= new NgTableParams({count: 10}, {
                counts: [],
                dataset: vm.basedata.impact
            });
        }

        vm.tableReload = function(e){
            if(e){
                e.target.blur();
            }
            angular.element('.loading-container').removeClass('hide');
            angular.element('.table').addClass('hide');
            baseService.getData(1).then(function(data){
                vm.basedata = data;
                vm.tableInit();
                angular.element('.loading-container').addClass('hide');
                angular.element('.table').removeClass('hide');
            });
        }

        // update
        vm.updateImpact = function(obj){
            putService.update('base/impact/' + obj.id, obj).then(function(){
                vm.tableReload();
            });
        };

    }

})();
