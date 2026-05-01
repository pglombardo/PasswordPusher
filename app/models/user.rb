# frozen_string_literal: true

class User < ApplicationRecord
  include Pwpush::TokenAuthentication
  include User::TotpAuthentication

  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  # Email-based modules (:confirmable, :lockable, :recoverable) are added when
  # Settings.enable_user_account_emails is true (requires SMTP in config/settings.yml).
  devise_modules = [:database_authenticatable, :registerable, :rememberable, :validatable, :trackable, :timeoutable]
  devise_modules += [:confirmable, :lockable, :recoverable] if Settings.enable_user_account_emails
  devise(*devise_modules)

  has_many :pushes, dependent: :destroy

  attr_readonly :admin

  def admin?
    admin
  end
end
