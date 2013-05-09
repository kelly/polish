_            = require 'underscore'
gm           = require 'gm'
async        = require 'async'
path         = require 'path'

imageReplace = (page, selectors, options = {}, callback) ->

  cropAll = (els, callback) ->
    async.map _.flatten(els), cropOne, (err, imgs) -> callback(err, imgs)

  cropOne = (img, callback) ->
    img.path = path.join(options.imgPath, options.prefix + '-' + img.className + '.png')
    gm(path.join(options.tmpPath, options.tmpImgFile))
      .crop(img.width, img.height, img.x, img.y)
      .dither(false)
      .noProfile()
      .write img.path, (err) ->
        if err then callback(err, null) else callback(null, img)

  screenshot = (callback) ->
    page.render path.join(options.tmpPath, options.tmpImgFile)
    callback(null)

  replaceHTML = (imgs, callback) ->
    page.evaluate (imgs) ->
      $.each imgs, (idx, img) ->
        imgEl = "<img src='#{img.path}' width='#{img.width}' height='#{img.height}'/>"
        $(".#{img.className}").html imgEl
      $('body').html()
    , (html) -> 
      callback(null, html)
    , imgs

  getOneEl = (selector, callback) ->
    page.evaluate (selector) ->
      $els = $(selector)
      imgs = []
      $els.each (idx, el) ->
        $el = $(el)
        unless $el[0] == undefined
          imgs.push
            className : if $els.length > 1 then selector.replace(/^(#|\.)/, '') + "-#{idx}" else selector.replace(/^(#|\.)/, '')
            x         : $el.offset().left
            y         : $el.offset().top
            height    : $el.outerHeight()
            width     : $el.outerWidth()
          $el.addClass(imgs[idx].className) # makes replacement easy
      return imgs
    , (imgs) -> 
      callback(null, imgs)
    , selector

  getAllEls = (callback) ->
    async.map selectors, getOneEl, (err, els) -> 
      callback(null, els)

  render = (callback) ->
    async.waterfall [
      screenshot,
      getAllEls,
      cropAll,
      replaceHTML]
    , (err, result) =>
      callback(err, result)
  
  render callback

module.exports = imageReplace