class Password < ApplicationRecord
  has_many :views, dependent: :destroy
  has_encrypted :payload, :note

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
    self.expired_on = Time.now
    save
  end

  # Override to_json so that we can add in <days_remaining>, <views_remaining>
  # and show the clear password
  def to_json(*args)
  # def to_json(owner: false, payload: false)
    attr_hash = attributes

    owner = false
    payload = false

    owner = args.first[:owner] if args.first.key?(:owner)
    payload = args.first[:payload] if args.first.key?(:payload)

    attr_hash['days_remaining'] = days_remaining
    attr_hash['views_remaining'] = views_remaining

    # Remove unnecessary fields
    attr_hash.delete('payload_ciphertext')
    attr_hash.delete('note_ciphertext')
    attr_hash.delete('user_id')
    attr_hash.delete('id')

    attr_hash.delete('note') unless owner
    attr_hash.delete('payload') unless payload

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
end
