class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    if params[:q].present?
      new_q = {}
      params[:q].each do |k,v|
        if k == 'quantity_in'
          # 			    puts v
          if v == "0"
            value = v
          else
            value = Array(1..200)
          end
            new_q[k] = value
        else
        new_q[k] = v
        end
      end
      # puts new_q
    end

    @search = Product.ransack(new_q)
    @search.sorts = 'id desc' if @search.sorts.empty?
    @products = @search.result.paginate(page: params[:page], per_page: 10)

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
    respond_to do |format|
      if @product.update(product_params)
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

  def get_file
    if Rails.env.development?
      Product.get_file
    else
      Product.delay.get_file
    end
    flash[:notice] = 'Задача обновления остатков запущена'
    redirect_to products_path
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
					if value.to_i == 1
					product_id = pr.id
					#puts product_id
					Product.productimage(product_id)
					end
				end
				if key.to_s != 'picture'
					if !value.blank?
					pr.update_attributes(key => value)
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:product).permit(:page, :per_page, :sku, :skubrand, :barcode, :brand, :title, :sdesc, :desc, :cat, :catins, :costprice, :price, :quantity, :image, :weight, :url)
    end
end
