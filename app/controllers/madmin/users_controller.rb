module Madmin
  class UsersController < Madmin::ResourceController
    def create
      @record = resource.model.new(user_params)

      # Generate a secure random password
      password = Devise.friendly_token.first(16)
      @record.password = password
      @record.password_confirmation = password

      # Handle auto-confirmation if checkbox is checked
      if params[:user][:auto_confirm] == "1"
        @record.skip_confirmation_notification!
        @record.skip_confirmation!
        @record.confirm
      end

      if @record.save
        redirect_to resource.show_path(@record), notice: success_message
      else
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      @record = resource.model_find(params[:id])

      # Prevent admin from deleting their own account
      if @record == current_user
        redirect_to resource.index_path, alert: "You cannot delete your own account."
        return
      end

      user_email = @record.email

      begin
        if @record.destroy
          redirect_to resource.index_path, notice: "User #{user_email} has been deleted."
        else
          redirect_to resource.index_path, alert: "Failed to delete user #{user_email}"
        end
      rescue => e
        redirect_to resource.index_path, alert: "An error occurred while deleting user #{user_email}: #{e.message}"
      end
    end

    private

    def user_params
      params.require(:user).permit(:email)
    end

    def success_message
      message = "User #{@record.email} has been created successfully. "
      message += "A secure password has been automatically generated. "
      message += "The user can reset their password using the 'Forgot Password' link on the login page."
      message
    end
  end
end
