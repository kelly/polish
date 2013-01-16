gm           = require 'gm'
async        = require 'async'
path         = require 'path'

imageReplace = (@page, @selectors, options) ->

  cropAll = (els, callback) ->
    async.map els, cropOne, (imgs) -> callback(null, imgs)

  cropOne = (img, callback) ->
    img.path = path.join(@options.imgPath, "#{el.replace(/^\w+#(\w+)/,'')}.png}")
    gm(path.join(@options.tmpPath, @options.tmpImgFile))
      .crop(img.width, img.height, img.x, img.y)
      .dither(false)
      .colors(50)
      .bitDepth(8)
      .noProfile()
      .write path, (err) ->
        if err callback(err) else callback(img)

  screenshot = (callback) ->
    @page.render path.join(@options.tmpPath, @options.tmpImageFile)
    callback()

  replaceHTML = (selector, img, callback) ->
    @page.evaluate (selector, img) ->
      $(selector).replaceWith "<img src='#{img.path}' width='#{img.width}' height='#{img.height}' />"
    , callback, selector, img

  getOneEl = (selector, callback) ->
    @page.evaluate (selector, callback) ->
      $els = $(selector)
      imgs = {}
      $els.each ($el) ->
        unless $el[0] == undefined
          img
            x       : $el.offset().left
            y       : $el.offset().top
            height  : $el.outerHeight()
            width   : $el.outerWidth()
          imgs.push img
      imgs
    , callback, selector

  getAllEls = (callback) ->
    async.map @selectors, getOneEl, (els) -> callback(null, els)

  render = ->
    async.waterfall [
      screenshot,
      getAllEls,
      cropAll]
    , (err, result) ->
      return result
  
  render()

module.exports = imageReplace