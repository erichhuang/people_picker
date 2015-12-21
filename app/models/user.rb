class User < ActiveRecord::Base
  include Tokenable

  validates :uid, presence: true, uniqueness: true
end
