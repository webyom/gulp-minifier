(function() {
  var CleanCSS, EOL, UglifyJS, fs, getErrorStack, gutil, logErr, minifier, path, through;

  fs = require('fs');

  path = require('path');

  gutil = require('gulp-util');

  through = require('through2');

  minifier = require('html-minifier');

  CleanCSS = require('clean-css');

  UglifyJS = require('uglify-js');

  EOL = '\n';

  logErr = function(e, file) {
    console.log('gulp-minifier Error:', e.message);
    console.log('file:', file.path);
    if (e.line) {
      return console.log(getErrorStack(file.contents.toString(), e.line));
    }
  };

  getErrorStack = function(content, line) {
    var maxLineNoLen, startLine;
    startLine = Math.max(1, line - 2);
    maxLineNoLen = 0;
    content = content.split(/\n|\r\n|\r/).slice(startLine - 1, line + 2);
    content.forEach(function(l, i) {
      var lineNo;
      lineNo = (startLine + i) + (startLine + i === line ? ' ->' : '   ') + '| ';
      maxLineNoLen = Math.max(maxLineNoLen, lineNo.length);
      return content[i] = lineNo + l;
    });
    content.forEach(function(l, i) {
      if (l.split('|')[0].length + 2 < maxLineNoLen) {
        return content[i] = ' ' + l;
      }
    });
    return content.join(EOL);
  };

  module.exports = function(opt) {
    return through.obj(function(file, enc, next) {
      if (file.isStream()) {
        return this.emit('error', new gutil.PluginError('gulp-minifier', 'Streams not supported'));
      }
      if (!file.isNull() && opt.minify) {
        module.exports.minify(file, opt);
      }
      this.push(file);
      return next();
    });
  };

  module.exports.minify = function(file, opt) {
    var content, e, error, error1, error2, extname, includeExtNameMap, keptComment, minifyCSS, minifyJS;
    includeExtNameMap = opt.includeExtNameMap || {};
    extname = path.extname(file.path);
    if ((extname === '.js' || extname === '.css' || extname === '.html') || includeExtNameMap[extname]) {
      content = file.contents.toString();
      if (extname === '.js') {
        if (opt.minifyJS) {
          keptComment = opt.getKeptComment ? opt.getKeptComment(content, file.path) : '';
          if (typeof opt.minifyJS === 'object') {
            minifyJS = opt.minifyJS;
          } else {
            minifyJS = {};
          }
          minifyJS.fromString = true;
          try {
            content = keptComment + UglifyJS.minify(content, minifyJS).code;
          } catch (error) {
            e = error;
            logErr(e, file);
          }
        }
      } else if (extname === '.css') {
        if (opt.minifyCSS) {
          keptComment = opt.getKeptComment ? opt.getKeptComment(content, file.path) : '';
          if (typeof opt.minifyCSS === 'object') {
            minifyCSS = opt.minifyCSS;
          } else {
            minifyCSS = {};
          }
          minifyCSS.keepSpecialComments = 0;
          try {
            content = keptComment + new CleanCSS(minifyCSS).minify(content);
          } catch (error1) {
            e = error1;
            logErr(e, file);
          }
        }
      } else {
        try {
          content = minifier.minify(content, opt);
        } catch (error2) {
          e = error2;
          logErr(e, file);
        }
      }
      file.contents = new Buffer(content);
    }
    return file;
  };

}).call(this);
