require 'securerandom'

class PasswordsController < ApplicationController
  helper PasswordsHelper

  acts_as_token_authentication_handler_for User, fallback: :none, only: [:create, :destroy]
  acts_as_token_authentication_handler_for User, only: [:audit]

  resource_description do
    name 'Pushes'
    short 'Interact directly with pushes.'
  end

  api :GET, '/p/:url_token.json', 'Retrieve a push.'
  param :url_token, String, desc: 'Secret URL token of a previously created push.', :required => true
  formats ['json']
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/fk27vnslkd.json'
  description "Retrieves a push including it's payload and details.  If the push is still active, this will burn a view and the transaction will be logged in the push audit log."
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
        format.json { render json: @password.to_json(payload: true) }
      end
      return
    else
      @payload = @password.payload
    end

    log_view(@password)
    expires_now

    respond_to do |format|
      format.html { render layout: 'bare' }
      format.json { render json: @password.to_json(payload: true) }
    end

    # Expire if this is the last view for this push
    @password.expire if !@password.views_remaining.positive?
  end

  # GET /passwords/new
  def new
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    @password = Password.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  api :POST, '/p.json', 'Create a new push.'
  param :password, Hash, "Push details", required: true do
    param :payload, String, desc: 'The password or secret text to share.', required: true
    param :note, String, desc: 'If authenticated, the note to label this push.', allow_blank: true
    param :expire_after_days, Integer, desc: 'Expire secret link and delete after this many days.'
    param :expire_after_views, Integer, desc: 'Expire secret link and delete after this many views.'
    param :deletable_by_viewer, [true, false], desc: "Allow users to delete passwords once retrieved."
    param :retrieval_step, [true, false], desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  formats ['json']
  example 'curl -X POST -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" --data "password[payload]=mypassword&password[expire_after_days]=2&password[expire_after_views]=10" https://pwpush.com/p.json'
  def create
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    # params[:password] has to exist
    # params[:password] has to be a ActionController::Parameters (Hash)
    password_param = params.fetch(:password, {})
    if !password_param.respond_to?(:fetch)
      respond_to do |format|
        format.html { redirect_to root_path, status: :bad_request, notice: 'Bad Request' }
        format.json { render json: '{}', status: :bad_request }
      end
      return
    end

    # params[:password][:payload] || params[:password][:payload] has to exist
    # params[:password][:payload] can't be blank
    # params[:password][:payload] must have a length between 1 and 1 megabyte
    payload_param = password_param.fetch(:payload, '')
    files_param   = password_param.fetch(:files, [])
    unless (payload_param.is_a?(String) && payload_param.length.between?(1, 1.megabyte)) || !files_param.empty?
      respond_to do |format|
        format.html { redirect_to root_path, status: :bad_request, notice: 'Bad Request' }
        format.json { render json: '{}', status: :bad_request }
      end
      return
    end

    @password = Password.new
    @password.expire_after_days = params[:password].fetch(:expire_after_days, Settings.expire_after_days_default)
    @password.expire_after_views = params[:password].fetch(:expire_after_views, Settings.expire_after_views_default)
    @password.user_id = current_user.id if user_signed_in?
    @password.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase

    create_detect_deletable_by_viewer(@password, params)
    create_detect_retrieval_step(@password, params)

    @password.payload = params[:password][:payload]
    @password.note = params[:password][:note] unless params[:password].fetch(:note, '').blank?
    @password.files.attach(params[:password][:files])

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

  api :GET, '/p/:url_token/preview.json', 'Helper endpoint to retrieve the fully qualified secret URL of a push.'
  param :url_token, String, desc: 'Secret URL token of a previously created push.', :required => true
  formats ['json']
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/fk27vnslkd/preview.json'
  description ""
  def preview
    @password = Password.find_by_url_token!(params[:id])

    @secret_url = helpers.secret_url(@password)

    respond_to do |format|
      format.html { render action: 'preview' }
      format.json { render json: { url: @secret_url }, status: :ok }
    end
  end

  def preliminary
    begin
      @password = Password.find_by_url_token!(params[:id])
    rescue ActiveRecord::RecordNotFound
      # Showing a 404 reveals that this Secret URL never existed
      # which is an information leak (not a secret anymore)
      #
      # We also don't want data in general. We entirely delete old pushes that:
      # 1. have expired (payloads already deleted long ago)
      # 2. are anonymous/not linked to a user account (audit log not needed)
      #
      # When not found, show the 'expired' page so even very old secret URLs
      # when clicked they will be accurate - this secret URL has expired.
      # No easy fix for JSON unfortunately as we don't have a record to show.
      respond_to do |format|
        format.html { render template: 'passwords/show_expired', layout: 'naked' }
        format.json { render json: { error: 'not-found' }.to_json, status: 404 }
      end
      return
    end

    respond_to do |format|
      format.html { render action: 'preliminary', layout: 'naked' }
    end
  end

  api :GET, '/p/:url_token/audit.json', 'Retrieve the audit log for a push.'
  param :url_token, String, desc: 'Secret URL token of a previously created push.', :required => true
  formats ['json']
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/fk27vnslkd/audit.json'
  description "This will return array of views including IP, referrer and other such metadata.  The _successful_ field indicates whether " +
    "the view was made while the push was still active (and not expired).  Note that you must be the owner of the push to retrieve " +
    "the audit log and this call will always return 401 Unauthorized for pushes not owned by the credentials provided."
  def audit
    @password = Password.includes(:views).find_by_url_token!(params[:id])

    if @password.user_id != current_user.id
      respond_to do |format|
        format.html { redirect_to :root, notice: _("That push doesn't belong to you.") }
        format.json { render json: { "error": "That push doesn't belong to you." } }
      end
      return
    end

    respond_to do |format|
      format.html { }
      format.json {
        render json: { views: @password.views }.to_json(except: [:user_id, :password_id, :id])
      }
    end
  end

  api :DELETE, '/p/:url_token.json', 'Expire a push: delete the payload and expire the secret URL.'
  param :url_token, String, desc: 'Secret URL token of a previously created push.', :required => true
  formats ['json']
  example 'curl -X DELETE -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/fkwjfvhall92.json'
  description "Expires a push immediately.  Must be authenticated & owner of the push _or_ the push must have been created with _deleteable_by_viewer_."
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
                        notice: _('The push payload & content have been deleted and secret URL expired.')
          else
            redirect_to @password,
                        notice: _('The push payload & content have been deleted and secret URL expired.')
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
    if Settings.enable_retrieval_step == true
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
          password.retrieval_step = Settings.retrieval_step_default
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
    if Settings.enable_deletable_pushes == true
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
          password.deletable_by_viewer = Settings.deletable_pushes_default
        end
      end
    else
      # DELETABLE_PASSWORDS_ENABLED not enabled
      password.deletable_by_viewer = false
    end
  end

  def password_params
    params.require(:password).permit(:payload, :expire_after_days, :expire_after_views,
                                     :retrieval_step, :deletable_by_viewer, :note, :files => [])
  end
end
