module Cathode
  # Defines a token model to hold the API tokens.
  class Token < ActiveRecord::Base
    after_initialize :generate_token

    validates :token, uniqueness: true

    # Expires the token by deactivating it and updating its `expired_at` field.
    # @return [Token] self
    def expire
      update active: false, expired_at: Time.now
      self
    end

  private

    def generate_token
      self.token = SecureRandom.hex
    end
  end
end
