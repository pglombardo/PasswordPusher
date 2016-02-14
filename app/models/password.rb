class Password < ActiveRecord::Base
  attr_accessible :payload, :expire_after_days, :expire_after_views, :deletable_by_viewer
  has_many :views, :dependent => :destroy

  def to_param
    self.url_token.to_s
  end

  def days_old
    (Time.now.to_datetime - self.created_at.to_datetime).to_i
  end

  def days_remaining
    [(self.expire_after_days - self.days_old), 0].max
  end

  def views_remaining
    [(self.expire_after_views - self.views.count), 0].max
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

    unless self.expire_after_days.between?(EXPIRE_AFTER_DAYS_MIN, EXPIRE_AFTER_DAYS_MAX)
      self.expire_after_days = EXPIRE_AFTER_DAYS_DEFAULT
    end

    unless self.expire_after_views.between?(EXPIRE_AFTER_VIEWS_MIN, EXPIRE_AFTER_VIEWS_MAX)
      self.expire_after_views = EXPIRE_AFTER_VIEWS_DEFAULT
    end

    unless self.new_record?
      if (self.days_old >= self.expire_after_days) or (self.views.count >= self.expire_after_views)
        # This password has hit max age or max views - expire it
        self.expired = true
        self.payload = nil
        self.save
      end
    end
  end
end
