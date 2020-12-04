(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateProjectByTemplateController', CreateProjectByTemplateController);

    function CreateProjectByTemplateController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, $uibModal) {

        var vm = this;

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/ci/group/0' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeRegionTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                } else { 
                    swal({ title: "加载版本失败!", text: data.info, type:'error' });
                }
            });
        };

        vm.reload();

        vm.copyProjectByTemplate = function (id, name) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/copyProjectByTemplate.html',
                controller: 'CopyProjectByTemplateController',
                controllerAs: 'copyProjectByTemplate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return treeid},
                    sourceid: function () { return id},
                    sourcename: function () { return name},
                    reload : function () { return reload},
                    cancel : function () { return vm.cancel},
                }
            });
        };
    }
})();

