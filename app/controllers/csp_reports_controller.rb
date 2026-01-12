class CspReportsController < ApplicationController
  # Skip CSRF protection as browsers won't send it
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    # Limit request size to prevent DoS attacks
    if request.body.size > 10.kilobytes
      head :content_too_large
      return
    end

    begin
      # The violation report is in request.body.read
      report = JSON.parse(request.body.read)["csp-report"]

      if report.present?
        # Sanitize and structure the log message
        safe_report = {
          "document-uri" => report["document-uri"].to_s[0, 1024],
          "violated-directive" => report["violated-directive"].to_s[0, 256],
          "blocked-uri" => report["blocked-uri"].to_s[0, 1024]
        }

        Rails.logger.warn("CSP Violation: #{safe_report.inspect}")
      end

      # Return empty response - 204 No Content
      head :no_content
    rescue JSON::ParserError => e
      Rails.logger.error("Invalid CSP report JSON: #{e.message}")
      head :bad_request
    rescue => e
      Rails.logger.error("CSP report processing error: #{e.message}")
      head :internal_server_error
    end
  end
end
