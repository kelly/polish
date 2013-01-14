path         = require('path')
fs           = require('fs')
EventEmitter = require('events').EventEmitter
$            = require 'jquery'

class Template extends EventEmitter

  format: 'html'
  el: undefined

  constructor: (fileName, @data, @options) ->  
    filePath = path.join(@options.path, fileName + '.handlebars')

    @page = @options.page
    @file = fs.readFileSync(filePath, 'utf8');

  compile: (page, callback) ->
    page.evaluate (file, data) ->
      template = Handlebars.compile(file)
      template(data)
    , callback, @file, @data

  toImage: ->
    @format = 'img'
    # @imgEl = $('td').replaceWith('<img>')

module.exports = Template