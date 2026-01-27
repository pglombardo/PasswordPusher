# frozen_string_literal: true

CI.run do
  step "Setup", "bin/setup"

  step "Style: Ruby", "bundle exec rubocop"
  step "Style: ERB", "bundle exec erb_lint --lint-all"
  step "Style: i18n", "bundle exec i18n-tasks health"

  step "Security: Brakeman code analysis", "bundle exec brakeman --skip-files containers/build/ --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"

  step "Tests: Rails", "bin/rails test"
  step "Tests: System", "bin/rails test:system"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  if success?
    step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  else
    failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  end
end
