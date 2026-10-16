#!/usr/bin/env node
/**
 * Builds themed CSS bundles: app/assets/builds/application-<slug>.css per Bootswatch theme.
 * Uses set_theme.js to write themes/_selected.scss (shim) for each theme, then Sass + PostCSS.
 */
const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = __dirname;
const themesDir = path.join(root, "app/assets/stylesheets/themes");
const buildsDir = path.join(root, "app/assets/builds");

function themeSlugs() {
  return fs
    .readdirSync(themesDir)
    .filter((f) => f.endsWith(".css") && f !== "selected.css")
    .map((f) => path.basename(f, ".css"))
    .sort();
}

function run(cmd, extraEnv = {}) {
  execSync(cmd, {
    cwd: root,
    stdio: "inherit",
    env: { ...process.env, ...extraEnv },
  });
}

// Drop a leftover Google Fonts @import (for example after a Bootswatch refresh)
// and fail if any Google Fonts host is still in the built CSS.
function rejectRemoteFonts(outFile) {
  let css = fs.readFileSync(outFile, "utf8");
  const stripped = css.replace(
    /@import\s+url\(\s*["']https:\/\/fonts\.googleapis\.com[^"']*["']\s*\)\s*;?/g,
    "",
  );
  if (stripped !== css) {
    fs.writeFileSync(outFile, stripped);
    console.warn(`Removed a fonts.googleapis.com import from ${path.basename(outFile)}`);
    css = stripped;
  }
  if (/fonts\.googleapis\.com|fonts\.gstatic\.com/.test(css)) {
    console.error(
      `Google Fonts host remains in ${outFile}. Theme CSS must use the bundled faces in themes/_bundled_fonts.scss.`,
    );
    process.exit(1);
  }
}

function compileOneTheme(slug) {
  const outFile = path.join(buildsDir, `application-${slug}.css`);
  run(`node ./set_theme.js`, { PWP__THEME: slug });
  run(
    `sass --quiet-deps ./app/assets/stylesheets/application.bootstrap.scss:${outFile} --no-source-map --load-path=node_modules --load-path=app/assets/stylesheets --load-path=vendor/stylesheets`,
  );
  run(
    `postcss ${outFile} --use=autoprefixer --output=${outFile} --verbose`,
  );
  rejectRemoteFonts(outFile);
}

function restoreDefaultSelected() {
  run(`node ./set_theme.js`, { PWP__THEME: "default" });
}

const singleMode =
  process.argv.includes("--single") || process.env.BUILD_CSS_SINGLE === "1";

if (singleMode) {
  const slug = (process.env.PWP__THEME || "default").toLowerCase();
  compileOneTheme(slug);
  console.log(`Built theme CSS: application-${slug}.css`);
} else {
  for (const slug of themeSlugs()) {
    console.log(`Building theme: ${slug}`);
    compileOneTheme(slug);
  }
  restoreDefaultSelected();
  console.log("All theme stylesheets built; restored themes/_selected.scss -> default.");
}
