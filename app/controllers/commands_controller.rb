class CommandsController < ApplicationController

  def create
    unless params[:command] == '/pwp'
      render :text => 'Unknown command.', layout: false, content_type: 'text/plain'
      return
    end

    secret, opts = params[:text].split(' ')
    if opts
      days, views = opts.split(',')
    end

    @password = Password.new
    @password.expire_after_days = days
    @password.expire_after_views = views
    @password.deletable_by_viewer = DELETABLE_BY_VIEWER_PASSWORDS

    # Encrypt the passwords
    @key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
    @password.payload = @key.encrypt64(secret)

    @password.url_token = rand(36**16).to_s(36)
    @password.validate!

    if @password.save
      render :text => "https://pwpush.com/p/#{@password.url_token}"
    else
      render :text => @password.errors
    end
  end
end
