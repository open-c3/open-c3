(function () {
  'use strict';
  angular
    .module('openc3')
    .controller('NavigationDialogController', NavigationDialogController);

  /** @ngInject */
  function NavigationDialogController ($http, $uibModalInstance, id, reload) {

    var vm = this;
    vm.dialogId = id
    vm.postdata = { name: '', show: '1', url: '', describe: '' }

    vm.cancel = function () { $uibModalInstance.dismiss(); reload(); };

    vm.editReload = function () {
      vm.loadover = false
      $http.get(`/api/connector/navigation/config/${vm.dialogId}`).then(
        function successCallback (response) {
          if (response.data.stat) {
            vm.postdata = response.data.data
          } else {
            swal('获取信息失败', response.data.info, 'error');
          }
        },
        function errorCallback (response) {
          swal('获取信息失败', response.status, 'error');
        });
    };

    if (vm.dialogId) {
      vm.editReload();
    };

    vm.update = function () {
      vm.loadover = false
      const newData = {
        describe: vm.postdata.describe,
        url: vm.postdata.url,
        name: vm.postdata.name,
        show: String(vm.postdata.show)
      }
      if (vm.dialogId) { newData.id = vm.dialogId }
      $http.post(`/api/connector/navigation/config${vm.dialogId ? `/${vm.dialogId}` : ''}`, newData).then(
        function successCallback (response) {
          if (response.data.stat) {
            swal({ title: vm.dialogId ? '编辑成功' : '新建成功', type: 'success' });
            vm.cancel()
          } else {
            swal('获取信息失败', response.data.info, 'error');
          }
        },
        function errorCallback (response) {
          swal('获取信息失败', response.status, 'error');
        });
    };
  }
})();
