(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('VirtualController', VirtualController);

  /** @ngInject */
  function VirtualController ($scope, $state, $http, $injector, $uibModal, ngTableParams) {
    var vm = this;
    vm.treeid = $state.params.treeid;
    vm.state = $state;
    var toastr = toastr || $injector.get('toastr');

    vm.loadover = false;
    vm.tabsLoadover = false;

    vm.tabsList = [];
    $scope.selectTab = {};
    vm.nodecount = 0;
    vm.machineTableList = [];
    $scope.selectedData = [];

    // 获取虚拟服务树节点列表（Tabs选项卡）
    vm.getVirtualTreeList = function () {
      $http.get(`/api/connector/vtree/${vm.treeid}`).success(function (data) {
        if (data.stat == true) {
          vm.tabsList = data.data;
          $scope.selectTab = data.data[0];
        } else {
          toastr.error("加载失败:" + data.info);
        }
      });
    };

    // 获取机器列表 (Table表格)
    vm.getTabledata = function () {
      vm.loadover = false;
      $http.get(`/api/agent/nodeinfo/${vm.treeid}`).success(function (data) {
        if (data.stat) {
          vm.loadover = true;
          vm.nodecount = data.data.length;
          vm.machineTableList = new ngTableParams({ count: 10 }, { counts: [], data: data.data.reverse() });
        } else {
          toastr.error("获取机器列表失败：" + response.data.info);
        };
      });
    };

    // 获取已经勾选的机器列表
    vm.getCheckVnode = function (id) {
      vm.tabsLoadover = true;
      $http.get(`/api/connector/vnode/${id}`).success(function (data) {
        vm.tabsLoadover = false;
        if (data.stat) {
          $scope.selectedData = Object.keys(data.data);
        } else {
          toastr.error("获取勾选主机失败：" + data.info);
        };
      });
    };

    vm.reload = function () {
      vm.getVirtualTreeList();
      vm.getTabledata();
    };

    vm.reload();

    // 创建虚拟服务树节点 (新增Tab弹窗)
    vm.createTab = function () {
      $uibModal.open({
        templateUrl: 'app/pages/business/virtual/dialog/createTabs/createTabs.html',
        controller: 'CreateTabsController',
        controllerAs: 'createTabs',
        backdrop: 'static',
        size: 'lg',
        keyboard: false,
        bindToController: true,
        resolve: {
          treeid: function () { return vm.treeid },
          reload: function () { return vm.reload }
        }
      });
    };

    // 切换虚拟服务树节点(切换Tab)
    vm.handleTabChange = function (value) {
      $scope.selectTab = value;
    };

    // 删除虚拟服务树节点 (删除Tab)
    vm.removeTab = function (item) {
      swal({
        title: "确认删除虚拟节点？",
        text: "删除虚拟节点",
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        cancelButtonText: "取消",
        confirmButtonText: "确定",
        closeOnConfirm: true
      }, function () {
        $http.delete(`/api/connector/vtree/${vm.treeid}/${item.id}`).success(function (data) {
          if (data.stat == true) {
            swal({ title: "删除成功!", type: 'success' });
            vm.reload();
          } else {
            swal({ title: "删除失败!", text: data.info, type: 'error' });
          }
        });
      });
    };

    // 是否勾选Check
    $scope.hadleIsChecked = function (value) {
      return $scope.selectedData.indexOf(value) > -1;
    };

    // 勾选机器请求
    vm.machineCheckOperate = function (isChecked, tabId, params) {
      if (isChecked) {
        $http.post(`/api/connector/vnode/${tabId}`, params).success(function (data) {
          if (data.stat !== true) {
            swal({ title: "操作失败!", text: data.info, type: 'error' });
          }
        })
      } else {
        $http.delete(`/api/connector/vnode/${tabId}`, { params }).success(function (data) {
          if (data.stat !== true) {
            swal({ title: "操作失败!", text: data.info, type: 'error' });
          }
        })
      }
    }

    // 机器勾选操作
    $scope.nameUpdateSelection = function ($event, name) {
      const checkbox = $event.target;
      const selectId = $scope.selectTab.id;
      vm.machineCheckOperate(checkbox.checked, selectId, { name });
    };

    $scope.$watch('selectTab', function () {
      if ($scope.selectTab.id) {
        vm.getCheckVnode($scope.selectTab.id);
      }
    })
  };
})();
