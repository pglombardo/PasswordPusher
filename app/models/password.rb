class Password < ApplicationRecord
  has_many :views, dependent: :destroy
  encrypts :payload, :note

  def to_param
    url_token.to_s
  end

  def days_old
    (Time.now.to_datetime - created_at.to_datetime).to_i
  end

  def days_remaining
    [(expire_after_days - days_old), 0].max
  end

  def views_remaining
    [(expire_after_views - views.where(kind: 0).size), 0].max
  end

  def successful_views
    views.where(successful: true, kind: 0).order(:created_at)
  end

  def failed_views
    views.where(successful: false, kind: 0).order(:created_at)
  end

  # Expire this password, delete the password and save the record
  def expire
    self.expired = true
    self.payload = nil
    self.payload_legacy = nil
    self.expired_on = Time.now
    save
  end

  # Override to_json so that we can add in <days_remaining>, <views_remaining>
  # and show the clear password
  def to_json(*args)
    attr_hash = attributes

    if !expired && payload.nil?
      # Use legacy decryption
      key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
      attr_hash['payload'] = key.decrypt64(payload_legacy)
    end

    attr_hash['days_remaining'] = days_remaining
    attr_hash['views_remaining'] = views_remaining

    # Remove unnecessary fields
    attr_hash.delete('payload_ciphertext')
    attr_hash.delete('payload_legacy')
    attr_hash.delete('note_ciphertext')
    attr_hash.delete('note_legacy')
    attr_hash.delete('user_id')
    attr_hash.delete('id')

    # FIXME: Never show note until we have JSON authentication
    # Only the push owner can see the note
    # attr_hash['note'] = key.decrypt64(note_legacy) if note.blank? && !note_legacy.blank?
    attr_hash.delete('note')

    Oj.dump attr_hash
  end

  ##
  # validate!
  #
  # Run basic validations on the password.  Expire the password
  # if it's limits have been reached (time or views)
  #
  def validate!
    return if expired

    # Range checking
    self.expire_after_days  ||= EXPIRE_AFTER_DAYS_DEFAULT
    self.expire_after_views ||= EXPIRE_AFTER_VIEWS_DEFAULT

    unless expire_after_days.between?(EXPIRE_AFTER_DAYS_MIN, EXPIRE_AFTER_DAYS_MAX)
      self.expire_after_days = EXPIRE_AFTER_DAYS_DEFAULT
    end

    unless expire_after_views.between?(EXPIRE_AFTER_VIEWS_MIN, EXPIRE_AFTER_VIEWS_MAX)
      self.expire_after_views = EXPIRE_AFTER_VIEWS_DEFAULT
    end

    return if new_record?

    expire if !days_remaining.positive? || !views_remaining.positive?
  end

  def decrypt(payload)
    return '' if !payload.is_a?(String) || payload.empty?

    # FIXME: Don't need to recreate key everytime
    key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
    # Force UTF-8 encoding so ASCII-8BIT characters like 'æ' will get converted
    # Note: This may break when we add support for MBCS.  TBD.
    key.decrypt64(payload).force_encoding('UTF-8')
  rescue OpenSSL::Cipher::CipherError => e
    Rails.logger.warn("Couldn't decrypt: #{e}")
    payload
  end
end
