fs = require 'fs'
path = require 'path'
gutil = require 'gulp-util'
through = require 'through2'
minifier = require 'html-minifier'
CleanCSS = require 'clean-css'
UglifyJS = require 'uglify-js'

module.exports = (opt) ->
	through.obj (file, enc, next) ->
		return @emit 'error', new gutil.PluginError('gulp-minifier', 'Streams not supported') if file.isStream()
		if not file.isNull() and opt.minify
			extname = path.extname file.path
			if extname in ['.js', '.css', '.html']
				content = file.contents.toString()
				if extname is '.js'
					if opt.minifyJS
						if typeof opt.minifyJS is 'object'
							minifyJS = opt.minifyJS
						else
							minifyJS = {}
						minifyJS.fromString = true
						content = UglifyJS.minify(content, minifyJS).code
				else if extname is '.css'
					if opt.minifyCSS
						if typeof opt.minifyCSS is 'object'
							minifyCSS = opt.minifyCSS
						else
							minifyCSS = {}
						content = new CleanCSS(minifyCSS).minify content
				else
					content = minifier.minify content, opt
				file.contents = new Buffer content
		@push file
		next()
