(function() {
  'use strict';

  angular
    .module('openc3')
    .filter('highlight', function(){
        
        return function(shell){
            if( shell == null || shell == "" ){
                return;
            }else{
                return  Prism.highlight(shell, Prism.languages.bash);
            }
        }

    });


})();
