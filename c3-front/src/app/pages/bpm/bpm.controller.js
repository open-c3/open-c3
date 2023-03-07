(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('BpmController', BpmController);

    function BpmController($state, $uibModal,$http, $scope, ngTableParams,resoureceService, $injector, $location ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.defaulttreeid = '0';
        vm.bpmuuid = $state.params.bpmuuid;
        vm.jobid = $state.params.jobid;

        vm.optionx = {};
        var toastr = toastr || $injector.get('toastr');

        vm.bpmname = $location.search()['name'];
        $scope.jobVar = [];         // 保存作业中需要填写的变量
        $scope.choiceJob = null;    // 已选择的作业数据
        $scope.taskData = {
            'jobname':null,
            'group':null,
            'variable':{},
            'uuid':null,
        };

        vm.showfromops = '0';
        vm.fromopsdefault = '0';
        vm.vfromops = {};
        vm.fromops = function ( type ) {
            vm.fromopsdefault = type;
            angular.forEach($scope.jobVar, function (data, idx) {
                if( data.fromops == '1' )
                {
                    vm.vfromops[data.name] = type;
                }
            });
        };
        vm.selectIndex = 0
        vm.chtempclear = function ( obj ) {
            if( obj.type == "kvarray" )
            {
                obj.tempvalue = [];
                vm.chKvArray( obj );
            }
            if( obj.type == "selectxm" )
            {
                obj.tempvalue = [ { "value": "" }];
                vm.chSelectxm( obj );
            }
        };

        vm.chSelectxm = function ( obj ) {
            var temp = [];
            angular.forEach(obj['tempvalue'], function (data, idx) {
                temp.push(data.value)
            });
            obj['value'] = temp.join(',');
 
            vm.optionxchange( obj.name, obj.value )
        };

        vm.addSelectxm = function ( obj ) {
            if( obj['tempvalue'] == undefined )
            {
                obj['tempvalue'] = [];
            }
            obj['tempvalue'].push( { "value": "" } );

            var temp = [];
            angular.forEach(obj['tempvalue'], function (data, idx) {
                temp.push(data.value)
            });
            obj['value'] = temp.join(',');
        };

        vm.delSelectxm = function ( obj, index ) {
            obj['tempvalue'].splice(index , 1);
            var temp = [];
            angular.forEach(obj['tempvalue'], function (data, idx) {
                temp.push(data.value)
            });
            obj['value'] = temp.join(',');
        };

        vm.chKvArray = function ( obj ) {
            obj['value'] = angular.toJson( obj['tempvalue'] );
        };

        vm.addKvArray = function ( obj ) {
            if( obj['tempvalue'] == undefined )
            {
                obj['tempvalue'] = [];
            }
            obj['tempvalue'].push( { "key": "", "value": "" } );
            obj['value'] = angular.toJson( obj['tempvalue'] );
        };

        vm.delKvArray = function ( obj, index ) {
            obj['tempvalue'].splice(index , 1);
            obj['value'] = angular.toJson( obj['tempvalue'] );
        };

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
                if( names[0] == lastvarnames[0] && names[1] == lastvarnames[1] )
                {
                    tempidx = tempidx + 1;
                    names[1] = vm.multitempidx;
                    var newdata = angular.copy(data);
                    newdata.name = names.join('.')
                    newdata['byaddvar'] = true;
                    $scope.jobVar.splice(index + tempidx, 0, newdata);
                    if( vm.optionx[data.name] )
                    {
                        vm.optionx[newdata.name] = vm.optionx[data.name];
                    }
                    if( vm.selectxrely[data.name] != undefined )
                    {
                        vm.selectxrely[newdata.name] = vm.selectxrely[data.name];
                    }
 
                    if( vm.selectxhide[data.name] != undefined )
                    {
                        vm.selectxhide[newdata.name] = vm.selectxhide[data.name];
                    }
                }
            });
        };

        vm.bpmvar = {};
        vm.loadbpmvar = function () {
            $http.get('/api/job/bpm/var/' + vm.bpmuuid ).success(function(data){
                if (data.stat){
                    vm.bpmvar = data.data;
                    if( data.data['_sys_opt_'] )
                    {
                        vm.optionx      = data.data['_sys_opt_']['optionx'];
                        vm.selectxrely  = data.data['_sys_opt_']['selectxrely'];
                        vm.selectxhide  = data.data['_sys_opt_']['selectxhide'];
                        $scope.jobVar   = data.data['_sys_opt_']['variable'];
                        // C3TODO 230306 BPM表单的数据，存入后重新获取后，整型变成了字符串类型
                        // 这里的multitempidx存入时是一个数字，存入后重新获取，变成了一个字符串
                        // 现在通过Number进行转换，应该处理一下接口让其返回数字类型
                        vm.multitempidx = Number(data.data['_sys_opt_']['multitempidx']);
                    }
                    vm.reload();
                }else {
                    swal({ title:'获取表单内容失败', text: data.info, type:'error' });
                }
            });
        };
 
        vm.selectxloading = {};
        vm.selectxrely = {};
        vm.selectxhide = {};

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

        vm.optionxchange = function( stepname, stepvalue )
        {
             var ename = vm.extname( stepname );
             //clear
             angular.forEach($scope.jobVar, function (data, index) {

                 var tempename = vm.extname( data.name ); 
                 if( ename[0] == tempename[0] && data['rely'])
                 {
                    angular.forEach(data['rely'], function (name, index) {
                        if( name == ename[1] )
                        {
                            data.value= "";
                            vm.chtempclear(data);
                        }
                    });
                 }
            });

            //hide
            angular.forEach($scope.jobVar, function (data, index) {

                 var tempename = vm.extname( data.name ); 
                 if(data['show'] && typeof data['show'][0] === 'string')
                 {
                    if (ename[0] == tempename[0] && data['show'][0] == ename[1]) {
                     var match = false;
                     angular.forEach(data['show'], function (data, index) {
                         if( data == stepvalue && index > 0 )
                         {
                             match = true;
                         }
                     });

                     //if( data['show'][1] == stepvalue )
                     if( match )
                     {
                         vm.selectxhide[data.name] = '0';
                         data.value = "";
                     }
                     else
                     {
                         vm.selectxhide[data.name] = '1';
                         data.value = "_openc3_hide_";
                     }
                    }
                 } else if (data['show']) {
                    let itemKeysResults = []
                    let selectItem = {}
                    const dataShowItems = Object.keys(data['show'][0])
                    if(ename[0] === tempename[0] && dataShowItems.find(item => item === ename[1])){
                    angular.forEach(data['show'], function (item, index) {
                      let itemKeysResult = {select: []}
                      itemKeysResult['name'] = Object.keys(item)
                      for (let key in item) {
                        selectItem =  $scope.jobVar.filter(cItem => cItem.name.indexOf(key) > -1)[0]
                        itemKeysResult['select'].push(!!item[key].find(cItem=> cItem === selectItem.value))
                      }
                      itemKeysResults[index] = itemKeysResult
                    });
                    angular.forEach(itemKeysResults, function (item) {
                        item.match = !item.select.filter(cItem=> cItem === false).length
                    })
                    if(itemKeysResults.map(item => item.match).filter(cItem => cItem === true ).length > 0) {
                      vm.selectxhide[data.name] = '0';
                      data.value = "";
                    } else {
                      vm.selectxhide[data.name] = '1';
                      data.value = "_openc3_hide_";
                    }
                 }
                }
            });
        }

        vm.optionxclick = function( stepname , selectIndex)
        {
            vm.selectIndex = selectIndex
            var varDict = {};
            var stepconf;
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
                vm.selectxrely[data.name] = '0';
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
                        vm.selectxrely[checkname] = '1';
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
                        if( vm.bpmname && data.name == vm.bpmname )
                        {
                            $scope.choiceJob = data
                        }
                    });
                }else {
                    swal({ title:'获取BPM菜单失败', text: data.info, type:'error' });
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
            vm.multitempidx = 1;
            vm.reload();
        }


        vm.varsvalue = {};

        vm.runTask = function(){
            var varDict = {};
            angular.forEach($scope.jobVar, function (data, index) {
                varDict[data.name] = data.value;
            });
            $scope.taskData.variable = varDict;

            $scope.taskData.variable['_sys_opt_'] = {};
            $scope.taskData.variable['_sys_opt_']['optionx']      = vm.optionx;
            $scope.taskData.variable['_sys_opt_']['selectxrely']  = vm.selectxrely;
            $scope.taskData.variable['_sys_opt_']['selectxhide']  = vm.selectxhide;
            $scope.taskData.variable['_sys_opt_']['variable']     = $scope.jobVar;
            $scope.taskData.variable['_sys_opt_']['multitempidx'] = vm.multitempidx;

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

            $scope.taskData.variable['_sys_opt_'] = {};
            $scope.taskData.variable['_sys_opt_']['optionx']      = vm.optionx;
            $scope.taskData.variable['_sys_opt_']['selectxrely']  = vm.selectxrely;
            $scope.taskData.variable['_sys_opt_']['selectxhide']  = vm.selectxhide;
            $scope.taskData.variable['_sys_opt_']['variable']     = $scope.jobVar;
            $scope.taskData.variable['_sys_opt_']['multitempidx'] = vm.multitempidx;

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
            if( vm.bpmuuid != "0" )
            {
                vm.loadover = true;
                return;
            }
 
            if($scope.choiceJob){
                $scope.taskData.jobname = $scope.choiceJob.name;
                $scope.taskData.group = null

                vm.loadover = false;
                $http.get('/api/job/bpm/variable/' + $scope.choiceJob.name ).then(
                    function successCallback(response) {

                        if (response.data.stat){
                            vm.vartemp = [];
                            vm.showfromops = '0';
                            angular.forEach(response.data.data, function (value, key) {
                                if( value.name )
                                {
                                    if( value.fromops == '1' )
                                    {
                                        vm.showfromops = '1';
                                    }
                                    if( vm.bpmvar[value.name] != undefined )
                                    {
                                        value.value = vm.bpmvar[value.name] 
                                        if( value.type && value.type == "kvarray" )
                                        {
                                            value.tempvalue = angular.fromJson( value.value );
                                        }
                                        if( value.type && value.type == "selectxm" )
                                        {
                                            value.tempvalue = [];
                                            angular.forEach(value.value.split(","), function (data, idx) {
                                                value.tempvalue.push({"value": data})
                                            });
                                            if( value.tempvalue.length < 1 )
                                            {
                                                value.tempvalue.push({"value": ""})
                                            }
                                        }
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

