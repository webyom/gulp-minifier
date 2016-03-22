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
		next()

module.exports.minify = (file, opt) ->
	includeExtNameMap = opt.includeExtNameMap or {}
	extname = path.extname file.path
	if extname in ['.js', '.css', '.html'] or includeExtNameMap[extname]
		content = file.contents.toString()
		if extname is '.js'
			if opt.minifyJS
				keptComment = if opt.getKeptComment then opt.getKeptComment(content, file.path) else ''
				if typeof opt.minifyJS is 'object'
					minifyJS = opt.minifyJS
				else
					minifyJS = {}
				minifyJS.fromString = true
				try
					content = keptComment + UglifyJS.minify(content, minifyJS).code
				catch e
					logErr e, file
		else if extname is '.css'
			if opt.minifyCSS
				keptComment = if opt.getKeptComment then opt.getKeptComment(content, file.path) else ''
				if typeof opt.minifyCSS is 'object'
					minifyCSS = opt.minifyCSS
				else
					minifyCSS = {}
				minifyCSS.keepSpecialComments = 0
				try
					content = keptComment + new CleanCSS(minifyCSS).minify content
				catch e
					logErr e, file
		else
			try
				content = minifier.minify content, opt
			catch e
				logErr e, file
		file.contents = new Buffer content
	file
