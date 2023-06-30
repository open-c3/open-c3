(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('VirtualTreeController', VirtualTreeController);

  /** @ngInject */
  function VirtualTreeController ($scope, $http, $injector, $uibModalInstance, ngTableParams, type, tabId, dialogData,reload, dialogSelectData) {
    var vm = this;
    vm.type = type
    vm.tabId = tabId;
    vm.dialogData = dialogData;
    vm.dialogSelectData = dialogSelectData;
    var toastr = toastr || $injector.get('toastr');
    vm.pageSizeArr = [10, 20, 30, 50, 100];
    vm.nodecount = 0;
    $scope.selectedData = [];
    vm.checkDataList = [];
    vm.typeTitle = {
      add: '添加',
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
        add: [],
        delete: []
      }
      angular.forEach(vm.checkboxes.items, function (key, value) {
        if (key) typeSelectData[vm.type].push(value)
      });
      vm.machineCheckOperate(vm.type, { name: typeSelectData[vm.type].join(',') });
    }

    // 获取机器列表
    vm.getTabledata = function () {
      $scope.selectedData = Object.keys(vm.dialogSelectData)
      const params = {
        add: vm.dialogData.filter(item => !$scope.selectedData.find(cItem => cItem === item.name)),
        delete: vm.dialogData.filter(item => $scope.selectedData.find(cItem => cItem === item.name)),
      }
      const newData = params[type];
      vm.nodecount = newData.length;
      vm.checkDataList = newData;
      vm.machineTableList = new ngTableParams({ count: 10 }, { counts: vm.pageSizeArr, data: newData.reverse() });
    };

    vm.getTabledata();

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
        if (type === 'add') {
          $http.post(`/api/connector/vnode/${vm.tabId}`, params).success(function (data) {
            vm.cancel();
            if (data.stat !== true) {
              swal({ title: "操作失败!", text: data.info, type: 'error' });
            }else {
              reload()
            }
          })
        } else {
          $http.delete(`/api/connector/vnode/${vm.tabId}`, { params }).success(function (data) {
            vm.cancel();
            if (data.stat !== true) {
              swal({ title: "操作失败!", text: data.info, type: 'error' });
            }else {
              reload()
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
