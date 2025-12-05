# frozen_string_literal: true

class AuditLog < ApplicationRecord
  include PrometheusMetrics

  enum :kind, [:creation, :view, :failed_view, :expire, :failed_passphrase, :admin_view, :owner_view], validate: true

  belongs_to :push
  belongs_to :user, optional: true

  # Track views in Prometheus
  after_create :track_view_metric, if: :view?
  after_create :track_failed_view_metric, if: :failed_view?
  after_create :track_failed_passphrase_metric, if: :failed_passphrase?

  private

  def track_view_metric
    PrometheusMetrics.track_metric("push_viewed", {
      push_kind: push.kind,
      user_type: user_id.present? ? "authenticated" : "anonymous",
      had_passphrase: push.passphrase.present? ? "yes" : "no"
    })
  end

  def track_failed_view_metric
    PrometheusMetrics.track_metric("push_failed_view", {
      push_kind: push.kind,
      user_type: user_id.present? ? "authenticated" : "anonymous",
      reason: "expired_or_deleted"
    })
  end

  def track_failed_passphrase_metric
    PrometheusMetrics.track_metric("push_failed_passphrase", {
      push_kind: push.kind,
      user_type: user_id.present? ? "authenticated" : "anonymous"
    })
  end

  def subject_name
    user&.email || "❓"
  end
end
