require 'openssl'
require 'digest/sha2'
require 'base64'
require 'json'

class PasswordsController < ApplicationController
  # GET /passwords/1
  # GET /passwords/1.json
  def show
	check_host()
	
    if params.has_key?(:id)
	
      @password = Password.find_by_url_token!(params[:id])

	  # Show 404 if the password coma from a other host
	  if (@password.host != request.host)
	    not_found
	  end
	
      # If this is the first view, update record.  Otherwise, record a view.
      @first_view = @password.first_view

      if @first_view
        @password.update_attribute(:first_view, false)
      else
        @password.views = View.where(:password_id => @password.id, :successful => true)
      end
    # Redirect to root if the password is from diffrent host
    else
      redirect_to :root
      return
    end

    # This password may have expired since the last view.  Validate the password
    # expiration before doing anything.
    @password.validate!

    unless @password.expired
      # Decrypt the passwords
      @payload = decrypt(CRYPT_KEY,CRYPT_SALT,@password.payload)
    end

    log_view(@password) unless @first_view

    expires_now()

    respond_to do |format|
      format.html # show.html.erb
      @password.payload = @payload
      format.json { render :json => @password }
    end
  end

  # GET /passwords/new
  # GET /passwords/new.json
  def new
    check_host()
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
    check_host()
    if params[:password][:payload].blank? or params[:password][:payload] == PAYLOAD_INITIAL_TEXT
      redirect_to '/'
      return
    end
	
	# User can input a secret with a length of 250 chars. After the first encrypton 
	# on client site the payload will be longer up to 703 chars
    if params[:password][:payload].length > 730
      redirect_to '/', :error => "That password is too long."
      return
    end

    @password = Password.new
    time = params[:password][:expire_after_time]
    @password.expire_after_time = time
    @password.expire_after_views = params[:password][:expire_after_views]

    if DELETABLE_BY_VIEWER_PASSWORDS && params[:password].key?(:deletable_by_viewer)
      @password.deletable_by_viewer = true
    else
      @password.deletable_by_viewer = false
    end

    @password.url_token = rand(36**16).to_s(36)

    # The first view on new passwords are free since we redirect
    # the passwd creator to the password itself (and don't burn up a view).
    @password.first_view = true

    # Encrypt the passwords
    @password.payload = encrypt(CRYPT_KEY,CRYPT_SALT,params[:password][:payload])

    @password.validate!
	
    @password.host = request.host
	
	if @password.save
	  response = {'success' => 1, 'token' => @password.url_token}
	else
	  response = {'success' => 0}
	end
	
    respond_to do |format|
      if @password.save
        format.html { render :json => response.to_json }
        @password.payload = params[:password][:payload]
        format.json { render :json => @password, :status => :created }
      else
        format.html { render :json => response.to_json }
        format.json { render :json => @password.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    check_host()
    if params.has_key?(:id)
      @password = Password.find_by_url_token!(params[:id])
    end

    # Redirect to root if we couldn't find password
    unless @password
      redirect_to :root
      return
    end
	
    # Redirect to root if the password is from diffrent host
	if (@password.host != request.host)
      redirect_to :root
      return
	end
	
    # Redirect to root if the found password wasn't 
	# market as deletable
	if (!@password.deletable_by_viewer)
      redirect_to :root
      return
	end

    @password.expired = true
    @password.payload = nil
    @password.deleted = true

    respond_to do |format|
      if @password.save
        format.html { redirect_to @password, :notice => "The password has been deleted." }
        format.json { render :json => @password, :status => :destroyed }
      else
        format.html { render :action => "new" }
        format.json { render :json => @password.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def password_params
    params.require(:password).permit(:payload, :expire_after_time, :expire_after_views, :deletable_by_viewer)
  end

  def user_params
    params.requre(:user).permit(:email, :password, :password_confirmation, :remember_me)
  end
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

  def encrypt(key,salt,data)
    cipher = OpenSSL::Cipher.new("aes-256-cbc")
    cipher.encrypt
    dKey = Digest::SHA256.hexdigest(key + salt)
    cipher.key = dKey[0..31]
    iv = cipher.random_iv
    encrypted = cipher.update(data)
    encrypted << cipher.final
    return Base64.encode64(iv + encrypted)
  end

  def decrypt(key,salt,data)
    decodedData = Base64.decode64(data)
    cipher = OpenSSL::Cipher.new("aes-256-cbc")
    cipher.decrypt
    dKey = Digest::SHA256.hexdigest(key + salt)
    cipher.key = dKey[0..31]
    cipher.iv = decodedData[0..15]
    decrypted = cipher.update(decodedData[16..-1])
    decrypted << cipher.final
    return decrypted
  end
  
  def check_host()
	if ! ALLOWED_DOMAINS.include? request.host
		if ! Rails.env.test? && ! Rails.env.development?
			unkonw_host_error(request.host)
			raise ActionController::ActionControllerError.new('Server Error')
		end
	end
  end
end
