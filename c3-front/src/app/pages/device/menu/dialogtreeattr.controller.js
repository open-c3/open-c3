(function () {
  'use strict';
  angular
    .module('openc3')
    .controller('CmdbSearchDialogTreeAttrController', CmdbSearchDialogTreeAttrController);

  /** @ngInject */
  function CmdbSearchDialogTreeAttrController ($http, $uibModalInstance, reloadtreeattr, ngTableParams, attrname,value, treeid, toastr) {

    var vm = this;

    vm.cancel = function () { $uibModalInstance.dismiss();  };
    vm.attrname = attrname;
    vm.value = value;
    if ( vm.value == 'unkown' )
    {
        vm.value = '';
    }

    vm.save = function () {
        $http.post('/api/connector/treeattr/' + treeid, { "name": attrname, "value": vm.value } ).success(function(data){
            if(data.stat == true)
            {
                reloadtreeattr();
                vm.cancel();
            } else {
                toastr.error("操作失败:" + data.info)
            }
        });
    };

  }
})();
