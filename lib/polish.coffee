_            = require 'underscore'
$            = require 'jquery'
phantom      = require 'phantomjs-node'
EventEmitter = require('events').EventEmitter
util         = require 'util' 
gm           = require 'gm'
path         = require 'path'
Template     = require './template'
juice        = require 'juice'
fs           = require 'fs'

class Polish extends EventEmitter

  templates: []

  constructor: (@template, @options = {}) ->

    @on 'error', (msg) -> @report msg

    _.bindAll @, 'report'

    dir = path.resolve(__dirname, '..')

    _.defaults @options,
      viewportSize : 
        width         : 1080
        height        : 768 
      compression     : 70
      tmpImgFile      : 'tmp.png'
      tmpPath         : path.join(dir, '/tmp/');
      imgPath         : path.join(dir, '/images/')
      templatesPath   : path.join(dir, '/templates/')
      stylesheetsPath : path.join(dir, '/stylesheets/')
      includes        : ['http://cdnjs.cloudflare.com/ajax/libs/handlebars.js/1.0.rc.1/handlebars.min.js',
                         'http://cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min.js'] 

  createPage: ->
    phantom.create (@phantom) =>
      @phantom.createPage (page) =>
        page.set 'viewportSize', width: @options.viewportSize.width, height: @options.viewportSize.height
        page.set 'settings.loadImages', true
        page.open @import, (status) =>
          if status isnt 'success'
            @emit 'error', 'unable to load file #{@import}'
          else
            @page = page
            if @options.includes then @include(@options.includes) else @emit 'ready'


  include: (urls) ->
    @page.includeJs urls.pop(), => if urls.length == 0 then @emit 'ready' else @include urls

  report: (msg) ->
    console.log "error: #{msg}"

  toImage: (els...) ->
    @rasterize()
    _.each els, (el) =>
      @getDimensions el, (data) =>
        if data == null 
          @emit 'error', "can\'t find selector: #{el}"
        else 
          path = "#{@options.imgPath}/#{el.replace(/^\w+#(\w+)/,'')}.png"
          gm(@options.tmpPath)
            .crop(data.width, data.height, data.offset.left, data.offset.top)
            .write path, (err) =>
              if err 
                @emit 'error', err
              else 
                @optimize(path)

  template: (file, data) ->
    template = new Template(file, data, path: @options.templatesPath)

  append: (templates...) ->
    @templates = @templates.concat(templates)

  readStylesheets: ->
    fs.readFileSync path.join(@options.stylesheetsPath, 'style.css'), 'utf8'

  compileTemplates: (callback) ->
    html = ''
    lp = (templates) =>
      templates.pop().compile @page, (el) ->
        html += el
        if templates.length == 0 then callback(html) else lp(templates)
    lp @templates

  generate: ->
    @createPage()
    @on 'ready', =>
      @compileTemplates (html) =>
        css = @readStylesheets()
        console.log juice(html, css)
        @exit()

  rasterize: ->
    @page.render path.join(@options.tmpPath, @options.tmpImageFile)

  optimize: (path) ->

  exit: ->
    @phantom.exit()

  setCss: (selector, callback) ->

  getDimensions: (selector, callback) ->
    @page.evaluate (selector, callback) ->
      
      $el = $(selector)
      unless $el[0] == undefined
        offset: $el.offset()
        height: $el.outerHeight()
        width:  $el.outerWidth()

    , callback, selector

module.exports = Polish