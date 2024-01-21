(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceDataRemarksController', DeviceDataRemarksController)
        .filter('cut30', function () {
            return function (text) {
                if( text.length > 33 )
                {
                    return "..." + text.substr(text.length - 30)
                }
                return text;

            }
        });

    function DeviceDataRemarksController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, uuid, $scope, $injector, treeid , type, subtype, homereload, selectedtimemachine ) {

        var vm = this;

        vm.treeid = treeid;
        vm.type = type;
        vm.subtype = subtype;
        vm.uuid = uuid;

        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        vm.data = "";

        vm.name = 'remarks'
        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/device/extcol/' + type + '/' + subtype +'/' + uuid + '/' + vm.name ).success(function(data){
              if(data.stat == true) 
                { 
                    vm.data = data.data;
                    vm.loadover = true;
                } else { 
                    toastr.error("加载数据失败:" + data.info)
                }
            });
        };

        vm.saveextcol = function(){
            $http.post('/api/agent/device/extcol/' + type + '/' + subtype +'/' + vm.uuid + '/' + vm.name, { "data": vm.data } ).success(function(data){
                if(data.stat == true) 
                { 
                    toastr.success("操作完成");
                    vm.cancel();
                    //homereload();
                } else { 
                    toastr.error("操作失败:" + data.info)
                }
            });
        };
 
        vm.reload();
    }
})();
