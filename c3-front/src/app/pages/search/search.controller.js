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
    vm.iconMap = {
      bpm: '/assets/images/bpm.png',
      navigation: '/assets/images/navigation.png',
    }
    vm.searchTypeObject = {};

    vm.converArray = function (arr) {
      const searchTypeArr = [...new Set(arr.map(item => item.type))].map(item => { return { type: item } });
      const searchTypeObj = {};
      angular.forEach(searchTypeArr, function (item, index) {
        searchTypeObj[item.type] = { type: item.type === 'website' ? '网址导航' : item.type, content: arr.filter(cItem => cItem.type === item.type) }
      })
      return searchTypeObj;
    }

    vm.reload = function () {
      vm.searchloadover = true;
      $http.get('/api/connector/navigation/menu').success(function (data) {
        vm.searchloadover = false;
        if (data.stat) {
          vm.cardMenu = data.data;
          vm.defaultSearchArr = data.data
          vm.searchTypeObject = vm.converArray(data.data);
        } else {
          vm.searchloadover = false;
          swal({ title: '获取菜单失败', text: data.info, type: 'error' });
          vm.cardMenu = []
        }
      }).catch(err => {
        vm.searchloadover = false;
        console.error(err)
      });
    };
    vm.reload();

    vm.handleCardClick = function (items) {
      if (!items.url) return
      window.open(items.url)
    }

    vm.buttonSubmit = function () {
      const defaultArr = JSON.parse(JSON.stringify(vm.defaultSearchArr))
      if (vm.choiceSearch === '') {
        vm.cardMenu = defaultArr;
        vm.searchTypeObject = vm.converArray(vm.cardMenu);
        return;
      }
      vm.cardMenu = defaultArr.filter(item => item.name.toLowerCase().includes(vm.choiceSearch.toLowerCase()));
      vm.searchTypeObject = vm.converArray(vm.cardMenu);
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


