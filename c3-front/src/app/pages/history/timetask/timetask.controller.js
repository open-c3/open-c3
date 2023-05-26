(function() {
  'use strict';

  angular
      .module('openc3')
      .controller('HistoryTimeTaskController', HistoryTimeTaskController);

  function HistoryTimeTaskController($filter, $state, $http, $uibModal, $scope, ngTableParams) {

      var vm = this;
      vm.treeid = $state.params.treeid;
      $scope.nowTime = $filter('date')(new Date, "yyyy-MM-dd");
      vm.loadover = false;

      vm.jumpLinkMap = {
        add: '/#/bpm/0/0?name=bpm-resources-group-ec2-add',
        del: '/#/bpm/0/0?name=bpm-resources-group-ec2-remove',
        shield: '/#/bpm/0/0?name=bpm-resources-group-ec2-config-special',
        switch: '/#/bpm/4000000000/0?name=bpm-resources-operate-aws-ec2'
      }
      vm.reload = function () {
        $http.get('/api/job/bpm/crontask').success(function (data) {
          vm.loadover = true;
          if (data.stat) {
            vm.data_Table = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
          }else {
            swal('获取列表失败', data.info, 'error');
          }
        }).error(function (err) {
          swal('获取列表失败', err, 'error');
        })
      };

      vm.reload();

      vm.handleOpen = function (type) {
        window.open(vm.jumpLinkMap[type]);
      };
  }

})();
