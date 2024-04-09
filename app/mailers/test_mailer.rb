class TestMailer < ApplicationMailer
  def send_test_email(email)
    puts "Configured from address: '#{Settings.mail.mailer_sender}'"
    raise StandardError, "No host domain provided: host_domain" if Settings.host_domain.nil?
    raise StandardError, "No host domain protocol provided: host_protocol" if Settings.host_protocol.nil?
    raise StandardError, "No SMTP host address provided: smtp_address" if Settings.mail.smtp_address.nil?
    raise StandardError, "No SMTP port provided: smtp_port" if Settings.mail.smtp_port.nil?
    raise StandardError, "No SMTP username provided: smtp_user_name" if Settings.mail.smtp_user_name.nil?
    raise StandardError, "No SMTP password provided: smtp_password" if Settings.mail.smtp_password.nil?

    mail(to: email,
      subject: "Test Email from Password Pusher",
      body: "⭐ If you are reading this, sending email works! ⭐")
  end
end
