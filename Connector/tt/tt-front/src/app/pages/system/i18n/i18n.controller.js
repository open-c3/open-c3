(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('I18nController', I18nController);

    /** @ngInject */
    function I18nController($state, $window, $filter, $http, $timeout, langService, toastr, adminService) {

        var vm = this;

        adminService.getData().then(function(data){
            if (!data){
                $state.go('home.e403');
                return;
            }
        });

        vm.langData = {};
        vm.langInit = function(){
            angular.element('.loading-container').removeClass('hide');
            langService.getData().then(function(data){
                vm.langData = data;
                angular.forEach(vm.langData, function(lang){
                    lang.jsonData = angular.fromJson(lang.data);
                    lang.wellFormed = true;
                });
                $timeout(function(){
                    vm.showTab = true;
                }, 0);
                angular.element('.loading-container').addClass('hide');
            });
        }

        vm.langInit();

        // parse json textarea string into jsonData obj
        vm.parseJson = function(lang, langString){
            try{
                lang.jsonData = angular.fromJson(langString);
                lang.wellFormed = true;
            }catch(e){
                lang.wellFormed = false;
            }
        };

        // parse jsonData obj to textarea string
        vm.unparseJson = function(lang, langData){
            lang.jsonString = $filter('json')(langData);
        };

        //save json data
        vm.save = function(langid, jsonData){
            $http.put('/api/tt/common/i18n/' + langid, {data:angular.toJson(jsonData)}).success(function(data){
                if(data.code == 200){
                    toastr.success(data.data);
                }
            });
        };

    }

})();
