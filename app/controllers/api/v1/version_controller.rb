class Api::V1::VersionController < Api::BaseController
  def show
    render json: {
      application_version: Version.current.to_s,
      api_version: Apipie.configuration.default_version,
      edition: "oss"
    }
  end
end
