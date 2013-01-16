gm           = require 'gm'
async        = require 'async'

imageReplace = (@page, @selectors, options) ->

  cropAll: (callback) ->

    crop = (selectors) ->
      el
      @getDimensions selector, (els) =>

        if data == null then console.log "can\'t find selector: #{el}" else @crop(img)

    crop @selectors

  crop: (img, callback) ->
    img.path = path.join(@options.imgPath, "#{el.replace(/^\w+#(\w+)/,'')}.png}")
    gm(path.join(@options.tmpPath, @options.tmpImgFile))
      .crop(img.width, img.height, img.x, img.y)
      .dither(false)
      .colors(50)
      .bitDepth(8)
      .noProfile()
      .write path, (err) =>
        if err console.log err else callback(img)

  screenshot: (callback) ->
    @page.render path.join(@options.tmpPath, @options.tmpImageFile)
    callback()

  replaceHTML: (selector, img, callback) ->
    @page.evaluate (selector, img) ->
      $(selector).replaceWith "<img src='#{img.path}' width='#{img.width}' height='#{img.height}' />"
    , callback, selector, img

  getEl: (selector, callback) ->
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

  getAllEls: (callback) ->
    els = []

    get = (selectors) =>
      @getEl selector, (e) ->
        els.push e
        
    @getE

  render: ->
    async.waterfall [@screenshot,
      @getEls,
      @cropAll,
      @replaceHTML]
    , (err, result) ->
      return result

    # @getEls (els) =>
    #   @cropAll (imgs) =>
    #     @replaceHTML (html) ->
    #       return html

  return @render()

module.exports = imageReplace