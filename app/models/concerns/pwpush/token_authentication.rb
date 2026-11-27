# frozen_string_literal: true

module Pwpush
  module TokenAuthentication
    extend ActiveSupport::Concern

    included do
      self.filter_attributes |= %i[
        authentication_token
        authentication_token_digest
        authentication_token_hint
      ]

      after_find { @raw_authentication_token = nil }
    end

    class_methods do
      def digest_authentication_token(token)
        Pwpush::AuthenticationTokenDigest.hexdigest(token)
      end

      # Indexed lookup by HMAC digest, then a constant-time compare of the stored digest.
      def find_by_authentication_token(token)
        return if token.blank?

        digest = digest_authentication_token(token)
        return if digest.blank?

        user = find_by(authentication_token_digest: digest)
        return if user.nil?
        return if user.authentication_token_digest.blank?
        return unless secure_authentication_token_digest?(user.authentication_token_digest, digest)

        user
      end

      def secure_authentication_token_digest?(stored, computed)
        return false if stored.bytesize != computed.bytesize

        ActiveSupport::SecurityUtils.secure_compare(stored, computed)
      end
    end

    def has_authentication_token?
      authentication_token_digest.present?
    end

    def masked_authentication_token
      Pwpush::AuthenticationTokenDigest.masked(authentication_token_hint)
    end

    # In-memory plaintext from this process only (just after generate/regenerate).
    # The database column is always NULL after hashing.
    def authentication_token
      @raw_authentication_token
    end

    def authentication_token=(plaintext)
      assign_hashed_authentication_token(plaintext)
      super(nil)
    end

    def regenerate_authentication_token!
      token = generate_authentication_token
      self.authentication_token = token
      save!
      token
    end

    def purge_authentication_token!
      self.authentication_token = nil
      save!
    end

    def serializable_hash(options = nil)
      options = options ? options.dup : {}
      except = Array(options[:except]).map(&:to_s)
      except |= %w[authentication_token authentication_token_digest authentication_token_hint]
      super(options.merge(except: except))
    end

    private

    def assign_hashed_authentication_token(plaintext)
      token = plaintext.presence
      @raw_authentication_token = token
      if token
        self.authentication_token_digest = self.class.digest_authentication_token(token)
        self.authentication_token_hint = Pwpush::AuthenticationTokenDigest.hint_for(token)
      else
        self.authentication_token_digest = nil
        self.authentication_token_hint = nil
      end
      self.authentication_token_legacy = false
    end

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        digest = self.class.digest_authentication_token(token)
        break token unless self.class.exists?(authentication_token_digest: digest)
      end
    end
  end
end
