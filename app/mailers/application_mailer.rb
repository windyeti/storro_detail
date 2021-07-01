class ApplicationMailer < ActionMailer::Base
  default from: 'no-replay@integration.com'
  layout 'mailer'
end
