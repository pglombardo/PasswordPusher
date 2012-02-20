class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google
    @user = User.find_for_open_id(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.google_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
  def yahoo
    @user = User.find_for_open_id(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Yahoo"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.yahoo_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
  def twitter
    @user = User.find_for_open_id(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Twitter"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.twitter_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
  
  def create
     unless params.has_key?(:confirm)
       omniauth = request.env["omniauth.auth"]
       authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
       if authentication
         flash[:success] = "Welcome back!"
         sign_in_and_redirect(:user, authentication.user)
         return

       elsif user_signed_in?
         current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
         flash[:success] = "Successfully linked account.  You can now use this account to log into Gameface."
         redirect_to authentications_url and return

       else
         session[:omniauth] = omniauth.except('extra')
         redirect_to auth_confirm_path and return
       end
     else
       omniauth = session[:omniauth]
       user = User.new
       user.apply_omniauth(omniauth)
       if params.has_key?(:email)
         user.email = params[:email]
       end
       if user.save
         flash[:success] = "Welcome to Gameface!  We're excited to have you!"
         sign_in_and_redirect(:user, user) and return
       else
         session[:omniauth] = omniauth.except('extra')
         raise "failed to save user record"
         redirect_to auth_finalize_path and return
       end
     end
   end
end