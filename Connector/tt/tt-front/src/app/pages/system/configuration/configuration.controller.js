(function () {
  'use strict';
  angular
    .module('cmdb')
    .controller('ConfigurationController', ConfigurationController);
  /** @ngInject */
  function ConfigurationController ($state, $http, baseService, NgTableParams, adminService, $window, $uibModal, toastr) {

    var vm = this;
    var swal = $window.swal;
    vm.baseDataMap = {
      impact: {},
      category: {},
      type: {},
      item: {},
      group: {},
      group_user: {},
      item_group_map: {}
    };
    vm.createType = false
    adminService.getData().then(function (data) {
      if (!data) {
        $state.go('home.e403');
        return;
      }
    });

    baseService.getData().then(function (data) {
      vm.baseData = data;
      angular.forEach(data, function (value, key) {
        angular.forEach(value, function (cValue, cKey) {
          if (key === 'impact') {
            vm.baseDataMap[key][cValue['level']] = cValue.name
          } else if (key === 'group') {
            vm.baseDataMap[key][cValue['id']] = cValue.group_name
          } else if (key === 'group_user') {
            vm.baseDataMap[key][cValue['id']] = cValue.priority + '-' + cValue.email
          } else {
            vm.baseDataMap[key][cValue['id']] = cValue.name
          }
        })
      })
    });


    vm.tableReload = function (e) {
      if (e) {
        e.target.blur();
      }
      vm.configTable = new NgTableParams({ count: 10 }, {
        counts: [],
        dataset: []
      });
      angular.element('.loading-container').removeClass('hide');
      angular.element('.table').addClass('hide');
      $http.get('/api/tt/person/list').success(function (data) {
        if (data.code === 200) {
          vm.tableData = data.data;
          vm.createType = vm.tableData.some(function (item) { return !item.target_user })
          vm.configTable = new NgTableParams({ count: 10 }, {
            counts: [],
            dataset: data.data
          });
          vm.configTotal = data.length
          angular.element('.loading-container').addClass('hide');
          angular.element('.table').removeClass('hide');
        } else {
          toastr.error('获取数据失败！');
          angular.element('.loading-container').addClass('hide');
          angular.element('.table').removeClass('hide');
        }
      });
    }

    vm.tableReload();

    // 创建配置
    vm.handleCreate = function (type) {
        $uibModal.open({
          templateUrl: 'app/pages/system/configuration/newEdit/newEdit.html',
          controller: 'NewEditController',
          controllerAs: 'newEdit',
          backdrop: 'static',
          size: 'lg',
          keyboard: false,
          bindToController: true,
          resolve: {
            types: function () { return type === 'default' ? false : true },
            itemDetail: function () { return {} },
            reload: function () { return vm.tableReload },
          }
        })
    }

    // delete
    vm.deleteConfig = function (obj) {
      swal({
        title: 'Delete Config?',
        text: "确认删除?",
        type: 'question',
        showCancelButton: true
      }).then(function () {
        $http.delete('/api/tt/person/delete/' + obj.id).success(function (data) {
          if (data.code === 200) {
            toastr.success('删除成功！');
            vm.tableReload()
          } else {
            toastr.error('删除失败！');
          }
        });
      })
    }

    // update
    vm.updateConfig = function (obj) {
      if (vm.tableData.length) {
        $uibModal.open({
          templateUrl: 'app/pages/system/configuration/newEdit/newEdit.html',
          controller: 'NewEditController',
          controllerAs: 'newEdit',
          backdrop: 'static',
          size: 'lg',
          keyboard: false,
          bindToController: true,
          resolve: {
            types: function () { return obj.target_user ? true : false },
            itemDetail: function () { return JSON.parse(JSON.stringify(obj)) },
            reload: function () { return vm.tableReload },
          }
        })
      }
    };

    // copy
    vm.copyConfig = function (obj) {
      $uibModal.open({
        templateUrl: 'app/pages/system/configuration/copyConfig/copyConfig.html',
        controller: 'CopyConfigController',
        controllerAs: 'copyConfig',
        backdrop: 'static',
        size: 'lg',
        keyboard: false,
        bindToController: true,
        resolve: {
          types: function () { return obj.target_user ? true : false },
          items: function () { return JSON.parse(JSON.stringify(obj)) },
          reload: function () { return vm.tableReload },
        }
      })
    }

  }

})();