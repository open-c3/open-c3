(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('EditStatusController', EditStatusController)
    .filter('cut30', function () {
      return function (text) {
        if (text.length > 33) {
          return "..." + text.substr(text.length - 30)
        }
        return text;

      }
    });

  function EditStatusController ($uibModalInstance, $http, $injector, type, treeid, selectResDetail, tableReload, dialogStatusList) {

    var vm = this;
    vm.type = type
    vm.treeid = treeid;
    vm.selectResDetail = selectResDetail;
    var toastr = toastr || $injector.get('toastr');
    vm.statusList = dialogStatusList
    vm.remarkRequired = {}
    vm.markSelected = ''
    vm.postdata = {
      status: '',
      remark: ''
    }

    // 切换状态
    vm.handleChange = function () {
      vm.remarkRequired = vm.statusList.filter(item => item.name === vm.markSelected)[0]
      vm.postdata.status = vm.markSelected
      vm.postdata.remark = ''
    }

    // 提交禁用条件
    vm.isConfirmDisabled = function () {
      if (!vm.postdata.status) {
        return true
      } else if (vm.postdata.status === '暂不处理' && vm.postdata.remark === '') {
        return true
      } else {
        return false
      }
    }

    vm.cancel = function () { $uibModalInstance.dismiss() };

    vm.confirm = function () {
      swal({
        title: '确定要更改为该状态吗？',
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        cancelButtonText: "取消",
        confirmButtonText: "确定",
        closeOnConfirm: true
      }, function () {
        const uuidStr = vm.type === 'compute' ? vm.selectResDetail.map(item => item.ip).join(',') : vm.selectResDetail.map(item => item['实例ID']).join(',')
        const params = {
          projectid: vm.treeid,
          status: vm.postdata.status,
          mark: vm.postdata.remark,
          type: vm.type,
          uuids: uuidStr
        }
        $http.post(`/api/agent/resourcelow/mark/${vm.type}/${vm.treeid}`, params).success(function (data) {
          if (data.stat) {
            swal('操作成功!', 'success');
            vm.cancel();
            tableReload();
          } else {
            swal({ title: '操作失败', text: data.info, type: 'error' });
            vm.cancel();
          }
        })
      });
    }
  }
})();
