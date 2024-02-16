# frozen_string_literal: true

json.extract! file_push, :id, :expire_after_days, :expire_after_views, :expired, :url_token, :user_id, :deleted,
  :deletable_by_viewer, :retrieval_step, :expired_on, :payload, :note, :created_at, :updated_at
json.url file_push_url(file_push, format: :json)
