class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, #:validatable, :recoverable,
         :authentication_keys => [:username]
  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :password, :password_confirmation, :remember_me

  validates :username, presence: :true, uniqueness: { case_sensitive: false }

  has_many :passwords
end
