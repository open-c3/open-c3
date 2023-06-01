(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('SecondConfirmController', SecondConfirmController);

  function SecondConfirmController ($http, $uibModalInstance, $injector, stat, projectName, opinion, dialogReload) {
    var vm = this;
    var toastr = toastr || $injector.get('toastr');
    vm.opinion = opinion;
    vm.stat = stat;
    vm.inputcheckout = '';
    vm.inputMessage = false
    vm.hasCodeArr = ['deploy', 'rollback'];
    vm.flowlineName = vm.hasCodeArr.includes(projectName.split('/')[0]) ? `${projectName.split('/')[1]}/${projectName.split('/')[2]}` : projectName

    vm.handleVersionCode = function (value) {
      if (!value) {
        vm.inputMessage = false
      } else {
        if (vm.stat.checkcode !== value) {
          vm.inputMessage = true
        } else {
          vm.inputMessage = false
        }
      }
    };

    vm.cancel = function () {
      $uibModalInstance.dismiss();
    };

    vm.returnSave = function () {
      $http.post('/api/job/approval/control', { uuid: vm.stat.uuid, opinion: vm.opinion }).success(function (data) {
        if (data.stat) {
          vm.cancel();
          dialogReload();
        } else {
          swal({ title: '操作失败', text: data.info, type: 'error' });
        }
      });
    };
  }
})();
