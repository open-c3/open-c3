(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('GlobalSearchPageController', GlobalSearchPageController)

  function GlobalSearchPageController ($state, $http, $uibModalInstance) {
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
    vm.frequentArray = ['腾讯云', 'AWS', 'Google', '权限', '域名', 'CDN', '资源申请', '资源回收'];
    const ipReg = /(\d{1,3}\.){3}\d{1,3}/
    const bpmReg = /^BPM\d{18}/i
    const ttReg = /^tt\d{10}/i

    vm.reload = function () {
      vm.searchloadover = true;
      $http.get('/api/connector/navigation/menu').success(function (data) {
        vm.searchloadover = false;
        if (data.stat) {
          vm.cardMenu = data.data;
          vm.defaultSearchArr = data.data
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
      vm.cancel();
    }

    vm.buttonSubmit = function () {
      const defaultArr = JSON.parse(JSON.stringify(vm.defaultSearchArr))
      if (vm.choiceSearch === '') {
        vm.cardMenu = defaultArr;
        return;
      }
      vm.cardMenu = defaultArr.filter(item => item.name.toLowerCase().includes(vm.choiceSearch.toLowerCase()));
    }

    vm.handleClear = function () {
      vm.choiceSearch = null;
      const defaultArr = JSON.parse(JSON.stringify(vm.defaultSearchArr));
      vm.cardMenu = defaultArr;
    }

    vm.inputChange = function () {
      vm.buttonSubmit();
    }

    vm.inputKeyUp = function (event) {
      if (event.keyCode === 13) {
        const orderId = (vm.choiceSearch || '').toUpperCase()
        if (ipReg.test(vm.choiceSearch)) {
          sessionStorage.setItem('globalSearch', vm.choiceSearch || '')
          $state.go('home.device.data', { treeid: vm.treeid, timemachine: 'curr', type: 'all', subtype: 'all' });
        } else if (bpmReg.test(vm.choiceSearch)) {
          window.open(`/#/bpm/0/${orderId}`, '_blank')
        } else if (ttReg.test(vm.choiceSearch)) {
          window.open(`/#/tt/show/${orderId}`, '_blank')
        }
        vm.cancel();
      }
    }

    vm.handleFrequentClick = function (selectedItems) {
      if (vm.choiceSearch === selectedItems) {
        return
      }
      vm.choiceSearch = selectedItems
      vm.buttonSubmit();
    }

    vm.cancel = function () {
      $uibModalInstance.dismiss();
    }
  }

})();


