# frozen_string_literal: true

# File-push size limits and signed URL lifetimes are configured in
# Settings.files (PWP__FILES__*). Blob methods read those values per call.
Rails.application.config.to_prepare do
  ActiveStorage::Blob.prepend(Pwpush::ActiveStorageUrlExpiry)
  ActiveStorage::DirectUploadsController.prepend(Pwpush::DirectUploadSizeLimit)
end

# azure-blob 0.10+ already signs SAS URLs as sv=2024-05-04 (Put Blob up to
# 5000 MiB). Fail boot on Microsoft storage if a downgrade reintroduces #1208.
Rails.application.config.after_initialize do
  next unless Settings.files&.storage.to_s == "microsoft"

  require "azure_blob"
  Pwpush::AzureSas.assert_sufficient!
end
