# frozen_string_literal: true

module Pwpush
  # Rejects oversized blobs before Active Storage creates them for direct upload.
  module DirectUploadSizeLimit
    def create
      byte_size = params.dig(:blob, :byte_size)
      unless Pwpush::FileLimits.allowed_byte_size?(byte_size)
        render json: {error: Pwpush::FileLimits.too_large_message}, status: :unprocessable_content
        return
      end

      super
    end
  end
end
