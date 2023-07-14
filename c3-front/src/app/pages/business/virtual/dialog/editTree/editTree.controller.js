(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('VirtualTreeController', VirtualTreeController);

  /** @ngInject */
  function VirtualTreeController ($scope, $http, $state, $injector, $uibModalInstance, ngTableParams, type, tabId, currentId, reload) {
    var vm = this;
    vm.treeid = $state.params.treeid;
    vm.type = type
    vm.tabId = tabId;
    vm.currentId = currentId
    vm.dialogData = [];
    vm.dialogSelectData = [];
    var toastr = toastr || $injector.get('toastr');
    vm.pageSizeArr = [10, 20, 30, 50, 100];
    vm.nodecount = 0;
    $scope.selectedData = [];
    vm.checkDataList = [];
    vm.typeTitle = {
      create: '添加',
      delete: '删除'
    }
    vm.checkboxes = {
      checked: false,
      items: {},
      itemNumber: 0
    };

    vm.cancel = function () { $uibModalInstance.dismiss(); };

    vm.confirm = function () {
      const typeSelectData = {
        create: [],
        delete: []
      }
      angular.forEach(vm.checkboxes.items, function (key, value) {
        if (key) typeSelectData[vm.type].push(value)
      });
      vm.machineCheckOperate(vm.type, { name: typeSelectData[vm.type].join(',') });
    }

    // 获取已经勾选的机器列表
    vm.getCheckVnode = function (id) {
      vm.editLoadover = false;
      $http.get(`/api/connector/vnode/${id}`).success(function (data) {
        if (data.stat) {
          vm.dialogSelectData = data.data
          $scope.selectedData = Object.keys(data.data);
          vm.getTabledata();
        } else {
          toastr.error("获取勾选主机失败：" + data.info);
        };
      });
    };

    vm.getTabledata = function () {
      vm.editLoadover = false;
      $http.get(`/api/agent/nodeinfo/${vm.treeid}`).success(function (data) {
        vm.editLoadover = true;
        if (data.stat) {
          vm.dialogData = data.data
          const params = {
            create: vm.dialogData.filter(item => !$scope.selectedData.find(cItem => cItem === item.name)),
            delete: vm.dialogData.filter(item => $scope.selectedData.find(cItem => cItem === item.name)),
          }
          const newData = params[type];
          vm.nodecount = newData.length;
          vm.checkDataList = newData;
          vm.machineTableList = new ngTableParams({ count: 10 }, { counts: vm.pageSizeArr, data: newData.reverse() });
        } else {
          vm.editLoadover = true;
          toastr.error("获取机器列表失败：" + data.info);
        };
      });
    };

    vm.getCheckVnode(vm.tabId || vm.currentId);

    // 编辑机器请求
    vm.machineCheckOperate = function (type, params) {
      if (params.name === '') {
        vm.cancel();
        return false
      }
      swal({
        title: `确认${vm.typeTitle[vm.type]}机器？`,
        text: `${vm.typeTitle[vm.type]}机器`,
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        cancelButtonText: "取消",
        confirmButtonText: "确定",
        closeOnConfirm: true
      }, function () {
        if (type === 'create') {
          $http.post(`/api/connector/vnode/${vm.tabId|| vm.currentId}`, params).success(function (data) {
            vm.cancel();
            if (data.stat === true) {
              toastr.success('操作成功');
              reload()
            }else {
              swal({ title: "操作失败!", text: data.info, type: 'error' });
            }
          })
        } else {
          $http.delete(`/api/connector/vnode/${vm.tabId|| vm.currentId}`, { params }).success(function (data) {
            vm.cancel();
            if (data.stat === true) {
              toastr.success('操作成功');
              reload()
            }else {
              swal({ title: "操作失败!", text: data.info, type: 'error' });
            }
          })
        }
      });
    }

    // 监听全选checkbox
    $scope.$watch(function () { return vm.checkboxes.checked }, function (value) {
      angular.forEach(vm.checkDataList, function (item, index, array) {
        vm.checkboxes.items[[array[index].name]] = value
      });
      vm.checkboxes.itemsNumber = Object.values(vm.checkboxes.items).filter(item => item === true).length
      let nodeList = []
      for (let key in vm.checkboxes.items) {
        nodeList.push(String(key))
      }
    }, true);

    // 监听单个列表项的checkbox
    $scope.$watch(function () { return vm.checkboxes.items }, function (value) {
      var checked = 0, unchecked = 0
      angular.forEach(vm.checkDataList, function (item, index, array) {
        checked += (vm.checkboxes.items[array[index].name]) || 0;
        unchecked += (!vm.checkboxes.items[array[index].name]) || 0;
      });
      if (vm.checkDataList.length > 0 && ((unchecked == 0) || (checked == 0))) {
        vm.checkboxes.checked = (checked == vm.checkDataList.length);
      }
      vm.checkboxes.itemsNumber = checked
      angular.element(document.getElementsByClassName("select-all")).prop("indeterminate", (checked != 0 && unchecked != 0));
    }, true);
  };
})();
