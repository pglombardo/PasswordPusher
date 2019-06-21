if !Rails.env.production?
    # New Headers
    Rails.application.config.action_dispatch.default_headers.store('Report-To', '{"group":"default","max_age":31536000,"endpoints":[{"url":"https://d44c6675f6f03f85482859e657572968.report-uri.com/a/t/g"}],"include_subdomains":true}')
    Rails.application.config.action_dispatch.default_headers.store('NEL', '{"report_to":"default","max_age":31536000,"include_subdomains":true, "success_fraction": 1.0,"failure_fraction": 1.0}')
    Rails.application.config.content_security_policy do |policy|
      policy.default_src :none
      policy.font_src    :self
      policy.img_src     :self
      policy.script_src  :self
      policy.style_src   :self
      policy.connect_src :self
      
      policy.form_action :self
      policy.base_uri :self
      policy.frame_ancestors :none
      policy.upgrade_insecure_requests false
      policy.report_uri "https://d44c6675f6f03f85482859e657572968.report-uri.com/r/t/csp/enforce; report-to default"
      end
  
      Rails.application.config.content_security_policy_report_only = false

    # Remaining Headers


end