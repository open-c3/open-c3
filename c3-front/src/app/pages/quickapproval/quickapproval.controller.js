(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('QuickApprovalController', QuickApprovalController);

    function QuickApprovalController($state, $http, $injector, ngTableParams, genericService, $uibModal ) {
        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        var uuid = $state.params.uuid;

        vm.inputcheckcode = '';
        vm.seftime = genericService.seftime
        vm.show = false
        vm.stat = {}
        vm.loadoverA = false;
        vm.loadoverB = false;
        vm.data = {};
  
        vm.reload = function () {
            vm.loadoverA = false;
            vm.loadoverB = false;
            $http.get('/api/job/approval/control/' + uuid).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:25}, {counts:[],data:response.data.data});
                        vm.data = response.data.data[0]
                        vm.loadoverA = true;
                    }else{
                        toastr.error("获取信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取信息失败:"+response.status)

                });

            $http.get('/api/job/approval/control/status/' + uuid).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.stat = response.data.data
                        vm.loadoverB = true;
                    }else{
                        toastr.error("获取信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取信息失败:"+response.status)

                });
 
        };

        vm.edit = function (opinion) {
          if (vm.stat.checkcode && vm.stat.opinion === 'unconfirmed') {
          if (opinion === 'agree') {
            $uibModal.open({
              templateUrl: 'app/pages/quickapproval/dialog/SecondConfirm.html',
              controller: 'SecondConfirmController',
              controllerAs: 'secondConfirm',
              backdrop: 'static',
              size: 'lg',
              keyboard: false,
              bindToController: true,
              resolve: {
                opinion: function () { return opinion },
                stat: function () { return vm.stat },
                projectName: function () {return vm.data.name || '-'},
                dialogReload: function () {return vm.reload}
              }
            })
          } else if (opinion === 'refuse') {
            swal({
              title: '是否拒绝发布线上',
              type: "warning",
              showCancelButton: true,
              confirmButtonColor: "#DD6B55",
              cancelButtonText: "取消",
              confirmButtonText: "确定",
              closeOnConfirm: true
            }, function () {
              $http.post('/api/job/approval/control', { uuid: uuid, opinion: opinion }).success(function (data) {
                if (data.stat) {
                  vm.reload();
                } else {
                  swal({ title: '操作失败', text: data.info, type: 'error' });
                }
              });
            });
          }
          } else {
            $http.post('/api/job/approval/control', { uuid:uuid, opinion: opinion }).success(function (data) {
              if (data.stat) {
                vm.reload();
              } else {
                swal({ title: '操作失败', text: data.info, type: 'error' });
              }
            });
          }
        }

        vm.reload();

    }
})();
