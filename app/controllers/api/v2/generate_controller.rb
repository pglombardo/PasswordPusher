# frozen_string_literal: true

class Api::V2::GenerateController < Api::BaseController
  wrap_parameters :generate, format: [:json]

  rate_limit to: 30, within: 1.minute, only: :create,
    by: -> { current_user&.id || request.remote_ip },
    with: -> { render json: {error: I18n._("Too many generation requests. Please try again in a minute.")}, status: :too_many_requests }

  def create
    result = Pwpush::Generator.generate(**generate_params)
    render json: result, status: :ok
  rescue Pwpush::Generator::InvalidParameter => error
    render json: {error: error.message}, status: :unprocessable_content
  end

  private

  def generate_params
    permitted = generate_param_source.permit(
      :type, :language, :count, :length, :uppercase, :lowercase, :digits, :symbols,
      :avoid_ambiguous, :min_digits, :min_symbols, :charset, :word_count, :separator,
      :capitalize, :number, :symbol
    ).to_h.symbolize_keys
    permitted
  end

  # JSON ParamsWrapper copies the body into `generate` and leaves :format on the
  # root params. Permit the wrapped hash so those keys are not logged as unpermitted.
  def generate_param_source
    nested = params[:generate]
    nested.is_a?(ActionController::Parameters) ? nested : params
  end
end
