(function() {
  'use strict';

  angular
    .module('openc3')
    .factory('genericService', genericService);


  function genericService($http, $q, $state, $filter) {

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

        // 前端导出

        fun.exportDownload = function (str, data) {
          let newStr = str;
          data.forEach((items,i) => {
            let newItem = items
            newStr += '<tr>'
            for (let item in Object.assign({}, newItem)) {
              if (item !== '$$hashKey') {
                let cellvalue = newItem[item] || ''
                newStr += `<td style="mso-number-format:'\@';">${cellvalue}</td>`
              }
            }
            newStr += '</tr>'
          })
          const worksheet = '导出结果'
          const uri = 'data:application/vnd.ms-excel;base64,'
          const template = `<html xmlns:o="urn:schemas-microsoft-com:office:office"
            xmlns:x="urn:schemas-microsoft-com:office:excel"
            xmlns="http://www.w3.org/TR/REC-html40">
            <head><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet>
            <x:Name>${worksheet}</x:Name>
            <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet>
            </x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]-->
            </head><body><table>${newStr}</table></body></html>`
          function base64(s) {
            return window.btoa(unescape(encodeURIComponent(s)))
          }
          window.location.href = uri + base64(template)
        }

   return fun

  }

})();
