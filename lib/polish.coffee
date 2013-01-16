_            = require 'underscore'
phantom      = require 'phantomjs-node'
path         = require 'path'
Template     = require './template'
juice        = require 'juice'
fs           = require 'fs'
async        = require 'async'

class Polish

  constructor: (@layout, @locals, @options = {}) ->

    _.bindAll @, 'include', 'createPage', 'compileTemplates', 'compileLayout', 'inlineCSS'

    dir = path.resolve(__dirname, '..')

    _.defaults @options,
      viewportSize : 
        width         : 1080
        height        : 768
      compression     : 70
      tmpImgFile      : 'tmp.png'
      tmpHTMLFile     : 'tmp.html'
      tmpPath         : path.join(dir, '/tmp/');
      imgPath         : path.join(dir, '/images/')
      layoutsPath     : path.join(dir, '/layouts/')
      stylesheetsPath : path.join(dir, '/stylesheets/')
      includes        : ['http://cdnjs.cloudflare.com/ajax/libs/handlebars.js/1.0.rc.1/handlebars.min.js',
                         'http://cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min.js'] 
    @render()

  createPage: (callback) ->
    phantom.create (@phantom) =>
      @phantom.createPage (page) =>
        page.set 'viewportSize', width: @options.viewportSize.width, height: @options.viewportSize.height
        page.set 'settings.loadImages', true
        htmlPath = path.join(@options.tmpPath, @options.tmpHTMLFile)
        page.open htmlPath, (status) =>
          if status isnt 'success'
            callback 'unable to load file #{@import}'
          else
            @page = page
            callback null

  include: (callback) ->
    if @options.includes
      add = (urls) =>
        @page.includeJs urls.pop(), -> 
          if urls.length == 0 then callback(null) else add urls
      add @options.includes
    else callback()

  compileLayout: (callback) ->
    layout = new Template path.join(@options.layoutsPath, @layout), @locals
    layout.compile @page, (html) ->
      callback(null, html)

  compileTemplates: (callback) ->
    templates = []

    lp = (templates) =>
      if templates.length == 0 
        callback(null)
      else
        template = templates.pop()
        template.compile @page, (html) =>
          @locals[template.parent] = html
          lp templates
    
    _.each @locals, (item, key) ->
      unless typeof item == 'string' 
        templates.push new Template item.template, item.locals, parent: key

    lp templates

  inlineCSS: (html, callback) ->
    css = fs.readFileSync path.join(@options.stylesheetsPath, 'base.css'), 'utf8'
    callback null, juice(html, css)
  
  render: ->
    async.waterfall [
      @createPage,
      @include,
      @compileTemplates,
      @compileLayout,
      @inlineCSS
    ], (err, result) ->
      console.log result

    # @createPage()
    # @on 'ready', =>
    #   @compile (html) =>
    #     css = fs.readFileSync path.join(@options.stylesheetsPath, 'base.css'), 'utf8'
    #     # html = htmlToImage(@page, '.image')
    #     @exit()
    #     console.log juice(html, css)

  exit: ->
    @phantom.exit()

  setCSS: (selector, val, callback) ->
    @page.evaluate (selector, val) ->
      $(selector, val).css(val)
    , callback, selector, val

module.exports = Polish