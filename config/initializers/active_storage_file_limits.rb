# frozen_string_literal: true

# File-push size limits and signed URL lifetimes are configured in
# Settings.files (PWP__FILES__*). Blob methods read those values per call.
Rails.application.config.to_prepare do
  ActiveStorage::Blob.prepend(Pwpush::ActiveStorageUrlExpiry)
  ActiveStorage::DirectUploadsController.prepend(Pwpush::DirectUploadSizeLimit)
  ActiveStorage.singleton_class.prepend(Pwpush::ActiveStorageUrlsExpireIn)
end

# azure-blob 0.10+ already signs SAS URLs as sv=2024-05-04 (Put Blob up to
# 5000 MiB). Fail boot on Microsoft storage if a downgrade reintroduces #1208.
# Also fail boot on a max_file_size typo so it cannot silently disable the cap.
Rails.application.config.after_initialize do
  Pwpush::FileLimits.max_file_size_bytes

  next unless Settings.files&.storage.to_s == "microsoft"

  require "azure_blob"
  Pwpush::AzureSas.assert_sufficient!
end
