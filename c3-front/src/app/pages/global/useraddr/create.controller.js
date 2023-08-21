(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('UseraddrCreateController', UseraddrCreateController);

    function UseraddrCreateController( $http, $uibModalInstance, $injector, reload, infoId ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');
        vm.infoId = infoId;

        vm.postdata = {};

        if (vm.infoId) {
          $http.get(`/api/connector/useraddr/${vm.infoId}`).then(data => {
            const resData = data.data
            if (resData.stat){
              vm.postdata = {
                id: resData.data.id,
                user: resData.data.user,
                email: resData.data.email,
                phone: resData.data.phone,
                voicemail: resData.data.voicemail,
              }
            }else {
              swal('获取信息失败', data.data.info, 'error' );
            }
          })
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
          $http.post('/api/connector/useraddr', vm.postdata ).success(function(data){
            if(data.stat == true) {
              vm.cancel();
              reload();
              toastr.success(`${vm.infoId ? '编辑': '新建'}成功！`)
            } else { swal({ title: `${vm.infoId ? '编辑': '新建'}失败！`, text: data.info, type:'error' }); }

          });
        };

    }
})();

