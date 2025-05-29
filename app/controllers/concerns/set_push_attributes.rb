module SetPushAttributes
  extend ActiveSupport::Concern

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_deletable_by_viewer(push, push_params)
    if push.url?
      # URLs cannot be preemptively deleted by end users ever
      push.deletable_by_viewer = nil
    elsif push.settings_for_kind.enable_deletable_pushes == true
      if push_params.key?(:deletable_by_viewer)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_dbv = push_params[:deletable_by_viewer].to_s.downcase
        push.deletable_by_viewer = %w[on yes checked true].include?(user_dbv)
      else
        push.deletable_by_viewer = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          push.settings_for_kind.deletable_pushes_default
        end
      end
    else
      # DELETABLE_PASSWORDS_ENABLED not enabled
      push.deletable_by_viewer = false
    end
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_retrieval_step(push, push_params)
    if push.settings_for_kind.enable_retrieval_step == true
      if push_params.key?(:retrieval_step)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_rs = push_params[:retrieval_step].to_s.downcase
        push.retrieval_step = %w[on yes checked true].include?(user_rs)
      else
        push.retrieval_step = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          push.settings_for_kind.retrieval_step_default
        end
      end
    else
      # RETRIEVAL_STEP_ENABLED not enabled
      push.retrieval_step = false
    end
  end
end
