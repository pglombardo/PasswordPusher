module SetPushAttributes
  extend ActiveSupport::Concern

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_deletable_by_viewer(push, push_params)
    if push.url?
      # URLs cannot be preemptively deleted by end users ever
      push.deletable_by_viewer = false
    elsif settings_for(push).enable_deletable_pushes == true
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
          settings_for(push).deletable_pushes_default
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
    if settings_for(push).enable_retrieval_step == true
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
          settings_for(push).retrieval_step_default
        end
      end
    else
      # RETRIEVAL_STEP_ENABLED not enabled
      push.retrieval_step = false
    end
  end

  def set_expire_limits(push)
    push.expire_after_days ||= settings_for(push).expire_after_days_default
    push.expire_after_views ||= settings_for(push).expire_after_views_default

    # MIGRATE - ask
    # Are these assignments needed?
    unless push.expire_after_days.between?(settings_for(push).expire_after_days_min, settings_for(push).expire_after_days_max)
      push.expire_after_days = settings_for(push).expire_after_days_default
    end

    unless push.expire_after_views.between?(settings_for(push).expire_after_views_min, settings_for(push).expire_after_views_max)
      push.expire_after_views = settings_for(push).expire_after_views_default
    end
  end

end