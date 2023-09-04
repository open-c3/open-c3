(function () {
  'use strict';
  angular
    .module('cmdb')
    .directive('c3index', c3index);
  /** @ngInject */
  function c3index () {
    var directive = {
      restrict: 'E',
      templateUrl: 'app/components/c3index/c3index.html',
      scope: {},
      controller: c3indexController,
      controllerAs: 'c3index'
    };
    return directive;

    /** @ngInject */
    function c3indexController ($state, $http, $scope, $filter, $q, toastr) {
      if ($state.current.name == "home") {
        var vm = this;

        vm.orderStart = new Date();
        vm.orderEnd = new Date();
        vm.isFirstLoad = true;
        vm.isEndFirstLoad = true;
        vm.loading = false;
        vm.cardList = [
          {
            name: 'S.TT.create_order',
            icon: '/assets/images/tt-order-create-2x.png',
            type: 'create',
            color: '#2f875a',
            self: '/#/tt/new',
            count: 0,
          },
          {
            name: 'S.TT.user_total',
            icon: '/assets/images/tt-order-user-2x.png',
            type: 'user_count',
            color: '#3ece85',
            count: 0,
          },
          {
            name: 'S.TT.order_total',
            icon: '/assets/images/tt-order-count-2x.png',
            color: '#467CFD',
            type: 'tt_count',
            self: '/#/tt/ordertotal',
            count: 0,
          },
          {
            name: 'S.TT.todo_total',
            icon: '/assets/images/tt-order-upcoming-2x.png',
            type: 'related_group_toto_count',
            color: '#ef537b',
            self: '/#/tt/todototal',
            count: 0,
          },
          {
            name: 'S.TT.personal_todo',
            icon: '/assets/images/tt-order-personal-2x.png',
            type: 'self_todo_count',
            color: '#ff6633',
            self: '/#/tt/personaltodo',
            count: 0,
          },
        ];
        vm.countTypeMap = {
          related_group_toto_count: 0,
          self_todo_count: 0,
          tt_count: 0,
          user_count: 0,
        }

        vm.handleTimeRange = function (type) {
          var currentDate = new Date();
          if (type === 'week') {
            vm.orderStart = new Date(currentDate.setDate(currentDate.getDate() - currentDate.getDay() + 1));
            vm.orderEnd = new Date(currentDate.setDate(currentDate.getDate() - currentDate.getDay() + 7));
          } else if (type === 'month') {
            vm.orderStart = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
            vm.orderEnd = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);
          } else if (type === 'quarter') {
            var currentQuarter = Math.floor(currentDate.getMonth() / 3) + 1;
            vm.orderStart = new Date(currentDate.getFullYear(), (currentQuarter - 1) * 3, 1);
            vm.orderEnd = new Date(currentDate.getFullYear(), currentQuarter * 3, 0);
          }
        };

        //点击卡片跳转
        vm.handleJump = function (item) {
          if(item.type === 'user_count') {
            return
          }
          window.location.href = `${item.self}?start=${vm.orderStart.getTime()/ 1000 }&end=${vm.orderEnd.getTime()/1000}`
        };

        // 获取符合条件的工单数量
        vm.getInfoData = function () {
          var start = Math.trunc(vm.orderStart.getTime() / 1000)
          var end = Math.trunc((vm.orderEnd ? vm.orderEnd: new Date()).getTime() / 1000)
          return $http.get('/api/tt/statistics/work_order_summary/summary' + '?start=' + start + '&end=' + end).success(function (data) {
            if (data.code === 200) {
              vm.cardList.map(function (item) {
                item.count = data.data[item.type] || 0
                return item
              })
            } else {
              toastr.error('获取数据失败')
            }
          }).error(function (data) {
            toastr.error('获取数据失败' + data)
            console.error(data)
          })
        }

        // 获取本周工单统计
        vm.getWeekData = function () {
          var start = Math.trunc(vm.orderStart.getTime() / 1000)
          var end = Math.trunc(vm.orderEnd.getTime() / 1000)
          return $http.get('/api/tt/statistics/work_order_summary' + '?start=' + start + '&end=' + end).success(function (data) {
            if (data.code === 200) {
              vm.weekData = data.data
              var xAxisArr = vm.weekData.map(function (item) { return item.date });
              var seriesArr = [];
              var seriesObj = [];
              vm.weekData.forEach(function (item) { seriesObj = Object.keys(item.data) });
              seriesArr = seriesObj.map(function (item) {
                var data = [];
                vm.weekData.forEach(function (item2) { data.push(item2.data[item]) })
                return { name: item, data: data }
              })
              vm.chartLine(xAxisArr, seriesArr)
            } else {
              toastr.error('获取数据失败')
            }
          }).error(function (data) {
            toastr.error('获取数据失败' + data)
            console.error(data)
          })
        };

        // 获取工单提交排名
        vm.getSubmitData = function () {
          var start = Math.trunc(vm.orderStart.getTime() / 1000)
          var end = Math.trunc(vm.orderEnd.getTime() / 1000)
          return $http.get('/api/tt/statistics/work_order_summary/by_apply_user' + '?start=' + start + '&end=' + end).success(function (data) {
            if (data.code === 200) {
              vm.submitData = data.data
              var xAxisArr = vm.submitData.map(function (item) { return item.key });
              var seriesArr = [{ name: '工单数量(只展示前10)', data: vm.submitData.map(function (item) { return item.value }) }];
              vm.chartBarSubmit(xAxisArr, seriesArr)
            } else {
              toastr.error('获取数据失败')
            }
          }).error(function (data) {
            toastr.error('获取数据失败' + data)
            console.error(data)
          })
        };

        // 获取工单待办排名
        vm.getUpComingData = function () {
          var start = Math.trunc(vm.orderStart.getTime() / 1000)
          var end = Math.trunc(vm.orderEnd.getTime() / 1000)
          return $http.get('/api/tt/statistics/work_order_summary/by_status' + '?start=' + start + '&end=' + end + '&status=' + 0).success(function (data) {
            if (data.code === 200) {
              vm.upcomingData = data.data
              var xAxisArr = vm.upcomingData.map(function (item) { return item.key });
              var seriesArr = [{ name: '工单数量(只展示前10)', data: vm.upcomingData.map(function (item) { return item.value }) }];
              vm.chartBarUpcoming(xAxisArr, seriesArr)
            } else {
              toastr.error('获取数据失败')
            }
          }).error(function (data) {
            toastr.error('获取数据失败' + data)
            console.error(data)
          })
        };

        // 获取工单完成排名
        vm.getFinishData = function () {
          var start = Math.trunc(vm.orderStart.getTime() / 1000)
          var end = Math.trunc(vm.orderEnd.getTime() / 1000)
          return $http.get('/api/tt/statistics/work_order_summary/by_status' + '?start=' + start + '&end=' + end + '&status=' + 1).success(function (data) {
            if (data.code === 200) {
              vm.finishData = data.data
              var xAxisArr = vm.finishData.map(function (item) { return item.key });
              var seriesArr = [{ name: '工单数量(只展示前10)', data: vm.finishData.map(function (item) { return item.value }) }];
              vm.chatBarFinish(xAxisArr, seriesArr)
            } else {
              toastr.error('获取数据失败')
            }
          }).error(function (data) {
            toastr.error('获取数据失败' + data)
            console.error(data)
          })
        };

        vm.getData = function () {
          try {
            vm.loading = true
            var promiseArr =  [
              vm.getInfoData(),
              vm.getWeekData(),
              vm.getSubmitData(),
              vm.getUpComingData(),
              vm.getFinishData(),
            ]
            return $q.all(promiseArr)
            .then(function(results) {
              console.log(results)
              vm.loading = false
            })
            .catch(function(error) {
              vm.loading = false
              console.error('获取数据失败'+ error);
            });
          } catch (error) {
            toastr.error('获取数据失败' + error);
            console.error(error);
          }
        };

        vm.getData();

        // 本周工单统计
        vm.chartLine = function (xAxisArr, seriesArr) {
          return Highcharts.chart('line-container', {
            chart: { type: 'spline' },
            title: { text: '本周工单统计', align: 'left' },
            yAxis: {
              title: {
                text: '工单数量'
              }
            },
            xAxis: {
              categories: xAxisArr
            },
            legend: {
              layout: 'vertical',
              align: 'right',
            },
            series: seriesArr,
            responsive: {
              rules: [{
                condition: {
                  maxWidth: 500
                },
                chartOptions: {
                  legend: {
                    layout: 'horizontal',
                    align: 'center',
                    verticalAlign: 'bottom'
                  }
                }
              }]
            }
          });
        };

        // 工单提交排名
        vm.chartBarSubmit = function (xAxisArr, seriesArr) {
          return Highcharts.chart('submit-container', {
            chart: { type: 'bar' },
            title: { text: '工单提交排名', align: 'left' },
            xAxis: {
              categories: xAxisArr,
              title: {
                text: null
              },
              gridLineWidth: 1,
              lineWidth: 0
            },
            yAxis: {
              min: 0,
              title: { text: '工单数量', align: 'high' },
              labels: { overflow: 'justify' },
              gridLineWidth: 0
            },
            tooltip: {
              valueSuffix: ' millions'
            },
            plotOptions: {
              bar: {
                dataLabels: {
                  enabled: true
                },
                groupPadding: 0.1
              },
              series: {
                color: '#3ece85' // 通过数组设置多个柱子颜色
              }
            },
            credits: {
              enabled: false
            },
            series: seriesArr
          });
        };

        // 待办工单
        vm.chartBarUpcoming = function (xAxisArr, seriesArr) {
          return Highcharts.chart('upcoming-container', {
            chart: {
              type: 'bar'
            },
            title: {
              text: '待办工单排名',
              align: 'left'
            },
            xAxis: {
              categories: xAxisArr,
              title: {
                text: null
              },
              gridLineWidth: 1,
              lineWidth: 0
            },
            yAxis: {
              min: 0,
              title: {
                text: '工单数量',
                align: 'high'
              },
              labels: {
                overflow: 'justify'
              },
              gridLineWidth: 0
            },
            tooltip: {
              valueSuffix: ' millions'
            },
            plotOptions: {
              bar: {
                dataLabels: {
                  enabled: true
                },
                groupPadding: 0.1
              },
              series: {
                color: '#ef537b' // 通过数组设置多个柱子颜色
              }
            },
            credits: {
              enabled: false
            },
            series: seriesArr
          });
        };

        // 完成工单
        vm.chatBarFinish = function (xAxisArr, seriesArr) {
          return Highcharts.chart('finish-container', {
            chart: {
              type: 'bar'
            },
            title: {
              text: '完成工单排名',
              align: 'left'
            },
            xAxis: {
              categories: xAxisArr,
              title: {
                text: null
              },
              gridLineWidth: 1,
              lineWidth: 0
            },
            yAxis: {
              min: 0,
              title: {
                text: '工单数量',
                align: 'high'
              },
              labels: {
                overflow: 'justify'
              },
              gridLineWidth: 0
            },
            tooltip: {
              valueSuffix: ' millions'
            },
            plotOptions: {
              bar: {
                dataLabels: {
                  enabled: true
                },
                groupPadding: 0.1
              },
              series: {
                color: '#467CFD' // 通过数组设置多个柱子颜色
              }
            },
            credits: {
              enabled: false
            },
            series: seriesArr
          });
        };

        vm.getDate = function (date) {
          return $filter('date')(date, "yyyy-MM-dd")
        }

        // 监听时间变化
        $scope.$watchGroup(['c3index.orderStart', 'c3index.orderEnd'], function (newValues, oldvalues) {
          var startTime = newValues[0];
          var endTime = newValues[1];
          vm.orderStart = startTime;
          vm.orderEnd = endTime;
          var oldStartTime = oldvalues[0];
          var oldEndTime = oldvalues[1];
          if (vm.isEndFirstLoad) {
            vm.isEndFirstLoad = false;
            return;
          }
          if (vm.getDate(oldStartTime) === vm.getDate(startTime) && vm.getDate(oldEndTime) === vm.getDate(endTime)) {
            return false;
          }
          if (startTime && endTime) {
            var newValue = Math.trunc(startTime.getTime() / 1000);
            var newEndValue = Math.trunc(endTime.getTime() / 1000);
            vm.sFirstLoad = false;
            if (newValue > newEndValue) {
              toastr.error('开始时间不能大于结束时间');
            } else {
              vm.getData();
            }
          }
        });
      }
    }
  }

})();
