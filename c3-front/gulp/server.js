'use strict';

var path = require('path');
var gulp = require('gulp');
var conf = require('./conf');

var browserSync = require('browser-sync');
var browserSyncSpa = require('browser-sync-spa');

var util = require('util');

var proxyMiddleware = require('http-proxy-middleware');

function browserSyncInit(baseDir, browser) {
  browser = browser === undefined ? 'default' : browser;

  var routes = null;
  if(baseDir === conf.paths.src || (util.isArray(baseDir) && baseDir.indexOf(conf.paths.src) !== -1)) {
    routes = {
      '/bower_components': 'bower_components',
      '/custom': 'custom'
    };
  }

  var server = {
    baseDir: baseDir,
    routes: routes
  };

  /*
   * You can add a proxy to your backend by uncommenting the line below.
   * You just have to configure a context which will we redirected and the target url.
   * Example: $http.get('/users') requests will be automatically proxified.
   *
   * For more details and option, https://github.com/chimurai/http-proxy-middleware/blob/v0.9.0/README.md
   */
  server.middleware = [
      proxyMiddleware('/api/connector/',{ pathRewrite:{'^/api/connector/': '/'}, target: 'http://open-c3.org/api/connector', changeOrigin: true}),
      proxyMiddleware('/api/pms/',{ pathRewrite:{'^/api/pms/': '/'}, target: 'http://open-c3.org/api/pms', changeOrigin: true}),
      proxyMiddleware('/api/sso/',{ pathRewrite:{'^/api/sso/': '/'}, target: 'http://open-c3.org/api/sso', changeOrigin: true}),
      proxyMiddleware('/api/jobx/',{ pathRewrite:{'^/api/jobx/': '/'}, target: 'http://open-c3.org/api/jobx', changeOrigin: true}),
      proxyMiddleware('/api/job/',{ pathRewrite:{'^/api/job/': '/'}, target: 'http://open-c3.org/api/job', changeOrigin: true}),
      proxyMiddleware('/api/agent/',{ pathRewrite:{'^/api/agent/': '/'}, target: 'http://open-c3.org/api/agent', changeOrigin: true}),
      proxyMiddleware('/api/ci/',{ pathRewrite:{'^/api/ci/': '/'}, target: 'http://open-c3.org/api/ci', changeOrigin: true})
  ];


  browserSync.instance = browserSync.init({
    startPath: '/',
    server: server,
    browser: browser,
    host: 'dev.open-c3.org',
    open:"external"
  });
}

browserSync.use(browserSyncSpa({
  selector: '[ng-app]'// Only needed for angular apps
}));

gulp.task('serve', ['watch'], function () {
  browserSyncInit([path.join(conf.paths.tmp, '/serve'), conf.paths.src]);
});

gulp.task('serve:dist', ['build'], function () {
  browserSyncInit(conf.paths.dist);
});

gulp.task('serve:e2e', ['inject'], function () {
  browserSyncInit([conf.paths.tmp + '/serve', conf.paths.src], []);
});

gulp.task('serve:e2e-dist', ['build'], function () {
  browserSyncInit(conf.paths.dist, []);
});
