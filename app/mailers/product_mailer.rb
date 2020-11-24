class ProductMailer < ApplicationMailer

  layout 'product_mailer'
  default from: 'ad2020k@yandex.ru'
  default reply_to: 'ad2020k@yandex.ru'

  	def downloadproduct_product(productbefore, productafter)
  		@productbefore = productbefore
  		@productafter = productafter
  		@app_name = 'Detail - управление товарами'

  		mail to: 'panaet80@gmail.com',
  		     subject: "Робот Detail - загрузка и обновление товаров"
  	end

    def ins_file(file)
  		@file = file
  		@app_name = 'Detail - управление товарами'

  		mail to: 'panaet80@gmail.com',
  		     subject: "Робот Detail - файл создан"
  	end

end
