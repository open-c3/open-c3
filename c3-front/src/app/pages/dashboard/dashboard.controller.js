(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DashboardController', DashboardController);

    function DashboardController($scope, $state, $http, treeService, ngTableParams, $injector, $timeout, genericService) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        var toastr = toastr || $injector.get('toastr');

        if( vm.treeid < 0 )
        {
            //var defaulttreeid = 0
            //var demotreeid = 0
            $http.get( '/api/connector/connectorx/treemap' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        //angular.forEach(response.data.data, function (d, index) {
                        //
                        //    var re=/_demo$/;
                        //    if(re.test(d.name))
                        //    {
                        //        if( d.id > demotreeid )
                        //        {
                        //            demotreeid = d.id
                        //        }
                        //    }
                        //    if( d.id > defaulttreeid )
                        //    {
                        //        defaulttreeid = d.id
                        //    }
                        //});

                        //if( demotreeid )
                        //{
                        //    defaulttreeid = demotreeid
                        //}
                        //if( defaulttreeid )
                        //{
                        //    $state.go('home.dashboard', {treeid: defaulttreeid});
                        //}
                        //else
                        //{
                        //    toastr.error( "没找到默认的服务树节点" )
                        //}
                        $state.go('home.dashboard', {treeid: 4000000000});
                    }else {
                        toastr.error( "获取服务树失败:" + response.data.info )
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取服务树失败:" + response.status )
                });
            return;
        }

        vm.taskdatetime = [];
        vm.seftime = genericService.seftime
        vm.statuszh = { "": "Init", "success": "Success", "fail": "Fail", "decision": "Fail", "running": "Running", "ignore": "Ignore", "waiting": "Waiting" }
        vm.tasksuccess = [];
        vm.taskall = [];
        vm.runminites = [];
        vm.treeid = $state.params.treeid;
        vm.state = $state;

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.getDetailData = function () {
            $http.get('/api/job/nodeinfo/' + vm.treeid + "/count" ).then(
                function successCallback(response) {

                    if (response.data.stat){
                        $scope.businessCount = response.data.data.node;
                    }else {
                        toastr.error( "获取机器数量失败:" + response.data.info )
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取机器数量失败:" + response.status )
                });
            $http.get('/api/job/jobs/' + vm.treeid + "/count" ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.commonCount = response.data.data.permanent;
                    }else {
                        toastr.error( "获取作业数量失败:" + response.data.info )
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取作业数量失败:" + response.status )
                });
            $http.get('/api/job/task/' + vm.treeid + "/count" ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.fail = response.data.data.fail;
                        $scope.success = response.data.data.success;
                        $scope.running = response.data.data.running;
                        $scope.monthTask = $scope.fail+$scope.success+$scope.running
                    }else {
                        toastr.error( "获取作业子任务数量失败:" + response.data.info )
                    }
                },
                function errorCallback (response){
                        toastr.error( "获取作业子任务数量失败:" + response.data.info )
                });
            $http.get('/api/job/crontab/' + vm.treeid + "/count" ).then(
                function successCallback(response) {

                    if (response.data.stat){
                        $scope.unavailable = response.data.data.unavailable;
                        $scope.available = response.data.data.available;
                        $scope.crontCount = $scope.unavailable + $scope.available;
                    }else {
                        toastr.error( "获取定时任务数量失败:" + response.data.info )
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取定时任务数量失败:" + response.status )
                });
        };

        vm.get30Task = function () {
            $http.get('/api/job/task/' + vm.treeid + "/analysis/date" ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.all30task = response.data.data;
                        angular.forEach(vm.all30task, function (oneday, index) {
                            vm.taskdatetime.push(oneday[0]);
                            vm.taskall.push(oneday[1]);
                            vm.tasksuccess.push(oneday[2]);
                        });
                        vm.show30Task(vm.taskdatetime, vm.tasksuccess,vm.taskall)
                    }else {
                        toastr.error( "获取作业信息失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取作业信息失败: " + response.status )
                });
        };

        vm.getLastTask = function () {
            $http.get('/api/job/task/' + vm.treeid + "/analysis/last" ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.data_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data});
                    }else {
                        toastr.error( "获取作业信息失败："+response.data.info )
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取作业信息失败: " + response.status )
                });
        };

        vm.get30Runtime = function () {
            $http.get('/api/job/task/' + vm.treeid + "/analysis/runtime" ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.allruntime = response.data.data;
                        angular.forEach(vm.allruntime, function (value, key) {
                            if(key == "0-1"){
                                vm.runminites.push(['0-1Min', parseFloat(value)])
                            }else if(key == "1-3"){
                                vm.runminites.push(['1-3Min', parseFloat(value)])
                            }
                            else if(key == "3-5"){
                                vm.runminites.push(['3-5Min', parseFloat(value)])
                            }
                            else if(key == "5-10"){
                                vm.runminites.push(['5-10Min', parseFloat(value)])
                            }
                            else if(key == "10-30"){
                                vm.runminites.push(['10-30Min', parseFloat(value)])
                            }
                            else if(key == "30+"){
                                vm.runminites.push(['30+Min', parseFloat(value)])
                            }

                        }); 
                            vm.showRuntime(vm.runminites);
                    }else {
                        toastr.error( "获取作业信息失败："+response.data.info )
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取作业信息失败: " + response.status )
                });
        };

        vm.getDetailData();
        vm.get30Runtime();
        vm.get30Task();
        vm.getLastTask();

        vm.ciinfo = {}
        vm.getCiInfo = function () {
            $http.get('/api/ci/group/' + vm.treeid).success(function(data){
                if(data.stat)
                {
                    angular.forEach(data.data, function (value, key) {
                        vm.ciinfo['_ci_'+value.id+'_'] = value.name
                    });
                }
                else
                {
                    toastr.error( "加载流水线名称失败:" + data.info )
                }
            });
        }
        vm.getCiInfo();

        vm.show30Task = function (datetimes, okcounts, allcounts) {
            var charts = Highcharts.chart('container', {
                chart: {
                    type: 'spline'
                },
                title: {
                    text: ''
                },
                subtitle: {
                    text: ''
                },
                xAxis: {
                    categories: datetimes
                },
                yAxis: {
                    title: {
                        text: ''
                    },
                    labels: {
                        formatter: function () {
                            return this.value ;
                        }
                    }
                },
                tooltip: {
                    crosshairs: true,
                    shared: true
                },
                plotOptions: {
                    spline: {
                        marker: {
                            radius: 4,
                            lineColor: '#666666',
                            lineWidth: 1
                        }
                    }
                },
                series: [{
                    name: 'Success',
                    marker: {
                        symbol: 'square'
                    },
                    data: okcounts
                }, {
                    name: 'Total',
                    marker: {
                        symbol: 'diamond'
                    },
                    data: allcounts
                }],
            });
            let oldmarginLeft = angular.element('#content_wrapper').css("marginLeft")
            window.addEventListener('click', function() {
              if (oldmarginLeft !== angular.element('#content_wrapper').css("marginLeft")) {
                charts.setSize(angular.element('#container').css('width').split('px')[0])
                oldmarginLeft = angular.element('#content_wrapper').css("marginLeft")
              }
            })
        };

        vm.showRuntime = function (times) {
          var charts = Highcharts.chart('container2', {
                chart: {
                    plotBackgroundColor: null,
                    plotBorderWidth: null,
                    plotShadow: false
                },
                title: {
                    text: ''
                },
                tooltip: {
                    headerFormat: '{series.name}<br>',
                    pointFormat: '{point.name}: <b>{point.percentage:.1f}%</b>'
                },
                plotOptions: {
                    pie: {
                        allowPointSelect: true,
                        cursor: 'pointer',
                        dataLabels: {
                            enabled: true,
                            format: '<b>{point.name}</b>: {point.percentage:.1f} %',
                            style: {
                                color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                            }
                        }
                    }
                },
                series: [{
                    type: 'pie',
                    name: '',
                    data: times
                }]
            });

            let oldmarginLeft = angular.element('#content_wrapper').css("marginLeft")
            window.addEventListener('click', function() {
              if (oldmarginLeft !== angular.element('#content_wrapper').css("marginLeft")) {
                charts.setSize(angular.element('#container2').css('width').split('px')[0])
                oldmarginLeft = angular.element('#content_wrapper').css("marginLeft")
              }
            })
        };

    }

})();
