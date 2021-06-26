class PasswordsController < ApplicationController
  # GET /passwords/1
  # GET /passwords/1.json
  def show
    redirect_to :root && return unless params.key?(:id)
    @password = Password.find_by_url_token!(params[:id])

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
      # Decrypt the passwords
      @key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
      @payload = @key.decrypt64(@password.payload)
    end

    log_view(@password)
    expires_now

    respond_to do |format|
      format.html { render layout: 'naked' }
      format.json { render json: @password }
    end
  end

  # GET /passwords/new
  # GET /passwords/new.json
  def new
    @password = Password.new
    expires_in 3.hours, :public => true, 'max-stale' => 0

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @password }
    end
  end

  # POST /passwords
  # POST /passwords.json
  def create
    if params[:password][:payload].blank? || params[:password][:payload] == PAYLOAD_INITIAL_TEXT
      redirect_to '/'
      return
    end

    if params[:password][:payload].length > 250
      redirect_to '/', error: 'That password is too long.'
      return
    end

    @password = Password.new
    @password.expire_after_days = params[:password][:expire_after_days]
    @password.expire_after_views = params[:password][:expire_after_views]
    @password.url_token = rand(36**16).to_s(36)

    create_detect_deletable_by_viewer(@password, params)
    create_detect_retrieval_step(@password, params)

    @password.payload = encrypt_password(params[:password][:payload])
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

    # Support forced https links with FORCE_SSL env var
    @secret_url = if ENV.key?('FORCE_SSL') && !request.ssl?
                    password_url(@password).gsub(/http/i, 'https')
                  else
                    password_url(@password)
                  end

    @secret_url += '/r' if @password.retrieval_step

    respond_to do |format|
      format.html { render action: 'preview', layout: 'naked' }
      format.json { render json: @password, status: :ok }
    end
  end

  def preliminary
    @password = Password.find_by_url_token!(params[:id])

    # Support forced https links with FORCE_SSL env var
    @secret_url = if ENV.key?('FORCE_SSL') && !request.ssl?
                    password_url(@password).gsub(/http/i, 'https')
                  else
                    password_url(@password)
                  end

    respond_to do |format|
      format.html { render action: 'preliminary', layout: 'naked' }
      format.json { render json: @password, status: :ok }
    end
  end

  def destroy
    @password = Password.find_by_url_token!(params[:id])

    # Redirect to root if we couldn't find password or
    # the found password wasn't market as deletable
    if @password.deletable_by_viewer == false
      redirect_to :root
      return
    end

    @password.expired = true
    @password.payload = nil
    @password.deleted = true

    respond_to do |format|
      if @password.save
        format.html { redirect_to @password, notice: 'The password has been deleted.' }
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
  def log_view(password)
    view = View.new
    view.password_id = password.id
    view.ip = request.env['HTTP_X_FORWARDED_FOR'].nil? ? request.env['REMOTE_ADDR'] : request.env['HTTP_X_FORWARDED_FOR']

    # Limit retrieved values to 256 characters
    view.user_agent  = request.env['HTTP_USER_AGENT'].to_s[0, 255]
    view.referrer    = request.env['HTTP_REFERER'].to_s[0, 255]

    view.successful  = password.expired ? false : true
    view.save

    password.views << view
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
    if DELETABLE_BY_VIEWER_PASSWORDS == true
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
          password.deletable_by_viewer = DELETABLE_BY_VIEWER_DEFAULT
        end
      end
    else
      # DELETABLE_BY_VIEWER_PASSWORDS not enabled
      password.deletable_by_viewer = false
    end
  end

  def encrypt_password(password)
    @key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
    @key.encrypt64(password)
  end
end