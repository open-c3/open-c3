(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('TTSearchController', TTSearchController);

    /** @ngInject */
    function TTSearchController($state, $http, baseService, NgTableParams, toastr) {

        var vm = this;

        baseService.getData().then(function(data){
            vm.baseData = data;
        });

        // search
        vm.search = function(){

            vm.tickets = [];

            if (angular.equals(vm.tableFilter, {})){
                toastr.error('ERR (NULL)');
                return;
            }

            if (vm.tableFilter.create_start === null){
                delete vm.tableFilter.create_start;
            }
            if (vm.tableFilter.create_end === null){
                delete vm.tableFilter.create_end;
            }

            if (vm.tableFilter.create_end && vm.tableFilter.create_start && vm.tableFilter.create_start > vm.tableFilter.create_end){
                toastr.error('ERR (Time Wrong!)');
                return;
            }

            vm.searched = true;
            vm.loading = true;
            $http.post('/api/tt/search/list/', vm.tableFilter).success(function(data){
                if (data.code == 200){
                    vm.tickets = data.data;
                    vm.tableParams = new NgTableParams(
                        {count:25},
                        {counts:[],dataset:vm.tickets}
                    );

                }
                vm.loading = false;
            });

        };

        // reset
        vm.resetFilter = function(){
            vm.tableFilter = {};
        };

        vm.resetFilter();

    }

})();
