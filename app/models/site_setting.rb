# frozen_string_literal: true

class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # Class method to get custom CSS
  def self.custom_css
    find_by(key: "custom_css")&.value || ""
  end

  # Class method to set custom CSS
  def self.custom_css=(css)
    setting = find_or_initialize_by(key: "custom_css")
    setting.value = css
    setting.save!
  end
end
