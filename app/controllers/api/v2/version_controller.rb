# frozen_string_literal: true

class Api::V2::VersionController < Api::BaseController
  def show
    render json: {
      application_version: Version.current.to_s,
      api_version: "2.1",
      edition: "oss",
      features: features
    }
  end

  private

  def features
    {
      anonymous_access: Settings.allow_anonymous,
      api_token_authentication: true,
      accounts: {
        enabled: false
      },
      pushes: {
        enabled: true,
        email_auto_dispatch: false,
        file_attachments: {
          enabled: Settings.enable_file_pushes,
          requires_authentication: true
        },
        url_pushes: {
          enabled: Settings.enable_url_pushes
        },
        qr_code_pushes: {
          enabled: Settings.enable_qr_pushes
        }
      },
      requests: {
        enabled: false
      }
    }
  end
end
