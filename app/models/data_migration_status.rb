class DataMigrationStatus < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
