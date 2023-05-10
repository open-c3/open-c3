(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('manageStepController', manageStepController);

  function manageStepController ($scope, $state, $http, $uibModal, $uibModalInstance, $timeout, $injector, treeId, editData, seq) {
    var vm = this;
    var toastr = toastr || $injector.get('toastr');
    vm.treeid = treeId;
    vm.editData = editData
    vm.cancel = function () {
      $uibModalInstance.dismiss();
    };

    vm.getPluginData = function () {
      $http.get('/api/job/bpm/manage/plugin/list').success(function (data) {
        if (data.stat) {
          $scope.allPluginOptions = data.data;
        } else {
          toastr.error("加载插件列表失败:" + data.info)
        }
      })
    };
    vm.getPluginData();

    // 获取单个插件信息
    vm.getItemsPluginChange = function () {
      $http.get(`/api/job/bpm/manage/plugin/conf/${$scope.selectedPlugin}`).success(function (data) {
        if (data.stat) {
          const inputEdit = vm.scriptTypeEditor['yaml']
          inputEdit(data.data, false)
        } else {
          toastr.error("加载凭据列表失败:" + data.info)
        }
      });
    };

    vm.editorAuto = function (data, re) {
      vm.autoEditor = ace.edit("editor");
      const autoeditor = vm.autoEditor;
      autoeditor.setTheme("ace/theme/dracula");
      autoeditor.session.setMode("ace/mode/sh");
      document.getElementById('editor').style.fontSize = '14px';
      autoeditor.setShowPrintMargin(false);
      autoeditor.setHighlightActiveLine(false);
      if (data) {
        autoeditor.setValue(data);
      }
      if (re) {
        autoeditor.setReadOnly(true)
      }
    };

    vm.scriptTypeEditor = {
      "yaml": vm.editorAuto,
    };

    vm.returnSave = function () {
      let conf = '';
      if (!vm.autoEditor) {
        swal({ title: "数据不全", type: 'error' });
        return;
      };
      conf = vm.autoEditor.getValue();
      conf.replace(/\r\n/g, "\n");
      if (!$scope.selectedPlugin) {
        swal({
          title: "流程名称为空",
          type: 'error'
        });
      } else if (conf === '') {
        swal({
          title: "请输入流程内容",
          type: 'error'
        });
      } else {
        const post_data = {
          conf,
          name: $scope.selectedPlugin,
          type: `${seq}.${$scope.selectedPlugin}.yaml`
        };
        $uibModalInstance.close(
          post_data
        );
      };
    };

    if (editData) {
      $scope.selectedPlugin = editData.name;
      setTimeout(() => {
        const inputEdit = vm.scriptTypeEditor['yaml']
        inputEdit(editData.conf, false)
      }, 1000);
    };

    $timeout(vm.editorSh, 500, true, "", false);
  }
})();
