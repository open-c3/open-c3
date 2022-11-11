(function() { 
    'use strict'; 
    angular
        .module('cmdb')
        .controller('TTShowController', TTShowController);

    /** @ngInject */
    function TTShowController($state, $log, $http, $window, baseService, oauserService, FileUploader, toastr) {

        if(!$state.params.id || $state.params.id.length != 12){
            $state.go('home.e404');
            return;
        }

        var vm = this;
        var swal = $window.swal;
        vm.no = $state.params.id;
        vm.isUpdating = false;

        // file uploader
        vm.uploader = new FileUploader({
            alias: 'upload',
            removeAfterUpload: true
        });
        vm.uploader.filters.push({
            name:'sizeFilter',
            fn:function(item){
                return item.size <= 1024*1024*5;
            }
        });

        // upload exec
        vm.uploader.onCompleteItem = function(item, res, s){
            if (s != 200){
                toastr.error('update error.' + '(' + s + ')');
            }else{
                if (res.code != 200){
                    toastr.error(res.data + '(' + res.code+ ')');
                }else{
                    toastr.success(res.data);
                    vm.init();
                }
            }
        };

        // del attachment
        vm.del_attachment = function(a){
            swal({
                title: 'Delete Confirm?',
                text: "确认删除?("+a.name+")",
                type: 'question',
                showCancelButton: true
            }).then(function() {
                $http.delete('/api/tt/attachment/' + vm.ticket.id +'/'+  a.uuid).success(function(data){
                    if (data.code == 200){
                        swal('Success', '删除成功', 'success');
                        vm.init();
                    }
                });
            }).catch(swal.noop);
        };
        
        // group 转map格式
        vm.group_arr_to_map = function(){
            vm.group_map = {};
            var groups = [];
            angular.copy(vm.baseData.group, groups);
            angular.forEach(groups, function(g){
                vm.group_map[g.id] = g;
            });
        };

        // init item-group
        vm.initItemGroup = function(){
            vm.group_arr_to_map();
            var none_item_groups = {}
            angular.copy(vm.group_map, none_item_groups);

            vm.item_groups = [];

            angular.forEach(vm.baseData.item_group_map, function(m){
                if (m.item_id == vm.ticket.item){
                    vm.group_map[m.group_id].priority = "*";
                    vm.item_groups.push(vm.group_map[m.group_id]);
                    delete none_item_groups[m.group_id];
                }
            });

            angular.forEach(vm.baseData.group, function(g){
                if (g.id in none_item_groups){
                    vm.item_groups.push(g);
                }
            });
        };

        // item change
        vm.item_change = function(){
            vm.initItemGroup();
        };

        // group change
        vm.group_change = function(){
            delete vm.ticket.group_user;
        };

        // download
        vm.download = function(uuid){
            var url = '/api/tt/attachment/download/'+vm.ticket.id + '/' +uuid;
            $window.open(url);
        };

        // submit
        vm.submit = function(){

            if (angular.equals(vm.ticket, vm.oldTicket)){
                toastr.warning("Nothing to update.");
                return;
            }

            // 检测 根本原因 解决方案 是否填写
            if (vm.ticket.status=='resolved'){
                if (vm.ticket.root_cause == '' || vm.ticket.solution == ''){
                    toastr.warning("事件状态解决，必须填写解决方案和根本原因<br>Root cause & Solution is required when status is 'Resolved'",'',{timeOut:5000});
                    vm.tabActive = 2;
                    return;
                }
            }

            swal({
                title: 'Update Confirm?',
                text: "确认更新?("+vm.ticket.no+")",
                type: 'question',
                showCancelButton: true
            }).then(function() {
                vm.isUpdating = true;
                $http.put('/api/tt/ticket/' + vm.ticket.id, vm.ticket).success(function(data){
                    if (data.code == 200){
                        toastr.success(data.data);
                        vm.init();
                    }
                    vm.isUpdating = false;
                });
            }).catch(swal.noop);
        };

        // replylog
        vm.getReplylog = function(ticketid){
            $http.get('/api/tt/common/replylog/' + ticketid).success(function(data){
                vm.replylog = data.data;
            });
        };
        vm.addReplylog = function(){
            if (vm.newReplylog!='' && vm.newReplylog!='undefined'){
                $http.post('/api/tt/common/replylog', {ticket_id:vm.ticket.id, content:vm.newReplylog}).success(function(data){
                    toastr.success(data.data);
                    vm.init();
                    vm.newReplylog = '';
                });
            }
        };
        // worklog
        vm.getWorklog = function(ticketid){
            $http.get('/api/tt/common/worklog/' + ticketid).success(function(data){
                vm.worklog = data.data;
            });
        };
        vm.addWorklog = function(){
            if (vm.newWorklog!='' && vm.newWorklog!='undefined'){
                $http.post('/api/tt/common/worklog', {ticket_id:vm.ticket.id, content:vm.newWorklog}).success(function(data){
                    toastr.success(data.data);
                    vm.init();
                    vm.newWorklog = '';
                });
            }
        };
        // syslog
        vm.getSyslog = function(ticketid){
            $http.get('/api/tt/common/syslog/' + ticketid).success(function(data){
                vm.syslog = data.data;
            });
        };
        // status flow
        vm.getStatusFlow = function(ticketid){
            $http.get('/api/tt/status_flow/' + ticketid).success(function(data){
                vm.status_flow = data.data;
            });
        };

        // applicant oa info
        vm.getApplyUserOa = function(){
            $http.get('/api/tt/base/get_user_info?user=' + vm.ticket.apply_user).success(function(data){
                vm.OA_applicant = data.data;
            });
        };

        // change status
        vm.changeStatus = function(){
            if (vm.ticket.status=='resolved'){
                vm.tabActive = 2;
            }
        };

        // init
        vm.init = function(){

            vm.isUpdating = true;
            // 获取ticket信息
            $http.get('/api/tt/ticket/' + vm.no).success(function(data){
                if (data.code == 404){
                    $state.go('home.e404');
                }
                if (data.code == 200){
                    vm.ticket = data.data;
                    vm.oldTicket = {};
                    angular.copy(data.data,vm.oldTicket);
                    vm.uploader.url = '/api/tt/attachment/upload/' + vm.ticket.id;
                    vm.uploader.queueLimit = 5-vm.ticket.attachment.length;

                    vm.isUpdating = false;

                    $log.debug(vm.ticket);

                    // basedata
                    baseService.getData().then(function(data){
                        vm.baseData = data;
                        vm.initItemGroup();
                    });

                    vm.getSyslog(vm.ticket.id);
                    vm.getReplylog(vm.ticket.id);
                    vm.getWorklog(vm.ticket.id);
                    vm.getStatusFlow(vm.ticket.id);
                    vm.getApplyUserOa();

                }

            });

        };

        vm.init();

    }

})();
