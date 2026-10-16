# frozen_string_literal: true

require "prometheus_exporter/client"

module Pwpush
  module Metrics
    DEFINITIONS = {
      pushes_created: {
        name: "pwpush_pushes_created_total",
        help: "Total pushes successfully created."
      },
      retrievals: {
        name: "pwpush_retrievals_total",
        help: "Total push retrieval events."
      },
      authentication_events: {
        name: "pwpush_authentication_events_total",
        help: "Total authentication events."
      },
      uploaded_files: {
        name: "pwpush_uploaded_files_total",
        help: "Total files attached to pushes."
      },
      uploaded_file_bytes: {
        name: "pwpush_uploaded_file_bytes_total",
        help: "Total bytes attached to file pushes."
      }
    }.freeze

    class << self
      attr_writer :client

      def enabled?
        Settings.prometheus&.enabled == true
      end

      def client
        @client ||= PrometheusExporter::Client.new(
          host: Settings.prometheus.client_host,
          port: Settings.prometheus.client_port.to_i,
          logger: Rails.logger,
          json_serializer: :oj
        )
      end

      def increment(metric, value: 1, labels: {})
        return unless enabled?

        DEFINITIONS.fetch(metric)
        client.send_json(
          type: "pwpush",
          metric: metric,
          value: value,
          labels: labels.transform_values(&:to_s)
        )
      rescue => error
        Rails.logger.debug { "Prometheus metric delivery failed: #{error.class}: #{error.message}" }
        nil
      end

      def reset!
        @client = nil
      end
    end
  end
end
