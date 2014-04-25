module Cathode
  class Token < ActiveRecord::Base
    after_initialize :generate_token

    validates :token, uniqueness: true

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
