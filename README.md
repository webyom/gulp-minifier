# gulp-minifier

Minify HTML, JS, CSS with html-minifier, uglify-es, clean-css.

For example:

```js
var minify = require('gulp-minifier');

gulp.task('example', function() {
  return gulp.src('example/src/**/*').pipe(minify({
    minify: true,
    minifyHTML: {
      collapseWhitespace: true,
      conservativeCollapse: true,
    },
    minifyJS: {
      sourceMap: true
    },
    minifyCSS: true,
    getKeptComment: function (content, filePath) {
        var m = content.match(/\/\*![\s\S]*?\*\//img);
        return m && m.join('\n') + '\n' || '';
    }
  })).pipe(gulp.dest('example/dest'));
});
```
