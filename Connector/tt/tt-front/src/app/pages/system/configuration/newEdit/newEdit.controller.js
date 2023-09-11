(function () {
  'use strict';
  angular
    .module('cmdb')
    .controller('NewEditController', NewEditController);
  /** @ngInject */
  function NewEditController ($uibModalInstance, $uibModal, $http, $window, baseService, FileUploader, types, toastr, itemDetail, reload) {
    var vm = this;

    vm.types = types;
    vm.itemDetail = itemDetail;

    vm.cancel = function () { $uibModalInstance.dismiss(); };
    var swal = $window.swal;
    vm.ticket = {
      impact: 5
    };
    if (itemDetail.impact) {
      vm.ticket = itemDetail
    }
    vm.cti_search_w = '';
    vm.item_groups = []; // 选择的item对应的group

    // file uploader
    vm.uploader = new FileUploader({
      queueLimit: 5,
      alias: 'upload'
    });
    vm.uploader.filters.push({
      name: 'sizeFilter',
      fn: function (item) {
        return item.size <= 1024 * 1024 * 5;
      }
    });

    baseService.getData().then(function (data) {
      vm.baseData = data;
      vm.item_groups = vm.baseData.group;
    });


    // group 转map格式
    vm.group_arr_to_map = function () {
      vm.group_map = {};
      var groups = [];
      angular.copy(vm.baseData.group, groups);
      angular.forEach(groups, function (g) {
        vm.group_map[g.id] = g;
      });
    };

    // item change
    vm.item_change = function () {

      vm.group_arr_to_map();
      var none_item_groups = {}
      angular.copy(vm.group_map, none_item_groups);

      vm.item_groups = [];

      angular.forEach(vm.baseData.item_group_map, function (m) {
        if (m.item_id == vm.ticket.item) {
          vm.group_map[m.group_id].priority = "*";
          vm.item_groups.push(vm.group_map[m.group_id]);
          delete none_item_groups[m.group_id];
        }
      });

      angular.forEach(vm.baseData.group, function (g) {
        if (g.id in none_item_groups) {
          vm.item_groups.push(g);
        }
      });

      if (vm.item_groups.length > 0) {
        vm.ticket.work_group = vm.item_groups[0].id;
      }
    };

    // group change
    vm.group_change = function () {
      delete vm.ticket.group_user;
    };

    // cti search
    vm.cti_search = function () {
      if (vm.cti_search_w.trim() != '') {
        $uibModal.open({
          templateUrl: 'app/pages/tt/new/cti_search.html',
          controller: 'CtiSearchController',
          controllerAs: 'ctisearch',
          backdrop: 'static',
          keyboard: false,
          bindToController: true,
          animation: false,
          resolve: {
            cti_search_w: function () {
              return vm.cti_search_w;
            },
            baseData: function () {
              return vm.baseData;
            },
            cti_select: function () {
              return vm.cti_select;
            }
          }
        });
      }
      vm.cti_search_w = '';
    };
    // cti select
    vm.cti_select = function (c, t, i) {
      vm.ticket.category = c;
      vm.ticket.type = t;
      vm.ticket.item = i;
      if (i != 0) {
        vm.item_change();
      }
    };

    // submit
    vm.submit = function () {
      var apiStr = ''
     if (itemDetail.impact) {
      apiStr = '/api/tt/person/update'
     } else {
      apiStr = '/api/tt/person/create'
     }
      swal({
        title: 'Submit Confirm?',
        text: "确认提交?",
        type: 'question',
        showCancelButton: true
      }).then(function () {
        $http.post(apiStr, vm.ticket).success(function (data) {
          if (data.code === 200) {
            vm.cancel();
            reload();
            toastr.success('操作成功！');
          }
        }).error(function (data) {
          toastr.error('操作失败！' + data);
        });
      })
    };

  }
})();
