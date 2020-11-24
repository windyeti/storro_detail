class ProductMailer < ApplicationMailer

  layout 'product_mailer'

  	def downloadproduct_product(productbefore, productafter)
  		@productbefore = productbefore
  		@productafter = productafter
  		@app_name = 'Detail - управление товарами'

  		mail to: 'panaet80@gmail.com',
  		     subject: "Робот Detail - загрузка и обновление товаров",
  		     from: "robot@gmail.com",
  		     reply_to: "robot@gmail.com"
  	end


end
