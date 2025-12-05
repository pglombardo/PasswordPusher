# frozen_string_literal: true

class AuditLog < ApplicationRecord
  include PrometheusMetrics

  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase], validate: true

  belongs_to :push
  belongs_to :user, optional: true

  # Track views in Prometheus
  after_create :track_view_metric, if: :view?

  private

  def track_view_metric
    PrometheusMetrics.track_metric("push_viewed", {
      push_kind: push.kind,
      user_id: user_id.present? ? "authenticated" : "anonymous"
    })
  end

  def subject_name
    user&.email || "anonymous"
  end
end
