(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('ResourceDetailController', ResourceDetailController)
    .filter('cut30', function () {
      return function (text) {
        if (text.length > 33) {
          return "..." + text.substr(text.length - 30)
        }
        return text;

      }
    });

  function ResourceDetailController ($uibModalInstance, $http, type, treeid, subtype, selectedtimemachine, uuid, config, $sce) {

    var vm = this;
    vm.treeid = treeid;
    vm.type = type;
    vm.subtype = subtype;
    vm.config = config;
    vm.uuid = uuid;
    vm.modalTitle = 'C3T.'+ vm.config['name']
    vm.selectedtimemachine = selectedtimemachine

    vm.cancel = function () { $uibModalInstance.dismiss() };

    vm.showDataText = function(htmlText) {
      var rawHtml = `<div>${htmlText}</div>`
      return $sce.trustAsHtml(rawHtml);
    };

    // 请求资源列表返回的接口
    vm.getData = function () {
      $http.post(`/api/agent/device/detail/${vm.type}/${vm.subtype}/${vm.treeid}/${vm.uuid}?timemachine=${vm.selectedtimemachine}`, { 'exturl': vm.config['url'] }).success(function (data) {
        if (data.stat) {
          $http.get(data.data).success(function (data) {
            if (data.stat) {
              if (typeof data.data === 'string') {
                vm.showData = data.data
              }else {
                vm.showData = JSON.stringify(data.data)
              }
            } else {
              swal({ title: '获取信息失败', text: data.info, type: 'error' });
            }
          })
        } else {
          swal({ title: '获取URL地址失败', text: data.info, type: 'error' });
        }
      });
    }

    vm.getData();
  }
})();
