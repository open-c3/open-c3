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
    vm.tabsLoadover = false;

    vm.tabsList = [];
    $scope.selectTab = {};
    vm.nodecount = 0;
    $scope.selectedData = [];

    // 获取虚拟服务树节点列表（Tabs选项卡）
    vm.getVirtualTreeList = function () {
      $http.get(`/api/connector/vtree/${vm.treeid}`).success(function (data) {
        if (data.stat == true) {
          vm.tabsList = data.data;
          if (!($scope.selectTab && $scope.selectTab.id)) {
            $scope.selectTab = data.data[0]
          }
        } else {
          toastr.error("加载失败:" + data.info);
        }
      });
    };

    // 获取机器列表 (Table表格)
    vm.getTabledata = function () {
      vm.tabsLoadover = false;
      $http.get(`/api/agent/nodeinfo/${vm.treeid}`).success(function (data) {
        vm.tabsLoadover = true;
        if (data.stat) {
          const newData = data.data.filter(item => $scope.selectedData.find(cItem => cItem === item.name))
          vm.nodecount = newData.length;
          vm.machineTableList = new ngTableParams({ count: 10 }, { counts: [], data: newData.reverse() });
        } else {
          toastr.error("获取机器列表失败：" + response.data.info);
        };
      });
    };

    // 获取已经勾选的机器列表
    vm.getCheckVnode = function (id) {
      vm.tabsLoadover = false;
      $http.get(`/api/connector/vnode/${id}`).success(function (data) {
        if (data.stat) {
          $scope.selectedData = Object.keys(data.data);
          vm.getTabledata();
        } else {
          toastr.error("获取勾选主机失败：" + data.info);
        };
      });
    };

    vm.reload = function () {
      vm.getVirtualTreeList();
    };

    vm.reload();

    // 创建虚拟服务树节点 (新增Tab弹窗)
    vm.createTab = function () {
      const modalInstance = $uibModal.open({
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
      modalInstance.result.then(function (result) {
        vm.handleEdit('create', result.id)
      })
    };

    // 编辑操作
    vm.handleEdit = function (type, id) {
      $uibModal.open({
        templateUrl: 'app/pages/business/virtual/dialog/editTree/editTree.html',
        controller: 'VirtualTreeController',
        controllerAs: 'editVirtual',
        backdrop: 'static',
        size: 'lg',
        keyboard: false,
        bindToController: true,
        resolve: {
          type: function () { return type },
          reload: function () { return vm.reload },
          tabId: function () { return id || '' },
          currentId: function () { return $scope.selectTab.id || '' },
        }
      });
    }

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

    $scope.$watch('selectTab', function () {
      if ($scope.selectTab && $scope.selectTab.id) {
        vm.getCheckVnode($scope.selectTab.id);
      }
    })
  };
})();
