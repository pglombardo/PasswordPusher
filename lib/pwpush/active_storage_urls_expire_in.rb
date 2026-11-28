# frozen_string_literal: true

module Pwpush
  # rails_blob_url / rails_storage_redirect sign blob IDs with this value.
  module ActiveStorageUrlsExpireIn
    def urls_expire_in
      Pwpush::FileLimits.blob_url_expires_in
    end
  end
end
