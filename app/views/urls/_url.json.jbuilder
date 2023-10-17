# frozen_string_literal: true

json.extract! url, :id, :expire_after_days, :created_at, :updated_at
json.url url_url(url, format: :json)
