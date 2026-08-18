# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class PasswordPusher::EnvOrFileTest < ActiveSupport::TestCase
  ENV_NAME = "PWPUSH_ENV_OR_FILE_TEST"
  FILE_ENV_NAME = "#{ENV_NAME}_FILE"

  setup do
    @original_env = ENV[ENV_NAME]
    @original_file_env = ENV[FILE_ENV_NAME]
    ENV.delete(ENV_NAME)
    ENV.delete(FILE_ENV_NAME)
  end

  teardown do
    if @original_env.nil?
      ENV.delete(ENV_NAME)
    else
      ENV[ENV_NAME] = @original_env
    end

    if @original_file_env.nil?
      ENV.delete(FILE_ENV_NAME)
    else
      ENV[FILE_ENV_NAME] = @original_file_env
    end
  end

  test "returns ENV value when set and ignores _FILE" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "secret")
      File.write(path, "from-file")
      ENV[ENV_NAME] = "from-env"
      ENV[FILE_ENV_NAME] = path

      assert_equal "from-env", PasswordPusher::EnvOrFile.read(ENV_NAME)
    end
  end

  test "returns stripped file contents when ENV unset and _FILE set" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "secret")
      File.write(path, "secret-from-file\n")
      ENV[FILE_ENV_NAME] = path

      assert_equal "secret-from-file", PasswordPusher::EnvOrFile.read(ENV_NAME)
    end
  end

  test "raises when _FILE is set but path is missing" do
    ENV[FILE_ENV_NAME] = "/nonexistent/path/to/secret"

    error = assert_raises(PasswordPusher::EnvOrFile::Error) do
      PasswordPusher::EnvOrFile.read(ENV_NAME)
    end
    assert_match(/not readable/, error.message)
    assert_match(FILE_ENV_NAME, error.message)
  end

  test "raises when _FILE is set but path is unreadable" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "secret")
      File.write(path, "secret")
      File.chmod(0o000, path)
      ENV[FILE_ENV_NAME] = path

      begin
        error = assert_raises(PasswordPusher::EnvOrFile::Error) do
          PasswordPusher::EnvOrFile.read(ENV_NAME)
        end
        assert_match(/not readable/, error.message)
      ensure
        File.chmod(0o600, path)
      end
    end
  end

  test "uses file when ENV is empty and _FILE is set" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "secret")
      File.write(path, "from-file")
      ENV[ENV_NAME] = ""
      ENV[FILE_ENV_NAME] = path

      assert_equal "from-file", PasswordPusher::EnvOrFile.read(ENV_NAME)
    end
  end

  test "returns nil when neither ENV nor _FILE is set" do
    assert_nil PasswordPusher::EnvOrFile.read(ENV_NAME)
  end

  test "returns nil when _FILE is empty" do
    ENV[FILE_ENV_NAME] = ""

    assert_nil PasswordPusher::EnvOrFile.read(ENV_NAME)
  end

  test "raises when _FILE points to an empty file" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "secret")
      File.write(path, "")
      ENV[FILE_ENV_NAME] = path

      error = assert_raises(PasswordPusher::EnvOrFile::Error) do
        PasswordPusher::EnvOrFile.read(ENV_NAME)
      end
      assert_match(/empty/, error.message)
    end
  end

  test "raises when _FILE points to a whitespace-only file" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "secret")
      File.write(path, " \n\t\n")
      ENV[FILE_ENV_NAME] = path

      error = assert_raises(PasswordPusher::EnvOrFile::Error) do
        PasswordPusher::EnvOrFile.read(ENV_NAME)
      end
      assert_match(/empty/, error.message)
    end
  end

  test "raises EnvOrFile::Error when _FILE points to a directory" do
    Dir.mktmpdir do |dir|
      ENV[FILE_ENV_NAME] = dir

      error = assert_raises(PasswordPusher::EnvOrFile::Error) do
        PasswordPusher::EnvOrFile.read(ENV_NAME)
      end
      assert_match(/not readable/, error.message)
    end
  end
end
