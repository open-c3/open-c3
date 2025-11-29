(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('SystemstatusShowlogController', SystemstatusShowlogController);

    function SystemstatusShowlogController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, $injector, treeid, reload, item ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');

        vm.postdata = item;

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        function nl2br(str) {
            return str.replace(/\n/g, '<br>');
        }
        vm.loadover = false;
        vm.reload = function(){
            vm.loadover = false;
            $http.post('/api/connector/systemstatus/log', vm.postdata ).success(function(data){
                    vm.loadover = true;
                    if(data.stat == true) {
                        document.getElementById('systemstatuslog').innerHTML = nl2br(data.data);
                    } else { swal({ title: "加载失败!", text: data.info, type:'error' }); }

            });
        };
        vm.reload();

    }
})();

