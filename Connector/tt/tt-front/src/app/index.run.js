(function() {
  'use strict';

  angular
    .module('cmdb')
    .run(runBlock);

  /** @ngInject */
  function runBlock($log) {
    $log.debug('runBlock end');
  }

})();
