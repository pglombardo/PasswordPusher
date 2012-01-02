class PasswordsController < ApplicationController
  # GET /passwords
  # GET /passwords.json
  def index
    @passwords = Password.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @passwords }
    end
  end

  # GET /passwords/1
  # GET /passwords/1.json
  def show
    if params.has_key?(:url_token)
      @password = Password.find_by_url_token!(params[:url_token])   
      @views = View.where(:password_id => @password.id)
    else
      redirect_to :root
      return
    end
    
    @views_remaining = 0    
    @days_old = (Time.now.to_datetime - @password.created_at.to_datetime).to_i
    @days_remaining = @password.expire_after_days - @days_old
    unless @password.expired
      # This password hasn't expired yet.
      
      if @password.expire_after_days < @days_old
        # This password has expired - expire it
        @password.expired = true
        @password.payload = nil
        @password.save
      elsif  @views.count > @password.expire_after_views and not @password.expired
          # Expire this Password as it has hit maximum views
          @password.expired = true
          @password.payload = nil
          @password.save
        else
          @views_remaining = @password.expire_after_views - @views.count
      end
    else
      # This password is expired      
    end
    
    @view = View.new
    @view.password_id = @password.id
    @view.ip = request.env["HTTP_X_FORWARDED_FOR"]
    @view.user_agent = request.env["HTTP_USER_AGENT"]
    @view.referrer = request.env["HTTP_REFERRER"]
    @view.save
    
    @views << @view

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @password }
    end
  end

  # GET /passwords/new
  # GET /passwords/new.json
  def new
    @password = Password.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @password }
    end
  end

  # GET /passwords/1/edit
  def edit
    @password = Password.find(params[:id])
  end

  # POST /passwords
  # POST /passwords.json
  def create
    if params[:password].has_key?(:payload) and params[:password][:payload] == PAYLOAD_INITIAL_TEXT
      redirect_to '/'
      return
    end
    
    @password = Password.new(params[:password])
    @password.url_token = rand(36**16).to_s(36)
    
    respond_to do |format|
      if @password.save
        format.html { redirect_to "/p/#{@password.url_token}", :notice => 'Password was successfully created.' }
        format.json { render :json => @password, :status => :created, :location => @password }
      else
        format.html { render :action => "new" }
        format.json { render :json => @password.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /passwords/1
  # PUT /passwords/1.json
  def update
    @password = Password.find(params[:id])

    respond_to do |format|
      if @password.update_attributes(params[:password])
        format.html { redirect_to @password, :notice => 'Password was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @password.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /passwords/1
  # DELETE /passwords/1.json
  def destroy
    @password = Password.find(params[:id])
    @password.destroy

    respond_to do |format|
      format.html { redirect_to passwords_url }
      format.json { head :ok }
    end
  end
end
