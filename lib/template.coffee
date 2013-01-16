path         = require('path')
fs           = require('fs')
EventEmitter = require('events').EventEmitter
$            = require 'jquery'

class Template extends EventEmitter

  format: 'html'
  el: undefined

  constructor: (filePath, @data, @options = {}) ->  
    filePath = filePath + '.handlebars'
    @file = fs.readFileSync(filePath, 'utf8');
    @parent = @options.parent || null

  compile: (page, callback) ->
    page.evaluate (file, data) ->
      template = Handlebars.compile(file)
      template(data)
    , callback, @file, @data

module.exports = Template