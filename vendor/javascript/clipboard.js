var t="undefined"!==typeof globalThis?globalThis:"undefined"!==typeof self?self:global;var e={};(function webpackUniversalModuleDefinition(t,n){e=n()})(0,(function(){return function(){var e={686:function(e,n,r){r.d(n,{default:function(){return h}});var o=r(279);var i=r.n(o);var a=r(370);var u=r.n(a);var c=r(817);var l=r.n(c);
/**
           * Executes a given operation type.
           * @param {String} type
           * @return {Boolean}
           */
function command(t){try{return document.execCommand(t)}catch(t){return false}}
/**
           * Cut action wrapper.
           * @param {String|HTMLElement} target
           * @return {String}
           */
var f=function ClipboardActionCut(t){var e=l()(t);command("cut");return e};var s=f;
/**
           * Creates a fake textarea element with a value.
           * @param {String} value
           * @return {HTMLElement}
           */
function createFakeElement(t){var e="rtl"===document.documentElement.getAttribute("dir");var n=document.createElement("textarea");n.style.fontSize="12pt";n.style.border="0";n.style.padding="0";n.style.margin="0";n.style.position="absolute";n.style[e?"right":"left"]="-9999px";var r=window.pageYOffset||document.documentElement.scrollTop;n.style.top="".concat(r,"px");n.setAttribute("readonly","");n.value=t;return n}
/**
           * Create fake copy action wrapper using a fake element.
           * @param {String} target
           * @param {Object} options
           * @return {String}
           */
var p=function fakeCopyAction(t,e){var n=createFakeElement(t);e.container.appendChild(n);var r=l()(n);command("copy");n.remove();return r};
/**
           * Copy action wrapper.
           * @param {String|HTMLElement} target
           * @param {Object} options
           * @return {String}
           */var d=function ClipboardActionCopy(t){var e=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{container:document.body};var n="";if("string"===typeof t)n=p(t,e);else if(t instanceof HTMLInputElement&&!["text","search","url","tel","password"].includes(null===t||void 0===t?void 0:t.type))n=p(t.value,e);else{n=l()(t);command("copy")}return n};var y=d;function _typeof(t){_typeof="function"===typeof Symbol&&"symbol"===typeof Symbol.iterator?function _typeof(t){return typeof t}:function _typeof(t){return t&&"function"===typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t};return _typeof(t)}
/**
           * Inner function which performs selection from either `text` or `target`
           * properties and then executes copy or cut operations.
           * @param {Object} options
           */var v=function ClipboardActionDefault(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};var e=t.action,n=void 0===e?"copy":e,r=t.container,o=t.target,i=t.text;if("copy"!==n&&"cut"!==n)throw new Error('Invalid "action" value, use either "copy" or "cut"');if(void 0!==o){if(!o||"object"!==_typeof(o)||1!==o.nodeType)throw new Error('Invalid "target" value, use a valid Element');if("copy"===n&&o.hasAttribute("disabled"))throw new Error('Invalid "target" attribute. Please use "readonly" instead of "disabled" attribute');if("cut"===n&&(o.hasAttribute("readonly")||o.hasAttribute("disabled")))throw new Error('Invalid "target" attribute. You can\'t cut text from elements with "readonly" or "disabled" attributes')}return i?y(i,{container:r}):o?"cut"===n?s(o):y(o,{container:r}):void 0};var b=v;function clipboard_typeof(t){clipboard_typeof="function"===typeof Symbol&&"symbol"===typeof Symbol.iterator?function _typeof(t){return typeof t}:function _typeof(t){return t&&"function"===typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t};return clipboard_typeof(t)}function _classCallCheck(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}function _defineProperties(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||false;r.configurable=true;"value"in r&&(r.writable=true);Object.defineProperty(t,r.key,r)}}function _createClass(t,e,n){e&&_defineProperties(t.prototype,e);n&&_defineProperties(t,n);return t}function _inherits(t,e){if("function"!==typeof e&&null!==e)throw new TypeError("Super expression must either be null or a function");t.prototype=Object.create(e&&e.prototype,{constructor:{value:t,writable:true,configurable:true}});e&&_setPrototypeOf(t,e)}function _setPrototypeOf(t,e){_setPrototypeOf=Object.setPrototypeOf||function _setPrototypeOf(t,e){t.__proto__=e;return t};return _setPrototypeOf(t,e)}function _createSuper(e){var n=_isNativeReflectConstruct();return function _createSuperInternal(){var r,o=_getPrototypeOf(e);if(n){var i=_getPrototypeOf(this||t).constructor;r=Reflect.construct(o,arguments,i)}else r=o.apply(this||t,arguments);return _possibleConstructorReturn(this||t,r)}}function _possibleConstructorReturn(t,e){return!e||"object"!==clipboard_typeof(e)&&"function"!==typeof e?_assertThisInitialized(t):e}function _assertThisInitialized(t){if(void 0===t)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return t}function _isNativeReflectConstruct(){if("undefined"===typeof Reflect||!Reflect.construct)return false;if(Reflect.construct.sham)return false;if("function"===typeof Proxy)return true;try{Date.prototype.toString.call(Reflect.construct(Date,[],(function(){})));return true}catch(t){return false}}function _getPrototypeOf(t){_getPrototypeOf=Object.setPrototypeOf?Object.getPrototypeOf:function _getPrototypeOf(t){return t.__proto__||Object.getPrototypeOf(t)};return _getPrototypeOf(t)}
/**
           * Helper function to retrieve attribute value.
           * @param {String} suffix
           * @param {Element} element
           */function getAttributeValue(t,e){var n="data-clipboard-".concat(t);if(e.hasAttribute(n))return e.getAttribute(n)}var _=function(e){_inherits(Clipboard,e);var n=_createSuper(Clipboard);
/**
             * @param {String|HTMLElement|HTMLCollection|NodeList} trigger
             * @param {Object} options
             */function Clipboard(e,r){var o;_classCallCheck(this||t,Clipboard);o=n.call(this||t);o.resolveOptions(r);o.listenClick(e);return o}
/**
             * Defines if attributes would be resolved using internal setter functions
             * or custom functions that were passed in the constructor.
             * @param {Object} options
             */_createClass(Clipboard,[{key:"resolveOptions",value:function resolveOptions(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};(this||t).action="function"===typeof e.action?e.action:(this||t).defaultAction;(this||t).target="function"===typeof e.target?e.target:(this||t).defaultTarget;(this||t).text="function"===typeof e.text?e.text:(this||t).defaultText;(this||t).container="object"===clipboard_typeof(e.container)?e.container:document.body}
/**
               * Adds a click event listener to the passed trigger.
               * @param {String|HTMLElement|HTMLCollection|NodeList} trigger
               */},{key:"listenClick",value:function listenClick(e){var n=this||t;(this||t).listener=u()(e,"click",(function(t){return n.onClick(t)}))}
/**
               * Defines a new `ClipboardAction` on each click event.
               * @param {Event} e
               */},{key:"onClick",value:function onClick(e){var n=e.delegateTarget||e.currentTarget;var r=this.action(n)||"copy";var o=b({action:r,container:(this||t).container,target:this.target(n),text:this.text(n)});this.emit(o?"success":"error",{action:r,text:o,trigger:n,clearSelection:function clearSelection(){n&&n.focus();window.getSelection().removeAllRanges()}})}
/**
               * Default `action` lookup function.
               * @param {Element} trigger
               */},{key:"defaultAction",value:function defaultAction(t){return getAttributeValue("action",t)}
/**
               * Default `target` lookup function.
               * @param {Element} trigger
               */},{key:"defaultTarget",value:function defaultTarget(t){var e=getAttributeValue("target",t);if(e)return document.querySelector(e)}
/**
               * Allow fire programmatically a copy action
               * @param {String|HTMLElement} target
               * @param {Object} options
               * @returns Text copied.
               */},{key:"defaultText",
/**
               * Default `text` lookup function.
               * @param {Element} trigger
               */
value:function defaultText(t){return getAttributeValue("text",t)}},{key:"destroy",value:function destroy(){(this||t).listener.destroy()}}],[{key:"copy",value:function copy(t){var e=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{container:document.body};return y(t,e)}
/**
               * Allow fire programmatically a cut action
               * @param {String|HTMLElement} target
               * @returns Text cutted.
               */},{key:"cut",value:function cut(t){return s(t)}
/**
               * Returns the support of the given action, or all actions if no action is
               * given.
               * @param {String} [action]
               */},{key:"isSupported",value:function isSupported(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:["copy","cut"];var e="string"===typeof t?[t]:t;var n=!!document.queryCommandSupported;e.forEach((function(t){n=n&&!!document.queryCommandSupported(t)}));return n}}]);return Clipboard}(i());var h=_},828:function(t){var e=9;if("undefined"!==typeof Element&&!Element.prototype.matches){var n=Element.prototype;n.matches=n.matchesSelector||n.mozMatchesSelector||n.msMatchesSelector||n.oMatchesSelector||n.webkitMatchesSelector}
/**
           * Finds the closest parent that matches a selector.
           *
           * @param {Element} element
           * @param {String} selector
           * @return {Function}
           */function closest(t,n){while(t&&t.nodeType!==e){if("function"===typeof t.matches&&t.matches(n))return t;t=t.parentNode}}t.exports=closest},438:function(e,n,r){var o=r(828);
/**
           * Delegates event to a selector.
           *
           * @param {Element} element
           * @param {String} selector
           * @param {String} type
           * @param {Function} callback
           * @param {Boolean} useCapture
           * @return {Object}
           */function _delegate(e,n,r,o,i){var a=listener.apply(this||t,arguments);e.addEventListener(r,a,i);return{destroy:function(){e.removeEventListener(r,a,i)}}}
/**
           * Delegates event to a selector.
           *
           * @param {Element|String|Array} [elements]
           * @param {String} selector
           * @param {String} type
           * @param {Function} callback
           * @param {Boolean} useCapture
           * @return {Object}
           */function delegate(t,e,n,r,o){if("function"===typeof t.addEventListener)return _delegate.apply(null,arguments);if("function"===typeof n)return _delegate.bind(null,document).apply(null,arguments);"string"===typeof t&&(t=document.querySelectorAll(t));return Array.prototype.map.call(t,(function(t){return _delegate(t,e,n,r,o)}))}
/**
           * Finds closest match and invokes callback.
           *
           * @param {Element} element
           * @param {String} selector
           * @param {String} type
           * @param {Function} callback
           * @return {Function}
           */function listener(t,e,n,r){return function(n){n.delegateTarget=o(n.target,e);n.delegateTarget&&r.call(t,n)}}e.exports=delegate},879:function(t,e){
/**
           * Check if argument is a HTML element.
           *
           * @param {Object} value
           * @return {Boolean}
           */
e.node=function(t){return void 0!==t&&t instanceof HTMLElement&&1===t.nodeType};
/**
           * Check if argument is a list of HTML elements.
           *
           * @param {Object} value
           * @return {Boolean}
           */e.nodeList=function(t){var n=Object.prototype.toString.call(t);return void 0!==t&&("[object NodeList]"===n||"[object HTMLCollection]"===n)&&"length"in t&&(0===t.length||e.node(t[0]))};
/**
           * Check if argument is a string.
           *
           * @param {Object} value
           * @return {Boolean}
           */e.string=function(t){return"string"===typeof t||t instanceof String};
/**
           * Check if argument is a function.
           *
           * @param {Object} value
           * @return {Boolean}
           */e.fn=function(t){var e=Object.prototype.toString.call(t);return"[object Function]"===e}},370:function(t,e,n){var r=n(879);var o=n(438);
/**
           * Validates all params and calls the right
           * listener function based on its target type.
           *
           * @param {String|HTMLElement|HTMLCollection|NodeList} target
           * @param {String} type
           * @param {Function} callback
           * @return {Object}
           */function listen(t,e,n){if(!t&&!e&&!n)throw new Error("Missing required arguments");if(!r.string(e))throw new TypeError("Second argument must be a String");if(!r.fn(n))throw new TypeError("Third argument must be a Function");if(r.node(t))return listenNode(t,e,n);if(r.nodeList(t))return listenNodeList(t,e,n);if(r.string(t))return listenSelector(t,e,n);throw new TypeError("First argument must be a String, HTMLElement, HTMLCollection, or NodeList")}
/**
           * Adds an event listener to a HTML element
           * and returns a remove listener function.
           *
           * @param {HTMLElement} node
           * @param {String} type
           * @param {Function} callback
           * @return {Object}
           */function listenNode(t,e,n){t.addEventListener(e,n);return{destroy:function(){t.removeEventListener(e,n)}}}
/**
           * Add an event listener to a list of HTML elements
           * and returns a remove listener function.
           *
           * @param {NodeList|HTMLCollection} nodeList
           * @param {String} type
           * @param {Function} callback
           * @return {Object}
           */function listenNodeList(t,e,n){Array.prototype.forEach.call(t,(function(t){t.addEventListener(e,n)}));return{destroy:function(){Array.prototype.forEach.call(t,(function(t){t.removeEventListener(e,n)}))}}}
/**
           * Add an event listener to a selector
           * and returns a remove listener function.
           *
           * @param {String} selector
           * @param {String} type
           * @param {Function} callback
           * @return {Object}
           */function listenSelector(t,e,n){return o(document.body,t,e,n)}t.exports=listen},817:function(t){function select(t){var e;if("SELECT"===t.nodeName){t.focus();e=t.value}else if("INPUT"===t.nodeName||"TEXTAREA"===t.nodeName){var n=t.hasAttribute("readonly");n||t.setAttribute("readonly","");t.select();t.setSelectionRange(0,t.value.length);n||t.removeAttribute("readonly");e=t.value}else{t.hasAttribute("contenteditable")&&t.focus();var r=window.getSelection();var o=document.createRange();o.selectNodeContents(t);r.removeAllRanges();r.addRange(o);e=r.toString()}return e}t.exports=select},279:function(e){function E(){}E.prototype={on:function(e,n,r){var o=(this||t).e||((this||t).e={});(o[e]||(o[e]=[])).push({fn:n,ctx:r});return this||t},once:function(e,n,r){var o=this||t;function listener(){o.off(e,listener);n.apply(r,arguments)}listener._=n;return this.on(e,listener,r)},emit:function(e){var n=[].slice.call(arguments,1);var r=(((this||t).e||((this||t).e={}))[e]||[]).slice();var o=0;var i=r.length;for(o;o<i;o++)r[o].fn.apply(r[o].ctx,n);return this||t},off:function(e,n){var r=(this||t).e||((this||t).e={});var o=r[e];var i=[];if(o&&n)for(var a=0,u=o.length;a<u;a++)o[a].fn!==n&&o[a].fn._!==n&&i.push(o[a]);i.length?r[e]=i:delete r[e];return this||t}};e.exports=E;e.exports.TinyEmitter=E}};var n={};function __webpack_require__(t){if(n[t])return n[t].exports;var r=n[t]={exports:{}};e[t](r,r.exports,__webpack_require__);return r.exports}!function(){__webpack_require__.n=function(t){var e=t&&t.__esModule?function(){return t.default}:function(){return t};__webpack_require__.d(e,{a:e});return e}}();!function(){__webpack_require__.d=function(t,e){for(var n in e)__webpack_require__.o(e,n)&&!__webpack_require__.o(t,n)&&Object.defineProperty(t,n,{enumerable:true,get:e[n]})}}();!function(){__webpack_require__.o=function(t,e){return Object.prototype.hasOwnProperty.call(t,e)}}();return __webpack_require__(686)}().default}));var n=e;const r=e.ClipboardJS,o=e.node,i=e.nodeList,a=e.string,u=e.fn,c=e.TinyEmitter;export{r as ClipboardJS,c as TinyEmitter,n as default,u as fn,o as node,i as nodeList,a as string};

