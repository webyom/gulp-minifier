gulp = require 'gulp'
coffee = require 'gulp-coffee'
minify = require './src/index'

compile = () ->
	gulp.src('src/**/*.coffee')
		.pipe coffee()
		.pipe gulp.dest('lib')

example = () ->
	gulp.src('example/src/**/*')
		.pipe minify
			minify: true
			minifyHTML:
				collapseWhitespace: true
				conservativeCollapse: true
			minifyJS:
				sourceMap: true
			minifyCSS:
				sourceMap: true
				sourceMapInlineSources: true
			getKeptComment: (content, filePath) ->
				m = content.match /\/\*![\s\S]*?\*\//img
				m && m.join('\n') + '\n' || ''
		.pipe gulp.dest('example/dest')

exports.compile = compile
exports.example = example
exports.default = compile
