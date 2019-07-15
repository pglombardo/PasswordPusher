class Password < ActiveRecord::Base
  has_many :views, :dependent => :destroy
	
  def to_param
    self.url_token.to_s
  end

  def hours_old
    (Time.now.to_i - self.created_at.to_i)/(60*60)
  end

  def hours_remaining
    [(self.expire_after_time - self.hours_old), 0].max
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
    self.expire_after_time  ||= EXPIRE_AFTER_TIME_DEFAULT
    self.expire_after_views ||= EXPIRE_AFTER_VIEWS_DEFAULT

	unless EXPIRE_AFTER_TIME_ALLOWED.include? self.expire_after_time
      self.expire_after_time = EXPIRE_AFTER_TIME_DEFAULT
	end
	
	unless EXPIRE_AFTER_VIEWS_ALLOWED.include? self.expire_after_views
      self.expire_after_views = EXPIRE_AFTER_VIEWS_DEFAULT
	end
	
    unless self.new_record?
      if (self.hours_old >= self.expire_after_time) or (self.views.count >= self.expire_after_views)
        # This password has hit max age or max views - expire it
        self.expired = true
        self.payload = nil
        self.save
      end
    end
  end
end
