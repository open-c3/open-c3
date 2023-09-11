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

  function ResourceDetailController ($uibModalInstance, $http, type, treeid, subtype, config) {

    var vm = this;
    vm.treeid = treeid;
    vm.type = type;
    vm.subtype = subtype;
    vm.config = config;

    vm.cancel = function () { $uibModalInstance.dismiss() };

    // 请求资源列表返回的接口
    vm.getData = function () {
      $http.get(vm.config['url']).success(function (data) {
        if (data.stat) {
          vm.showData = data.data
        }
      })
    }

    vm.getData();
  }
})();
