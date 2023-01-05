(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('BpmController', BpmController);

    function BpmController($state, $uibModal,$http, $scope, ngTableParams,resoureceService, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.defaulttreeid = '0';
        vm.bpmuuid = $state.params.bpmuuid;
        vm.jobid = $state.params.jobid;

        vm.optionx = {};
        var toastr = toastr || $injector.get('toastr');

        $scope.jobVar = [];         // 保存作业中需要填写的变量
        $scope.choiceJob = null;    // 已选择的作业数据
        $scope.taskData = {
            'jobname':null,
            'group':null,
            'variable':{},
            'uuid':null,
        };

        vm.multitempidx = 1;
        vm.delVar = function ( index, lastvarname ) {
            var lastvarnames = lastvarname.split(".")
            for( var i = $scope.jobVar.length -1; i>=0;i--)
            {
                var names = $scope.jobVar[i].name.split(".")
                if( names[0] == lastvarnames[0] && names[1] == lastvarnames[1] )
                {
                    $scope.jobVar.splice(i , 1);
                }
            }
        };
        vm.addVar = function ( index, lastvarname ) {
            vm.multitempidx = vm.multitempidx + 1;
            var lastvarnames = lastvarname.split(".")
        
            var tempidx = 0;
            angular.forEach($scope.jobVar, function (data, idx) {
                var names = data.name.split(".")
                if( names[0] == lastvarnames[0] && names[1] == '1' )
                {
                    tempidx = tempidx + 1;
                    names[1] = vm.multitempidx;
                    var newdata = angular.copy(data);
                    newdata.name = names.join('.')
                    newdata['byaddvar'] = true;
                    $scope.jobVar.splice(index + tempidx, 0, newdata);
                }
            });
        };

        vm.bpmvar = {};
        vm.loadbpmvar = function () {
            $http.get('/api/job/bpm/var/' + vm.bpmuuid ).success(function(data){
                if (data.stat){
                    vm.bpmvar = data.data;
                    vm.reload();
                }else {
                    swal({ title:'获取表单内容失败', text: data.info, type:'error' });
                }
            });
        };
 
        vm.selectxloading = {};
        vm.selectxrely = {};

        vm.extname = function( stepname )
        {
                var stepnames = stepname.split(".")
                var prefix;
                var rawname;
                if( stepnames.length == 2 )
                {
                    prefix = stepnames[0];
                    rawname = stepnames[1];
                }
                else
                {
                    prefix = stepnames[0] + '.' + stepnames[1];
                    rawname = stepnames[2]
                }
                return [ prefix, rawname ];
        }

        vm.optionxchange = function( stepname )
        {
             var ename = vm.extname( stepname );
             angular.forEach($scope.jobVar, function (data, index) {

                 var tempename = vm.extname( data.name ); 
                 if( ename[0] == tempename[0] && data['rely'])
                 {
                    angular.forEach(data['rely'], function (name, index) {
                        if( name == ename[1] )
                        {
                            data.value= "";
                        }
                    });
                 }
            });
        }

        vm.optionxclick = function( stepname )
        {
            var varDict = {};
            var stepconf;
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
                vm.selectxrely[data.name] = false;
                if( data.name == stepname )
                {
                    stepconf = data;
                }
            });

            if( stepconf['rely'] )
            {
                
                var prefix;
                var rawname;
                var ename = vm.extname( stepname );
                prefix = ename[0];
                rawname = ename[1];

                var defect = false;
                angular.forEach(stepconf['rely'], function (data, index) {
                    var checkname = prefix +'.'+ data;
                    if( varDict[checkname] == "" )
                    {
                        vm.selectxrely[checkname] = true;
                        defect = true;
                    }
                });

                if( defect )
                {
                    vm.optionx[stepname] = [];
                    return;
                }
            }
 
            vm.selectxloading[stepname] = true;
            $http.post( '/api/job/bpm/optionx', { "bpm_variable": varDict, "stepname": stepname, "jobname":$scope.choiceJob.name } ).success(function(data){
                if (data.stat){
                    vm.selectxloading[stepname] = false;
                    vm.optionx[stepname] = data.data
                }else {
                    swal({ title: '获取选项失败', text: data.info, type:'error' });
                }
            });
 
        }

        vm.jobsloadover = true;
        vm.menu = [];
        vm.reload = function () {
            vm.jobsloadover = false;
            $http.get('/api/job/bpm/menu' ).success(function(data){
                vm.jobsloadover = true;
                if (data.stat){
                    vm.menu = data.data;
                    angular.forEach(vm.menu, function (data, index) {
                        if( data.name == vm.bpmvar._jobname_ )
                        {
                            $scope.choiceJob = data
                        }
                    });
                }else {
                    swal({ title:'获取应用地址失败', text: data.info, type:'error' });
                }
            });
        };

        vm.jobsloadover = false;
        if( vm.bpmuuid != "0" )
        {
            vm.loadbpmvar();
        }
        else
        {
            vm.reload();
        }


        vm.varsvalue = {};

        vm.runTask = function(){
            var varDict = {};
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
            });
            $scope.taskData.variable = varDict;

            resoureceService.work.runJobByName(vm.defaulttreeid, {"jobname":$scope.choiceJob.name, "bpm_variable": $scope.taskData.variable, "variable": {} })
                .then(function (repo) {
                    if (repo.stat){
                        $state.go('home.history.bpmdetail', {treeid:vm.defaulttreeid,taskuuid:repo.uuid});
                    }

                 }, function (repo) { });
        };

        vm.reSave = function(){
            var varDict = {};
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
            });
            $scope.taskData.variable = varDict;

            $http.post( '/api/job/bpm/var/' + vm.bpmuuid, { "bpm_variable": $scope.taskData.variable } ).success(function(data){
                if (data.stat){
                    swal({ title: '保存成功', type:'success' });
                }else {
                    swal({ title: '保存失败', text: data.info, type:'error' });
                }
            });
        };

        vm.choiceServer = function () {
                var openChoice = $uibModal.open({
                templateUrl: 'app/components/machine/choiceMachine.html',
                controller: 'ChoiceController',
                controllerAs: 'choice',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},

                }
            });
            openChoice.result.then(
                function (result) {
                    if (result.length != 0){
                        $scope.choiceShow = true;
                        var machineInfoNew = "";
                        angular.forEach($scope.jobVar, function (value, key) {
                            if( value.name == "ip" )
                            {
                                value.value = result.join(',');
                            }

                        });
 
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );
        };

        vm.loadover = false;
        $scope.$watch('choiceJob', function () {
            if($scope.choiceJob){
                $scope.taskData.jobname = $scope.choiceJob.name;
                $scope.taskData.group = null

                vm.optionx = {};
                vm.loadover = false;
                $http.get('/api/job/bpm/variable/' + $scope.choiceJob.name ).then(
                    function successCallback(response) {

                        if (response.data.stat){
                            vm.vartemp = [];
                            angular.forEach(response.data.data, function (value, key) {
                                if( value.value == "" )
                                {
                                    if( vm.bpmvar[value.name] != undefined )
                                    {
                                        value.value = vm.bpmvar[value.name] 
                                    }
                                     vm.vartemp.push( value )
                                }
                            });

                            if (vm.vartemp.length == 0){
                                $scope.jobVar = [];
                                $scope.taskData.variable = {};
                            }else {
                                $scope.jobVar = vm.vartemp;

                            }
                            vm.loadover = true;
                        }else {
                            toastr.error( "获取变量信息失败："+response.data.info )
                        }
                    },
                    function errorCallback (response){
                        toastr.error( "获取变量信息失败："+response.status )
                    });

            }

        }, true);
    }
})();

