(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('WorkgroupController', WorkgroupController);

    /** @ngInject */
    function WorkgroupController($state, $log, $window, $http, putService, baseService, NgTableParams, toastr, adminService) {

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
        });

        vm.init = function(){
            delete vm.currentGroup;
            delete vm.newGroup;
            delete vm.newUser;
            angular.element('.loading-container').removeClass('hide');
            angular.element('.table').addClass('hide');
            $http.get('/api/tt/base/group_item_user_rel').success(function(data){
                $log.debug('groups:', data);
                if (data.code == 200){
                    vm.groups = data.data;
                    vm.workgroupTable= new NgTableParams({count: 10}, {
                        counts: [],
                        dataset: vm.groups
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

        // update group
        vm.updateGroup = function(){
            swal({
                title: 'Update',
                html: 'Group <br>' + vm.currentGroup.group_name,
                type: 'question',
                showCancelButton: true
            }).then(function () {
                var work_start_arr = vm.currentGroup.work_hour_start.split(":"); 
                var work_start = work_start_arr[0] * 60 + work_start_arr[1] * 1;
                var work_end_arr = vm.currentGroup.work_hour_end.split(":"); 
                var work_end = work_end_arr[0] * 60 + work_end_arr[1] * 1;
                vm.currentGroup.work_hour_start = work_start;
                vm.currentGroup.work_hour_end = work_end;
                putService.update('base/group/' + vm.currentGroup.id, vm.currentGroup).then(function(){
                    vm.reload();
                });
            });
        };

        // delete group
        vm.delGroup = function(g){
            swal({
                title: 'Delete Confirm?',
                html: "确认删除?<br>" + g.group_name,
                type: 'warning',
                showCancelButton: true
            }).then(function() {
                $http.delete('/api/tt/base/group/' + g.id).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);

        };

        // add group
        vm.addGroup = function(){
            swal({
                title: 'Add',
                html: 'Group <br>' + vm.newGroup.group_name,
                type: 'question',
                showCancelButton: true
            }).then(function () {
                var work_start_arr = vm.newGroup.work_hour_start.split(":"); 
                var work_start = work_start_arr[0] * 60 + work_start_arr[1] * 1;
                var work_end_arr = vm.newGroup.work_hour_end.split(":"); 
                var work_end = work_end_arr[0] * 60 + work_end_arr[1] * 1;
                vm.newGroup.work_hour_start = work_start;
                vm.newGroup.work_hour_end = work_end;
                $http.post('/api/tt/base/group', vm.newGroup).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        }

        // open add form
        vm.openAddForm = function(){
            vm.newGroup = {};
            delete vm.currentGroup;
            delete vm.newUser;
        }
        
        // open edit form
        vm.openEditForm = function(g){
            vm.currentGroup = g;
            var work_start = vm.currentGroup.work_hour_start;
            var work_end = vm.currentGroup.work_hour_end;
            vm.currentGroup.work_hour_start = Math.floor(work_start / 60) + ':' + work_start % 60;
            vm.currentGroup.work_hour_end = Math.floor(work_end / 60) + ':' + work_end % 60;
            delete vm.newGroup;
            delete vm.newUser;
        }

        // cancel (add/edit) form
        vm.cancelForm = function(){
            delete vm.currentGroup;
            delete vm.newGroup;
            delete vm.newUser;
        };

        // add user
        vm.openAddUserForm = function(g){
            vm.newUser = {group_id:g.id};
            delete vm.currentGroup;
            delete vm.newGroup;
        };
        vm.addUser = function(){
            swal({
                title: 'Add User',
                text: vm.newUser.email,
                type: 'question',
                showCancelButton: true
            }).then(function () {
                $http.post('/api/tt/base/group_user', vm.newUser).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };

        // delete user
        vm.delUser = function(u){
            swal({
                title: 'Delete User',
                text: u.email,
                type: 'warning',
                showCancelButton: true
            }).then(function () {
                $http.delete('/api/tt/base/group_user/'+u.id).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.reload();
                    }
                });
            }).catch(swal.noop);
        };

        // 禁用/启用 用户
        vm.disableUser = function(u){

            var title = u.disabled == 1 ? "Enable User ?" : "Disable User";

            var user = {};
            angular.copy(u,user);

            if (user.disabled == 0){
                user.disabled = 1;
            }else{
                user.disabled = 0;
            }

            swal({
                title: title,
                text: u.email,
                type: 'warning',
                showCancelButton: true
            }).then(function () {
                // 检测用户是有未关闭的单子
                $http.post('/api/tt/search/list/open_ticket_for_user',{id:u.id, group_id: u.group_id}).success(function(data){
                    if (user.disabled == 1){
                        if (data.data.length>0){
                            toastr.warning("该用户有未关闭的单子！");
                            return;
                        }
                    }

                    $http.put('/api/tt/base/group_user/'+u.id,user).success(function(data){
                        if (data.code == 200){
                            toastr.success(data.data);
                            vm.reload();
                        }
                    });
                });
            }).catch(swal.noop);

        };

    }

})();
