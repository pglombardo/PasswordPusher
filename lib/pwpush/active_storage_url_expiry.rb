# frozen_string_literal: true

module Pwpush
  # Reads signed URL lifetime from Settings on each call so tests and
  # Settings.reload! take effect without a process restart.
  module ActiveStorageUrlExpiry
    def url(expires_in: Pwpush::FileLimits.blob_url_expires_in, **options)
      super
    end

    def service_url_for_direct_upload(expires_in: Pwpush::FileLimits.direct_upload_url_expires_in)
      super
    end
  end
end
