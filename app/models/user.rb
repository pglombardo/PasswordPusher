# frozen_string_literal: true

class User < ApplicationRecord
  include Pwpush::TokenAuthentication

  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :trackable, :confirmable, :lockable, :timeoutable

  has_many :pushes, dependent: :destroy

  def admin?
    admin
  end
end
