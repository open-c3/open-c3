(function () {
  'use strict';
  angular
    .module('openc3')
    .controller('NavigationController', NavigationController);

  /** @ngInject */
  function NavigationController ($state, $http, $uibModal, ngTableParams) {

    var vm = this;
    vm.treeid = $state.params.treeid;
    vm.siteaddr = `${window.location.protocol}://${window.location.host}`
    vm.iconMap = {
      bpm: '/assets/images/bpm.png',
      navigation: '/assets/images/navigation.png',
    };

    vm.showMap = {
      0: '否',
      1: '是',
    };

    vm.reload = function () {
      vm.loadover = false
      $http.get('/api/connector/navigation/config').then(
        function successCallback (response) {
          if (response.data.stat) {
            vm.dataTable = new ngTableParams({ count: 20 }, { counts: [], data: response.data.data });
            vm.loadover = true
          } else {
            swal('获取信息失败', response.data.info, 'error');
          }
        },
        function errorCallback (response) {
          swal('获取信息失败', response.status, 'error');
        });
    };

    vm.reload()

    vm.navigationOperate = function (type, id) {
      $uibModal.open({
        templateUrl: 'app/pages/global/navigation/dialog/dialog.html',
        controller: 'NavigationDialogController',
        controllerAs: 'navigationDialog',
        backdrop: 'static',
        size: 'lg',
        keyboard: false,
        bindToController: true,
        resolve: {
          id: function () { return id },
          type:function () { return type },
          reload: function () { return vm.reload }
        }
      });
    };

    vm.deleteNavigation = function (id) {
      swal({
        title: "删除导航",
        text: "删除",
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        cancelButtonText: "取消",
        confirmButtonText: "确定",
        closeOnConfirm: true
      }, function () {
        $http.delete(`/api/connector/navigation/config/${id}`).success(function (data) {
          if (data.stat == true) {
            swal({ title: "删除成功!", type: 'success' });
            vm.reload();
          } else {
            swal({ title: "删除失败!", text: data.info, type: 'error' });
          }
        });
      });
    }
  };

})();
