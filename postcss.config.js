const purgecss = require('@fullhuman/postcss-purgecss')
const cssnano = require('cssnano')

module.exports = {
  plugins: [
    require('autoprefixer'),
    require('postcss-import'),
    require('postcss-env-function'),
    require('postcss-simple-vars'),
    
    // Production optimizations
    ...(process.env.RAILS_ENV === 'production' ? [
      purgecss({
        content: [
          './app/views/**/*.html.erb',
          './app/javascript/**/*.js',
          './app/helpers/**/*.rb',
          './app/controllers/**/*.rb'
        ],
        defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || [],
        // Whitelist Bootstrap and custom classes that might be dynamically added
        safelist: [
          /^btn-/,
          /^alert-/,
          /^badge-/,
          /^text-/,
          /^bg-/,
          /^border-/,
          /^d-/,
          /^flex-/,
          /^justify-/,
          /^align-/,
          /^m[tblrxy]?-/,
          /^p[tblrxy]?-/,
          /^w-/,
          /^h-/,
          /^position-/,
          /^top-/,
          /^bottom-/,
          /^start-/,
          /^end-/,
          /^translate-/,
          /^rounded/,
          /^shadow/,
          /^opacity-/,
          /^overflow-/,
          /^visible/,
          /^invisible/,
          /^collapse/,
          /^show/,
          /^hide/,
          /^fade/,
          /^modal/,
          /^dropdown/,
          /^nav/,
          /^navbar/,
          /^card/,
          /^list-group/,
          /^table/,
          /^form/,
          /^input/,
          /^btn/,
          /^progress/,
          /^accordion/,
          /^breadcrumb/,
          /^pagination/,
          /^offcanvas/,
          /^toast/,
          /^tooltip/,
          /^popover/,
          /^carousel/,
          /^spinner/,
          /^placeholder/,
          /^ratio/,
          /^vstack/,
          /^hstack/,
          /^link-/,
          /^fs-/,
          /^fw-/,
          /^lh-/,
          /^font-/,
          /^user-select-/,
          /^pe-/,
          /^cursor-/,
          /^border-/,
          /^gradient/,
          'active',
          'disabled',
          'focus',
          'hover',
          'visited',
          'checked',
          'selected',
          'open',
          'closed',
          'loading',
          'error',
          'success',
          'warning',
          'info',
          'primary',
          'secondary',
          'danger',
          'dark',
          'light',
          'muted'
        ]
      }),
      cssnano({
        preset: ['default', {
          discardComments: { removeAll: true },
          normalizeWhitespace: true,
          minifyFontValues: true,
          minifySelectors: true,
          reduceIdents: false, // Keep animation names
          zindex: false // Don't optimize z-index values
        }]
      })
    ] : [])
  ]
}