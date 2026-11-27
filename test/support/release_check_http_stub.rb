# frozen_string_literal: true

# Stubs Net::HTTP at the network layer so ReleaseCheck.http_get_body runs for
# real. The fake request API matches production: yield the response, then
# return the response object (not the block value). Returning the block value
# would hide the bug these tests exist to catch.
module ReleaseCheckHTTPStub
  class FakeHTTP
    attr_writer :use_ssl, :open_timeout, :read_timeout, :write_timeout

    def initialize(response: nil, error: nil, retry_response: nil)
      @response = response
      @error = error
      @retry_response = retry_response
    end

    def request(_request)
      raise @error if @error

      yield @retry_response if @retry_response && block_given?
      yield @response if block_given?
      @response
    end
  end

  def stub_release_check_http(body: "", code: "200", content_length: :from_body, chunks: nil, error: nil, success: nil, retry_body: nil, &)
    success = code.to_s.start_with?("2") if success.nil?
    resolved_length = (content_length == :from_body) ? body.to_s.bytesize : content_length
    response = build_release_check_response(
      body: body.to_s,
      code: code.to_s,
      content_length: resolved_length,
      chunks: chunks,
      success: success
    )
    retry_response = if retry_body
      build_release_check_response(
        body: retry_body.to_s,
        code: "200",
        content_length: retry_body.to_s.bytesize,
        chunks: nil,
        success: true
      )
    end
    fake_http = FakeHTTP.new(response: response, error: error, retry_response: retry_response)
    original_new = Net::HTTP.method(:new)
    feed_host = URI(ReleaseCheck::FEED_URL).host

    Net::HTTP.stub(:new, ->(*args, **kwargs) {
      host = args.first.to_s
      if host == feed_host
        fake_http
      else
        original_new.call(*args, **kwargs)
      end
    }, &)
  end

  private

  def build_release_check_response(body:, code:, content_length:, chunks:, success:)
    response = if success
      Net::HTTPOK.new("1.1", code, "OK")
    else
      Net::HTTPResponse.new("1.1", code, "Error")
    end

    response.define_singleton_method(:content_length) { content_length }
    response.define_singleton_method(:read_body) do |&blk|
      parts = chunks || (body.empty? ? [] : [body])
      parts.each { |chunk| blk&.call(chunk) }
      body
    end
    response
  end
end
