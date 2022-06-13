(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonreportController', MonreportController);

    function MonreportController($scope, $state, $http, treeService, ngTableParams, $injector, $timeout, genericService) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.selecteddata = $state.params.data;
        if( vm.selecteddata == undefined )
        {
            vm.selecteddata = 'current'
        }

        var toastr = toastr || $injector.get('toastr');

        vm.taskdatetime = [];
        vm.treeid = $state.params.treeid;
        vm.state = $state;
        vm.updatetime;

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.filter = function ( datalist ) {
            $state.go('home.monreportfilterdata', {treeid:vm.treeid, data: datalist});
        }

        $scope.choiceData = vm.selecteddata;
        $scope.$watch('choiceData', function () {
                vm.filter( $scope.choiceData )
        });

        vm.reload = function () {
            $http.get('/api/ci/monreport/' + vm.treeid + "/datalist?" ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.datalist = response.data.data; 
                    }else {
                        toastr.error( "获取数据失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取数据失败: " + response.status )
                });

            $http.get('/api/ci/monreport/' + vm.treeid + "/report?data=" + vm.selecteddata ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.count1 = response.data.data.count1;
                        $scope.count2 = response.data.data.count2;
                        $scope.count3 = response.data.data.count3;
                        $scope.count4 = response.data.data.count4;

                        vm.showRuntime2(response.data.data.pingtu1);
                        vm.showRuntime3(response.data.data.pingtu2);
                        vm.showRuntime6(response.data.data.pingtu3);
                        vm.showRuntime7(response.data.data.pingtu4);
                        vm.data_Table = new ngTableParams({count:1000}, {counts:[],data:response.data.data.detailtable.reverse()});

                        vm.taskdatetime = [];

                        vm.updatetime = response.data.data.updatetime;

                        vm.changedata1 = [];
                        vm.changedata2 = [];
                        vm.changedata3 = [];
                        vm.changedata4 = [];
                        angular.forEach(response.data.data.change, function (oneday, index) {
                            vm.taskdatetime.push(oneday[0]);
                            vm.changedata1.push(oneday[1]);
                            vm.changedata2.push(oneday[2]);
                            vm.changedata3.push(oneday[3]);
                            vm.changedata4.push(oneday[4]);
                        });

                        vm.show30Task(vm.taskdatetime, vm.changedata1,vm.changedata2,vm.changedata3,vm.changedata4)
                    }else {
                        toastr.error( "获取数据失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取数据失败: " + response.status )
                });
        };

        vm.reload();

        vm.show30Task = function (datetimes, data1, data2,data3,data4) {
            
            var opt =  {
                chart: {
                    type: 'spline'
                },
                title: {
                    text: '日期分布'
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
                    name: '一级',
                    marker: {
                        symbol: 'diamond'
                    },
                    color: 'red',
                    data: data1
                }, {
                    name: '二级',
                    marker: {
                        symbol: 'square'
                    },
                    color: '#759',
                    data: data2
                }, {
                    name: '三级',
                    marker: {
                        symbol: 'square'
                    },
                    color: '#444',
                    data: data3
                }, {
                    name: '四级',
                    marker: {
                        symbol: 'square'
                    },
                    color: '#888',
                    data: data4
                } ]
            };
            Highcharts.chart('container', opt );
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

        vm.showRuntime6 = function (times) {
            $('#container6').highcharts({
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
        vm.showRuntime7 = function (times) {
            $('#container7').highcharts({
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
