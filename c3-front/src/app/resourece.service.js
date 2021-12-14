(function() {
  'use strict';

  angular
    .module('openc3')
    .factory('resoureceService', resoureceService);


  /** @ngInject */
  function resoureceService($http, treeService, $q, $state, $log) {

      //----- define here -----

      var List=[

          // ==================== script ==============================

          {
              namespace: 'script.check', method: 'get',
              url:       function(treeid){return '/api/job/scripts/' + treeid},
              actName:   '查询脚本', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'script.create', method: 'post',
              url:       function(treeid){return '/api/job/scripts/' + treeid},
              actName:   '创建脚本', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'script.change', method: 'post',
              url:       function(param){return '/api/job/scripts/' + param[0] +  "/"+ param[1]},
              actName:   '修改脚本', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'script.delete', method: 'delete',
              url:       function(param){return '/api/job/scripts/' + param[0]+  "/"+ param[1]},
              actName:   '删除脚本', confirm: true, failAlert: true, sucAlert: true,
          },
          // =========================== task ======================
          {
              namespace: 'work.runScript', method: 'post',
              url:       function(treeid){return '/api/job/task/' + treeid+  "/plugin_cmd"},
              actName:   '执行脚本', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'work.scp', method: 'post',
              url:       function(treeid){return '/api/job/task/' + treeid + "/plugin_scp"},
              actName:   '分发文件', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'work.runJob', method: 'post',
              url:       function(treeid){return '/api/job/task/' + treeid + "/job"},
              actName:   '执行作业', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'work.rebootTask', method: 'post',
              url:       function(treeid){return '/api/job/task/' + treeid + "/job"},
              actName:   '重新执行任务', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'work.reloadTask', method: 'post',
              url:       function(treeid){return '/api/job/task/' + treeid + "/redo"},
              actName:   '重新执行任务', confirm: true, failAlert: true, sucAlert: true,
          },
          // =========================== crontab  ===========================
          {
              namespace: 'work.createCron', method: 'post',
              url:       function(treeid){return '/api/job/crontab/' + treeid},
              actName:   '创建计划任务', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'work.changeCron', method: 'post',
              url:       function(param){return '/api/job/crontab/' + param[0]+  "/"+ param[1]},
              actName:   '修改计划任务', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'work.delCron', method: 'delete',
              url:       function(param){return '/api/job/crontab/' + param[0]+  "/"+ param[1]},
              actName:   '删除计划任务', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'work.runCron', method: 'post',
              url:       function(param){return '/api/job/crontab/' + param[0]+  "/"+ param[1] + "/status"},
              actName:   '执行计划任务', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'work.stopCron', method: 'post',
              url:       function(param){return '/api/job/crontab/' + param[0]+  "/"+ param[1] + "/status"},
              actName:   '停止计划任务', confirm: true, failAlert: true, sucAlert: true,
          },
          // =========================== task =================
          {
              namespace: 'task.runContinue', method: 'put',
              url:       function(treeid){return '/api/job/subtask/' + treeid},
              actName:   '继续执行', confirm: false, failAlert: true, sucAlert: true,
          }, {
              namespace: 'task.runRunnings', method: 'put',
              url:       function(treeid){return '/api/job/subtask/' + treeid},
              actName:   '重试任务', confirm: true, failAlert: true, sucAlert: true,
          }, {
              namespace: 'task.runIgnore', method: 'post',
              url:       function(treeid){return '/api/job/subtask/' + treeid},
              actName:   '忽略错误', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'task.runShutTask', method: 'post',
              url:       function(treeid){return '/api/job/subtask/' + treeid},
              actName:   '终止整个任务', confirm: true, failAlert: true, sucAlert: true,
          },
          // =========================== job ==================================
          {
              namespace: 'job.createJob', method: 'post',
              url:       function(treeid){return '/api/job/jobs/' + treeid},
              actName:   '创建作业', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'job.createJobxx', method: 'post',
              url:       function(treeid){return '/api/job/jobs/' + treeid},
              actName:   '创建作业', confirm: false, failAlert: true, sucAlert: false,
          },
          {
              namespace: 'job.delJob', method: 'delete',
              url:       function(param){return '/api/job/jobs/' + param[0] +"/"+ param[1]},
              actName:   '删除作业', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'job.updateJob', method: 'post',
              url:       function(param){return '/api/job/jobs/'  + param[0] +"/"+ param[1]},
              actName:   '修改作业', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'job.updateJobxx', method: 'post',
              url:       function(param){return '/api/job/jobs/'  + param[0] +"/"+ param[1]},
              actName:   '修改作业', confirm: false, failAlert: true, sucAlert: false,
          },
          // ======================== user ============================
          {
              namespace: 'user.addUser', method: 'post',
              url:       function(treeid){return '/api/job/userlist/' + treeid},
              actName:   '添加用户', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'user.delUser', method: 'delete',
              url:       function(param){return '/api/job/userlist/' + param[0] +"/"+ param[1]},
              actName:   '删除用户', confirm: true, failAlert: true, sucAlert: true,
          },
            // ======================== machine============================
          {
              namespace: 'machine.addMachine', method: 'post',
              url:       function(treeid){return '/api/job/nodelist/' + treeid},
              actName:   '添加机器', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'machine.delMachine', method: 'delete',
              url:       function(param){return '/api/job/nodelist/' + param[0] +"/"+ param[1]},
              actName:   '删除机器', confirm: true, failAlert: true, sucAlert: true,
          },
            // ======================== machinew============================
          {
              namespace: 'machinew.addMachinew', method: 'post',
              url:       function(treeid){return '/api/connector/default/node/' + treeid},
              actName:   '添加机器', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'machinew.delMachinew', method: 'delete',
              url:       function(param){return '/api/connector/default/node/' + param[0] +"/"+ param[1]},
              actName:   '删除机器', confirm: true, failAlert: true, sucAlert: true,
          },
 
          // ======================== variate============================
          {
            namespace: 'variate.delVV', method: 'delete',
            url:       function(param){return '/api/job/vv/' + param[0] +"/"+ param[1]},
            actName:   '删除该条信息', confirm: true, failAlert: true, sucAlert: true,
            },
          // ======================== nodegroup ============================
          {
              namespace: 'group.create', method: 'post',
              url:       function(treeid){return '/api/job/nodegroup/' + treeid},
              actName:   '创建分组', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'group.change', method: 'post',
              url:       function(param){return '/api/job/nodegroup/'+ param[0] +"/"+ param[1]},
              actName:   '修改分组', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'group.delete', method: 'delete',
              url:       function(param){return '/api/job/nodegroup/'+ param[0] +"/"+ param[1]},
              actName:   '删除分组', confirm: true, failAlert: true, sucAlert: true,
          },
          // ======================== notify ============================
          {
              namespace: 'notify.adduser', method: 'post',
              url:       function(treeid){return '/api/job/notify/'+ treeid},
              actName:   '添加通知人', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'notify.deluser', method: 'delete',
              url:       function(param){return '/api/job/notify/'+  param[0] +"/"+ param[1]},
              actName:   '删除通知人', confirm: true, failAlert: true, sucAlert: true,
          },
          // ======================= global ==============================
          {
              namespace: 'global.update', method: 'post',
              url:       function(){return '/api/job/environment'},
              actName:   '更新报警通知', confirm: true, failAlert: true, sucAlert: true,
          },

          // ======================= var ==============================
          {
              namespace: 'variable.save', method: 'post',
              url:       function(treeid){return '/api/job/variable/'+  treeid},
              actName:   '保存变量', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'variable.update', method: 'post',
              url:       function(treeid){return '/api/job/variable/'+  treeid+"/update"},
              actName:   '保存变量', confirm: true, failAlert: true, sucAlert: true,
          },
          {
              namespace: 'variable.delete', method: 'delete',
              url:       function(treeid){return '/api/job/variable/'+  treeid},
              actName:   '删除变量', confirm: true, failAlert: true, sucAlert: true,
          },
          // ======================= kill task ==============================
          {
              namespace: 'task.kill', method: 'delete',
              url:       function(param){return '/api/job/slave/'+param[0]+"/killtask/"+  param[1]},
              actName:   '终止任务', confirm: true, failAlert: true, sucAlert: true,
          },// ======================= file manage ==============================
          {
              namespace: 'file.delete', method: 'delete',
              url:       function(param){return '/api/job/fileserver/'+param[0]+"/"+  param[1]},
              actName:   '删除文件', confirm: true, failAlert: true, sucAlert: true,
          },// ======================= token ==============================
          {
              namespace: 'token.delete', method: 'delete',
              url:       function(param){return '/api/job/token/'+param[0]+"/"+  param[1]},
              actName:   '删除token', confirm: true, failAlert: true, sucAlert: true,
          },

          // ============================ jobx group job ===========================

//TODO OPENC3 这里临时创建了两个函数xx
          {
              namespace: 'group.creategroupxx', method: 'post',
              url:       function(treeid){return '/api/jobx/group/' + treeid},
              actName:   '创建分组', confirm: false, failAlert: true, sucAlert: false,
          },{
              namespace: 'group.updategroupxx', method: 'post',
              url:       function(params){return '/api/jobx/group/' + params[0] + "/"+ params[1]},
              actName:   '更新分组', confirm: false, failAlert: true, sucAlert: false,
          }, {
              namespace: 'group.creategroup', method: 'post',
              url:       function(treeid){return '/api/jobx/group/' + treeid},
              actName:   '创建分组', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'group.updategroup', method: 'post',
              url:       function(params){return '/api/jobx/group/' + params[0] + "/"+ params[1]},
              actName:   '更新分组', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'group.deletegroup', method: 'delete',
              url:       function(params){return '/api/jobx/group/' + params[0] + "/"+ params[1]},
              actName:   '删除分组', confirm: true, failAlert: true, sucAlert: true,
          },
          // =================================== jobx task =============================
          {
              namespace: 'task.createtask', method: 'post',
              url:       function(treeid){return '/api/jobx/task/' +treeid +'/job/byname'},
              actName:   '创建任务', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'task.stoptask', method: 'delete',
              url:       function(params){return '/api/jobx/task/' +params[0] +'/'+params[1]},
              actName:   '停止任务', confirm: true, failAlert: true, sucAlert: true,
          },{
              namespace: 'task.confirmtask', method: 'put',
              url:       function(params){return '/api/jobx/subtask/' +params[0] +'/'+params[1]+'/confirm'},
              actName:   '执行确认', confirm: true, failAlert: true, sucAlert: true,
          },



      ];


      //----- code begin -----

      var self = {};
      for(var i in List)
      {
          var item = List[i];       // get a dict from List.

          var strings = item.namespace.split('.');      // get namespace split list

          if(strings.length != 2)
          {
              continue;
          }
          if(!self[strings[0]])
          {
              self[strings[0]] = {};
          }

          function action(urlObj, dataObj, wait){

              var res = this;       // res is replaced  item. item = List[i] = {namespace:copy.save, ...}
              angular.element(document).find("div[wait-mark='"+ wait +"']").css('display','');
              angular.element(document).find("div[wait-show='"+ wait +"']").css('display','none');
              if(wait){
                  if(wait.warning){
                      res.warningtext = wait.warning;
                  }else {
                      res.warningtext = null;
                  }
              }else {
                  res.warningtext = null;
              }



              var deferred = $q.defer();            // create a promise obj.

              function httpSuc(response){

                  $log.debug('http suc!', response);
                  if(response.data.stat != true)
                  {
                      if(res.failAlert){

                          swal({ title: res.actName + "失败!", text: response.data.info, type:'error' });
                      }
                      deferred.reject(response.data);       // change state is reject. error
                  }else{

                      if(res.sucAlert){

                          swal({ title: res.actName + "成功!", type:'success' });
                      }
                      deferred.resolve(response.data);      // change state is  resolve. success
                  }
              }

              function httpFail(response){

                  $log.debug('http fail!', response);

                  if(res.failAlert){

                      swal({ title: res.actName + "失败!", text: response.status + ": " + response.statusText, type:'error' });
                  }
                  deferred.reject(response);
              }

              function act(){
                  var url = res.url(urlObj);
                  $log.debug(urlObj);
                  $log.debug('url:', url);
                  $log.debug('data:', dataObj);

                  if(res.method=='post')
                  {
                      $http.post(url, dataObj).then(httpSuc,httpFail).finally(function(){
                          if(wait)
                          {
                              angular.element(document).find("div[wait-mark='"+ wait +"']").css('display','none');
                              angular.element(document).find("div[wait-show='"+ wait +"']").css('display','');
                          }

                      });
                  }else if(res.method=='put')
                  {
                      $http.put(url, dataObj).then(httpSuc,httpFail).finally(function(){
                          if(wait)
                          {
                              angular.element(document).find("div[wait-mark='"+ wait +"']").css('display','none');
                              angular.element(document).find("div[wait-show='"+ wait +"']").css('display','');
                          }

                      });
                  }else if(res.method=='get'){

                      $http.get(url, dataObj).then(httpSuc,httpFail).finally(function(){
                          if(wait)
                          {
                              angular.element(document).find("div[wait-mark='"+ wait +"']").css('display','none');
                              angular.element(document).find("div[wait-show='"+ wait +"']").css('display','');
                          }
                      });
                  }else if(res.method=='delete'){

                      $http.delete(url, dataObj).then(httpSuc,httpFail).finally(function(){
                          if(wait)
                          {
                              angular.element(document).find("div[wait-mark='"+ wait +"']").css('display','none');
                              angular.element(document).find("div[wait-show='"+ wait +"']").css('display','');
                          }
                      });
                  }
              }

              if(res.confirm)
              {
                  swal({

                      title: "确定" + res.actName + "?",
                      text: res.warningtext,
                      type: "warning", showCancelButton: true,
                      confirmButtonColor: "#DD6B55",
                      closeOnConfirm: false, showLoaderOnConfirm: true

                  }, act);
              }else{
                  act();
              }

              return deferred.promise;
          }
          self[strings[0]][strings[1]] = action.bind(item);         // save
      }
      $log.debug(self);
      return self;
  }

})();
