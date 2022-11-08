(function() {
  'use strict';

  angular
    .module('cmdb')
    .directive('c3navbar', c3navbar);

  /** @ngInject */
  function c3navbar() {
    var directive = {

      restrict: 'E',
      templateUrl: 'app/components/navbar/navbar.html',
      scope: {},
      controller: NavbarController,
      controllerAs: 'nav'
    };

    return directive;

    /** @ngInject */
    function NavbarController($rootScope, $translate, $http, $cookies, $window, langService, ssoService, oauserService) {

      var vm = this;

      // show/hide menu
      // from cookie
      vm.currentMenu = $cookies.get('c3menu');
      
      vm.showMenu = function(){

          angular.element("body").removeClass('sb-l-m');
          $cookies.put('c3menu', 'none');
          vm.currentMenu = $cookies.get('c3menu');
          angular.element('#sidebar_left').nanoScroller({preventPageScrolling:true});
          angular.element('.nano-pane').css("display", "block");
      };

      vm.hideMenu= function(){
          // body class
          angular.element("body").addClass("sb-l-m");
          $cookies.put('c3menu', 'sb-l-m');
          // menu
          vm.currentMenu = $cookies.get('c3menu');
          angular.element('#sidebar_left').nanoScroller({ destroy: true });
          angular.element('.nano-pane').css("display", "none");
      };

      vm.toggleMenu = function(){
          if(vm.currentMenu!='sb-l-m'){
              vm.hideMenu();
          }else{
              vm.showMenu();
          }
      };

      if(vm.currentMenu!='sb-l-m'){
          vm.showMenu();
      }else{
          vm.hideMenu();
      }
      // language
      langService.getData().then(function(data){
          vm.langData = data;
      });

      vm.changeLang = function(key){
          $translate.use(key);
          vm.currentLang = $translate.proposedLanguage() || $translate.use();
      };

      // logout
      vm.logout = function(){
          var siteaddr = $window.location.protocol + '//' + $window.location.host;
          $http.get('/api/connector/connectorx/ssologout?siteaddr=' + siteaddr ).success(function(data){
              if(data.data)
              {
                  $window.location.href=data.data
              }
              else
              {
                  $window.location.reload();
              }
          });
      };

      // get login user
      oauserService.getData().then(function(data){
          vm.user = data;
      });

    }

  }

})();
