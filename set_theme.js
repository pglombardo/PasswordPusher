const fs = require("fs");
const path = require("path");

// Get the theme name from the environment variable, default to "default"
const theme = (process.env.PWP__THEME || "default").toLowerCase();

// Define paths
const themesDir = path.resolve(__dirname, "./app/assets/stylesheets/themes");
const selectedThemePath = path.join(themesDir, "selected.css");
const themeFilePath = path.join(themesDir, `${theme}.css`);

// Validate if the theme file exists
if (!fs.existsSync(themeFilePath)) {
  console.error(`Error: Theme "${theme}" not found at ${themeFilePath}`);
  process.exit(1);
}

// Ensure cleanup: Remove existing symlink or file before creating a new one
try {
  if (fs.lstatSync(selectedThemePath).isSymbolicLink()) {
    fs.unlinkSync(selectedThemePath); // Remove symlink
  } else if (fs.existsSync(selectedThemePath)) {
    fs.unlinkSync(selectedThemePath); // Remove file if it exists
  }
} catch (err) {
  if (err.code !== "ENOENT") { // Ignore "no such file" errors
    console.error(`Failed to clean up existing file/symlink: ${err.message}`);
    process.exit(1);
  }
}

// Create the symlink
try {
  fs.symlinkSync(themeFilePath, selectedThemePath, "file"); // "file" type symlink
  console.log(`Symlink created: ${selectedThemePath} -> ${themeFilePath}`);
} catch (err) {
  console.error(`Failed to create symlink: ${err.message}`);
  process.exit(1);
}