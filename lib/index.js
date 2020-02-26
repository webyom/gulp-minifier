(function() {
  var CleanCSS, EOL, HtmlMinifier, PluginError, Terser, Vinyl, _, fs, getErrorStack, logErr, path, through;

  _ = require('lodash');

  fs = require('fs');

  path = require('path');

  Vinyl = require('vinyl');

  PluginError = require('plugin-error');

  through = require('through2');

  HtmlMinifier = require('html-minifier-terser');

  CleanCSS = require('clean-css');

  Terser = require('terser');

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
        return this.emit('error', new PluginError('gulp-minifier', 'Streams not supported'));
      }
      if (!file.isNull() && opt.minify) {
        module.exports.minify(file, opt);
      }
      if (file._sourceMapFile) {
        this.push(file._sourceMapFile);
      }
      this.push(file);
      return next();
    });
  };

  module.exports.minify = function(file, opt) {
    var content, e, extname, fileName, includeExtNameMap, minifyCSS, minifyHTML, minifyJS, newFile, result, source, sourceMap, sourceMapUrl;
    includeExtNameMap = opt.includeExtNameMap || {};
    extname = path.extname(file.path);
    if ((extname === '.js' || extname === '.css' || extname === '.html') || includeExtNameMap[extname]) {
      content = file.contents.toString();
      if (extname === '.js') {
        if (opt.minifyJS) {
          minifyJS = _.extend({}, opt.minifyJS);
          if (minifyJS.sourceMap) {
            sourceMap = typeof minifyJS.sourceMap === 'object' ? minifyJS.sourceMap : {};
            fileName = path.basename(file.path);
            sourceMapUrl = fileName + '.map';
            minifyJS.sourceMap = {
              includeSources: sourceMap.includeSources !== false,
              filename: fileName,
              url: sourceMap.getUrl ? sourceMap.getUrl(file.path) : sourceMapUrl
            };
            if (fs.existsSync(file.path + '.map')) {
              minifyJS.sourceMap.content = fs.readFileSync(file.path + '.map').toString();
            }
          }
          try {
            source = {};
            source[path.basename(file.path)] = content;
            result = Terser.minify(source, minifyJS);
            if (result.error) {
              throw result.error;
            }
            content = result.code;
            if (minifyJS.sourceMap) {
              newFile = new Vinyl({
                base: file.base,
                cwd: file.cwd,
                path: file.path + '.map',
                contents: Buffer.from(result.map)
              });
              file._sourceMapFile = newFile;
            }
          } catch (error) {
            e = error;
            logErr(e, file);
          }
        }
      } else if (extname === '.css') {
        if (opt.minifyCSS) {
          minifyCSS = _.extend({}, opt.minifyCSS);
          try {
            source = {};
            source[path.basename(file.path)] = {
              styles: content
            };
            result = new CleanCSS(minifyCSS).minify(source);
            content = result.styles;
            if (minifyCSS.sourceMap) {
              content = content + '\n/*# sourceMappingURL=' + path.basename(file.path) + '.map */';
              newFile = new Vinyl({
                base: file.base,
                cwd: file.cwd,
                path: file.path + '.map',
                contents: Buffer.from(result.sourceMap.toString())
              });
              file._sourceMapFile = newFile;
            }
          } catch (error) {
            e = error;
            logErr(e, file);
          }
        }
      } else {
        if (opt.minifyHTML) {
          try {
            minifyHTML = _.extend({}, opt.minifyHTML);
            content = HtmlMinifier.minify(content, minifyHTML);
          } catch (error) {
            e = error;
            logErr(e, file);
          }
        }
      }
      file.contents = Buffer.from(content);
    }
    return file;
  };

}).call(this);
