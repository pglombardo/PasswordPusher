# frozen_string_literal: true

require "test_helper"

class TusUploadStoreTest < ActiveSupport::TestCase
  setup do
    @id = TusUploadStore.generate_id
    @store = TusUploadStore.new(@id)
  end

  teardown do
    @store&.destroy!
  end

  # ---- generate_id ----
  test "generate_id returns url-safe base64 string" do
    id = TusUploadStore.generate_id
    assert id.is_a?(String)
    assert_equal 32, id.length
    assert_match(/\A[A-Za-z0-9_-]+\z/, id)
  end

  test "generate_id returns unique values" do
    ids = 10.times.map { TusUploadStore.generate_id }
    assert_equal ids.uniq.size, ids.size
  end

  # ---- valid_id? ----
  test "valid_id? accepts url-safe alphanumeric ids" do
    assert TusUploadStore.valid_id?(@id)
    assert TusUploadStore.valid_id?("a")
    assert TusUploadStore.valid_id?("A-Z_a-z0-9")
    assert TusUploadStore.valid_id?("x" * 64)
  end

  test "valid_id? rejects path traversal and invalid chars" do
    assert_not TusUploadStore.valid_id?("..")
    assert_not TusUploadStore.valid_id?("../etc/passwd")
    assert_not TusUploadStore.valid_id?("a/b")
    assert_not TusUploadStore.valid_id?("")
    assert_not TusUploadStore.valid_id?(nil)
    assert_not TusUploadStore.valid_id?("x" * 65)
    assert_not TusUploadStore.valid_id?("space in id")
    assert_not TusUploadStore.valid_id?("dot.inside")
  end

  test "initialize raises InvalidId for invalid id" do
    assert_raises(TusUploadStore::InvalidId) { TusUploadStore.new("..") }
    assert_raises(TusUploadStore::InvalidId) { TusUploadStore.new("a/b") }
    assert_raises(TusUploadStore::InvalidId) { TusUploadStore.new("") }
  end

  # ---- root ----
  test "root returns path under Rails root" do
    assert_equal Rails.root.join("tmp/uploads"), TusUploadStore.root
  end

  # ---- create! ----
  test "create! persists meta and returns self" do
    result = @store.create!(upload_length: 100, filename: "a.txt", content_type: "text/plain")
    assert_equal @store, result
    assert @store.exist?
    assert_equal 100, @store.upload_length
    assert_equal 0, @store.upload_offset
    m = @store.send(:meta)
    assert_equal "a.txt", m["filename"]
    assert_equal "text/plain", m["content_type"]
    assert m["created_at"].present?
  end

  test "create! raises when upload_length is blank" do
    assert_raises(ArgumentError, "upload_length required") do
      @store.create!(upload_length: nil)
    end
    assert_raises(ArgumentError, "upload_length required") do
      @store.create!(upload_length: "")
    end
  end

  test "create! accepts optional filename and content_type as nil" do
    @store.create!(upload_length: 5)
    assert @store.exist?
    m = @store.send(:meta)
    assert_nil m["filename"]
    assert_nil m["content_type"]
  end

  # ---- exist? ----
  test "exist? is false before create" do
    assert_not @store.exist?
  end

  test "exist? is true after create" do
    @store.create!(upload_length: 1)
    assert @store.exist?
  end

  # ---- meta, upload_length, upload_offset (raise NotFound) ----
  test "meta raises NotFound when store does not exist" do
    assert_raises(TusUploadStore::NotFound) { @store.meta }
  end

  test "upload_length and upload_offset raise NotFound when store does not exist" do
    assert_raises(TusUploadStore::NotFound) { @store.upload_length }
    assert_raises(TusUploadStore::NotFound) { @store.upload_offset }
  end

  # ---- append_chunk! ----
  test "append_chunk! appends data and returns new offset" do
    @store.create!(upload_length: 10)
    new_offset = @store.append_chunk!(offset: 0, io: StringIO.new("hello"))
    assert_equal 5, new_offset
    assert_equal 5, @store.upload_offset
    assert_equal "hello", File.read(@store.data_path)
  end

  test "append_chunk! appends second chunk when offset matches" do
    @store.create!(upload_length: 10)
    @store.append_chunk!(offset: 0, io: StringIO.new("he"))
    new_offset = @store.append_chunk!(offset: 2, io: StringIO.new("llo"))
    assert_equal 5, new_offset
    assert_equal "hello", File.read(@store.data_path)
  end

  test "append_chunk! raises OffsetMismatch when offset does not match" do
    @store.create!(upload_length: 10)
    @store.append_chunk!(offset: 0, io: StringIO.new("ab"))
    err = assert_raises(TusUploadStore::OffsetMismatch) do
      @store.append_chunk!(offset: 0, io: StringIO.new("x"))
    end
    assert_equal 2, err.current_offset
  end

  test "append_chunk! raises NotFound when store does not exist" do
    assert_raises(TusUploadStore::NotFound) do
      @store.append_chunk!(offset: 0, io: StringIO.new("x"))
    end
  end

  test "append_chunk! with concurrent call one succeeds one gets OffsetMismatch" do
    @store.create!(upload_length: 10)
    results = []
    run = lambda do |payload|
      @store.append_chunk!(offset: 0, io: StringIO.new(payload))
      results << :ok
    rescue TusUploadStore::OffsetMismatch => e
      results << e
    end
    t1 = Thread.new { run.call("ab") }
    t2 = Thread.new { run.call("xy") }
    t1.join
    t2.join
    assert_equal 2, results.size
    assert results.one? { |r| r == :ok }, "Exactly one append should succeed"
    mismatch = results.find { |r| r.is_a?(TusUploadStore::OffsetMismatch) }
    assert mismatch, "One thread should get OffsetMismatch"
    assert_equal 2, mismatch.current_offset
    assert_equal 2, @store.upload_offset
    assert_equal 2, File.size(@store.data_path), "Winner wrote 2 bytes"
  end

  # ---- complete? ----
  test "complete? is false when offset less than length" do
    @store.create!(upload_length: 5)
    @store.append_chunk!(offset: 0, io: StringIO.new("ab"))
    assert_not @store.complete?
  end

  test "complete? is true when offset equals length" do
    @store.create!(upload_length: 5)
    @store.append_chunk!(offset: 0, io: StringIO.new("hello"))
    assert @store.complete?
  end

  test "complete? is false when store does not exist" do
    assert_not @store.complete?
  end

  # ---- finalize_to_blob! ----
  test "finalize_to_blob! creates blob and destroys store" do
    @store.create!(upload_length: 4, filename: "f.bin", content_type: "application/octet-stream")
    @store.append_chunk!(offset: 0, io: StringIO.new("data"))
    blob = @store.finalize_to_blob!
    assert blob.present?
    assert_equal "f.bin", blob.filename.to_s
    assert_equal "application/octet-stream", blob.content_type
    assert_equal 4, blob.byte_size
    assert_not @store.exist?
  end

  test "finalize_to_blob! uses default filename and content_type when missing" do
    @store.create!(upload_length: 2)
    @store.append_chunk!(offset: 0, io: StringIO.new("xy"))
    blob = @store.finalize_to_blob!
    assert_equal "upload", blob.filename.to_s
    assert_equal "application/octet-stream", blob.content_type
  end

  test "finalize_to_blob! raises ArgumentError when upload not complete" do
    @store.create!(upload_length: 10)
    @store.append_chunk!(offset: 0, io: StringIO.new("ab"))
    assert_raises(ArgumentError, "upload not complete") do
      @store.finalize_to_blob!
    end
    assert @store.exist?
  end

  test "finalize_to_blob! raises NotFound when store does not exist" do
    assert_raises(TusUploadStore::NotFound) { @store.finalize_to_blob! }
  end

  # ---- destroy! ----
  test "destroy! removes directory" do
    @store.create!(upload_length: 1)
    assert @store.exist?
    @store.destroy!
    assert_not @store.exist?
    assert_not File.exist?(@store.path)
  end

  test "destroy! is safe when directory does not exist" do
    assert_nothing_raised { @store.destroy! }
  end

  # ---- cleanup_stale! ----
  test "cleanup_stale! removes uploads older than ttl" do
    store_old = TusUploadStore.new(TusUploadStore.generate_id)
    store_old.create!(upload_length: 1)
    meta_path = store_old.meta_path
    File.write(meta_path, {
      "upload_length" => 1,
      "upload_offset" => 0,
      "filename" => nil,
      "content_type" => nil,
      "created_at" => (Time.current - 86400 * 2).utc.iso8601
    }.to_json)

    store_new = TusUploadStore.new(TusUploadStore.generate_id)
    store_new.create!(upload_length: 1)

    TusUploadStore.cleanup_stale!(ttl_seconds: 86400)

    assert_not File.exist?(store_old.path)
    assert store_new.exist?
  ensure
    store_old&.destroy!
    store_new&.destroy!
  end

  test "cleanup_stale! keeps uploads within ttl" do
    @store.create!(upload_length: 1)
    TusUploadStore.cleanup_stale!(ttl_seconds: 86400)
    assert @store.exist?
  end

  test "cleanup_stale! does not fail on invalid meta.json and leaves dir in place" do
    dir = TusUploadStore.root.join(TusUploadStore.generate_id)
    FileUtils.mkdir_p(dir)
    File.write(dir.join("meta.json"), "not valid json")
    assert_nothing_raised do
      TusUploadStore.cleanup_stale!(ttl_seconds: 0)
    end
    # Invalid meta is skipped (rescued), directory is not removed
    assert File.exist?(dir)
  ensure
    FileUtils.rm_rf(dir) if dir && File.exist?(dir)
  end

  test "cleanup_stale! does not fail on missing created_at" do
    dir = TusUploadStore.root.join(TusUploadStore.generate_id)
    FileUtils.mkdir_p(dir)
    File.write(dir.join("meta.json"), {"upload_length" => 1, "upload_offset" => 0}.to_json)
    assert_nothing_raised do
      TusUploadStore.cleanup_stale!(ttl_seconds: 86400)
    end
    # Directory left in place (created_at missing => not removed)
    assert File.exist?(dir)
  ensure
    FileUtils.rm_rf(dir) if dir && File.exist?(dir)
  end

  test "cleanup_stale! is no-op when root does not exist" do
    TusUploadStore.root
    TusUploadStore.stub(:root, Pathname.new("/nonexistent/tmp/uploads")) do
      assert_nothing_raised do
        TusUploadStore.cleanup_stale!(ttl_seconds: 86400)
      end
    end
  end
end
