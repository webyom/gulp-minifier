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
    minifyCSS: true
  })).pipe(gulp.dest('example/dest'));
});
```
