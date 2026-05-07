authenticated :user, lambda { |u| u.admin? } do
  namespace :madmin, path: "admin/dbexplore" do
    namespace :active_storage do
      resources :attachments
      resources :blobs
      resources :variant_records
    end
    resources :audit_logs
    resources :notify_by_emails
    resources :pushes
    resources :users, except: [:edit, :update]
    root to: "dashboard#show"
  end
end
