class VisitorsController < ApplicationController
  def mail_test
    data_email = {
      message: 'Проба письма',
      subject: 'Проба письма',
      body: '<strong>Здесь будет текст</strong>'.html_safe
    }
    NotificationMailer.send_notify(data_email).deliver_later
    redirect_to visitors_path
  end
end
