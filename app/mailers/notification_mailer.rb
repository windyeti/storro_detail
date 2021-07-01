class NotificationMailer < ApplicationMailer
  def send_notify(data)
    @message = data[:message]
    @subject = data[:subject]
    mail(to: "Aichurkin@storro.ru", subject: @subject, bcc: ["yegor.tikhanin@gmail.com"])
  end
end
