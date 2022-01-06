require 'securerandom'

class PasswordsController < ApplicationController
  helper PasswordsHelper

  # GET /passwords/1
  # GET /passwords/1.json
  def show
    redirect_to :root && return unless params.key?(:id)

    begin
      @password = Password.includes(:views).find_by_url_token!(params[:id])
    rescue ActiveRecord::RecordNotFound
      # Showing a 404 reveals that this Secret URL never existed
      # which is an information leak (not a secret anymore)
      # We also don't want data in general. We entirely delete old pushes that:
      # 1. have expired (payloads already deleted long ago)
      # 2. are anonymous/not linked to a user account (audit log not needed)
      # Old, expired & anonymous pushes have no value to anybody.
      # When not found, show the 'expired' page so even very old secret URLs
      # when clicked they will be accurate - this secret URL has expired.
      # No easy fix for JSON unfortunately as we don't have a record to show.
      respond_to do |format|
        format.html { render template: 'passwords/show_expired', layout: 'naked' }
        format.json { render json: { error: 'not-found' }.to_json, status: 404 }
      end
      return
    end

    # This password may have expired since the last view.  Validate the password
    # expiration before doing anything.
    @password.validate!

    if @password.expired
      log_view(@password)
      respond_to do |format|
        format.html { render template: 'passwords/show_expired', layout: 'naked' }
        format.json { render json: @password }
      end
      return
    else
      @payload = @password.payload.nil? ? @password.decrypt(@password.payload_legacy) : @password.payload
    end

    log_view(@password)
    expires_now

    respond_to do |format|
      format.html { render layout: 'bare' }
      format.json { render json: @password }
    end
  end

  # GET /passwords/new
  # GET /passwords/new.json
  def new
    @password = Password.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @password }
    end
  end

  # POST /passwords
  # POST /passwords.json
  def create
    # params[:password] has to exist
    # params[:password][:payload] has to exist
    # params[:password][:payload] can't be blank
    # params[:password][:payload] can't be longer than 1 megabyte

    payload_param = params.fetch(:password, {}).fetch(:payload, '')
    if payload_param.blank? || payload_param.length > 1.megabyte

      respond_to do |format|
        format.html { redirect_to root_path, status: :bad_request, notice: 'Bad Request' }
        format.json { render json: '{}', status: :bad_request }
      end
      return
    end

    @password = Password.new
    @password.expire_after_days = params[:password].fetch(:expire_after_days,
                                                          EXPIRE_AFTER_DAYS_DEFAULT)
    @password.expire_after_views = params[:password].fetch(:expire_after_views,
                                                           EXPIRE_AFTER_VIEWS_DEFAULT)
    @password.user_id = current_user.id if user_signed_in?
    @password.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase

    create_detect_deletable_by_viewer(@password, params)
    create_detect_retrieval_step(@password, params)

    @password.payload = params[:password][:payload]
    @password.note = params[:password][:note] unless params[:password].fetch(:note, '').blank?

    @password.validate!

    respond_to do |format|
      if @password.save
        format.html { redirect_to preview_password_path(@password) }
        format.json { render json: @password, status: :created }
      else
        format.html { render action: 'new' }
        format.json { render json: @password.errors, status: :unprocessable_entity }
      end
    end
  end

  def preview
    @password = Password.find_by_url_token!(params[:id])

    respond_to do |format|
      format.html { render action: 'preview' }
      format.json { render json: @password, status: :ok }
    end
  end

  def preliminary
    @password = Password.find_by_url_token!(params[:id])

    respond_to do |format|
      format.html { render action: 'preliminary', layout: 'naked' }
      format.json { render json: @password, status: :ok }
    end
  end

  def audit
    authenticate_user!

    @password = Password.includes(:views).find_by_url_token!(params[:id])

    if @password.user_id != current_user.id
      redirect_to :root, notice: _("That push doesn't belong to you.")
      return
    end
  end

  def destroy
    @password = Password.find_by_url_token!(params[:id])
    is_owner = false

    if user_signed_in?
      # Check if logged in user owns the password to be expired
      if @password.user_id == current_user.id
        is_owner = true
      else
        redirect_to :root, notice: _('That push does not belong to you.')
        return
      end
    elsif @password.deletable_by_viewer == false
      # Anonymous user - assure deletable_by_viewer enabled
      redirect_to :root, notice: _('That push is not deletable by viewers.')
      return
    end

    log_view(@password, manual_expiration: true)

    @password.expired = true
    @password.payload = nil
    @password.deleted = true
    @password.expired_on = Time.now

    respond_to do |format|
      if @password.save
        format.html {
          if is_owner
            redirect_to audit_password_path(@password),
                        notice: _('The password has been deleted and secret URL expired.')
          else
            redirect_to @password,
                        notice: _('The password has been deleted and secret URL expired.')
          end
        }
        format.json { render json: @password, status: :ok }
      else
        format.html { render action: 'new' }
        format.json { render json: @password.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  ##
  # log_view
  #
  # Record that a view is being made for a password
  #
  def log_view(password, manual_expiration: false)
    record = {}

    # 0 - standard user view
    # 1 - manual expiration
    record[:kind] = manual_expiration ? 1 : 0

    record[:user_id] = current_user.id if user_signed_in?
    record[:ip] = request.env['HTTP_X_FORWARDED_FOR'].nil? ? request.env['REMOTE_ADDR'] : request.env['HTTP_X_FORWARDED_FOR']

    # Limit retrieved values to 256 characters
    record[:user_agent]  = request.env['HTTP_USER_AGENT'].to_s[0, 255]
    record[:referrer]    = request.env['HTTP_REFERER'].to_s[0, 255]

    record[:successful]  = password.expired ? false : true

    password.views.create(record)
    password
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_retrieval_step(password, params)
    if RETRIEVAL_STEP_ENABLED == true
      if params[:password].key?(:retrieval_step)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_rs = params[:password][:retrieval_step].to_s.downcase
        password.retrieval_step = %w[on yes checked true].include?(user_rs)
      else
        if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          password.retrieval_step = false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          password.retrieval_step = RETRIEVAL_STEP_DEFAULT
        end
      end
    else
      # RETRIEVAL_STEP_ENABLED not enabled
      password.retrieval_step = false
    end
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_deletable_by_viewer(password, params)
    if DELETABLE_PASSWORDS_ENABLED == true
      if params[:password].key?(:deletable_by_viewer)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_dvb = params[:password][:deletable_by_viewer].to_s.downcase
        password.deletable_by_viewer = %w[on yes checked true].include?(user_dvb)
      else
        if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          password.deletable_by_viewer = false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          password.deletable_by_viewer = DELETABLE_PASSWORDS_DEFAULT
        end
      end
    else
      # DELETABLE_PASSWORDS_ENABLED not enabled
      password.deletable_by_viewer = false
    end
  end
end
