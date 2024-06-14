class ApplicationMailer < ActionMailer::Base
  default from: Settings.mail.mailer_sender || "oss@pwpush.com"
  layout "mailer"
end
