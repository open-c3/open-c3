(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('TableController', TableController)
    .filter('cut30', function () {
      return function (text) {
        if (text.length > 33) {
          return "..." + text.substr(text.length - 30)
        }
        return text;

      }
    });

  function TableController ($uibModalInstance, ngTableParams, $http, type, treeid, subtype, selectedtimemachine, uuid, config, $sce) {

    var vm = this;
    vm.treeid = treeid;
    vm.type = type;
    vm.subtype = subtype;
    vm.config = config;
    vm.uuid = uuid;
    vm.tableLoading = false
    vm.selectedtimemachine = selectedtimemachine
    vm.countOptions = [20, 30,50, 100, 500]
    vm.cancel = function () { $uibModalInstance.dismiss() };

    // 请求资源列表返回的接口
    vm.getData = function () {
      vm.tableLoading = true
      $http.post(`/api/agent/device/detail/${vm.type}/${vm.subtype}/${vm.treeid}/${vm.uuid}?timemachine=${vm.selectedtimemachine}`, { 'exturl': vm.config['url'] }).success(function (data) {
        if (data.stat) {
          $http.get(data.data).success(function (data) {
            vm.tableLoading = false;
            if (data.stat) {
              vm.showTitle = data.title;
              vm.dataTable = new ngTableParams({ count: 20 }, { counts: vm.countOptions, data: data.data.reverse() });
            }
          })
        } else {
          vm.tableLoading = false;
          swal({ title: '获取URL地址失败', text: data.info, type: 'error' });
        }
      });
    }

    vm.getData();
  }
})();
