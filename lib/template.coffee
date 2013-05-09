path         = require 'path'
fs           = require 'fs'

class Template 

  constructor: (@path, @data, @options = {}) ->  
    @parent = @options.parent || null
    @path += '.handlebars'

  readFile: (callback) ->
    fs.readFile @path, 'utf8', (err, data) ->
      if err then console.log err
      callback(data)

  compile: (page, callback) ->
    @readFile (file) =>
      page.evaluate (file, data) ->
        template = Handlebars.compile(file)
        template(data)
      , callback, file, @data

module.exports = Template