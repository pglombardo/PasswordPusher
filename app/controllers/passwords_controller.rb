class PasswordsController < ApplicationController
  # GET /passwords/1
  # GET /passwords/1.json
  def show
    if params.key?(:id)
      @password = Password.find_by_url_token!(params[:id])

      # If this is the first view, update record.  Otherwise, record a view.
      @first_view = @password.first_view

      if @first_view
        @password.update_attribute(:first_view, false)
      else
        @password.views = View.where(:password_id => @password.id, :successful => true)
      end
    else
      redirect_to :root
      return
    end

    # This password may have expired since the last view.  Validate the password
    # expiration before doing anything.
    @password.validate!

    unless @password.expired
      # Decrypt the passwords
      @key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
      @payload = @key.decrypt64(@password.payload)
    end

    log_view(@password) unless @first_view

    expires_now

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @password }
    end
  end

  # GET /passwords/new
  # GET /passwords/new.json
  def new
    @password = Password.new
    expires_in 3.hours, :public => true, 'max-stale' => 0

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @password }
    end
  end

  # POST /passwords
  # POST /passwords.json
  def create
    if params[:password][:payload].blank? or params[:password][:payload] == PAYLOAD_INITIAL_TEXT
      redirect_to '/'
      return
    end

    if params[:password][:payload].length > 250
      redirect_to '/', :error => "That password is too long."
      return
    end

    @password = Password.new
    @password.expire_after_days = params[:password][:expire_after_days]
    @password.expire_after_views = params[:password][:expire_after_views]

    if DELETABLE_BY_VIEWER_PASSWORDS == true
      if params[:password].key?(:deletable_by_viewer)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_dvb = params[:password][:deletable_by_viewer].to_s.downcase
        @password.deletable_by_viewer = %w[on yes checked true].include?(user_dvb)
      else
        if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          @password.deletable_by_viewer = false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          @password.deletable_by_viewer = DELETABLE_BY_VIEWER_DEFAULT
        end
      end
    else
      # DELETABLE_BY_VIEWER_PASSWORDS not enabled
      @password.deletable_by_viewer = false
    end

    @password.url_token = rand(36**16).to_s(36)

    if params[:password].key?(:first_view)
      @password.first_view = params[:password][:first_view].to_s.casecmp('true').zero?
    else
      # The first view on new passwords are free since we redirect
      # the passwd creator to the password itself (and don't burn up a view).
      @password.first_view = true
    end

    # Encrypt the password
    @key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
    @password.payload = @key.encrypt64(params[:password][:payload])

    @password.validate!

    respond_to do |format|
      if @password.save
        format.html { redirect_to @password, notice: 'The password has been pushed.' }
        format.json { render json: @password, status: :created }
      else
        format.html { render action: 'new' }
        format.json { render json: @password.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if params.key?(:id)
      @password = Password.find_by_url_token!(params[:id])
    end

    # Redirect to root if we couldn't find password or
    # the found password wasn't market as deletable
    unless @password || @password.deletable_by_viewer
      redirect_to :root
      return
    end

    @password.expired = true
    @password.payload = nil
    @password.deleted = true

    respond_to do |format|
      if @password.save
        format.html { redirect_to @password, :notice => "The password has been deleted." }
        format.json { render :json => @password, :status => :ok }
      else
        format.html { render :action => "new" }
        format.json { render :json => @password.errors, :status => :unprocessable_entity }
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
    view.ip          = request.env["HTTP_X_FORWARDED_FOR"].nil? ? request.env["REMOTE_ADDR"] : request.env["HTTP_X_FORWARDED_FOR"]

    # Limit retrieved values to 256 characters
    view.user_agent  = request.env["HTTP_USER_AGENT"].to_s[0,255]
    view.referrer    = request.env["HTTP_REFERER"].to_s[0,255]

    view.successful  = password.expired ? false : true
    view.save

    password.views << view
    password
  end
end
