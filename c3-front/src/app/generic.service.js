(function() {
  'use strict';

  angular
    .module('openc3')
    .factory('genericService', genericService);


  function genericService($http, treeService, $q, $state, $filter) {

        var fun = {};
        fun.seftime = function(starttime, finishtime ) {

            if( ! starttime )
            {
                return '0:00:00';
            }
            if( ! finishtime )
            {
                finishtime = $filter('date')(new  Date(), 'yyyy-MM-dd HH:mm:ss')
            }

            var S = new Date( starttime.replace(/-/g, "/") )
            var E = new Date( finishtime.replace(/-/g, "/") )

            var sec =  ( (E.getTime() - S.getTime() ) /1000);
            var s = sec % 60;
            if(s < 10)
            {
                s = '0' + s
            }
            var min = Math.trunc(sec / 60);

            var m = min % 60;
            if( m < 10 )
            {
                 m = '0' + m
            }
    
            return (Math.trunc(min / 60) ) + ':' + m +':' + s;

        }

        fun.time2date = function( time ) {
            return time.split(" ")[0]
        }

   return fun

  }

})();
