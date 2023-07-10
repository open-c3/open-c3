(function () {
  'use strict';
  angular
    .module('openc3')
    .controller('CreateTabsController', CreateTabsController);

  /** @ngInject */
  function CreateTabsController ($http, $uibModalInstance, treeid, reload, $injector) {

    var vm = this;
    vm.treeid = treeid
    vm.postdata = { name: '' }
    var toastr = toastr || $injector.get('toastr');

    vm.cancel = function () { $uibModalInstance.dismiss(); };

    vm.create = function () {
      $http.post(`/api/connector/vtree/${vm.treeid}`, vm.postdata).success(function (data) {
        if (data.stat == true) {
          // swal({ title: '新建成功', type: 'success' });
          toastr.success('新建成功');
          $uibModalInstance.close({id: data.data})
          vm.cancel();
          reload();
        } else {
          toastr.error("加载失败:" + data.info);
        }
      });
    }
  }
})();
