class Password < ActiveRecord::Base
  attr_accessible :payload, :expire_after_time, :expire_after_views, :deletable_by_viewer
  has_many :views, :dependent => :destroy

  def to_param
    self.url_token.to_s
  end

  def days_old
    (Time.now.to_i - self.created_at.to_i)
  end

  def days_remaining
     if self.expire_after_time < 24
        expire_after = self.expire_after_time * 60 * 60
      else
        expire_after = (self.expire_after_time -23) * 24 * 60 * 60
      end
    [(expire_after - self.days_old)/(24*60*60), 0].max
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
    self.expire_after_time  ||= EXPIRE_AFTER_DAYS_DEFAULT
    self.expire_after_views ||= EXPIRE_AFTER_VIEWS_DEFAULT

    unless self.expire_after_time.between?(EXPIRE_AFTER_DAYS_MIN, EXPIRE_AFTER_DAYS_MAX)
      self.expire_after_time = EXPIRE_AFTER_DAYS_DEFAULT
    end

    unless self.expire_after_views.between?(EXPIRE_AFTER_VIEWS_MIN, EXPIRE_AFTER_VIEWS_MAX)
      self.expire_after_views = EXPIRE_AFTER_VIEWS_DEFAULT
    end

    unless self.new_record?
      if self.expire_after_time < 24
        expire_after = self.expire_after_time * 60 * 60
      else
        expire_after = (self.expire_after_time -23) * 24 * 60 * 60
      end
      if (self.days_old >= expire_after) or (self.views.count >= self.expire_after_views)
        # This password has hit max age or max views - expire it
        self.expired = true
        self.payload = nil
        self.save
      end
    end
  end
end
