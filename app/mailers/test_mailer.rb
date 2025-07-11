class TestMailer < ApplicationMailer
  def send_test_email(email)
    puts ""
    puts "--> Configured FROM: address: '#{Settings.mail.mailer_sender}'"

    if Settings.mail.smtp_address.nil?
      puts "--> No SMTP address provided. Mail subsystem should default to localhost."
    end

    if Settings.mail.smtp_port.nil?
      puts "--> No SMTP port provided. Mail subsystem should default to 25."
    else
      puts "--> Default port is #{Settings.mail.smtp_port} but will only be used if smtp_address is set."
    end

    if Settings.mail.mailer_sender.nil?
      raise StandardError, "mailer_sender is not set.  This is the required 'from' address when sending email."
    end

    if Settings.mail.smtp_authentication.present?
      puts "--> SMTP authentication is requested & enabled."
      raise StandardError, "No SMTP username provided: smtp_user_name" if Settings.mail.smtp_user_name.nil?
      raise StandardError, "No SMTP password provided: smtp_password" if Settings.mail.smtp_password.nil?
    end

    if Settings.host_domain.nil?
      raise StandardError, "No host domain provided: host_domain. This is required to create fully qualified URLs in emails."
    end

    if Settings.host_protocol.nil?
      raise StandardError, "No host domain protocol provided: host_protocol.  This is required to create fully qualified URLs in emails."
    end

    puts ""
    puts "The settings.yml mail configuration is:"
    puts "----------"
    Settings.mail.each do |key, value|
      if key.to_s.include?("password")
        puts "#{key}: [HIDDEN]"
      else
        puts "#{key}: #{value}"
      end
    end
    puts "----------"
    puts ""

    puts "The Mail subsystem SMTP configuration is:"
    puts "----------"
    Rails.application.config.action_mailer.smtp_settings.each do |key, value|
      if key.to_s.include?("password")
        puts "#{key}: [HIDDEN]"
      else
        puts "#{key}: #{value}"
      end
    end
    puts "----------"
    puts ""

    if Settings.mail.raise_delivery_errors
      puts "--> raise_delivery_errors is set to true in the configuration.  This will raise an error if the email fails to send."
    else
      puts "--> raise_delivery_errors is set to false.  Set to true to see errors if the email fails to send."
    end

    puts ""
    puts "--> Attempting to send a test email to #{email}..."
    mail(to: email,
      subject: "Test Email from Password Pusher",
      body: "⭐  If you are reading this, sending email works! ⭐ ")

    puts "--> ✅   It seems that the Email was accepted by the SMTP server!  Check destination inbox for the test email."
    puts ""

    puts "--> If you see an error, please paste this output into a GitHub issue for help."
    puts "  --> Make sure that no sensitive data is included."
    puts "  --> https://github.com/pglombardo/PasswordPusher/issues/new/choose"

    puts ""
  end
end
