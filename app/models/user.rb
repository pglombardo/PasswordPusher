# frozen_string_literal: true

class User < ApplicationRecord
  include Pwpush::TokenAuthentication
  include PrometheusMetrics

  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :trackable, :confirmable, :lockable, :timeoutable

  has_many :pushes, dependent: :destroy

  attr_readonly :admin

  # Track authentication events
  after_create :track_user_signup
  after_update :track_user_locked, if: :saved_change_to_locked_at?

  def admin?
    admin
  end

  private

  def track_user_signup
    PrometheusMetrics.track_metric("user_signup", {
      locale: preferred_language || "default"
    })
  end

  def track_user_locked
    return unless locked_at.present?

    PrometheusMetrics.track_metric("user_locked", {
      reason: "too_many_failed_attempts"
    })
  end
end
