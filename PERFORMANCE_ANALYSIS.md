# Performance Analysis and Optimization Plan

## Current State Analysis

### Bundle Sizes
- **JavaScript Bundle**: 536KB (uncompressed)
- **CSS Bundle**: 1.27MB (uncompressed)
- **Total Assets**: ~1.8MB (uncompressed)

### Key Performance Bottlenecks

#### 1. CSS Bundle Size (1.27MB)
- **Root Cause**: Full Bootstrap framework import
- **Impact**: Large initial download, slower page loads
- **Details**: 
  - 22,752 lines of CSS
  - Includes unused Bootstrap components
  - Multiple font families loaded simultaneously
  - All font variants (weights, styles) loaded

#### 2. JavaScript Bundle Size (536KB)
- **Root Cause**: Full library imports
- **Impact**: Slower JavaScript parsing and execution
- **Details**:
  - Full Bootstrap JavaScript bundle
  - @popperjs/core (56 references in bundle)
  - Multiple font packages
  - All Stimulus controllers loaded upfront

#### 3. Font Loading Strategy
- **Root Cause**: Multiple font families with all variants
- **Impact**: Render blocking, layout shifts
- **Details**:
  - Roboto (multiple weights/styles)
  - Roboto Slab
  - Roboto Mono
  - Bootstrap Icons
  - Flag Icons

#### 4. Theme System
- **Root Cause**: Large theme files (250-300KB each)
- **Impact**: Unused styles loaded
- **Details**:
  - 25+ theme files available
  - Each theme includes full Bootstrap customization
  - Only one theme used at a time

## Optimization Recommendations

### 1. CSS Optimizations (High Impact)

#### A. Selective Bootstrap Import
Replace full Bootstrap import with selective component imports:

```scss
// Instead of: @use 'bootstrap/scss/bootstrap';
@use 'bootstrap/scss/functions';
@use 'bootstrap/scss/variables';
@use 'bootstrap/scss/mixins';
@use 'bootstrap/scss/root';
@use 'bootstrap/scss/reboot';
@use 'bootstrap/scss/type';
@use 'bootstrap/scss/grid';
@use 'bootstrap/scss/containers';
@use 'bootstrap/scss/buttons';
@use 'bootstrap/scss/forms';
@use 'bootstrap/scss/navbar';
@use 'bootstrap/scss/card';
@use 'bootstrap/scss/modal';
@use 'bootstrap/scss/utilities';
```

**Expected Reduction**: 40-60% CSS bundle size

#### B. Font Optimization
- Load only required font weights and styles
- Use `font-display: swap` for better loading performance
- Consider system font fallbacks

#### C. CSS Purging
Implement PurgeCSS to remove unused styles:

```javascript
// Add to PostCSS config
const purgecss = require('@fullhuman/postcss-purgecss')

module.exports = {
  plugins: [
    ...(process.env.NODE_ENV === 'production' ? [purgecss({
      content: [
        './app/views/**/*.html.erb',
        './app/javascript/**/*.js',
        './app/helpers/**/*.rb'
      ],
      defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []
    })] : [])
  ]
}
```

### 2. JavaScript Optimizations (Medium Impact)

#### A. Dynamic Imports for Stimulus Controllers
Load controllers only when needed:

```javascript
// controllers/index.js
import { application } from "./application"

// Lazy load controllers
const controllerModules = {
  'gdpr': () => import('./gdpr_controller'),
  'copy': () => import('./copy_controller'),
  'pwgen': () => import('./pwgen_controller'),
  'form': () => import('./form_controller'),
  'knobs': () => import('./knobs_controller'),
  'passwords': () => import('./passwords_controller'),
  'multi-upload': () => import('./multi_upload_controller'),
  'theme': () => import('./theme_controller')
}

// Register controllers dynamically
Object.entries(controllerModules).forEach(([name, importFn]) => {
  application.register(name, importFn)
})
```

#### B. Selective Bootstrap JavaScript
Import only required Bootstrap components:

```javascript
// Instead of: import "bootstrap"
import 'bootstrap/js/dist/modal'
import 'bootstrap/js/dist/dropdown'
import 'bootstrap/js/dist/collapse'
// Only import what's actually used
```

#### C. Bundle Splitting
Configure esbuild for better code splitting:

```javascript
// esbuild.config.mjs
const config = {
  // ... existing config
  splitting: true,
  format: 'esm',
  outdir: path.join(process.cwd(), "app/assets/builds"),
  entryPoints: {
    application: "application.js",
    vendor: "vendor.js" // Separate vendor bundle
  }
}
```

### 3. Loading Strategy Optimizations (High Impact)

#### A. Critical CSS Extraction
Extract above-the-fold CSS:

```erb
<!-- In application layout -->
<style>
  <%= Rails.application.assets["critical.css"].to_s.html_safe %>
</style>
<%= stylesheet_link_tag "application", "data-turbo-track": "reload", media: "print", onload: "this.media='all'" %>
```

#### B. Resource Hints
Add preload/prefetch hints:

```erb
<%= preload_link_tag asset_path("application.js"), as: :script %>
<%= dns_prefetch_link_tag "//fonts.googleapis.com" %>
```

#### C. Service Worker for Caching
Implement service worker for aggressive caching of static assets.

### 4. Build Process Optimizations

#### A. Production Optimizations
Enhanced esbuild configuration:

```javascript
const config = {
  // ... existing config
  minify: process.env.RAILS_ENV === "production",
  treeShaking: true,
  target: ['es2020'],
  drop: process.env.RAILS_ENV === "production" ? ['console', 'debugger'] : [],
  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'development')
  }
}
```

#### B. Asset Compression
Configure gzip/brotli compression at the server level.

## Implementation Priority

### Phase 1 (Quick Wins - 1-2 days)
1. ✅ Selective Bootstrap CSS imports
2. ✅ Font optimization
3. ✅ Remove unused dependencies
4. ✅ Basic esbuild optimizations

### Phase 2 (Medium Effort - 3-5 days)
1. ✅ Implement CSS purging
2. ✅ Dynamic controller loading
3. ✅ Bundle splitting
4. ✅ Critical CSS extraction

### Phase 3 (Advanced - 1 week)
1. ✅ Service worker implementation
2. ✅ Advanced caching strategies
3. ✅ Performance monitoring
4. ✅ Automated performance budgets

## Expected Performance Improvements

### Bundle Size Reductions
- **CSS**: 1.27MB → 300-400KB (70% reduction)
- **JavaScript**: 536KB → 200-300KB (45% reduction)
- **Total**: 1.8MB → 500-700KB (65% reduction)

### Loading Performance
- **First Contentful Paint**: 30-50% improvement
- **Largest Contentful Paint**: 40-60% improvement
- **Time to Interactive**: 35-45% improvement

### User Experience
- Faster page loads
- Reduced layout shifts
- Better mobile performance
- Improved perceived performance

## Monitoring and Measurement

### Key Metrics to Track
1. Bundle sizes (JS/CSS)
2. Core Web Vitals (LCP, FID, CLS)
3. Time to First Byte (TTFB)
4. Resource load times
5. Cache hit rates

### Tools for Monitoring
- Lighthouse CI
- WebPageTest
- Chrome DevTools Performance tab
- Bundle analyzer tools

## Next Steps

1. Implement Phase 1 optimizations
2. Set up performance monitoring
3. Establish performance budgets
4. Create automated performance testing
5. Document performance guidelines for developers