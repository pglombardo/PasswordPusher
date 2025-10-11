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
  resources :data_migration_statuses
  resources :pushes
  resources :users
  resources :views
  namespace :solid_queue do
    resources :blocked_executions
  end
  namespace :solid_queue do
    resources :claimed_executions
  end
  namespace :solid_queue do
    resources :failed_executions
  end
  namespace :solid_queue do
    resources :jobs
  end
  namespace :solid_queue do
    resources :pauses
  end
  namespace :solid_queue do
    resources :processes
  end
  namespace :solid_queue do
    resources :ready_executions
  end
  namespace :solid_queue do
    resources :recurring_executions
  end
  namespace :solid_queue do
    resources :recurring_tasks
  end
  namespace :solid_queue do
    resources :scheduled_executions
  end
  namespace :solid_queue do
    resources :semaphores
  end
  root to: "dashboard#show"
end
