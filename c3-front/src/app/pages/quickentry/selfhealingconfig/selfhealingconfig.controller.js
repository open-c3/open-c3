(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('SelfHealingConfigController', SelfHealingConfigController);

    function SelfHealingConfigController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.siteaddr = window.location.protocol + '//' + window.location.host;
        vm.time = 0;

        vm.openJOBHistory = function( uuid )
        {
            var url = vm.siteaddr + '/#/history/jobdetail/0/' + uuid;
            window.open( url, '_blank')
        }

        vm.openJOBList = function(  )
        {
            var url = vm.siteaddr + '/#/business/job/0' ;
            window.open( url, '_blank')
        }

        vm.reloadConfig = function(){
            vm.loadoverConfig = false;
            $http.get('/api/agent/selfhealing/config' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeConfigTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadoverConfig = true;
                } else { 
                    toastr.error( "加载自愈套餐失败:" + data.info )
                }
            });
        };

        vm.reloadConfig();

        vm.reloadTask = function(){
            vm.loadoverTask = false;
            $http.get('/api/agent/selfhealing/task' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeTaskTable = new ngTableParams({count:15}, {counts:[],data:data.data.reverse()});
                    vm.time = data.time;
                    vm.loadoverTask = true;
                } else { 
                    toastr.error( "加载当前告警失败:" + data.info )
                }
            });
        };

        vm.reloadTask();

        vm.createConfig = function (postData, title) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/selfhealingconfig/create/config.html',
                controller: 'CreateSelfHealingConfigController',
                controllerAs: 'createSelfHealingConfig',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reloadConfig},
                    title: function(){ return title},
                    postData: function(){ return postData}
                }
            });
        };
 
        vm.deleteConfig = function(id) {
          swal({
            title: "是否要删除该自愈套餐",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/selfhealing/config/' + id ).success(function(data){
                if( ! data.stat ){ toastr.error("删除自愈套餐:" + date.info)}
                vm.reloadConfig();
            });
          });
        }

    }
})();
