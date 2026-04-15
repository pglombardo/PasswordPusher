# frozen_string_literal: true

class Api::V2::VersionController < Api::BaseController
  def show
    render json: {
      application_version: Version.current.to_s,
      api_version: "2.0",
      edition: "oss"
    }
  end
end
