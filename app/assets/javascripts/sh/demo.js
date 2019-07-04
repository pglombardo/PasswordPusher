/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 5);
/******/ })
/************************************************************************/
/******/ ({

/***/ 5:
/***/ (function(module, exports) {

/**
 * Shards — Main demo page script.
 */

// Main demo script.
(function ($) {
  $(document).ready(function() {

    // Hide the loader and show the elements.
    setTimeout(function () {
      $('.loader').addClass('hidden').delay(100).remove();
      $('.slide-in').each(function() {
        $(this).addClass('visible');
      });
    }, 1900);

    // Enable popovers everywhere.
    $('[data-toggle="popover"]').popover();

    // Enable tooltips everywhere.
    $('[data-toggle="tooltip"]').tooltip();

    // Disable example anchors scroll to top action.
    $('.example a').click(function(event) {
        event.target.getAttribute('href') === '#' && event.preventDefault();
    });

    // Hook the "Learn More" button event to scroll to content.
    $('#scroll-to-content').click(function(ev) {
      ev.preventDefault();
      if (typeof ev.target.dataset.scrollTo === 'undefined') {
        return;
      }

      $('html, body').animate({
        scrollTop: $(ev.target.dataset.scrollTo).offset().top - 100
      }, 1000)
    });

    //
    // Setup examples.
    //

    // Slider example 1.
    $('#slider-example-1').customSlider({
      start: [20, 80],
      range: {
        min: 0,
        max: 100
      },
      connect: true
    });

    // Slider example 2.
    $('#slider-example-2').customSlider({
      start: [20, 80],
      range: {
        min: 0,
        max: 100
      },
      connect: true,
      tooltips: true
    });

    // Slider example 3.
    $('#slider-example-3').customSlider({
      start: [20, 80],
      range: {
        min: 0,
        max: 100
      },
      connect: true,
      tooltips: true,
      pips: {
        mode: 'positions',
        values: [0, 25, 50, 75, 100],
        density: 5
      }
    });

    // Datepicker example 1.
    $('#datepicker-example-1').datepicker({});

    // Datepicker example 2.
    $('#datepicker-example-2').datepicker({});
  });
})(jQuery);


/***/ })

/******/ });