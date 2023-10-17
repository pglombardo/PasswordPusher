// Taken from the spoiler-alert project at https://github.com/joshbuddy/spoiler-alert
// The node module is not maintained and the npm package is not updated (>7 years as of Jan. 2023).
// Copied and modified here to be compatible with import maps.
//
// I may make new NPM package out of this someday.
//
// Copyright 2013 jQuery Foundation and other contributors
// http://jquery.com/

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///
export function spoilerAlert(selector, opts) {
    var elements = document.querySelectorAll(selector);
    var defaults = {
      max: 4,
      partial: 2,
      hintText: 'Click to reveal completely'
    };

    opts = Object.assign(defaults, opts || {});

    var maxBlur = opts.max;
    var partialBlur = opts.partial;
    var hintText = opts.hintText;

    var processElement = function(index) {
      var el = elements[index];
      el['data-spoiler-state'] = 'shrouded';

      el.style.webkitTransition = '-webkit-filter 250ms';
      el.style.transition = 'filter 250ms';

      var applyBlur = function(radius) {
        el.style.filter = 'blur('+radius+'px)';
        el.style.webkitFilter = 'blur('+radius+'px)';
      }

      applyBlur(maxBlur);

      el.addEventListener('mouseover', function(e) {
        el.style.pointer = 'Cursor';
        el.title = hintText;
        if (el['data-spoiler-state'] === 'shrouded') applyBlur(partialBlur);
      })

      el.addEventListener('mouseout', function(e) {
        el.title = hintText;
        if (el['data-spoiler-state'] === 'shrouded') applyBlur(maxBlur);
      })

      el.addEventListener('click', function(e) {
        switch(el['data-spoiler-state']) {
          case 'shrouded':
            el['data-spoiler-state'] = 'revealed';
            el.title = '';
            el.style.cursor = 'auto';
            applyBlur(0);
            break;
          default:
            el['data-spoiler-state'] = 'shrouded';
            el.title = hintText;
            el.style.cursor = 'pointer';
            applyBlur(maxBlur);
        }
      })
    }

    for (var i = 0; i !== elements.length; i++) processElement(i);
}
