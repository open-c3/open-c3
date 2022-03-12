(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorOncallOncallController', CreateMonitorOncallOncallController);

    function CreateMonitorOncallOncallController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, title) {

        var vm = this;
        vm.title = title
        vm.postData = {}
        if( postData.id )
        {
            vm.postData.id = postData.id
            vm.postData.name = postData.name
            vm.postData.description = postData.description

            $http.get('/api/agent/monitor/config/oncall/' + postData.id ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.postData = data.data
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载值班组信息失败:" + data.info )
                }
            });
 
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            $http.post('/api/agent/monitor/config/oncall', vm.postData ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }
            });
        };
    }
})();

