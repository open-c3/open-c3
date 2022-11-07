(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('TTReportController', TTReportController);

    /** @ngInject */
    function TTReportController($state, $http, baseService, NgTableParams, toastr) {

        var vm = this;

        baseService.getData().then(function(data){
            vm.baseData = data;
        });

        vm.tableFilter = {};
        var now = new Date();
        var a_month_ago = new Date();
        a_month_ago.setDate(a_month_ago.getDate()-30);

        vm.tableFilter = {
            "start": a_month_ago,
            "end": now
        };

        // report
        vm.report = function(){

            if (angular.equals(vm.tableFilter, {})){
                toastr.error('ERR (NULL)');
                return;
            }

            if (vm.tableFilter.end && vm.tableFilter.start && vm.tableFilter.start > vm.tableFilter.end){
                toastr.error('ERR (Time Wrong!)');
                return;
            }

            vm.loading = true;

            $http.post('/api/tt/report/kanban', vm.tableFilter).success(function(data){
                if (data.code == 200){
                    vm.data = data.data;
                    vm.tables = {};
                    angular.forEach(vm.data, function(d,key){
                      if (key === "group_user"){
                        for (var v=0 ;v < vm.baseData.group_user.length; v++){
                          for (var w=0 ; w<d.length;w++){
                            if (vm.baseData.group_user[v].id == d[w].id){
                              d[w].user = vm.baseData.group_user[v].email;
                              vm.tables[key] = new NgTableParams({count: 30, sorting: {submit_number: 'desc'}}, {counts: [], dataset: d});
                            }
                          }
                        }
                      }else {
                        vm.tables[key] = new NgTableParams({count: 30, sorting: {submit_number: 'desc'}}, {counts: [], dataset: d});
                      }
                    });
                 }

                vm.loading = false;

            });

        };

        vm.report();

    }

})();
