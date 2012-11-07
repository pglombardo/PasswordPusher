class PasswordsController < ApplicationController
  # GET /passwords/1
  # GET /passwords/1.json
  def show
    if params.has_key?(:url_token)
      @password = Password.find_by_url_token!(params[:url_token])   
      @views = View.where(:password_id => @password.id, :successful => true)
    else
      redirect_to :root
      return
    end
    
    @views_remaining = 0
    @days_remaining = 0
    
    # Range checking
    @password.expire_after_days = EXPIRE_AFTER_DAYS_DEFAULT unless @password.expire_after_days
    @password.expire_after_views = EXPIRE_AFTER_VIEWS_DEFAULT unless @password.expire_after_views

    # Calculate views remaining and days remaining
    @views_remaining = @password.expire_after_views - @views.count
    
    @days_old = (Time.now.to_datetime - @password.created_at.to_datetime).to_i
    @days_remaining = @password.expire_after_days - @days_old
    
    unless @password.expired
      # This password hasn't expired yet.
      
      if (@days_old > @password.expire_after_days) or (@views.count > @password.expire_after_views)
        # This password has hit max age or max views - expire it
        @password.expired = true
        @password.payload = nil
        @password.save
      else

        # Decrypt the passwords
        @key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
        @payload = @key.decrypt64(@password.payload)
      end
    else
      # This password is expired      
    end
    
    @views_remaining = 0 if @views_remaining < 0
    @days_remaining = 0  if @days_remaining  < 0
    
    if @views.count == 0
      @first_view = true
    end
    
    @view = View.new
    @view.password_id = @password.id
    @view.ip = request.env["HTTP_X_FORWARDED_FOR"].nil? ? request.env["REMOTE_ADDR"] : request.env["HTTP_X_FORWARDED_FOR"]
    @view.user_agent = request.env["HTTP_USER_AGENT"]
    @view.referrer = request.env["HTTP_REFERER"]
    @view.successful = @password.expired ? false : true
    @view.save
    
    @views << @view
    
    expires_now()

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

    @password = Password.new()
    
    @password.expire_after_days = params[:password][:expire_after_days]
    @password.expire_after_views = params[:password][:expire_after_views]
    
    # Check ranges
    unless @password.expire_after_days.between?(EXPIRE_AFTER_DAYS_MIN, EXPIRE_AFTER_DAYS_MAX)
      @password.expire_after_days = EXPIRE_AFTER_DAYS_DEFAULT
    end
    
    unless @password.expire_after_views.between?(EXPIRE_AFTER_VIEWS_MIN, EXPIRE_AFTER_VIEWS_MAX)
      @password.expire_after_views = EXPIRE_AFTER_VIEWS_DEFAULT 
    end
    
    @password.url_token = rand(36**16).to_s(36)
    
    if current_user
      @password.user_id = current_user.id
    end
    
    # Encrypt the passwords
    @key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
    @password.payload = @key.encrypt64(params[:password][:payload])
    
    respond_to do |format|
      if @password.save
        format.html { redirect_to "/p/#{@password.url_token}", :notice => "The password has been pushed." }
        format.json { render :json => @password, :status => :created }
      else
        format.html { render :action => "new" }
        format.json { render :json => @password.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    if params.has_key?(:url_token)
      @password = Password.find_by_url_token!(params[:url_token])   
    else
      redirect_to :root
      return
    end
    
    @password.expired = true
    @password.payload = nil
    @password.deleted = true
    
    respond_to do |format|
      if @password.save
        format.html { redirect_to "/p/#{@password.url_token}", :notice => "The password has been deleted." }
        format.json { render :json => @password, :status => :destroyed }
      else
        format.html { render :action => "new" }
        format.json { render :json => @password.errors, :status => :unprocessable_entity }
      end
    end
  end
end
