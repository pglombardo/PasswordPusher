json.extract! push, :expire_after_views,
  :expired,
  :url_token,
  :deletable_by_viewer,
  :retrieval_step,
  :expired_on,
  :passphrase,
  :created_at,
  :updated_at,
  :expire_after_days,
  :days_remaining,
  :views_remaining,
  :deleted

json.json_url secret_url(push) + ".json"
json.html_url secret_url(push)

if controller.action_name == "create"
  json.note push.note
  json.name push.name
end

if controller.action_name == "show"
  json.payload push.payload

  json.files do
    json.array! push.files do |file|
      json.filename file.filename.to_s
      json.content_type file.content_type
      json.url rails_blob_url(file)
    end
  end
end
