# frozen_string_literal: true

# Concern to add Prometheus metrics tracking to models
module PrometheusMetrics
  extend ActiveSupport::Concern

  # Send a metric to Prometheus
  def self.track_metric(action, labels = {})
    return if Rails.env.test?
    return unless defined?(PrometheusExporter::Client)

    PrometheusExporter::Client.default.send_json(
      type: "password_pusher",
      action: action,
      labels: labels
    )
  rescue StandardError => e
    Rails.logger.error("Prometheus metric tracking failed: #{e.message}")
  end

  class_methods do
    # Track push creation with callback
    def track_push_created
      after_create do
        labels = {
          kind: kind,
          user_type: user_id.present? ? "authenticated" : "anonymous",
          has_passphrase: respond_to?(:passphrase) && passphrase.present? ? "yes" : "no",
          deletable_by_viewer: deletable_by_viewer ? "yes" : "no",
          retrieval_step: retrieval_step ? "yes" : "no"
        }

        # Add file-specific metrics
        if respond_to?(:files) && files.attached?
          labels[:file_count] = files.count
          labels[:total_file_size] = files.sum(&:byte_size)
        end

        PrometheusMetrics.track_metric("push_created", labels)
      end
    end

    # Track push expiration with callback
    def track_push_expired
      after_update :track_expiration_metric, if: :saved_change_to_expired?
    end
  end

  private

  def track_expiration_metric
    return unless expired?

    PrometheusMetrics.track_metric("push_expired", {
      kind: kind,
      days_lived: days_old,
      view_count: view_count,
      had_passphrase: passphrase_ciphertext.present? ? "yes" : "no"
    })
  end
end
