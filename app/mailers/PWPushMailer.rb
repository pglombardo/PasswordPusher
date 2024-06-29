class PWPushMailer < Devise::Mailer
  if Settings.mail
    if Settings.mail.mailer_sender
      default from: Settings.mail.mailer_sender
    end

    if Settings.mail.mailer_reply_to
      default reply_to: Settings.mail.mailer_reply_to
    end
  end
end

