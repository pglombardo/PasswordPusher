# frozen_string_literal: true

require "test_helper"
require "azure_blob"
require "active_storage/service/azure_blob_service"

class Pwpush::AzureSasTest < ActiveSupport::TestCase
  test "azure-blob SAS version is new enough to exceed the 256MB Put Blob cap" do
    assert AzureBlob::SharedKeySigner::SAS::Version >= Pwpush::AzureSas::MIN_PUT_BLOB_VERSION
    assert Pwpush::AzureSas.sufficient?
  end

  test "direct upload SAS URLs advertise that API version" do
    service = ActiveStorage::Service::AzureBlobService.new(
      storage_account_name: "pwpushtest",
      storage_access_key: Base64.strict_encode64("test-access-key"),
      container: "files"
    )

    url = service.url_for_direct_upload(
      "some-key",
      expires_in: 5.minutes,
      content_type: "text/plain",
      content_length: 1,
      checksum: "abc"
    )

    params = CGI.parse(URI.parse(url).query)
    assert_equal [AzureBlob::SharedKeySigner::SAS::Version], params["sv"]
    assert params["sv"].first >= Pwpush::AzureSas::MIN_PUT_BLOB_VERSION
    assert_not_equal "2018-11-09", params["sv"].first
  end

  test "assert_sufficient! raises when the SAS version is too old" do
    Pwpush::AzureSas.stub :version, "2018-11-09" do
      error = assert_raises(RuntimeError) { Pwpush::AzureSas.assert_sufficient! }
      assert_includes error.message, "256MB"
    end
  end
end
