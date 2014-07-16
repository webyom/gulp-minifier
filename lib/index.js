(function() {
  var CleanCSS, UglifyJS, fs, gutil, minifier, path, through;

  fs = require('fs');

  path = require('path');

  gutil = require('gulp-util');

  through = require('through2');

  minifier = require('html-minifier');

  CleanCSS = require('clean-css');

  UglifyJS = require('uglify-js');

  module.exports = function(opt) {
    return through.obj(function(file, enc, next) {
      var content, extname, minifyCSS, minifyJS;
      if (file.isStream()) {
        return this.emit('error', new gutil.PluginError('gulp-minifier', 'Streams not supported'));
      }
      if (!file.isNull() && opt.minify) {
        extname = path.extname(file.path);
        if (extname === '.js' || extname === '.css' || extname === '.html') {
          content = file.contents.toString();
          if (extname === '.js') {
            if (opt.minifyJS) {
              if (typeof opt.minifyJS === 'object') {
                minifyJS = opt.minifyJS;
              } else {
                minifyJS = {};
              }
              minifyJS.fromString = true;
              content = UglifyJS.minify(content, minifyJS).code;
            }
          } else if (extname === '.css') {
            if (opt.minifyCSS) {
              if (typeof opt.minifyCSS === 'object') {
                minifyCSS = opt.minifyCSS;
              } else {
                minifyCSS = {};
              }
              content = new CleanCSS(minifyCSS).minify(content);
            }
          } else {
            content = minifier.minify(content, opt);
          }
          file.contents = new Buffer(content);
        }
      }
      this.push(file);
      return next();
    });
  };

}).call(this);
