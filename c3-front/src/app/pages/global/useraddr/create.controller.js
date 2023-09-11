(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('UseraddrCreateController', UseraddrCreateController);

    function UseraddrCreateController( $http, $uibModalInstance, $injector, reload, infoId ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');
        vm.infoId = infoId;

        vm.postdata = {
          mobileType: [{type:'', phone:''}],
        };
        vm.emailStatus = true
        vm.phoneStatus = true
        vm.voicemailStatus = true
        vm.mobileTypeOption = [
          { label: 'C3T.短信', value: '' },
          { label: 'C3T.钉钉', value: 'dingding' },
          { label: 'C3T.钉钉机器人', value: 'dingding-bot' },
          { label: 'C3T.飞书', value: 'feishu' },
          { label: 'C3T.飞书机器人', value: 'feishu-bot' },
          { label: 'lark', value: 'lark' },
        ]

        if (vm.infoId) {
          $http.get(`/api/connector/useraddr/${vm.infoId}`).then(data => {
            const resData = data.data
            const multiplePhone = resData.data.phone.split(',').map(item => {
              return {
                type: item.split(':')[1]? item.split(':')[0]: '',
                phone: item.split(':')[1]? item.split(':')[1]: item
              }
            })
            if (resData.stat){
              vm.postdata = {
                id: resData.data.id,
                user: resData.data.user,
                email: resData.data.email,
                phone: resData.data.phone,
                mobileType: multiplePhone,
                voicemail: resData.data.voicemail,
              }
              vm.emailStatus = resData.data.email === 'x' ? false : true
              vm.phoneStatus = resData.data.phone === 'x' ? false : true
              vm.voicemailStatus = resData.data.voicemail === 'x' ? false : true
            }else {
              swal('获取信息失败', data.data.info, 'error' );
            }
          })
        }

      vm.switchChange = function(type){
        if  (type === 'email') {
          if (!vm.emailStatus) {
            vm.postdata.email = 'x'
          } else {
            vm.postdata.email = ''
          }
        }
        if (type === 'phone') {
          if (!vm.phoneStatus) {
            vm.postdata.phone = 'x'
            vm.postdata.mobileType = vm.postdata.mobileType.map(item => {return {type: '', phone: 'x'}})
          } else {
            vm.postdata.phone = ''
            vm.postdata.mobileType = vm.postdata.mobileType.map(item => {return {type: '', phone: ''}})
          }
        }
        if (type === 'voicemail') {
          if (!vm.voicemailStatus){
            vm.postdata.voicemail = 'x'
          }else {
            vm.postdata.voicemail = ''
          }
        }
      }
 
        // 手机号下拉选择框
        vm.mobileTypeChange = function(value, index){
          vm.postdata.mobileType[index].type = value
        }

        // 添加键值对
        vm.addKvArray = function(){
          vm.postdata.mobileType.push({type:'', phone:''})
        }
        // 删除目标键值对
        vm.deleteKvArray = function(index){
          vm.postdata.mobileType.splice(index, 1)
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
          const middlewareData = JSON.parse(JSON.stringify(vm.postdata))
          const newData = {}
          if (middlewareData.id) {
            newData['id'] = middlewareData.id
          }
          newData['user'] = middlewareData.user
          newData['email'] = vm.emailStatus ? middlewareData.email : 'x'
          newData['phone'] = vm.phoneStatus ? middlewareData.mobileType.map(item => {return `${item.type? `${item.type}:`: ''}${item.phone}`}).join(','): 'x'
          newData['voicemail'] = vm.voicemailStatus ? middlewareData.voicemail : 'x'
          $http.post('/api/connector/useraddr', newData ).success(function(data){
            if(data.stat == true) {
              vm.cancel();
              reload();
              toastr.success(`${vm.infoId ? '编辑': '新建'}成功！`)
            } else { swal({ title: `${vm.infoId ? '编辑': '新建'}失败！`, text: data.info, type:'error' }); }

          });
        };

    }
})();

