(function() {
  'use strict';

  angular
    .module('openc3')
    .run(runBlock);

  /** @ngInject */
  function runBlock($log, $rootScope) {

    $log.debug('runBlock end');
  }

})();
