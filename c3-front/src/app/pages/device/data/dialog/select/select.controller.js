(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('SelectController', SelectController)
    .filter('cut30', function () {
      return function (text) {
        if (text.length > 33) {
          return "..." + text.substr(text.length - 30)
        }
        return text;

      }
    });

  function SelectController ($uibModalInstance, ngTableParams, $http, type, treeid, subtype, selectedtimemachine, item, uuid, config) {

    var vm = this;
    vm.treeid = treeid;
    vm.type = type;
    vm.subtype = subtype;
    vm.config = config;
    vm.uuid = uuid;
    vm.tableLoading = false
    vm.selectedtimemachine = selectedtimemachine
    vm.instanceType = ''
    vm.instanceTypeList = []
    vm.dataTable = new ngTableParams({count: 20}, {counts: [], data: [item]})
    vm.modalTitle = 'C3T.'+ vm.config['name']
    vm.cancel = function () { $uibModalInstance.dismiss() };

    // 请求实例类型列表返回的接口
    vm.getData = function () {
      vm.tableLoading = true
      $http.get('/api/agent/monitor/config/oncall').success(function (data) {
        vm.tableLoading = false;
        if (data.stat) {
          vm.instanceTypeList = data.data
        }
      });
    }

    vm.getData();

    // 选择实例类型
    vm.handleChange = function (instanceType) {
      vm.instanceType = instanceType
    }

    // 确认选择实例类型
    vm.confirm = function () {
      swal({
        title: `确认执行操作吗？`,
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        cancelButtonText: "取消",
        confirmButtonText: "确定",
        closeOnConfirm: true
      }, function () {
        const newUrl = `${config['url']}${vm.instanceType}`
        $http.post(`/api/agent/device/detail/${type}/${subtype}/${vm.treeid}/${uuid}?timemachine=${vm.selectedtimemachine}`, { 'exturl': newUrl }).success(function (data) {
          if (data.stat) {
            toastr.success("操作成功！");
            vm.cancel();
          } else {
            swal({ title: '操作失败', text: data.info, type: 'error' });
          }
        });
      });
    }
  }
})();
