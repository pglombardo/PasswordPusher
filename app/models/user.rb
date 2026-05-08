# frozen_string_literal: true

class User < ApplicationRecord
  include Pwpush::TokenAuthentication
  include User::TotpAuthentication

  MAX_EMAILS_PER_DAY = 100

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

  def email_limit_reached?
    email_sent_reset_at.present? && email_sent_reset_at.after?(Time.current.beginning_of_day) && (email_sent_count >= MAX_EMAILS_PER_DAY)
  end
end
