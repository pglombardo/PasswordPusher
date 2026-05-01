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

function copyBootstrapIconFonts() {
  const srcDir = path.join(root, "node_modules/bootstrap-icons/font/fonts");
  const destDir = path.join(buildsDir, "fonts");
  fs.mkdirSync(destDir, { recursive: true });
  for (const name of fs.readdirSync(srcDir)) {
    fs.copyFileSync(path.join(srcDir, name), path.join(destDir, name));
  }
}

function run(cmd, extraEnv = {}) {
  execSync(cmd, {
    cwd: root,
    stdio: "inherit",
    env: { ...process.env, ...extraEnv },
  });
}

function compileOneTheme(slug) {
  const outFile = path.join(buildsDir, `application-${slug}.css`);
  run(`node ./set_theme.js`, { PWP__THEME: slug });
  run(
    `sass --quiet-deps ./app/assets/stylesheets/application.bootstrap.scss:${outFile} --no-source-map --load-path=node_modules --load-path=app/assets/stylesheets --load-path=vendor/stylesheets`,
  );
  run(
    `postcss ${outFile} --use=autoprefixer --output=${outFile} -c postcss.config.js --verbose`,
  );
}

function restoreDefaultSelected() {
  run(`node ./set_theme.js`, { PWP__THEME: "default" });
}

const singleMode =
  process.argv.includes("--single") || process.env.BUILD_CSS_SINGLE === "1";

copyBootstrapIconFonts();

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
