(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AssignmentEditController', AssignmentEditController);

    function AssignmentEditController($uibModalInstance, $http, uuid, genericService, $injector,ngTableParams,homereload,show,id) {

        var vm = this;
        vm.show = show
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.seftime = genericService.seftime
        vm.loadover = false;
        vm.data = {}
        var toastr = toastr || $injector.get('toastr');
        vm.reload = function () {
            $http.get('/api/ci/assignment/' + id).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.data = response.data.data
                        vm.loadover = true
                    }else{
                        toastr.error("获取信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取信息失败:"+response.status)

                });
        };

        vm.reload();

        vm.commit = function () {
            $http.get('/api/ci/assignment/' + vm.data.id ).success(function(data){
                if (data.stat){
                    if(  data.data.status === 'todo' )
                    {
                        $http.post(vm.data.url, vm.data.data ).success(function(data){
                            if (data.stat){
                                vm.updateStatus('success');
                            }else {
                                vm.updateStatus('fail');
                                swal({ title:'提交失败', text: data.info, type:'error' });
                            }
                        });
                    }
                    else
                    {
                        swal({ title:'数据已经变更', text: "数据在您提交之前状态已经改变，请刷新确认。", type:'error' });
                    }
                }else {
                    swal({ title:'获取协助详情失败', text: data.info, type:'error' });
                }
            });
        };


        vm.updateStatus = function (stat) {
            $http.post('/api/ci/assignment/' + id, { "status": stat, "handle_reason": vm.data.handle_reason } ).success(function(data){
                if (data.stat){
                    homereload();
                    vm.cancel()
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });

        };




}})();
