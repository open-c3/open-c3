(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('TTListController', TTListController);

    /** @ngInject */
    function TTListController($state, $log, $http, baseService, NgTableParams) {

        var presetMod = {
            'assignme':'me_not_finish',
            'selfsubmit':'self_submit_not_finish',
            'emaillistme':'email_me_not_finish',
            'level12':'level_12',
            'myticket':'myticket',
            'menulist':'mygroup_not_finish'
        };
        var mod = $state.params.mod;

        var vm = this;

        baseService.getData().then(function(data){
            vm.baseData = data;
            $log.debug('base', vm.baseData);
        });

        // init
        vm.init = function(){

            if (mod in presetMod){

                vm.presetMod = presetMod[mod];

                vm.loading = true;

                $http.get('/api/tt/search/index/' + mod).success(function(data){
                    vm.tickets = data.data;
                    if (mod == 'menulist'){
                        var g = $state.params.g;
                        if (g!=undefined){
                            vm.tickets = data.data.group[g];
                            vm.groupname = g;
                        }else{
                            vm.tickets = [];
                            angular.forEach(data.data.group, function(v){
                                angular.forEach(v, function(i){
                                    vm.tickets.push(i);
                                });
                            });
                        }
                    }

                    vm.tableParams = new NgTableParams({count:25}, {counts:[],dataset:vm.tickets});

                    vm.loading = false;

                });

            }else{
                $state.go('home.e404');
            }

        };

        vm.init();

        // reload
        vm.tableReload = function(e){
            $log.debug($state.params.mod);
            if(e){
                e.target.blur();
            }
            vm.init();
        };

    }

})();
