# frozen_string_literal: true

require "test_helper"
require "stringio"
require "logger"

class BundledFontsTest < ActiveSupport::TestCase
  GOOGLE_FONT_HOSTS = /fonts\.googleapis\.com|fonts\.gstatic\.com/

  FONT_CSS = <<~CSS
    @font-face {
      font-family: "Inter";
      src: url("/inter-latin-400-normal.woff2") format("woff2");
    }
  CSS

  ERROR_PAGES = %w[
    404.html
    422.html
    500.html
    406-unsupported-browser.html
    maintenance.html
  ].freeze

  test "theme stylesheets and bundled faces do not reference Google Fonts" do
    files = Dir[Rails.root.join("app/assets/stylesheets/themes/*.{css,scss}")]

    assert files.any?
    files.each do |path|
      assert_no_match GOOGLE_FONT_HOSTS, File.read(path), path
    end
  end

  test "static error pages do not reference Google Fonts" do
    ERROR_PAGES.each do |name|
      path = Rails.root.join("public", name)
      source = File.read(path)

      assert_no_match GOOGLE_FONT_HOSTS, source, path.to_s
      assert_no_match(/font-family:\s*['"]?Inter['"]?/, source, path.to_s)
    end
  end

  test "fontsource latin files are on the Propshaft load path" do
    skip "fontsource packages are not installed" unless fontsource_installed?

    paths = Rails.application.config.assets.paths.map(&:to_s)

    assert_includes paths, Rails.root.join("node_modules/@fontsource/inter/files").to_s
    assert Rails.application.assets.load_path.find("inter-latin-400-normal.woff2"),
      "Expected inter-latin-400-normal.woff2 on the asset load path"
  end

  test "Propshaft fingerprints bundled font URLs" do
    skip "fontsource packages are not installed" unless fontsource_installed?

    compiled, logs = compile_font_urls

    assert_no_match(/Unable to resolve/, logs)
    assert_match(%r{url\("/assets/inter-latin-400-normal-[^"]+\.woff2"\)}, compiled)
  end

  private

  def fontsource_installed?
    Rails.root.join("node_modules/@fontsource/inter/files/inter-latin-400-normal.woff2").exist?
  end

  def compile_font_urls
    logs = StringIO.new
    original_logger = Propshaft.logger
    Propshaft.logger = Logger.new(logs)

    compiler = Propshaft::Compiler::CssAssetUrls.new(Rails.application.assets)
    asset = Struct.new(:logical_path).new(Pathname.new("application-zephyr.css"))
    compiled = compiler.compile(asset, FONT_CSS)

    [compiled, logs.string]
  ensure
    Propshaft.logger = original_logger
  end
end
