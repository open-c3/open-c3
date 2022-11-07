(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('EmailtplController', EmailtplController);

    /** @ngInject */
    function EmailtplController($state, $timeout, $log, $window, $http, putService, NgTableParams, toastr, adminService) {

        var vm = this;
        var swal = $window.swal;

        adminService.getData().then(function(data){
            if (!data){
                $state.go('home.e403');
                return;
            }
        });

        vm.init = function(){
            delete vm.currenttpl;
            delete vm.newtpl;
            angular.element('.loading-container').removeClass('hide');
            angular.element('.table').addClass('hide');
            $http.get('/api/tt/base/email_templates/').success(function(data){
                if (data.code == 200){
                    vm.tpls = data.data;
                    vm.tplsTable= new NgTableParams({count: 10}, {
                        counts: [],
                        dataset: vm.tpls
                    });
                    vm.showTab = true;
                }
                angular.element('.loading-container').addClass('hide');
                angular.element('.table').removeClass('hide');
            });
        };

        vm.reload = function(e){
            if(e){
                e.target.blur();
            }
            vm.init();
        }

        vm.init();

        // open add form
        vm.openAddForm = function(){
            vm.newtpl = {};
            delete vm.currenttpl;
            $timeout(function(){
                angular.element(".editor").wysiwyg();
            });
        }
        
        // open edit form
        vm.openEditForm = function(g){
            vm.currenttpl = g;
            delete vm.newtpl;
            $timeout(function(){
                angular.element(".editor").wysiwyg();
            });
        }

        // cancel (add/edit) form
        vm.cancelForm = function(){
            delete vm.currenttpl;
            delete vm.newtpl;
        };

        // add
        vm.addTpl = function(){
            swal({
                title: 'Add Template',
                text: vm.newtpl.name,
                type: 'question',
                showCancelButton: true
            }).then(function () {
                $http.post('/api/tt/base/email_templates', vm.newtpl).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };

        //update
        vm.updateTpl = function(){
            swal({
                title: 'Update',
                html: 'Template <br>' + vm.currenttpl.name,
                type: 'question',
                showCancelButton: true
            }).then(function () {
                putService.update('base/email_templates/' + vm.currenttpl.id, vm.currenttpl).then(function(){
                    vm.reload();
                });
            }).catch(swal.noop);
        };

    }

})();
