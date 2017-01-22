_ = require 'lodash'
fs = require 'fs'
path = require 'path'
gutil = require 'gulp-util'
through = require 'through2'
minifier = require 'html-minifier'
CleanCSS = require 'clean-css'
UglifyJS = require 'uglify-js'

EOL = '\n'

logErr = (e, file) ->
	console.log 'gulp-minifier Error:', e.message
	console.log 'file:', file.path
	if e.line
		console.log getErrorStack file.contents.toString(), e.line

getErrorStack = (content, line) ->
	startLine = Math.max 1, line - 2
	maxLineNoLen = 0
	content = content.split(/\n|\r\n|\r/).slice startLine - 1, line + 2
	content.forEach (l, i) ->
		lineNo = (startLine + i) + (if startLine + i is line then ' ->' else '   ') + '| '
		maxLineNoLen = Math.max(maxLineNoLen, lineNo.length)
		content[i] = lineNo + l
	content.forEach (l, i) ->
		if l.split('|')[0].length + 2 < maxLineNoLen
			content[i] = ' ' + l
	content.join EOL

module.exports = (opt) ->
	through.obj (file, enc, next) ->
		return @emit 'error', new gutil.PluginError('gulp-minifier', 'Streams not supported') if file.isStream()
		if not file.isNull() and opt.minify
			module.exports.minify(file, opt)
		@push file
		if file._sourceMapFile
			@push file._sourceMapFile
		next()

module.exports.minify = (file, opt) ->
	includeExtNameMap = opt.includeExtNameMap or {}
	extname = path.extname file.path
	if extname in ['.js', '.css', '.html'] or includeExtNameMap[extname]
		content = file.contents.toString()
		if extname is '.js'
			if opt.minifyJS
				keptComment = if opt.getKeptComment then opt.getKeptComment(content, file.path) else ''
				minifyJS = _.extend {}, opt.minifyJS
				minifyJS.fromString = true
				if minifyJS.outSourceMap
					minifyJS.outSourceMap = path.basename(file.path) + '.map'
				try
					source = {}
					source[path.basename(file.path)] = content
					result = UglifyJS.minify(source, minifyJS)
					content = keptComment + result.code
					if minifyJS.outSourceMap
						newFile = new gutil.File
							base: file.base
							cwd: file.cwd
							path: file.path + '.map'
							contents: new Buffer result.map
						file._sourceMapFile = newFile
				catch e
					logErr e, file
		else if extname is '.css'
			if opt.minifyCSS
				keptComment = if opt.getKeptComment then opt.getKeptComment(content, file.path) else ''
				minifyCSS = _.extend {}, opt.minifyCSS
				minifyCSS.keepSpecialComments = 0
				try
					source = {}
					source[path.basename(file.path)] = styles: content
					result = new CleanCSS(minifyCSS).minify source
					content = keptComment + result.styles
					if minifyCSS.sourceMap
						content = content + '\n/*# sourceMappingURL=' + path.basename(file.path) + '.map */'
						newFile = new gutil.File
							base: file.base
							cwd: file.cwd
							path: file.path + '.map'
							contents: new Buffer result.sourceMap.toString()
						file._sourceMapFile = newFile
				catch e
					logErr e, file
		else
			try
				content = minifier.minify content, opt
			catch e
				logErr e, file
		file.contents = new Buffer content
	file
