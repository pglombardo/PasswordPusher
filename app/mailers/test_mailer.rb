class TestMailer < ApplicationMailer
  def send_test_email(email)
    puts ""
    puts "--> Configured FROM: address: '#{Settings.mail.mailer_sender}'"
    raise StandardError, "No SMTP address provided: smtp_address" if Settings.mail.smtp_address.nil?
    raise StandardError, "No SMTP port provided: smtp_port" if Settings.mail.smtp_port.nil?
    raise StandardError, "No SMTP username provided: smtp_user_name" if Settings.mail.smtp_user_name.nil?
    raise StandardError, "No SMTP password provided: smtp_password" if Settings.mail.smtp_password.nil?
    raise StandardError, "No host domain provided: host_domain" if Settings.host_domain.nil?
    raise StandardError, "No host domain protocol provided: host_protocol" if Settings.host_protocol.nil?

    if Settings.mail.raise_delivery_errors
      puts "--> raise_delivery_errors is set to true in the configuration.  This will raise an error if the email fails to send."
    else
      puts "--> raise_delivery_errors is set to false.  Set to true to see errors if the email fails to send."
    end

    puts "--> Attempting to send a test email to #{email}..."
    mail(to: email,
      subject: "Test Email from Password Pusher",
      body: "⭐ If you are reading this, sending email works! ⭐")

    puts "--> It seems that the Email sent successfully!  Check destination inbox for the test email."
    puts ""

    puts "--> If you see an error, please paste this output into a GitHub issue for help."
    puts "  --> Make sure that no sensitive data is included."
    puts "  --> https://github.com/pglombardo/PasswordPusher/issues/new/choose"

    puts ""
  end
end
