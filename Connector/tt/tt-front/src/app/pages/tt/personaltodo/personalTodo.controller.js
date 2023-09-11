(function () {
  'use strict';
  angular
    .module('cmdb')
    .controller('PersonalTodoController', PersonalTodoController);

  /** @ngInject */
  function PersonalTodoController ($state, $http, $location, baseService, NgTableParams, toastr) {

    var vm = this;

    baseService.getData().then(function (data) {
      vm.baseData = data;
    });
    vm.querySerch = $location.search()
    vm.tableFilter = {};

    // search
    vm.search = function () {
      vm.tickets = [];
      if (vm.order_start) {
        vm.tableFilter.create_start = vm.order_start
      }

      if (vm.order_end) {
        vm.tableFilter.create_end = vm.order_end
      }

      if (angular.equals(vm.tableFilter, {})) {
        toastr.error('ERR (NULL)');
        return;
      }

      if (vm.tableFilter.create_start === null) {
        delete vm.tableFilter.create_start;
      }

      if (vm.tableFilter.create_end === null) {
        delete vm.tableFilter.create_end;
      }

      if (vm.tableFilter.create_end && vm.tableFilter.create_start && vm.tableFilter.create_start > vm.tableFilter.create_end) {
        toastr.error('ERR (Time Wrong!)');
        return;
      }

      vm.searched = true;
      vm.loading = true;
      var start = Math.trunc(vm.tableFilter.create_start.getTime() / 1000)
      var end = Math.trunc((vm.tableFilter.create_end ? vm.tableFilter.create_end : new Date()).getTime() / 1000)
      var keyword = vm.tableFilter.keyword ? '&keyword=' + vm.tableFilter.keyword : ''
      $http.get('/api/tt/statistics/get_todo_tts' + '?start=' + start + '&end=' + end + '&all=' + 0 + keyword).success(function (data) {
        if (data.code === 200) {
          vm.loading = false;
          vm.tickets = data.data;
          vm.tableParams = new NgTableParams(
            { count: 25 },
            { counts: [], dataset: vm.tickets }
          );

        } else {
          vm.loading = false;
          toastr.error('获取数据失败')
        }
      }).error(function (data) {
        vm.loading = false;
        toastr.error('获取数据失败' + data)
        console.error(data)
      })

    };

    if (vm.querySerch.start) {
      vm.order_start = new Date(Number(vm.querySerch.start) * 1000);
      vm.order_end = new Date(Number(vm.querySerch.end) * 1000);
      vm.search();
    }

    // reset
    vm.resetFilter = function () {
      vm.tableFilter = {};
    };

    vm.resetFilter();

  }

})();
