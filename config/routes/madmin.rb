authenticated :user, lambda { |u| u.admin? } do
  namespace :madmin, path: "admin/dbexplore" do
    namespace :active_storage do
      resources :attachments
    end
    namespace :active_storage do
      resources :blobs
    end
    namespace :active_storage do
      resources :variant_records
    end
    resources :audit_logs
    resources :pushes
    resources :users
    root to: "dashboard#show"
  end
end
