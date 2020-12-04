(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('TicketController', TicketController);

    function TicketController($state, $http, $uibModal, $scope, ngTableParams) {

        var vm = this;
        vm.createTicket = function () {
            $uibModal.open({
                templateUrl: 'app/pages/global/ticket/createTicket.html',
                controller: 'CreateTicketController',
                controllerAs: 'createticket',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    ticketid: function () {},
                    homereload: function () { return vm.reload },
                    title: function () { return '新建票据' },
                }
            });

        };

        vm.deleteTicket = function(id){
          swal({
            title: "删除票据",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){

            $http.delete( '/api/ci/ticket/' + id ).success(function(data){
                if (data.stat){
                    vm.reload();
                }else {
                    swal({ title:'删除票据列表失败', text: data.info, type:'error' });
                }
            });

          });
        };


        vm.editTicket = function(id){
            $uibModal.open({
                templateUrl: 'app/pages/global/ticket/createTicket.html',
                controller: 'CreateTicketController',
                controllerAs: 'createticket',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    ticketid: function () { return id},
                    homereload: function () { return vm.reload },
                    title: function () { return '编辑票据' },
                }
            });
        };

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/ci/ticket').success(function(data){
                if (data.stat){
                    vm.group_Table = new ngTableParams({count:25}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取票据列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

    }

})();
