(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('BusinessBpmEditController', BusinessBpmEditController);

  function BusinessBpmEditController ($timeout, $state, $http, $stateParams, $uibModal, $scope, treeService, resoureceService) {
    var vm = this;
    vm.allNewStep = [];
    vm.bpmManageName = $stateParams.name;
    vm.bpmManageAlias = ''
    vm.bpmManageDescribe = ''
    vm.bpmManageType = 'diy'
    vm.treeid = $state.params.treeid;

    if (!vm.bpmManageName) {
      $state.go('home.business.bpm', { treeid: vm.treeid });
      return
    };

    vm.reload = function () {
      $http.get(`/api/job/bpm/manage/conf/${vm.bpmManageName}`).success(function (data) {
        if (data.stat) {
          const { base, step } = data.data
          vm.bpmManageAlias = base.alias
          vm.bpmManageDescribe = base.describe
          vm.allNewStep = step
        }
      })
    };
    vm.reload();

    treeService.sync.then(function () {
      vm.nodeStr = treeService.selectname(); 
    });

    vm.count = function (name) {
      let count = 0;
      for (let i = 0; i < vm.allNewStep.length; i++) {
        if (vm.allNewStep[i].name == name) {
          count = count + 1;
        }
      }
      return count;
    };

    vm.createManageStep = function (idx) {
      let count = vm.count("yaml");
      if (idx) {
        const editData = vm.allNewStep[idx];
        count = vm.count(editData.name);
      }
      const seq = count + 1;
      const openChoice = $uibModal.open({
        templateUrl: 'app/pages/business/bpm/manage/step.html',
        controller: 'manageStepController',
        controllerAs: 'manageStep',
        backdrop: 'static',
        size: 'lg',
        keyboard: false,
        bindToController: true,
        resolve: {
          treeId: function () { return vm.treeid },
          editData: function () { return "" },
          seq: function () { return seq }
        }
      });

      openChoice.result.then(
        function (result) {
          if (idx >= 0) {
            vm.allNewStep.splice(idx, 0, result);
          } else {
            vm.allNewStep.push(result);
          }
        }, function (reason) {
          console.log("createScriptJob error reason", reason)
        }
      );
    };


    vm.copyBpm = function (id) {
      const items = vm.allNewStep[id]
      const count = vm.count(items.name);
      const seq = count + 1;
      const tempdata = {
        'name': `${items.name}`,
        conf: items.conf,
        type: `${seq}.${items.name}.yaml`,
      }
      vm.allNewStep.splice(id + 1, 0, tempdata);
    };

    vm.editBpm = function (id) {
      const editData = vm.allNewStep[id];
      const openChoice = $uibModal.open({
        templateUrl: 'app/pages/business/bpm/manage/step.html',
        controller: 'manageStepController',
        controllerAs: 'manageStep',
        backdrop: 'static',
        size: 'lg',
        keyboard: false,
        bindToController: true,
        resolve: {
          treeId: function () { return vm.treeid },
          editData: function () { return editData },
          seq: function () { return 0 }
        }
      });

      openChoice.result.then(
        function (result) {
          vm.allNewStep.splice(id, 1, result);
        }, function (reason) {
          console.log("editBpm error reason", reason)
        }
      );
    };

    vm.delBpmData = function (id) {
      vm.allNewStep.splice(id, 1);
    };

    vm.saveCreateData = function () {
      if (vm.allNewStep.length > 0) {
        if (!vm.bpmManageName) {
          swal({
            title: "作业名称为空",
            type: 'error'
          });
        }
        else {
          const post_data = {
            base: {
              name: vm.bpmManageName,
              alias: vm.bpmManageAlias,
              describe: vm.bpmManageDescribe,
              type: vm.bpmManageType
            },
            step: vm.allNewStep,
          };
          swal({
            title: "确认保存流程？",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true,
          }, function () {
            $http.post(`/api/job/bpm/manage/conf/${vm.bpmManageName}`, post_data).success(function (data) {
              if (data.stat) {
                swal({ title: '保存成功', type: 'success' });
                $state.go('home.business.bpm', { treeid: vm.treeid })
              } else {
                swal({ title: '保存失败', text: data.info, type: 'error' });
              }
            })
          });
        }
      } else {
        swal({
          title: "数据不全",
          type: 'error',
        });
      }
    };

    vm.up = function (idx) {
      if (idx > 0) {
        [vm.allNewStep[idx - 1], vm.allNewStep[idx]] = [vm.allNewStep[idx], vm.allNewStep[idx - 1]]
      }
    };

    vm.down = function (idx) {
      if (idx < vm.allNewStep.length - 1) {
        [vm.allNewStep[idx + 1], vm.allNewStep[idx]] = [vm.allNewStep[idx], vm.allNewStep[idx + 1]]
      }
    };
  }

})();
