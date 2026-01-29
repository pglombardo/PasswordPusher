// ES Module version of spoiler-alert functionality
// Original source: https://github.com/joshbuddy/spoiler-alert

// Polyfill for Object.assign if not available
if (typeof Object.assign !== 'function') {
  Object.assign = function (target) {
    'use strict';
    if (target === undefined || target === null) {
      throw new TypeError('Cannot convert undefined or null to object');
    }

    const output = Object(target);
    for (let index = 1; index < arguments.length; index++) {
      const source = arguments[index];
      if (source !== undefined && source !== null) {
        for (const nextKey in source) {
          if (source.hasOwnProperty(nextKey)) {
            output[nextKey] = source[nextKey];
          }
        }
      }
    }
    return output;
  };
}

export function spoilerAlert(selector, opts) {
  const elements = document.querySelectorAll(selector);
  const defaults = {
    max: 4,
    partial: 2,
    hintText: 'Click to reveal completely'
  };

  opts = Object.assign(defaults, opts || {});

  const maxBlur = opts.max;
  const partialBlur = opts.partial;
  const hintText = opts.hintText;

  const processElement = function(index) {
    const el = elements[index];
    el.setAttribute('data-spoiler-state', 'shrouded');

    el.style.webkitTransition = '-webkit-filter 250ms';
    el.style.transition = 'filter 250ms';

    const applyBlur = function(radius) {
      el.style.filter = 'blur('+radius+'px)';
      el.style.webkitFilter = 'blur('+radius+'px)';
    }

    applyBlur(maxBlur);

    el.addEventListener('mouseover', function(e) {
      el.style.cursor = 'pointer';
      el.title = hintText;
      if (el.getAttribute('data-spoiler-state') === 'shrouded') applyBlur(partialBlur);
    })

    el.addEventListener('mouseout', function(e) {
      el.title = hintText;
      if (el.getAttribute('data-spoiler-state') === 'shrouded') applyBlur(maxBlur);
    })

    el.addEventListener('click', function(e) {
      switch (el.getAttribute('data-spoiler-state')) {
        case 'shrouded':
          el.setAttribute('data-spoiler-state', 'revealed');
          el.title = '';
          el.style.cursor = 'auto';
          applyBlur(0);
          break;
        default:
          el.setAttribute('data-spoiler-state', 'shrouded');
          el.title = hintText;
          el.style.cursor = 'pointer';
          applyBlur(maxBlur);
      }
    })
  }

  for (let i = 0; i !== elements.length; i++) processElement(i);
}

// Also export as default for compatibility
export default spoilerAlert;
