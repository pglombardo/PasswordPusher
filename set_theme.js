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

// Check if the symlink already exists and points to the correct theme
try {
  if (fs.existsSync(selectedThemePath)) {
    const existingTarget = fs.readlinkSync(selectedThemePath);
    if (existingTarget === themeFilePath) {
      console.log(`Symlink already set: ${selectedThemePath} -> ${existingTarget}`);
      process.exit(0); // Exit since the symlink is correct
    } else {
      fs.unlinkSync(selectedThemePath); // Remove the existing symlink or file
    }
  }
} catch (err) {
  console.error(`Failed to check existing symlink: ${err.message}`);
  fs.unlinkSync(selectedThemePath); // Force removal if something goes wrong
}

// Create the new symlink
fs.symlinkSync(themeFilePath, selectedThemePath);
console.log(`Symlink created: ${selectedThemePath} -> ${themeFilePath}`);