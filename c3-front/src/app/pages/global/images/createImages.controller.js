(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CreateImagesController', CreateImagesController);

    function CreateImagesController($uibModalInstance, $state, $http, $scope, homereload, imagesid, title, $injector ) {

        var vm = this;
        vm.title = title
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.postData = { share: 'false' };
        vm.uploadstatus = 0;
        vm.imagesid = imagesid

        var toastr = toastr || $injector.get('toastr');

        vm.siteaddr = window.location.host;

        vm.bytesToSize = function(bytes) {
            if (bytes === 0) return '0 B';
            var k = 1000, // or 1024
                sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
                i = Math.floor(Math.log(bytes) / Math.log(k));

           return (bytes / Math.pow(k, i)).toPrecision(3) + ' ' + sizes[i];
        }


        vm.loadimagesinfo = function( imagesid )
        {
            $http.get('/api/ci/images/' + imagesid + '/upload' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.uploadstatus = response.data.data
                    }else {
                        swal({ title:'检测镜像失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'检查镜像失败', text: response.status, type:'error' });
                });

        }
        if( imagesid )
        {
            $http.get('/api/ci/images/' + imagesid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.postData = response.data.data
                    }else {
                        swal({ title:'获取镜像详情失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'获取镜像详情失败', text: response.status, type:'error' });
                });

                vm.loadimagesinfo( imagesid )
        }

        vm.saveImages = function(){
            var uri = '/api/ci/images';
            if( imagesid )
            {
                uri = '/api/ci/images/' + imagesid;
            }
            $http.post(uri, vm.postData ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        homereload();
                        vm.cancel();
                    }else {
                        swal({ title:'保存镜像失败', text: response.data.info, type:'error' });
                    }
                }
            );
        };

        var ot = new Date().getTime()
        var oloaded = 0
        $scope.upForm = function () {
            var file = document.getElementById("choicefilesx").files[0];
            var name = document.getElementById("choicefilesx").files[0].name;
            $(".newFile").parents("div.col-sm-10").find("input[name='newFileMsg']").attr("data-name",name);
            var url = '/api/ci/images/' + imagesid + '/upload';
            var form = new FormData();
            form.append('file',file);

            var xhr = new XMLHttpRequest();
            xhr.open("post", url, true); //true 该参数规定请求是否异步处理
            xhr.onload = vm.uploadComplete; //请求完成执行
            xhr.onerror =  vm.uploadFailed; //请求失败执行
            xhr.upload.onprogress = vm.progressFunction;//请求过程中执行
            xhr.upload.onloadstart = function(){//请求开始执行
                ot = new Date().getTime();   //设置上传开始时间
                oloaded = 0;//设置上传开始时，以上传的文件大小为0
            };
            xhr.send(form); //开始请求
            //显示进度条
            $("#upload_progressBar_Module").css("display","block");
        };

        vm.uploadComplete = function(){
            if(this.status === 200 && this.readyState === 4){
                //进度条设置为100%；
                $("#myModal_add_progressBar").css("width","100%");
                $("#myModal_add_progressBar").html("100%");

                vm.loadimagesinfo( imagesid )
            }else{
                toastr.error("上传失败:" + this.responseText)
            }
        }

        vm.uploadFailed = function(){
            toastr.error("上传失败:" + this.responseText)
        }
        //上传进度实现方法，上传过程中会频繁调用该方法
        vm.progressFunction = function(evt){
            // event.total是需要传输的总字节，event.loaded是已经传输的字节。如果event.lengthComputable不为真，则event.total等于0
            if (evt.lengthComputable){
                if (Math.round(evt.loaded / evt.total * 100) < 99){
                    $("#upload_progressBar").css("width",Math.round(evt.loaded / evt.total * 100) + "%");
                    $("#upload_progressBar").html(Math.round(evt.loaded / evt.total * 100) + "%");
                    $("#percentage").html("已上传"+ Math.round(evt.loaded / evt.total * 100) + "%");
                }else{
                    $("#upload_progressBar").css("width","99%");
                    $("#upload_progressBar").html("99%");
                    $("#percentage").html("已上传99%");
                }
            }
            var nt = new Date().getTime();//获取当前时间
            var pertime = (nt-ot)/1000; //计算出上次调用该方法时到现在的时间差，单位为s
            ot = new Date().getTime(); //重新赋值时间，用于下次计算
            var perload = evt.loaded - oloaded; //计算该分段上传的文件大小，单位b
            oloaded = evt.loaded;//重新赋值已上传文件大小，用以下次计算
            //上传速度计算
            var speed = perload/pertime;//单位b/s
            var bspeed = speed;
            var units = 'b/s';//单位名称
            if(speed/1024>1){
                speed = speed/1024;
                units = 'k/s';
            }
            if(speed/1024>1){
                speed = speed/1024;
                units = 'M/s';
            }
            speed = speed.toFixed(1);
            //剩余时间
            var resttime = ((evt.total-evt.loaded)/bspeed).toFixed(1);
            if (Math.round(evt.loaded / evt.total * 100) < 99) {
                $("#time").html('，速度：' + speed + units + '，剩余时间：' + resttime + 's');
            }else{
                $("#time").html('，速度：' + speed + units + '，剩余时间：' + resttime + 's'+ '，请等待后端处理结果');
            }
        }

        vm.clickImport = function () {
            document.getElementById("choicefilesx").click();
        };
    }
})();
