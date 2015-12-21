module Tokenable
  extend ActiveSupport::Concern

  module ClassMethods
    def credentials(token)
      info = $redis.get(token)
      if info
        {
          info: info,
          expires_in: $redis.ttl(token)
        }
      end
    end
  end

  def display_name
    "#{first_name} #{last_name}"
  end

  def token(**credentials)
    credentials.symbolize_keys!
    [:client_id, :scope].each do |rkey|
      unless credentials.has_key? rkey
        raise ArgumentError, "#{rkey} required"
      end
    end
    [first_name, last_name, email].each do |rattr|
      unless rattr
        raise ArgumentError, "#{rattr} required"
      end
    end
    new_token = SecureRandom.hex
    credentials[:uid] = uid
    credentials[:first_name] = first_name
    credentials[:last_name] = last_name
    credentials[:display_name] = display_name
    credentials[:email] = email
    $redis.multi do
      $redis.set new_token, credentials.to_json
      $redis.expire new_token, Rails.application.config.token_ttl
    end
    new_token
  end

end
