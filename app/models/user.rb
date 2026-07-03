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

  # Returns true when the user has hit the daily cap on notification emails
  # (Settings.notify_by_email.daily_limit).
  #
  # Semantics:
  # * nil  -> no cap (feature is unlimited for this user)
  # * 0    -> feature disabled (always treated as "limit reached")
  # * >0   -> compare to today's dispatch count
  def email_limit_reached?
    limit = Settings.notify_by_email&.daily_limit
    return false if limit.nil?
    return true if limit.to_i.zero?

    email_sent_count_reset_at.present? &&
      !email_sent_count_reset_at.before?(Time.current.beginning_of_day) &&
      email_sent_count >= limit.to_i
  end
end
