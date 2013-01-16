_            = require 'underscore'
phantom      = require 'phantomjs-node'
path         = require 'path'
Template     = require './template'
juice        = require 'juice'
fs           = require 'fs'
async        = require 'async'
imageReplace = require './image'

polish = (@layout, @locals, @options = {}) ->

  # _.bindAll @, 'include', 'createPage', 'compileTemplates', 'compileLayout', 'inlineCSS'

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

  createPage = (callback) ->
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

  includeAll = (callback) ->
    async.map @options.includes, includeOne, -> callback(null)

  includeOne = (item, callback) ->
    @page.includeJs item, -> 
      callback(null)
      
  compileLayout = (callback) ->
    layout = new Template path.join(@options.layoutsPath, @layout), @locals
    layout.compile @page, (html) -> callback(null, html)

  compileAllTemplates = (callback) ->
    templates = []
    
    _.each @locals, (item, key) ->
      unless typeof item == 'string' 
        templates.push new Template item.template, item.locals, parent: key

    async.map templates, compileOneTemplate, -> callback(null)

  compileOneTemplate = (template, callback) ->
    template.compile @page, (html) =>
      @locals[template.parent] = html
      callback(null)

  createImages = ->
    imageReplace @page, @options.images

  inlineCSS = (html, callback) ->
    fs.readFile path.join(@options.stylesheetsPath, 'base.css'), 'utf8', (err, data) ->
      if err then callback err
      callback null, juice(html, data)
  
  render = (callback) ->
    async.waterfall [
      createPage,
      includeAll,
      compileAllTemplates,
      compileLayout,
      inlineCSS,
      createImages
    ], (err, result) ->
      if err then callback err else callback result

  exit = ->
    @phantom.exit()

  setCSS = (selector, val, callback) ->
    @page.evaluate (selector, val) ->
      $(selector, val).css(val)
    , callback, selector, val

  render (result) ->
    console.log result

module.exports = polish