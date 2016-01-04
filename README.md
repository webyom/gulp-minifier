# gulp-minifier

Minify HTML, JS, CSS with html-minifier, UglifyJS, CleanCSS.

For example:

```js
var minify = require('gulp-minifier');

gulp.task('example', function() {
  return gulp.src('example/src/**/*').pipe(minify({
    minify: true,
    collapseWhitespace: true,
    conservativeCollapse: true,
    minifyJS: true,
    minifyCSS: true,
    getKeptComment: function (content, filePath) {
        var m = content.match(/\/\*![\s\S]*?\*\//img);
        return m && m.join('\n') + '\n' || '';
    }
  })).pipe(gulp.dest('example/dest'));
});
```
