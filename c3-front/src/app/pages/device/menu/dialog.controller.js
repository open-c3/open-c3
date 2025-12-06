(function () {
  'use strict';
  angular
    .module('openc3')
    .controller('CmdbSearchDialogController', CmdbSearchDialogController);

  /** @ngInject */
  function CmdbSearchDialogController ($http, $uibModalInstance, id, reload, ngTableParams, gogogo) {

    var vm = this;
    vm.dialogId = id
    vm.search_text = ''

    vm.cancel = function () { $uibModalInstance.dismiss(); reload(); };
    vm.show = false;

    vm.searchloadover = true
    vm.search = function () {
        vm.searchloadover = false
       $http.get('/api/ci/v2/c3mc/cmdb/search?search_text=' + vm.search_text ).then(
           function successCallback(response) {
               vm.searchloadover = true
               vm.show = true;
               if (response.data.stat){
                   vm.dataTable = new ngTableParams({count:10}, {counts:[],data:response.data.data});
                   vm.loadover = true
               }else {
                   swal('获取信息失败', response.data.info, 'error' );
               }
           },
           function errorCallback (response ){
               swal('获取信息失败', response.status, 'error' );
           });
    };

    vm.gogogo = function (uuid) {
      gogogo( uuid, vm.search_text  );
      vm.cancel();
    };

  }
})();
