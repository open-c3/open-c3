(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('FlowreportController', FlowreportController);

    function FlowreportController($scope, $state, $http, treeService, ngTableParams, $injector, $timeout, genericService) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.selecteduser = $state.params.user;
        if( vm.selecteduser == undefined )
        {
            vm.selecteduser = ''
        }

        vm.selecteddata = $state.params.data;
        if( vm.selecteddata == undefined )
        {
            vm.selecteddata = 'current'
        }


        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        var toastr = toastr || $injector.get('toastr');

        vm.userlist = [];
        vm.taskdatetime = [];
        vm.rollbackcount = [];
        vm.deploycount = [];
        vm.cicount = [];
        vm.testcount = [];
        vm.treeid = $state.params.treeid;
        vm.state = $state;
        vm.updatetime;

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.filteruser = function (username, datalist ) {
            $state.go('home.flowreportfilterdata', {treeid:vm.treeid, user: username, data: datalist});
        }

        $scope.choiceName = vm.selecteduser;
        $scope.choiceData = vm.selecteddata;
        $scope.$watch('choiceName', function () {
                vm.filteruser( $scope.choiceName, $scope.choiceData )
        });


        $scope.$watch('choiceData', function () {
                vm.filteruser( $scope.choiceName, $scope.choiceData )
        });

 
        vm.reload = function () {
            $http.get('/api/ci/flowreport/' + vm.treeid + "/datalist?" ).then(
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

            $http.get('/api/ci/flowreport/' + vm.treeid + "/report?user=" + vm.selecteduser + "&data=" + vm.selecteddata ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.ciCount = response.data.data.cicount;
                        $scope.testCount = response.data.data.testcount;
                        $scope.deployCount = response.data.data.deploycount;
                        $scope.rollbackCount = response.data.data.rollbackcount;
                        $scope.commitCount = response.data.data.commitcount;
                        vm.userlist = response.data.data.userlist; 

                        vm.data_Table = new ngTableParams({count:1000}, {counts:[],data:response.data.data.detailtable.reverse()});

                        vm.taskdatetime = [];
                        vm.cicount = [];
                        vm.testcount = [];
                        vm.deploycount = [];
                        vm.rollbackcount = [];

                        vm.updatetime = response.data.data.updatetime;

                        angular.forEach(response.data.data.change, function (oneday, index) {
                            vm.taskdatetime.push(oneday[0]);
                            vm.cicount.push(oneday[1]);
                            vm.testcount.push(oneday[2]);
                            vm.deploycount.push(oneday[3]);
                            vm.rollbackcount.push(oneday[4]);
                        });

                        vm.show30Task(vm.taskdatetime, vm.cicount, vm.testcount, vm.rollbackcount, vm.deploycount )
                    }else {
                        toastr.error( "获取数据失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取数据失败: " + response.status )
                });
        };

        vm.reload();

        vm.show30Task = function (datetimes, cicounts, testcounts, rollbackcounts, deploycounts) {
            
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
                series: [ {
                    name: '构建',
                    marker: {
                        symbol: 'diamond'
                    },
                    color: 'blue',
                    data: cicounts
                }, {
                    name: '测试',
                    marker: {
                        symbol: 'diamond'
                    },
                    color: 'gray',
                    data: testcounts
                }, {
                    name: '发布',
                    marker: {
                        symbol: 'diamond'
                    },
                    color: 'green',
                    data: deploycounts
                }, {
                    name: '回滚',
                    marker: {
                        symbol: 'square'
                    },
                    color: 'red',
                    data: rollbackcounts
                }]
            };
            Highcharts.chart('container', opt );
        };


    }

})();
