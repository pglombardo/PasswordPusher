# if Settings.enable_logins
#   authenticated :user, ->(u) { u.admin? } do
#     mount MissionControl::Jobs::Engine, at: "/admin/jobs"
#   end
# end
authenticated :user, lambda { |u| u.admin? } do
  get "/admin", to: "admin#index", as: :admin_root
end
