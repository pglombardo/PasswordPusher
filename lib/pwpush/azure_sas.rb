# frozen_string_literal: true

module Pwpush
  # Azure Put Blob size is capped by the SAS `sv` API version:
  # versions before 2019-12-12 allow 256 MiB; 2019-12-12 and later allow
  # 5000 MiB. See https://github.com/pglombardo/PasswordPusher/issues/1208
  module AzureSas
    MIN_PUT_BLOB_VERSION = "2019-12-12"
    PUT_BLOB_MAX_BYTES = 5000 * 1024 * 1024

    module_function

    def version
      AzureBlob::SharedKeySigner::SAS::Version
    end

    def sufficient?(sas_version = version)
      sas_version.to_s >= MIN_PUT_BLOB_VERSION
    end

    def assert_sufficient!
      return unless defined?(AzureBlob::SharedKeySigner::SAS)

      actual = version
      return if sufficient?(actual)

      raise "azure-blob SAS version #{actual} is older than #{MIN_PUT_BLOB_VERSION}. " \
            "That API version caps Put Blob (direct uploads) at 256MB. " \
            "Use azure-blob ~> 0.10.0, which signs URLs as sv=2024-05-04."
    end
  end
end
