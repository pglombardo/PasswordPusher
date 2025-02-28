class Api::V1::VersionController < Api::BaseController
  api :GET, "/api/v1/version.json", "Get the version details of the application and the API."
  formats ["JSON"]
  description <<-EOS
    == Version Information

    Retrieves the current application version, API version, edition and other information.

    === Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/api/v1/version.json

    === Example Response

      {
        "application_version": "2.1.0",
        "api_version": "1",
        "edition": "oss"
      }
  EOS
  def show
    render json: {
      application_version: Version.current.to_s,
      api_version: Apipie.configuration.default_version,
      edition: "oss"
    }
  end
end
