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

  var proxyDomain = 'http://open-c3.org'
  /*
   * You can add a proxy to your backend by uncommenting the line below.
   * You just have to configure a context which will we redirected and the target url.
   * Example: $http.get('/users') requests will be automatically proxified.
   *
   * For more details and option, https://github.com/chimurai/http-proxy-middleware/blob/v0.9.0/README.md
   */
  server.middleware = [
      proxyMiddleware('/api/connector/',{ pathRewrite:{'^/api/connector/': '/'}, target: proxyDomain + '/api/connector', changeOrigin: true}),
      proxyMiddleware('/api/pms/',{ pathRewrite:{'^/api/pms/': '/'}, target: proxyDomain + '/api/pms', changeOrigin: true}),
      proxyMiddleware('/api/sso/',{ pathRewrite:{'^/api/sso/': '/'}, target: proxyDomain + '/api/sso', changeOrigin: true}),
      proxyMiddleware('/api/jobx/',{ pathRewrite:{'^/api/jobx/': '/'}, target: proxyDomain + '/api/jobx', changeOrigin: true}),
      proxyMiddleware('/api/job/',{ pathRewrite:{'^/api/job/': '/'}, target: proxyDomain + '/api/job', changeOrigin: true}),
      proxyMiddleware('/api/agent/',{ pathRewrite:{'^/api/agent/': '/'}, target: proxyDomain + '/api/agent', changeOrigin: true}),
      proxyMiddleware('/api/ci/',{ pathRewrite:{'^/api/ci/': '/'}, target: proxyDomain + '/api/ci', changeOrigin: true}),
      proxyMiddleware('/api/tt/',{ pathRewrite:{'^/api/tt/': '/'}, target: proxyDomain + '/api/tt', changeOrigin: true}),
      proxyMiddleware('/third-party/',{ pathRewrite:{'^/third-party/': '/'}, target: proxyDomain + '/third-party', changeOrigin: true})
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
