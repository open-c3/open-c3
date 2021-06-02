(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('GitreportController', GitreportController);

    function GitreportController($scope, $state, $http, treeService, ngTableParams, $injector, $timeout, genericService) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.selecteduser = $state.params.user;
        if( vm.selecteduser == undefined )
        {
            vm.selecteduser = ''
        }

        var toastr = toastr || $injector.get('toastr');

        vm.userlist = [];
        vm.taskdatetime = [];
        vm.tasksuccess = [];
        vm.taskall = [];
        vm.treeid = $state.params.treeid;
        vm.state = $state;

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.filteruser = function (username) {
            if( username )
            {
                $state.go('home.gitreportfilteruser', {treeid:vm.treeid, user: username});
            }
            else
            {
                $state.go('home.gitreport', {treeid:vm.treeid});
            }
        }


        $scope.choiceName = vm.selecteduser;
        $scope.$watch('choiceJob', function () {
            if( vm.selecteduser != $scope.choiceJob )
            {
                vm.filteruser( $scope.choiceJob )
            }
        });

        vm.get30Task = function () {
            $http.get('/api/ci/gitreport/' + vm.treeid + "/report?user=" + vm.selecteduser ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.userCount = response.data.data.usercount;
                        $scope.codeAddCount = response.data.data.addcount;
                        $scope.codeDelCount = response.data.data.delcount;
                        $scope.commitCount = response.data.data.commitcount;
                        vm.userlist = response.data.data.userlist; 

                        vm.showRuntime2(response.data.data.pingtu);
                        vm.showRuntime3(response.data.data.pingtu2);
                        vm.data_Table = new ngTableParams({count:1000}, {counts:[],data:response.data.data.detailtable.reverse()});

                        vm.taskdatetime = [];
                        vm.tasksuccess = [];
                        vm.tasksuccess = [];

                        angular.forEach(response.data.data.change, function (oneday, index) {
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
            
            var opt =  {
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

    }

})();
