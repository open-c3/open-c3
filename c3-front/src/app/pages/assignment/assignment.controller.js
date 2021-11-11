(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AssignmentController', AssignmentController);

    function AssignmentController($http, ngTableParams, $uibModal, genericService) {
        var vm = this;
        vm.seftime = genericService.seftime
        vm.edit = function(id,show){
            $uibModal.open({
                templateUrl: 'app/pages/assignment/edit/edit.html',
                controller: 'AssignmentEditController',
                controllerAs: 'assignmentedit',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    uuid : function () { return 0},
                    id : function () { return id},
                    show : function () { return show},
                    homereload : function () { return vm.reloadB},
                }
            });
        };

        vm.reloadA = function () {
            vm.loadoverA = false;
            $http.get('/api/ci/assignment/byme').success(function(data){
                if (data.stat){
                    vm.bymeTable = new ngTableParams({count:10}, {counts:[],data:data.data});
                    vm.loadoverA = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };

        vm.reloadB = function () {
            vm.loadoverB = false;
            $http.get('/api/ci/assignment/tome').success(function(data){
                if (data.stat){
                    vm.tomeTable = new ngTableParams({count:10}, {counts:[],data:data.data});
                    vm.loadoverB = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });

        };

        vm.reloadA();
        vm.reloadB();

        vm.commit = function (commitdata, oldstatus) {
            $http.get('/api/ci/assignment/' + commitdata.id ).success(function(data){
                if (data.stat){
                    if(  data.data.status === oldstatus )
                    {
                        $http.post(commitdata.url, commitdata.data ).success(function(data){
                            if (data.stat){
                                vm.updateStatus( commitdata.id, 'success');
                            }else {
                                vm.updateStatus( commitdata.id, 'fail');
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

        vm.updateStatus = function (id, stat) {
            $http.post('/api/ci/assignment/' + id, { "status": stat} ).success(function(data){
                if (data.stat){
                    if( stat === 'cancel' )
                    {
                        vm.reloadA();
                    }
                    else
                    {
                        vm.reloadB();
                    }
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });

        };

    }
})();
