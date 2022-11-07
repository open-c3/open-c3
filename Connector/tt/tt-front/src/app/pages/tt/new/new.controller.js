(function () {
    'use strict';
    angular
        .module('cmdb')
        .controller('TTNewController', TTNewController);

    /** @ngInject */
    function TTNewController($state, $log, $http, $window, $uibModal, baseService, oauserService, FileUploader) {


        var vm = this;
        var swal = $window.swal;
        vm.ticket = {
            "impact": 5
        };
        vm.cti_search_w = '';
        vm.item_groups = []; // 选择的item对应的group

        // file uploader
        vm.uploader = new FileUploader({
            queueLimit: 5,
            alias: 'upload'
        });
        vm.uploader.filters.push({
            name: 'sizeFilter',
            fn: function (item) {
                return item.size <= 1024 * 1024 * 5;
            }
        });

        baseService.getData().then(function (data) {
            $log.debug('base:', data);
            vm.baseData = data;
            vm.item_groups = vm.baseData.group;
        });

        oauserService.getData().then(function (data) {
            vm.ticket.submit_user = data.email;
            vm.ticket.apply_user = data.email;
        });

        // group 转map格式
        vm.group_arr_to_map = function () {
            vm.group_map = {};
            var groups = [];
            angular.copy(vm.baseData.group, groups);
            angular.forEach(groups, function (g) {
                vm.group_map[g.id] = g;
            });
        };

        // item change
        vm.item_change = function () {

            vm.group_arr_to_map();
            var none_item_groups = {}
            angular.copy(vm.group_map, none_item_groups);

            vm.item_groups = [];

            angular.forEach(vm.baseData.item_group_map, function (m) {
                if (m.item_id == vm.ticket.item) {
                    vm.group_map[m.group_id].priority = "*";
                    vm.item_groups.push(vm.group_map[m.group_id]);
                    delete none_item_groups[m.group_id];
                }
            });

            angular.forEach(vm.baseData.group, function (g) {
                if (g.id in none_item_groups) {
                    vm.item_groups.push(g);
                }
            });

            if (vm.item_groups.length > 0) {
                vm.ticket.workgroup = vm.item_groups[0].id;
            }

            if (!vm.ticket.title && !vm.ticket.content || (vm.ticket.content == "<br>" && !vm.ticket.title)) {

                $http.get('/api/tt/base/item/' + vm.ticket.item).success(function (data) {
                    if (data.data.length == 1) {
                        vm.ticket.title = data.data[0].tpl_title;
                        vm.ticket.content = data.data[0].tpl_content;
                    }
                });

            }


        };

        // group change
        vm.group_change = function () {
            delete vm.ticket.group_user;
        };

        // cti search
        vm.cti_search = function () {

            if (vm.cti_search_w.trim() != '') {

                $uibModal.open({
                    templateUrl: 'app/pages/tt/new/cti_search.html',
                    controller: 'CtiSearchController',
                    controllerAs: 'ctisearch',
                    backdrop: 'static',
                    keyboard: false,
                    bindToController: true,
                    animation: false,
                    resolve: {
                        cti_search_w: function () {
                            return vm.cti_search_w;
                        },
                        baseData: function () {
                            return vm.baseData;
                        },
                        cti_select: function () {
                            return vm.cti_select;
                        }
                    }
                });

            }

            vm.cti_search_w = '';
        };
        // cti select
        vm.cti_select = function (c, t, i) {
            vm.ticket.category = c;
            vm.ticket.type = t;
            vm.ticket.item = i;
            if (i != 0) {
                vm.item_change();
            }
        };

        // submit
        vm.submit = function () {
            swal({
                title: 'Submit Confirm?',
                text: "确认提交?",
                type: 'question',
                showCancelButton: true
            }).then(function () {

                // submit modal
                $uibModal.open({
                    templateUrl: 'app/pages/tt/new/submit.html',
                    controller: 'TTSubmitController',
                    controllerAs: 'ttsubmit',
                    backdrop: 'static',
                    keyboard: false,
                    bindToController: true,
                    size: 'lg',
                    animation: false,
                    resolve: {
                        ticket: function () {
                            return vm.ticket;
                        },
                        uploader: function () {
                            return vm.uploader;
                        }
                    }
                });

            }).catch(swal.noop);
        };

    }

})();
