(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MachineController', MachineController);

    function MachineController($state, $http, $uibModal, $scope, ngTableParams, resoureceService, $injector) {

        var vm = this;

        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.createuser = data.email;
            });
        };

        $('#createstart').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createStart = result;
            $scope.$apply();
        });

        vm.Reset = function () {
            vm.name = "";
            vm.createuser = "";
            vm.createStart = "";
            vm.createEnd = "";
            vm.inip = "";
            vm.exip = "";
            vm.reload();
        };

        $('#createend').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createEnd= result;
            $scope.$apply();
        });

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.name){
                get_data.name=vm.name
            }
            if(vm.createuser){
                get_data.create_user=vm.createuser
            }
            if(vm.createStart){
                get_data.create_time_start=vm.createStart
            }
            if(vm.createEnd){
                get_data.create_time_end=vm.createEnd
            }
            if(vm.inip){
                get_data.inip = vm.inip
            }
            if(vm.exip){
                get_data.exip = vm.exip
            }

            $http({
                method:'GET',
                url:'/api/job/nodelist/' + vm.treeid,
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        vm.user_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                    }else {
                        toastr.error( "获取搜索信息失败:" + response.data.info )
                    }
                },
                function errorCallback(response) {
                    toastr.error( "获取搜索信息失败:" + response.status )
                }
            );

        };

        vm.createMachine = function () {
            $http.post('/api/job/nodelist/'+ vm.treeid, {'name': $scope.newMachine}).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.newMachine = '';
                        vm.reload();
                    }else {
                        toastr.error( "添加失败:" + response.data.info )
                    }
                },
                function errorCallback (response ){
                    toastr.error( "添加失败:" + response.status )
                }
            );
        };

        vm.delete = function(id){
            resoureceService.machine.delMachine([vm.treeid,id],null, null).finally(function(){
                vm.reload();
            });
        };

        vm.reload();
    }

})();
