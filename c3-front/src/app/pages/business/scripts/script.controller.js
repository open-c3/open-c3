(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ScriptsController', ScriptsController);

    function ScriptsController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, scriptId, $injector) {

        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        vm.treeid = $state.params.treeid;
        $('#createstart').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createStart = result;
            $scope.$apply();
        });

        $('#createend').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createEnd= result;
            $scope.$apply();
        });

        $('#editstart').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.editStart = result;
            $scope.$apply();
        });

        $('#editend').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.editEnd= result;
            $scope.$apply();
        });

        vm.delete = function(id, jobnames){
            if(jobnames){
                var msg = {"warning":"已被"+ jobnames +"作业调用"};
            }else {
                var msg = null;
            }

            resoureceService.script.delete([vm.treeid,id],null, msg).finally(function(){
                vm.reload(vm.treeid);

            });
        };

        vm.editScript = function(id){
            $http.get('/api/job/scripts/' + vm.treeid+"/"+ id).success(function(data){
                if (data.stat){
                    vm.scriptHtml(data.data, "true")
                }
            });
        };

        vm.runScript = function(id){
            scriptId.setter(id);
            $state.go('home.quickentry.cmd', {treeid:vm.treeid});

        };

        vm.createScript = function(){
            vm.scriptHtml(null, "false")

        };

        vm.scriptHtml = function(data, edit){
            $uibModal.open({
                templateUrl: 'app/components/scripts/createScript.html',
                controller: 'CreateScript',
                controllerAs: 'createS',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    reloadindex: function () { return vm.reload },
                    msg : function () {return data},
                    edit : function () {return edit},
                }
            });
        };

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.createuser = data.email;
            });
        };

        vm.Reset = function () {
            vm.createuser = "";
            vm.edituser = "";
            vm.scriptname = "";
            vm.createStart = "";
            vm.createEnd = null;
            vm.editStart = "";
            vm.editEnd = null;
            vm.reload()
        };

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.scriptname){
                get_data.name=vm.scriptname
            }
            if(vm.createuser){
                get_data.create_user=vm.createuser
            }
            if(vm.edituser){
                get_data.edit_user=vm.edituser
            }
            if(vm.createStart){
                get_data.create_time_start=vm.createStart
            }
            if(vm.createEnd){
                get_data.create_time_end=vm.createEnd
            }
            if(vm.editStart){
                get_data.edit_time_start=vm.editStart
            }
            if(vm.editEnd){
                get_data.edit_time_end=vm.editEnd
            }
            $http({
                method:'GET',
                url:'/api/job/scripts/' + vm.treeid,
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        vm.data_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                    }else {
                        toastr.error( "获取脚本信息失败："+response.data.info )
                    }
                },
                function errorCallback(response) {
                    toastr.error( "获取脚本信息失败："+response.status )
                }
            );
        };

        vm.reload();
    }

})();
