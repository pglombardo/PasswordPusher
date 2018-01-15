(function( $ ) {
  var userAgent = navigator.userAgent.toLowerCase();
  var browser = {}
  browser.mozilla = /mozilla/.test(userAgent) && !/webkit/.test(userAgent);
  browser.webkit = /webkit/.test(userAgent);
  browser.opera = /opera/.test(userAgent);
  browser.msie = /msie/.test(userAgent);

  var defaults = {
    max: 4,
    partial: 2,
    hintText: 'Click to reveal completely'
  }

  var alertShown = false

  $.fn.spoilerAlert = function(opts) {
    opts = $.extend(defaults, opts || {})
    var maxBlur = opts.max
    var partialBlur = opts.partial
    var hintText = opts.hintText
    if (!alertShown && browser.msie) {
      alert("WARNING, this site contains spoilers!")
      alertShown = true
    }
    return this.each(function() {
      var $spoiler = $(this)
      $spoiler.data('spoiler-state', 'shrouded')

      var animationTimer = null
      var currentBlur = maxBlur

      var cancelTimer = function() {
        if (animationTimer) {
          clearTimeout(animationTimer)
          animationTimer = null
        }
      }

      var applyBlur = function(radius) {
        currentBlur = radius
        if (browser.msie) {
          var filterValue = "progid:DXImageTransform.Microsoft.Blur(pixelradius="+radius+")"
          $spoiler.css('filter', filterValue)
        } else if (browser.mozilla) {
          var filterValue = radius > 0 ? "url(\"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg'>" +
            "<filter id='blur'><feGaussianBlur stdDeviation='" + radius + "' /></filter></svg>#blur\")" : ''
          $spoiler.css('filter', filterValue)
        } else {
          var filterValue = radius > 0 ? 'blur('+radius+'px)' : ''
          $spoiler.css('filter', filterValue)
            .css('-webkit-filter', filterValue)
            .css('-moz-filter', filterValue)
            .css('-o-filter', filterValue)
            .css('-ms-filter', filterValue)
        }
      }

      var performBlur = function(targetBlur, direction) {
        cancelTimer()
        if (currentBlur != targetBlur) {
          applyBlur(currentBlur + direction)
          animationTimer = setTimeout(function() { performBlur(targetBlur, direction) }, 10)
        }
      }

      // Does the user have IE 9 or less?
      var ieLessThanTen = function() {
        // This conditional check will return true if browser supports CANVAS
        // IE9 and under do not support CANVAS and this function is only ever
        // called by the IE checking function anyway
        return !document.createElement('canvas').getContext
      }

      applyBlur(currentBlur)

      $spoiler.on('mouseover', function(e) {
        $spoiler.css('cursor', 'pointer')
          .attr('title', hintText)
        if ($spoiler.data('spoiler-state') == 'shrouded') performBlur(partialBlur, -1)
      })
      $spoiler.on('mouseout', function(e) {
        if ($spoiler.data('spoiler-state') == 'shrouded') performBlur(maxBlur, 1)
      })
      $spoiler.on('click', function(e) {
        if ($spoiler.data('spoiler-state') == 'shrouded') {
          $spoiler.data('spoiler-state', 'revealed')
            .attr('title', '')
            .css('cursor', 'auto')
          performBlur(0, -1)
        } else {
          $spoiler.data('spoiler-state', 'shrouded')
            .attr('title', hintText)
            .css('cursor', 'pointer')
          performBlur(partialBlur, 1)
        }
      })
    })

  };
})( jQuery );
