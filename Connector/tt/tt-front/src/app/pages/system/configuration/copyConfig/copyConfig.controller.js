(function () {
  'use strict';
  angular
    .module('cmdb')
    .controller('CopyConfigController', CopyConfigController);
  /** @ngInject */
  function CopyConfigController ($uibModalInstance, $window, $http, toastr, types, items, reload ) {
    var vm = this;

    var swal = $window.swal;
    vm.types = types
    vm.ticket = {
      template_user: items.target_user
    }
    vm.items = items
    vm.cancel = function () { $uibModalInstance.dismiss(); };

    // 提交表单
    vm.submit = function ()  {
      swal({
        title: 'Submit Confirm?',
        text: "确认提交?",
        type: 'question',
        showCancelButton: true
      }).then(function () {
        $http.post('/api/tt/person/create/by_copy', vm.ticket).success(function (data) {
          if (data.code === 200) {
            toastr.success('提交成功！');
            reload()
            vm.cancel()
          } else {
            toastr.error('操作失败！');
          }
        }).error(function (data) {
          toastr.error('操作失败！' + data);
        });
      })
 
    }
    
  }
})();
