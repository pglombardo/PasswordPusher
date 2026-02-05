class ApplicationMailer < ActionMailer::Base
  helper PushesHelper

  default from: Settings.mail.mailer_sender || "oss@pwpush.com"
  layout "mailer"
end
