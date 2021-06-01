(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('GitreportController', GitreportController);

    function GitreportController($scope, $state, $http, treeService, ngTableParams, $injector, $timeout, genericService) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        var toastr = toastr || $injector.get('toastr');

        vm.taskdatetime = [];
        vm.tasksuccess = [];
        vm.taskall = [];
        vm.treeid = $state.params.treeid;
        vm.state = $state;

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.get30Task = function () {
            $http.get('/api/ci/gitreport/' + vm.treeid + "/report" ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.userCount = response.data.data.usercount;
                        $scope.codeAddCount = response.data.data.addcount;
                        $scope.codeDelCount = response.data.data.delcount;
                        $scope.commitCount = response.data.data.commitcount;

                        vm.showRuntime2(response.data.data.pingtu);
                        vm.showRuntime3(response.data.data.pingtu2);
                        vm.all30task = response.data.data.change;
                        vm.data_Table = new ngTableParams({count:1000}, {counts:[],data:response.data.data.detailtable.reverse()});
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

        vm.get30Task();

        vm.show30Task = function (datetimes, okcounts, allcounts) {
            Highcharts.chart('container', {
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
                    name: '删除(行)',
                    marker: {
                        symbol: 'square'
                    },
                    data: okcounts
                }, {
                    name: '添加(行)',
                    marker: {
                        symbol: 'diamond'
                    },
                    data: allcounts
                }]
            });

        };


        vm.showRuntime2 = function (times) {
            $('#container2').highcharts({
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
        };

        vm.showRuntime3 = function (times) {
            $('#container3').highcharts({
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
        };

    }

})();
