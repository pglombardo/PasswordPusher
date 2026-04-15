# frozen_string_literal: true

class Api::V2::PushesController < Api::V1::PushesController
  before_action :force_json_format

  private

  def force_json_format
    request.format = :json
  end

  def push_params
    permitted = params.require(:push).permit(:name, :kind, :expire_after_days, :expire_after_views,
      :deletable_by_viewer, :retrieval_step, :payload, :note, :passphrase, files: [])

    # For v2 requests, file uploads imply a file push unless kind is explicit.
    if permitted[:kind].blank? && permitted[:files].present?
      permitted[:kind] = "file"
    end

    permitted
  rescue => e
    Rails.logger.error("Error in push_params: #{e.message}")
    raise e
  end
end
