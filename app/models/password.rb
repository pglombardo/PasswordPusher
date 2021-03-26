class Password < ApplicationRecord
  # attr_accessible :payload, :expire_after_days, :expire_after_views, :deletable_by_viewer
  has_many :views, dependent: :destroy

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
    [(expire_after_views - views.size), 0].max
  end

  # Expire this password, delete the password and save the record
  def expire
    self.expired = true
    self.payload = nil
    save
  end

  # Override to_json so that we can add in <days_remaining>, <views_remaining>
  # and show the clear password
  def to_json(*args)
    attr_hash = attributes

    if !expired && !payload.nil?
      key = EzCrypto::Key.with_password CRYPT_KEY, CRYPT_SALT
      attr_hash['payload'] = key.decrypt64(attr_hash['payload'])
    end

    attr_hash['days_remaining'] = days_remaining
    attr_hash['views_remaining'] = views_remaining
    attr_hash.to_json
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

    expire unless days_remaining.positive?
    expire unless views_remaining.positive?
  end
end
