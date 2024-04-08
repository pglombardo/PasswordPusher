class TestMailer < ApplicationMailer
  def send_test_email(email)
    mail(to: email,
      subject: "Test Email from Password Pusher",
      body: "⭐ If you are reading this, sending email works! ⭐")
  end
end
