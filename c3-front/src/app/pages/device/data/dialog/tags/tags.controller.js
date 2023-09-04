(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('TagsController', TagsController)
    .filter('cut30', function () {
      return function (text) {
        if (text.length > 33) {
          return "..." + text.substr(text.length - 30)
        }
        return text;

      }
    });

  function TagsController ($uibModalInstance, $http, toastr, type, treeid, uuid, subtype, config) {

    var vm = this;
    vm.treeid = treeid;
    vm.type = type;
    vm.subtype = subtype;
    vm.uuid = uuid
    vm.config = JSON.parse(JSON.stringify(config));
    vm.tagsArr = []
    vm.defaultTagsArr = []
    vm.tagLoading = false
    vm.cancel = function () { $uibModalInstance.dismiss() };

    // 删除标签
    vm.deleteTags = function (item, index) {
      const params = {
        tagkey: item.key,
        tagvalue: item.value
      }
      swal({
        title: '确认删除该标签吗',
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        cancelButtonText: "取消",
        confirmButtonText: "确定",
        closeOnConfirm: true
      }, function () {
        $http.post(`/api/ci/v2/c3mc/cloud/control/tags/del/${vm.type}/${vm.subtype}/${vm.uuid}`, params).success(function (data) {
          if (data.stat) {
            vm.tagsArr.splice(index, 1)
            toastr.success('删除成功')
          }
        }).error(function (error) {
          toastr.error('删除失败' + error)
          console.error(error)
        })
      });
    }

    // 编辑标签
    vm.editTags = function (item) {
      item.status = !item.status
    }

    // 保存标签
    vm.saveTags = function (item) {
      if (item.key && item.value) {
        const params = {
          tagkey: item.key,
          tagvalue: item.value
        }
        const defaultParams = vm.defaultTagsArr.find(items => items.key === item.key)
        if (params.tagvalue === defaultParams.value) {
          item.status = !item.status
          return
        }
        swal({
          title: '确认保存该标签吗',
          type: "warning",
          showCancelButton: true,
          confirmButtonColor: "#DD6B55",
          cancelButtonText: "取消",
          confirmButtonText: "确定",
          closeOnConfirm: true
        }, function () {
          $http.post(`/api/ci/v2/c3mc/cloud/control/tags/add/${vm.type}/${vm.subtype}/${vm.uuid}`, params).success(function (data) {
            if (data.stat) {
              item.status = !item.status
              toastr.success('保存成功')
              item.isCreate = false
            }
          }).error(function (error) {
            toastr.error('保存失败' + error)
            console.error(error)
          })
        });
      }
    }

    // 添加新标签
    vm.addTags = function () {
      vm.tagsArr.push({
        status: true,
        isCreate: true,
        key: '',
        value: '',
      })
    }

    vm.getData = function () {
      vm.tagLoading = true
      $http.get(`/api/ci/v2/c3mc/cloud/control/tags/get/${vm.type}/${vm.subtype}/${vm.uuid}`).success(function (data) {
        if (data.stat) {
          vm.tagLoading = false
          vm.tagsArr = data.data
          vm.defaultTagsArr = JSON.parse(JSON.stringify(data.data))
          vm.tagsArr.map(item => {
            // 是否是编辑状态 true 是编辑状态  false 是非编辑状态
            item.status = false
            // 是否为新建标签 true 是新建标签  false 是已有标签
            item.isCreate = false
            return item
          })
        }
      }).error(function (error) {
        toastr.error('获取标签失败' + error)
        vm.tagLoading = false
        console.error(error)
      })

    }

    vm.getData();
  }
})();
