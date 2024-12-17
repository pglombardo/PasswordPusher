const fs = require("fs");
const path = require("path");

// Get the theme name from the environment variable, default to "default"
const theme = process.env.PWP__THEME || "default";

// Define the paths
const themesDir = path.resolve(__dirname, "./app/assets/stylesheets/themes");
const selectedThemePath = path.join(themesDir, "selected.css");
const themeFilePath = path.join(themesDir, `${theme}.css`);

// Check if the selected theme file exists
if (!fs.existsSync(themeFilePath)) {
  console.error(`Error: Theme "${theme}" not found at ${themeFilePath}`);
  process.exit(1);
}

// Remove existing symlink or file
if (fs.existsSync(selectedThemePath)) {
  fs.unlinkSync(selectedThemePath);
}

// Create a new symlink pointing to the selected theme
fs.symlinkSync(themeFilePath, selectedThemePath);
console.log(`Symlink created: ${selectedThemePath} -> ${themeFilePath}`);