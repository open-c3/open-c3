(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateSelfHealingConfigController', CreateSelfHealingConfigController);

    function CreateSelfHealingConfigController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, title) {

        var vm = this;
        vm.title = title
        vm.postData = { }
        if( postData.id )
        {
            vm.postData.id = postData.id
            vm.postData.name = postData.name
            vm.postData.altername = postData.altername
            vm.postData.jobname = postData.jobname
            vm.postData.eips = postData.eips
        }

        vm.siteaddr = window.location.protocol + '//' + window.location.host;
        vm.openJOBList = function(  )
        {
            var url = vm.siteaddr + '/#/business/job/0' ;
            window.open( url, '_blank')
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.reloadJobs = function(){
            $http.get('/api/job/jobs/0' ).success(function(data){
                if(data.stat == true) {
                    vm.Jobs = data.data
                } else { swal({ title: "加载作业列表失败!", text: data.info, type:'error' }); }
            });
        };

        vm.reloadJobs();

        vm.reloadAlerts = function(){
            $http.get('/api/agent/monitor/config/rule/0' ).success(function(data){
                if(data.stat == true) {
                    vm.Alerts = data.data
                } else { swal({ title: "加载告警列表失败!", text: data.info, type:'error' }); }
            });
        };

        vm.reloadAlerts();

        vm.add = function(){
            $http.post('/api/agent/selfhealing/config', vm.postData ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "添加自愈套餐失败!", text: data.info, type:'error' }); }
            });
        };
    }
})();

