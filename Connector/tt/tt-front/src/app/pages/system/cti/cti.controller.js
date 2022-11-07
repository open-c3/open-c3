(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('CtiController', CtiController);

    /** @ngInject */
    function CtiController($log, $state, $http, $window, toastr, baseService, adminService) {

        var vm = this;
        var swal = $window.swal;

        adminService.getData().then(function(data){
            if (!data){
                $state.go('home.e403');
                return;
            }
        });

        baseService.getData().then(function(data){

            vm.basedata = data;
            vm.init();
            vm.showTab = true;

            vm.addGroupOptions = {};
            angular.forEach(vm.basedata.group, function(g){
                vm.addGroupOptions[g.id] = g.group_name;
            });
        });

        vm.init = function(){
            vm.currentItem = {};
            vm.currentType = {};
            vm.newItem = {};
            $http.get('/api/tt/base/cti_tree_map').success(function(data){
                vm.cti_tree = data.data;
            });
        };

        vm.reload = function(e){
            if(e){
                e.target.blur();
            }
            angular.element('.loading-container').removeClass('hide');
            angular.element('.cti-tree').addClass('hide');
            baseService.getData(1).then(function(data){
                vm.basedata = data;
                vm.init();
                angular.element('.loading-container').addClass('hide');
                angular.element('.cti-tree').removeClass('hide');
            });
        };

        /*add category*/
        vm.addCategory = function(){
            swal({
                title: 'Add',
                text: 'Category',
                input: 'text',
                showCancelButton: true,
                confirmButtonText: 'Submit',
                showLoaderOnConfirm: true,
                preConfirm: function (input) {
                    return new Promise(function (resolve, reject) {
                        if (input == ''){
                            reject('can not be null');
                        }
                        resolve()
                    })
                },
                allowOutsideClick: false
            }).then(function (input) {
                var newobj = {name:input};
                $http.post('/api/tt/base/category', newobj).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };

        /*add type*/
        vm.addType = function(category){
            swal({
                title: 'Add',
                html: 'Type <br>[Category: ' + category.name + ' ]',
                input: 'text',
                showCancelButton: true,
                confirmButtonText: 'Submit',
                showLoaderOnConfirm: true,
                preConfirm: function (input) {
                    return new Promise(function (resolve, reject) {
                        if (input == ''){
                            reject('can not be null');
                        }
                        resolve()
                    })
                },
                allowOutsideClick: false
            }).then(function (input) {
                var newobj = {category_id:category.id, name:input};
                $http.post('/api/tt/base/type', newobj).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };

        /*update c.t name*/
        vm.updateSwal = function(obj, path){
            var newobj = {};
            angular.copy(obj, newobj);
            swal({
                title: 'Update',
                text: newobj.name,
                input: 'text',
                inputPlaceholder: obj.name,
                showCancelButton: true,
                confirmButtonText: 'Submit',
                showLoaderOnConfirm: true,
                preConfirm: function (input) {
                    return new Promise(function (resolve, reject) {
                        if (input == ''){
                            reject('can not be null');
                        }
                        resolve()
                    })
                },
                allowOutsideClick: false
            }).then(function (input) {
                newobj.name = input;
                $http.put('/api/tt/' + path + obj.id, newobj).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };

        /*delete*/
        vm.delSwal = function(d, value, path){
            swal({
                title: 'Delete Confirm?',
                html: "确认删除?<br>" + value,
                type: 'warning',
                showCancelButton: true
            }).then(function() {
                $http.delete('/api/tt/' + path + d.id).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };

        // edit item
        vm.editItem = function(item){
            angular.copy(item, vm.currentItem);
            vm.currentType = {};
        };
        vm.updateItem = function(){
            if (!angular.equals(vm.currentItem,{})){
                swal({
                    title: 'Submit Confirm?',
                    text: "确认修改?",
                    type: 'question',
                    showCancelButton: true
                }).then(function() {
                    $http.put('/api/tt/base/item/' + vm.currentItem.id, vm.currentItem).success(function(data){
                        if (data.code == 200){
                            toastr.success(data.data);
                            vm.reload();
                        }
                    });

                }).catch(swal.noop);
            }
        };

        // add item
        vm.addItem = function(type){
            angular.copy(type, vm.currentType);
            vm.newItem = {type_id:type.id};
            vm.currentItem = {};
        };
        vm.addItemSwal = function(){
            swal({
                title: 'Add Confirm?',
                html: "确认添加?<br>" + vm.newItem.name,
                type: 'question',
                showCancelButton: true
            }).then(function() {
                $http.post('/api/tt/base/item',vm.newItem).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };
        vm.cancelItem = function(){
            vm.newItem = {};
            vm.currentType = {};
            vm.currentItem = {};
        };

        // add group
        vm.addGroup = function(){

            var addGroupSteps = [
            {
                title: 'Select a WorkGroup',
                input: 'select',
                inputOptions: vm.addGroupOptions,
                inputPlaceholder: 'WorkGroup',
                showCancelButton: true,
                allowOutsideClick: false,
                inputValidator: function (value) {
                    return new Promise(function (resolve, reject) {
                        if (value == '') {
                            reject('Can not be NULL')
                        } else {
                            resolve()
                        }
                    })
                }
            },
            {
                title: 'WorkGroup Priority',
                text: 'input priority',
                input: 'number',
                showCancelButton: true,
                confirmButtonText: 'Submit',
                showLoaderOnConfirm: true,
                preConfirm: function (input) {
                    return new Promise(function (resolve, reject) {
                        if (input == ''){
                            reject('can not be null');
                        }
                        resolve()
                    })
                },
                allowOutsideClick: false
            }
            ];
            swal.queue(addGroupSteps).then(function(result){
                var groupId = result[0]*1;
                var priority = result[1]*1;
                var newmap = {item_id:vm.currentItem.id, group_id:groupId, priority:priority};
                $http.post('/api/tt/base/item_group_map', newmap).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
            return;
        };
        // del group
        vm.delGroup = function(map){
            swal({
                title: 'Add Confirm?',
                text: '确认解除?',
                type: 'warning',
                showCancelButton: true
            }).then(function() {
                $http.delete('/api/tt/base/item_group_map/'+map.id).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };

    }

})();
