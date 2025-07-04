#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🎨 CSS Optimization Analysis');
console.log('============================\n');

// Read the current CSS file
const cssPath = 'app/assets/builds/application.css';
const cssContent = fs.readFileSync(cssPath, 'utf8');

// Count CSS rules
const cssRules = cssContent.match(/[^{}]+\{[^{}]*\}/g) || [];
const totalRules = cssRules.length;

console.log(`📊 CSS Statistics:`);
console.log(`   Total CSS rules: ${totalRules.toLocaleString()}`);
console.log(`   File size: ${Math.round(fs.statSync(cssPath).size / 1024)} KB`);
console.log(`   Lines: ${cssContent.split('\n').length.toLocaleString()}`);

// Analyze font faces
const fontFaces = cssContent.match(/@font-face\s*\{[^}]*\}/g) || [];
console.log(`   Font faces: ${fontFaces.length}`);

// Analyze Bootstrap components
const bootstrapComponents = [
  'accordion', 'alert', 'badge', 'breadcrumb', 'btn', 'card', 'carousel',
  'collapse', 'dropdown', 'form', 'modal', 'nav', 'navbar', 'offcanvas',
  'pagination', 'popover', 'progress', 'spinner', 'table', 'toast', 'tooltip'
];

console.log(`\n📋 Bootstrap Components Found:`);
bootstrapComponents.forEach(component => {
  const regex = new RegExp(`\\.${component}`, 'g');
  const matches = cssContent.match(regex) || [];
  if (matches.length > 0) {
    console.log(`   ${component}: ${matches.length} rules`);
  }
});

// Analyze utility classes
const utilityPatterns = [
  { name: 'Margin/Padding', pattern: /\.[mp][tblrxy]?-\d+/g },
  { name: 'Display', pattern: /\.d-[a-z-]+/g },
  { name: 'Flexbox', pattern: /\.(flex|justify|align)-[a-z-]+/g },
  { name: 'Text', pattern: /\.text-[a-z-]+/g },
  { name: 'Background', pattern: /\.bg-[a-z-]+/g },
  { name: 'Border', pattern: /\.border[a-z-]*[0-9]*/g },
  { name: 'Width/Height', pattern: /\.[wh]-[0-9]+/g }
];

console.log(`\n🔧 Utility Classes:`);
utilityPatterns.forEach(({ name, pattern }) => {
  const matches = cssContent.match(pattern) || [];
  if (matches.length > 0) {
    console.log(`   ${name}: ${matches.length} rules`);
  }
});

// Find potentially unused CSS
console.log(`\n🔍 Optimization Opportunities:`);

// Check for unused color variants
const colorVariants = ['primary', 'secondary', 'success', 'danger', 'warning', 'info', 'light', 'dark'];
const unusedColors = colorVariants.filter(color => {
  const usage = cssContent.match(new RegExp(`\\.(btn|bg|text|border)-${color}`, 'g')) || [];
  return usage.length === 0;
});

if (unusedColors.length > 0) {
  console.log(`   Unused color variants: ${unusedColors.join(', ')}`);
}

// Check for unused breakpoints
const breakpoints = ['sm', 'md', 'lg', 'xl', 'xxl'];
const unusedBreakpoints = breakpoints.filter(bp => {
  const usage = cssContent.match(new RegExp(`@media.*${bp}`, 'g')) || [];
  return usage.length === 0;
});

if (unusedBreakpoints.length > 0) {
  console.log(`   Unused breakpoints: ${unusedBreakpoints.join(', ')}`);
}

// Generate optimization recommendations
console.log(`\n💡 Optimization Recommendations:`);
console.log(`   1. Remove unused font variants (currently loading ${fontFaces.length} font faces)`);
console.log(`   2. Implement critical CSS extraction for above-the-fold content`);
console.log(`   3. Consider using CSS modules or styled-components for component-specific styles`);
console.log(`   4. Enable gzip/brotli compression (can reduce size by 70-80%)`);
console.log(`   5. Use CSS custom properties instead of utility classes where possible`);

// Create a minimal CSS build
console.log(`\n🔨 Creating optimized CSS build...`);

// Critical CSS extraction (basic version)
const criticalCSS = `
/* Critical CSS - Above the fold styles */
:root {
  --bs-primary: #0d6efd;
  --bs-secondary: #6c757d;
  --bs-success: #198754;
  --bs-danger: #dc3545;
  --bs-warning: #ffc107;
  --bs-info: #0dcaf0;
  --bs-light: #f8f9fa;
  --bs-dark: #212529;
}

/* Essential resets and typography */
*,
*::before,
*::after {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: var(--bs-body-font-family);
  font-size: var(--bs-body-font-size);
  font-weight: var(--bs-body-font-weight);
  line-height: var(--bs-body-line-height);
  color: var(--bs-body-color);
  background-color: var(--bs-body-bg);
}

/* Essential grid system */
.container,
.container-fluid {
  width: 100%;
  padding-right: var(--bs-gutter-x, 0.75rem);
  padding-left: var(--bs-gutter-x, 0.75rem);
  margin-right: auto;
  margin-left: auto;
}

.row {
  display: flex;
  flex-wrap: wrap;
  margin-right: calc(-0.5 * var(--bs-gutter-x));
  margin-left: calc(-0.5 * var(--bs-gutter-x));
}

.col {
  flex: 1 0 0%;
}

/* Essential buttons */
.btn {
  display: inline-block;
  font-weight: 400;
  line-height: 1.5;
  color: #212529;
  text-align: center;
  text-decoration: none;
  vertical-align: middle;
  cursor: pointer;
  user-select: none;
  background-color: transparent;
  border: 1px solid transparent;
  padding: 0.375rem 0.75rem;
  font-size: 1rem;
  border-radius: 0.375rem;
  transition: color 0.15s ease-in-out, background-color 0.15s ease-in-out;
}

.btn-primary {
  color: #fff;
  background-color: var(--bs-primary);
  border-color: var(--bs-primary);
}

/* Essential forms */
.form-control {
  display: block;
  width: 100%;
  padding: 0.375rem 0.75rem;
  font-size: 1rem;
  font-weight: 400;
  line-height: 1.5;
  color: #212529;
  background-color: #fff;
  background-image: none;
  border: 1px solid #ced4da;
  appearance: none;
  border-radius: 0.375rem;
  transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
}

/* Essential utilities */
.d-none { display: none !important; }
.d-block { display: block !important; }
.d-flex { display: flex !important; }
.justify-content-center { justify-content: center !important; }
.align-items-center { align-items: center !important; }
.text-center { text-align: center !important; }
.mb-3 { margin-bottom: 1rem !important; }
.mt-3 { margin-top: 1rem !important; }
.p-3 { padding: 1rem !important; }
`;

fs.writeFileSync('app/assets/builds/critical.css', criticalCSS);
console.log(`   ✅ Critical CSS created (${Math.round(criticalCSS.length / 1024)} KB)`);

// Create performance budget
const performanceBudget = {
  maxBundleSize: 1024, // 1MB
  maxJSSize: 512,      // 512KB
  maxCSSSize: 512,     // 512KB
  targets: {
    'First Contentful Paint': '1.5s',
    'Largest Contentful Paint': '2.5s',
    'Time to Interactive': '3.0s',
    'Cumulative Layout Shift': '0.1'
  }
};

fs.writeFileSync('performance_budget.json', JSON.stringify(performanceBudget, null, 2));
console.log(`   ✅ Performance budget created`);

console.log(`\n🎯 Next Steps:`);
console.log(`   1. Run: yarn build:analyze to see current performance`);
console.log(`   2. Implement server-side compression (gzip/brotli)`);
console.log(`   3. Add resource hints (preload, prefetch) to HTML`);
console.log(`   4. Consider implementing a service worker for caching`);
console.log(`   5. Monitor Core Web Vitals in production`);