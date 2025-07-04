#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Starting Performance-Optimized Build...\n');

// Build configurations
const builds = [
  { name: 'Development', env: 'development' },
  { name: 'Production', env: 'production' }
];

// Function to get file size in KB
function getFileSize(filePath) {
  try {
    const stats = fs.statSync(filePath);
    return Math.round(stats.size / 1024);
  } catch (error) {
    return 0;
  }
}

// Function to format bytes
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

// Build and analyze each configuration
const results = [];

for (const build of builds) {
  console.log(`📦 Building ${build.name} bundle...`);
  
  // Set environment
  process.env.RAILS_ENV = build.env;
  process.env.NODE_ENV = build.env;
  
  try {
    // Build JavaScript
    console.log('  - Building JavaScript...');
    execSync('yarn build', { stdio: 'pipe' });
    
    // Build CSS
    console.log('  - Building CSS...');
    execSync('yarn build:css', { stdio: 'pipe' });
    
    // Get file sizes
    const jsSize = getFileSize('app/assets/builds/application.js');
    const cssSize = getFileSize('app/assets/builds/application.css');
    const totalSize = jsSize + cssSize;
    
    results.push({
      name: build.name,
      js: jsSize,
      css: cssSize,
      total: totalSize
    });
    
    console.log(`  ✅ ${build.name} build complete`);
    console.log(`     JS: ${formatBytes(jsSize * 1024)}`);
    console.log(`     CSS: ${formatBytes(cssSize * 1024)}`);
    console.log(`     Total: ${formatBytes(totalSize * 1024)}\n`);
    
  } catch (error) {
    console.error(`  ❌ ${build.name} build failed:`, error.message);
  }
}

// Generate performance report
console.log('📊 Performance Analysis Report');
console.log('===============================\n');

if (results.length >= 2) {
  const dev = results.find(r => r.name === 'Development');
  const prod = results.find(r => r.name === 'Production');
  
  if (dev && prod) {
    const jsReduction = Math.round(((dev.js - prod.js) / dev.js) * 100);
    const cssReduction = Math.round(((dev.css - prod.css) / dev.css) * 100);
    const totalReduction = Math.round(((dev.total - prod.total) / dev.total) * 100);
    
    console.log('Bundle Size Comparison:');
    console.log('                    Development  Production  Reduction');
    console.log(`JavaScript:         ${formatBytes(dev.js * 1024).padEnd(11)} ${formatBytes(prod.js * 1024).padEnd(11)} ${jsReduction}%`);
    console.log(`CSS:                ${formatBytes(dev.css * 1024).padEnd(11)} ${formatBytes(prod.css * 1024).padEnd(11)} ${cssReduction}%`);
    console.log(`Total:              ${formatBytes(dev.total * 1024).padEnd(11)} ${formatBytes(prod.total * 1024).padEnd(11)} ${totalReduction}%`);
    console.log('');
    
    // Performance recommendations
    console.log('🎯 Performance Recommendations:');
    console.log('================================\n');
    
    if (prod.js > 300) {
      console.log('⚠️  JavaScript bundle is still large (>300KB)');
      console.log('   Consider implementing code splitting or lazy loading');
    } else {
      console.log('✅ JavaScript bundle size is optimized');
    }
    
    if (prod.css > 500) {
      console.log('⚠️  CSS bundle is large (>500KB)');
      console.log('   Consider implementing critical CSS extraction');
    } else {
      console.log('✅ CSS bundle size is reasonable');
    }
    
    if (prod.total > 1000) {
      console.log('⚠️  Total bundle size is large (>1MB)');
      console.log('   Consider implementing asset compression (gzip/brotli)');
    } else {
      console.log('✅ Total bundle size is well optimized');
    }
  }
}

console.log('\n🎉 Build analysis complete!');

// Generate bundle analysis file
const analysisData = {
  timestamp: new Date().toISOString(),
  results: results,
  optimizations: [
    'Selective Bootstrap imports',
    'Optimized font loading',
    'JavaScript minification',
    'CSS purging (production)',
    'Tree shaking enabled',
    'Lazy controller loading'
  ]
};

fs.writeFileSync('bundle_analysis.json', JSON.stringify(analysisData, null, 2));
console.log('📄 Bundle analysis saved to bundle_analysis.json');