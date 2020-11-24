class ProductMailer < ApplicationMailer

  layout 'product_mailer'

  	def downloadproduct_product(productbefore, productafter)
  		@productbefore = productbefore
  		@productafter = productafter
  		@app_name = 'Detail - управление товарами'

  		mail to: 'panaet80@gmail.com, info@two-g.ru',
  		     subject: "Робот Detail - загрузка и обновление товаров",
  		     from: "robot@gmail.com",
  		     reply_to: "robot@gmail.com"
  	end

    def ins_file(file)
  		@file = file
  		@app_name = 'Detail - управление товарами'

  		mail to: 'panaet80@gmail.com, info@two-g.ru',
  		     subject: "Робот Detail - файл создан",
  		     from: "robot@gmail.com",
  		     reply_to: "robot@gmail.com"
  	end

end
