class User < ActiveRecord::Base
  include Tokenable

  validates :uid, presence: true, uniqueness: true

  scope :first_name_begins, ->(query_string) { where("first_name like ?", "#{query_string}%") }
  scope :last_name_begins, ->(query_string) { where("last_name like ?", "#{query_string}%") }
end
