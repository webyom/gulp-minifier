gulp = require 'gulp'
coffee = require 'gulp-coffee'

gulp.task 'compile', ->
	gulp.src('src/**/*.coffee')
		.pipe coffee()
		.pipe gulp.dest('lib')

gulp.task 'example', ->
	minify = require './lib/index'
	gulp.src('example/src/**/*')
		.pipe minify
			minify: true
			collapseWhitespace: true
			conservativeCollapse: true
			minifyJS: true
			minifyCSS: true
		.pipe gulp.dest('example/dest')

gulp.task 'default', ['compile']