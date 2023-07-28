(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AllalertsController', AllalertsController);

    function AllalertsController($http, ngTableParams, $uibModal, genericService) {
        var vm = this;
        vm.seftime = genericService.seftime

        vm.siteaddr = window.location.protocol + '//' + window.location.host;
        vm.checknewstatus=false;
        vm.defaultData = []
        vm.reload = function () {
            vm.reloadA();
            vm.reloadB();
            vm.reloadC();
        };
        vm.reloadA = function () {
            vm.loadAover = false;
            $http.get('/api/agent/monitor/alert/0?siteaddr=' + vm.siteaddr).success(function(data){
                if (data.stat){
                    vm.defaultData = data.data;
                    const unCheckedData = data.data.filter(item => item.status.state !== 'suppressed')
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:unCheckedData});
                    vm.loadAover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };

        vm.tottbind = {};
        vm.reloadB = function () {
            vm.loadBover = false;
            $http.get('/api/agent/monitor/alert/tottbind/0').success(function(data){
                if (data.stat){
                    vm.tottbind = data.data;
                    vm.loadBover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };

        vm.dealinfo = {};
        vm.reloadC = function () {
            vm.loadCover = false;
            $http.get('/api/agent/monitor/ack/deal/info').success(function(data){
                if (data.stat){
                    vm.dealinfo = data.data;
                    vm.loadCover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };
 
        vm.reload();

        vm.getinstancename = function( labels ) {
            var name = labels['instance'];

            if( labels['instanceid'] )
            {
                name = labels['instanceid'];
            }

            if( labels['cache_cluster_id'] )
            {
                name = labels['cache_cluster_id'];
            }

            if( labels['dbinstance_identifier'] )
            {
                name = labels['dbinstance_identifier'];
            }

            return name;
        };

        vm.loadover = true;
        vm.tott = function(d){
            swal({
                title: "提交工单",
                text: '监控告警转工单',
                type: "info",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true

            }, function(){
                vm.loadover = false;
                $http.post("/api/agent/monitor/alert/tott/0", d  ).success(function(data){
                    if(data.stat == true)
                    {
                       vm.loadover = true;
                       vm.reload();
                       swal({ title:'提交成功', text: data.info, type:'success' });
                    } else {
                       swal({ title:'提交失败', text: data.info, type:'error' });
                    }
                });

            });
        };

        vm.openTT = function (uuid, caseuuid) {
            vm.loadover = false;
            $http.get('/api/agent/monitor/alert/gotocase/0?uuid=' + uuid + '&caseuuid=' + caseuuid ).success(function(data){
                if (data.stat){
                    vm.loadover = true;
                    window.open(data.data, '_blank')
                }else {
                    swal({ title:'获取工单地址失败', text: data.info, type:'error' });
                }
            });
        };
 
        vm.openOneTab = function (url) {
            window.open(url, '_blank')
        };

        // 保存新状态
        vm.handleSaveStatusChange = function () {
          const selectData = JSON.parse(JSON.stringify(vm.defaultData))
          if (vm.checknewstatus) {
            const checkedData = selectData.filter(item => item)
            vm.dataTable = new ngTableParams({count:25}, {counts:[],data:checkedData});
          } else {
            const unCheckedData = selectData.filter(item => item.status.state !== 'suppressed')
            vm.dataTable = new ngTableParams({count:25}, {counts:[],data:unCheckedData});
          }
        }
    }
})();
