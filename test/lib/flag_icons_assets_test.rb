# frozen_string_literal: true

require "test_helper"
require "stringio"
require "logger"

class FlagIconsAssetsTest < ActiveSupport::TestCase
  FLAG_CSS = <<~CSS
    .fi-se { background-image: url(/flags/4x3/se.svg); }
    .fi-se.fis { background-image: url(/flags/1x1/se.svg); }
  CSS

  test "flag-icons is on the Propshaft load path" do
    paths = Rails.application.config.assets.paths.map(&:to_s)

    assert_includes paths, Rails.root.join("node_modules/flag-icons").to_s
  end

  test "rectangular and square flag SVGs resolve through Propshaft" do
    skip "flag-icons npm package is not installed" unless flag_icons_installed?

    load_path = Rails.application.assets.load_path

    assert load_path.find("flags/4x3/se.svg"), "Expected flags/4x3/se.svg on the asset load path"
    assert load_path.find("flags/1x1/se.svg"), "Expected flags/1x1/se.svg on the asset load path"
  end

  test "stylesheet configures flag-icons with /flags via the Sass module API" do
    source = File.read(Rails.root.join("app/assets/stylesheets/application.bootstrap.scss"))

    assert_match(
      %r{@use "flag-icons/sass/flag-icons" with \(\s*\$flag-icons-path: "/flags"\s*\)}m,
      source
    )
    assert_no_match(/\$fi-path/, source)
  end

  test "public/flags is a symlink to the flag-icons package" do
    flags_path = Rails.root.join("public/flags")

    # Tracked as a symlink; File.exist? is false on a clean checkout until yarn install.
    assert File.symlink?(flags_path), "Expected public/flags to be a symlink"
    assert_equal "../node_modules/flag-icons/flags", File.readlink(flags_path)

    skip "flag-icons npm package is not installed" unless flag_icons_installed?

    assert File.exist?(flags_path.join("4x3/se.svg"))
    assert File.exist?(flags_path.join("1x1/se.svg"))
  end

  test "Propshaft fingerprints flag URLs in default theme CSS" do
    skip "flag-icons npm package is not installed" unless flag_icons_installed?

    compiled, logs = compile_flag_urls("application-default.css")

    assert_no_match(/Unable to resolve/, logs)
    assert_match(%r{url\("/assets/flags/4x3/se-[^"]+\.svg"\)}, compiled)
    assert_match(%r{url\("/assets/flags/1x1/se-[^"]+\.svg"\)}, compiled)
  end

  test "Propshaft fingerprints flag URLs in custom theme CSS" do
    skip "flag-icons npm package is not installed" unless flag_icons_installed?

    compiled, logs = compile_flag_urls("application-custom.css")

    assert_no_match(/Unable to resolve/, logs)
    assert_match(%r{url\("/assets/flags/4x3/se-[^"]+\.svg"\)}, compiled)
    assert_match(%r{url\("/assets/flags/1x1/se-[^"]+\.svg"\)}, compiled)
  end

  private

  def flag_icons_installed?
    Rails.root.join("node_modules/flag-icons/flags/4x3/se.svg").exist?
  end

  def compile_flag_urls(logical_name)
    logs = StringIO.new
    original_logger = Propshaft.logger
    Propshaft.logger = Logger.new(logs)

    compiler = Propshaft::Compiler::CssAssetUrls.new(Rails.application.assets)
    asset = Struct.new(:logical_path).new(Pathname.new(logical_name))
    compiled = compiler.compile(asset, FLAG_CSS)

    [compiled, logs.string]
  ensure
    Propshaft.logger = original_logger
  end
end
