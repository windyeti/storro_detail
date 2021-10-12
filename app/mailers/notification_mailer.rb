class NotificationMailer < ApplicationMailer
  default from: 'support@storro.ru'
  layout 'mailer'

  def send_notify(data)
    @message = data[:message]
    @subject = data[:subject]
    @body = data[:body]

    mail(to: "Aichurkin@storro.ru", subject: @subject, bcc: ["yegor.tikhanin@gmail.com"])
  end
end
