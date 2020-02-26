_ = require 'lodash'
fs = require 'fs'
path = require 'path'
Vinyl = require 'vinyl'
PluginError = require 'plugin-error'
through = require 'through2'
HtmlMinifier = require 'html-minifier-terser'
CleanCSS = require 'clean-css'
Terser = require 'terser'

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
		return @emit 'error', new PluginError('gulp-minifier', 'Streams not supported') if file.isStream()
		if not file.isNull() and opt.minify
			module.exports.minify(file, opt)
		if file._sourceMapFile
			@push file._sourceMapFile
		@push file
		next()

module.exports.minify = (file, opt) ->
	includeExtNameMap = opt.includeExtNameMap or {}
	extname = path.extname file.path
	if extname in ['.js', '.css', '.html'] or includeExtNameMap[extname]
		content = file.contents.toString()
		if extname is '.js'
			if opt.minifyJS
				minifyJS = _.extend {}, opt.minifyJS
				if minifyJS.sourceMap
					sourceMap = if typeof minifyJS.sourceMap is 'object' then minifyJS.sourceMap else {}
					fileName = path.basename file.path
					sourceMapUrl = fileName + '.map'
					minifyJS.sourceMap =
						includeSources: sourceMap.includeSources isnt false
						filename: fileName
						url: if sourceMap.getUrl then sourceMap.getUrl(file.path) else sourceMapUrl
					if fs.existsSync file.path + '.map'
						minifyJS.sourceMap.content = fs.readFileSync(file.path + '.map').toString()
				try
					source = {}
					source[path.basename(file.path)] = content
					result = Terser.minify(source, minifyJS)
					throw result.error if result.error
					content = result.code
					if minifyJS.sourceMap
						newFile = new Vinyl
							base: file.base
							cwd: file.cwd
							path: file.path + '.map'
							contents: Buffer.from result.map
						file._sourceMapFile = newFile
				catch e
					logErr e, file
		else if extname is '.css'
			if opt.minifyCSS
				minifyCSS = _.extend {}, opt.minifyCSS
				try
					source = {}
					source[path.basename(file.path)] = styles: content
					result = new CleanCSS(minifyCSS).minify source
					content = result.styles
					if minifyCSS.sourceMap
						content = content + '\n/*# sourceMappingURL=' + path.basename(file.path) + '.map */'
						newFile = new Vinyl
							base: file.base
							cwd: file.cwd
							path: file.path + '.map'
							contents: Buffer.from result.sourceMap.toString()
						file._sourceMapFile = newFile
				catch e
					logErr e, file
		else
			if opt.minifyHTML
				try
					minifyHTML = _.extend {}, opt.minifyHTML
					content = HtmlMinifier.minify content, minifyHTML
				catch e
					logErr e, file
		file.contents = Buffer.from content
	file
