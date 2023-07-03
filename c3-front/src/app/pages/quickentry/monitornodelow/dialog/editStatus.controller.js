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

  function EditStatusController ($uibModalInstance, $window, $state, $http, $scope, $injector, treeService, treeid, selectResDetail) {

    var vm = this;
    vm.treeid = treeid;
    vm.selectResDetail = selectResDetail;
    var toastr = toastr || $injector.get('toastr');
    vm.postdata = {
      status: '',
      remark: ''
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
      });
    }
  }
})();
