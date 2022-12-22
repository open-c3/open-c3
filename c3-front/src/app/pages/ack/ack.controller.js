(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ACKController', ACKController);

    function ACKController($state, $http, $injector, ngTableParams, genericService ) {
        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        var uuid = $state.params.uuid;

        vm.seftime = genericService.seftime
        vm.loadover = false;
        vm.acked = {};
        vm.caseinfo = {};
        vm.casedata = []
        vm.caseuuid = '';
        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/agent/monitor/ack/' + uuid).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:25}, {counts:[],data:response.data.data});
                        vm.acked = response.data.acked
                        vm.casedata = response.data.data
                        vm.caseinfo = response.data.caseinfo
                        vm.caseuuid = response.data.caseuuid
                        vm.loadover = true;
                    }else{
                        toastr.error("获取信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取信息失败:"+response.status)

                });
        };

        vm.edit = function (ctrl, type) {
            $http.post( '/api/agent/monitor/ack/' + uuid, { ctrl: ctrl, type: type} ).success(function(data){
                if (data.stat){
                    vm.reload();
                }else {
                    swal({ title: '操作失败', text: data.info, type:'error' });
                }
            });
        };

        vm.reload();

        vm.tott = function(){
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
                $http.post("/api/agent/monitor/ack/tott/" + uuid, { caseinfo: vm.caseinfo, casedata: vm.casedata, caseuuid: vm.caseuuid }  ).success(function(data){
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
    }
})();
