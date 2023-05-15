(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('SearchPageController', SearchPageController)

  function SearchPageController ($state, $http) {
    var vm = this;
    vm.searchloadover = false;
    vm.treeid = $state.params.treeid;
    vm.cardMenu = [];
    vm.defaultSearchArr = []
    vm.choiceSearch = null

    vm.reload = function () {
      vm.searchloadover = true;
      $http.get('/api/job/bpm/menu').success(function (data) {
        vm.searchloadover = false;
        if (data.stat) {
          vm.cardMenu = data.data;
          vm.defaultSearchArr = data.data
        } else {
          swal({ title: '获取菜单失败', text: data.info, type: 'error' });
          vm.cardMenu = []
        }
      });
    };
    vm.reload();

    vm.handleCardClick = function (items) {
      $state.go('home.bpm', { treeid: vm.treeid, bpmuuid: 0, choicejob: items })
      vm.cancel();
    }

    vm.buttonSubmit = function () {
      const defaultArr = JSON.parse(JSON.stringify(vm.defaultSearchArr))
      if (vm.choiceSearch === '') {
        vm.cardMenu = defaultArr;
        return;
      }
      vm.cardMenu = defaultArr.filter(item => item.alias.includes(vm.choiceSearch));
    }

    vm.handleClear = function () {
      vm.choiceSearch = null;
      const defaultArr = JSON.parse(JSON.stringify(vm.defaultSearchArr));
      vm.cardMenu = defaultArr;
    }

    vm.inputChange = function () {
      vm.buttonSubmit();
    }

  }

})();


