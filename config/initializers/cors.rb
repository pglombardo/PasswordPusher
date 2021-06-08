Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/p.json', headers: :any, methods: [:post]
  end
end

