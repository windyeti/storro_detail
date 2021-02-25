class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # authorize_resource

  # GET /products
  # GET /products.json
  def index
    @search = Product.ransack(params[:q])
    @search.sorts = 'id desc' if @search.sorts.empty?
    @products = @search.result.paginate(page: params[:page], per_page: 100)
    if params['otchet_type'] == 'selected'
      Product.csv_param_selected( params['selected_products'], params['otchet_type'])
      new_file = "#{Rails.public_path}"+'/ins_detail_selected.csv'
      send_file new_file, :disposition => 'attachment'
    end
  end

  # GET /products/1
  # GET /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update

    provider_klass = @product.provider.permalink.constantize if @product.provider
    id_product_provider = @product.productid_provider if @product.productid_provider

    respond_to do |format|
      if @product.update(product_params)
        # Обнуляем в Товар Постащика --> Товар
        #
        # Поиск Товара Поставщика с котрым связан Товар, чтобы разорвать связь.
        # Новый Товар Поставщика будет связан с Товаром в after_update.
        # Это надо делать внутри update (после прохождения валидаций)
        # так как если валидация не пройдет == новая связь не установлена, а старая
        # связь с Товаром Поставщика будет разорвана (ТоварПоставщика.productid_product == nil)
        if provider_klass
          product_provider = provider_klass.find(id_product_provider) rescue nil
          if product_provider.present?
            product_provider.productid_product = nil
            product_provider.save
          end
        end

        # Устанавливаем в Товар Постащика --> Товар
        if @product.provider.present? && @product.productid_provider.present?
          product_provider = @product.provider.permalink.constantize.find(@product.productid_provider) rescue return
          product_provider.productid_product = @product.id
          product_provider.save
        end

        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def edit_multiple
    puts params[:product_ids].present?
    if params[:product_ids].present?
			@products = Product.find(params[:product_ids])
			respond_to do |format|
			  format.js
			end
		else
			redirect_to products_url
		end
  end

  def update_multiple
    @products = Product.find(params[:product_ids])
		@products.each do |pr|
			attr = params[:product_attr]
			attr.each do |key,value|
				if key.to_s == 'picture'
					# if value.to_i == 1
					# product_id = pr.id
					#puts product_id
					# Product.productimage(product_id)
					# end
				end
				if key.to_s != 'picture'
					if !value.blank?
					pr.update_attributes(key => value)
            if key.to_s == 'pricepr'
              Product.update_pricepr(pr.id)
            end
					end
				end
			end
		end
		flash[:notice] = 'Данные обновлены'
		redirect_to :back
  end

  def delete_selected
    @products = Product.find(params[:ids])
		@products.each do |product|
		    product.destroy
		end
		respond_to do |format|
		  format.html { redirect_to products_url, notice: 'Товары удалёны' }
		  format.json { render json: {:status => "ok", :message => "Товары удалёны"} }
		end
  end

  def update_price_quantity_all_providers
    Product.delay.update_price_quantity_all_providers
    redirect_to products_path, notice: 'Запущена задача обновления Цен и Остатков'
  end

  def import_insales_xml
    Product.delay.import_insales_xml
    flash[:notice] = 'Задача обновления каталога запущена'
    redirect_to products_path
  end

  def import
    # if Rails.env.development?
    #   Product.delay.import_insales(params[:file])
    # else
    #   Product.delay.import_insales(params[:file])
    # end
    path_file = params[:file].path
    extend_file = File.extname(params[:file].original_filename)
    ProductImportJob.perform_later(path_file, extend_file)
    flash[:notice] = 'Задача обновления каталога запущена'
    redirect_to products_path
  end

  # def csv_param
  #   if Rails.env.development?
  #     Product.csv_param
  #   else
  #     Product.delay.csv_param
  #   end
  #   flash[:notice] = "Запустили"
  #   redirect_to products_path
  # end

  def create_csv
    Product.delay.create_csv
    redirect_to products_path, notice: 'Запущен процесс создания файла'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:product).permit(:sku, :title, :desc, :cat, :charact, :charact_gab, :oldprice, :price, :quantity, :image, :url, :provider_price, :provider_id, :product_sku_provider, :productid_provider)
    end
end
