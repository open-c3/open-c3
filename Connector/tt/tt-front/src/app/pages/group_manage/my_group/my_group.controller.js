(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('MyGroupController', MyGroupController);

    /** @ngInject */
    function MyGroupController($log, $state, $window, $filter, $http, $timeout, toastr, putService, oauserService) {

        var vm = this;
        var swal = $window.swal;

        vm.updateGroup = function(g){
            swal({
                title: 'Update',
                html: g.group_name,
                type: 'question',
                showCancelButton: true
            }).then(function () {
                var work_start_arr = g.work_hour_start.split(":"); 
                var work_start = work_start_arr[0] * 60 + work_start_arr[1] * 1;
                var work_end_arr = g.work_hour_end.split(":"); 
                var work_end = work_end_arr[0] * 60 + work_end_arr[1] * 1;
                g.work_hour_start = work_start;
                g.work_hour_end = work_end;
                putService.update('base/group/' + g.id, g).then(function(){
                    vm.init();
                });
            }).catch(swal.noop);
        };

        vm.addUser = function(group){

            var addUserSteps = [
            {
                title: 'User Email',
                input: 'email',
                showCancelButton: true,
                allowOutsideClick: false
            },
            {
                title: 'Priority',
                text: 'input priority',
                input: 'number',
                showCancelButton: true,
                showLoaderOnConfirm: true,
                allowOutsideClick: false,
                preConfirm: function (input) {
                    return new Promise(function (resolve, reject) {
                        if (input == ''){
                            reject('can not be null');
                        }
                        resolve()
                    })
                }
            }
            ];
            swal.queue(addUserSteps).then(function(result){
                var email = result[0];
                var priority = result[1]*1;
                var newmap = {group_id:group.id, email: email, priority:priority };
                $http.post('/api/tt/base/group_user', newmap).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.init();
                    }
                });
            }).catch(swal.noop);
        };

        vm.deleteUser = function(u){
            swal({
                title: 'Delete User',
                text: u.email,
                type: 'warning',
                showCancelButton: true
            }).then(function () {
                $http.delete('/api/tt/base/group_user/'+u.id).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.init();
                    }
                });
            }).catch(swal.noop);
        };

        vm.updateUser = function(u){
            swal({
                title: 'Update User',
                text: u.email,
                type: 'question',
                showCancelButton: true
            }).then(function () {
                $http.put('/api/tt/base/group_user/'+u.id, u).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.init();
                    }
                });
            }).catch(swal.noop);
        };

        vm.init = function(){
            vm.groups = [];
            vm.newUser = {};
            $http.get("/api/tt/base/group/").success(function(data){
                if (data.code == 200){
                    vm.basegroup = data.data;
                    $log.debug("group:", vm.basegroup);
                    oauserService.getData().then(function(data){
                        vm.oauser = data;
                        angular.forEach(vm.basegroup, function(g){
                            var work_start = g.work_hour_start;
                            var work_end = g.work_hour_end;
                            g.work_hour_start = Math.floor(work_start / 60) + ':' + work_start % 60;
                            g.work_hour_end = Math.floor(work_end / 60) + ':' + work_end % 60;
                            if (g.admin_email ==  vm.oauser.email){
                                vm.groups.push(g);
                            }
                        });
                    });
                }
            });
        };

        vm.init();

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
                $http.post('/api/tt/search/list/open_ticket_for_user',{group_user:u.email}).success(function(data){
                    if (user.disabled == 1){
                        if (data.data.length>0){
                            toastr.warning("该用户有未关闭的单子！");
                            return;
                        }
                    }
                    $http.put('/api/tt/base/group_user/'+u.id,user).success(function(data){
                        if (data.code == 200){
                            toastr.success(data.data);
                            vm.init();
                        }

                    });
                });
            }).catch(swal.noop);
        };

    }

})();
