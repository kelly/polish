_            = require 'underscore'
phantom      = require 'phantomjs-node'
path         = require 'path'
Template     = require './template'
juice        = require 'juice'
fs           = require 'fs'
async        = require 'async'
imageReplace = require './image'
sass         = require 'node-sass'


polish = (layout, locals, options = {}, callback) ->

  dir = path.resolve(__dirname, '..')
  localDir = process.cwd()

  _.defaults options,
    viewportSize : 
      width         : 600
      height        : 480
    tmpImgFile      : 'tmp.png'
    tmpHTMLFile     : 'tmp.html'
    prefix          : ''
    tmpPath         : path.join(dir, '/tmp/');
    imgPath         : path.join(localDir, '/images/')
    layoutsPath     : path.join(dir, '/layouts/')
    includes        : ['http://cdnjs.cloudflare.com/ajax/libs/handlebars.js/1.0.rc.1/handlebars.min.js',
                       'http://cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min.js'] 

  createPage = (callback) ->
    phantom.create (@phantom) =>
      @phantom.createPage (page) =>
        page.set 'viewportSize', width: options.viewportSize.width, height: options.viewportSize.height
        page.set 'settings.loadImages', true
        htmlPath = path.join(options.tmpPath, options.tmpHTMLFile)
        page.open htmlPath, (status) =>
          if status isnt 'success'
            callback 'unable to load file #{@import}'
          else
            @page = page
            callback null

  includeAll = (callback) ->
    async.map options.includes, includeOne, -> callback(null)

  includeOne = (item, callback) ->
    @page.includeJs item, -> 
      callback(null)
      
  compileLayout = (callback) ->
    file = path.join(options.layoutsPath, layout)
    layout = new Template file, locals
    layout.compile @page, (html) -> callback(null, html)

  compileAllTemplates = (callback) ->
    templates = []
    
    _.each locals, (item, key) ->
      unless typeof item == 'string' 
        file = path.join(process.cwd(), item.template)
        templates.push new Template file, item.locals, parent: key

    async.map templates, compileOneTemplate, -> callback(null)

  compileOneTemplate = (template, callback) ->
    template.compile @page, (html) ->
      locals[template.parent] = html
      callback(null)

  createImages = (html, callback) ->
    if options.images 
      appendHtml 'body', html, =>
        imageReplace @page, options.images, options, (err, html) ->
          callback(err, html)
    else callback(null, html)

  readOneSass = (stylesheet, callback) ->
    read = (filePath) ->      
      fs.readFile filePath, 'utf8', (err, data) ->
        sass.render data, (err, css) -> callback(err, css)

    _.each ['.scss','.css'], (type, idx, list) ->
      filePath = path.join(localDir, stylesheet + type)
      fs.exists filePath, (exists) ->
        if exists 
          read(filePath)
        else if idx == list.length 
          callback "#{stylesheet} not found"

  readAllSass = (callback) ->
    async.map options.stylesheets, readOneSass, (err, css) -> 
     if err then callback err
     else callback(null, css)

  inlineCss = (html, callback) ->
    readAllSass (err, cssArray) ->
      css = cssArray.join('')
      if err then callback err
      callback null, juice(html, css)

  clean = (html, callback) ->
    # a bunch of tasks, to make it fit for delivery
    attrs =
      border: 0
      cellpadding: 0
      cellspacing: 0
      height: '100%'
      width: options.viewportSize.width

    @page.evaluate (attrs) ->

      $('table').each (el) ->
        $el = $(el)
        $.each attrs, (key, val) ->
          exists = $el.attr(key)
          if typeof exists != 'undefined' && exists != false
            $el.attr(key, value)

      $('#background-table').html()
    , (html) ->
      callback(null, html)
    , attrs
  
  render = (callback) ->
    async.waterfall [
      createPage,
      includeAll,
      compileAllTemplates,
      compileLayout,
      inlineCss,
      createImages
    ], (err, result) ->
      exit()
      callback result

  exit = ->
    @phantom.exit()

  appendHtml = (selector, html, callback) ->
    @page.evaluate (selector, html) ->
      $(selector).append(html)
    , callback, selector, html

  setCss = (selector, val, callback) ->
    @page.evaluate (selector, val) ->
      $(selector, val).css(val)
    , callback, selector, val

  render callback

module.exports = polish