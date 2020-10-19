class PropertiesController < ApplicationController
  before_action :set_property, only: [:show, :edit, :update, :destroy]

  # GET /properties
  # GET /properties.json
  def index
    @search = Property.ransack(:q)
    @search.sorts = 'id desc' if @search.sorts.empty?
    @properties = @search.result.paginate(page: params[:page], per_page: 50)
  end

  # GET /properties/1
  # GET /properties/1.json
  def show
  end

  # GET /properties/new
  def new
    @property = Property.new
  end

  # GET /properties/1/edit
  def edit
  end

  # POST /properties
  # POST /properties.json
  def create
    @property = Property.new(property_params)

    respond_to do |format|
      if @property.save
        format.html { redirect_to @property, notice: 'Property was successfully created.' }
        format.json { render :show, status: :created, location: @property }
      else
        format.html { render :new }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /properties/1
  # PATCH/PUT /properties/1.json
  def update
    respond_to do |format|
      if @property.update(property_params)
        format.html { redirect_to @property, notice: 'Property was successfully updated.' }
        format.json { render :show, status: :ok, location: @property }
      else
        format.html { render :edit }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  def set_all
    characts = Product.all.pluck(:charact)
    puts characts
    properties_array = []
    characts.each do |char|
      if char != nil
        char.split('---').each do |pa|
          properties_array << pa.split(':')[0].strip if pa != nil
        end
      end
    end
    properties_array.uniq.each do |pra|
      Property.create(title: pra, status: false)
    end
    flash[:notice] = 'Данные обновлены'
    redirect_to :back
  end

  def edit_multiple
    puts params[:property_ids].present?
    if params[:property_ids].present?
      @properties = Property.find(params[:property_ids])
      respond_to do |format|
        format.js
      end
    else
      redirect_to properties_url
    end
  end

  def update_multiple
    @properties = Property.find(params[:properties_ids])
    @properties.each do |pr|
      attr = params[:property_attr]
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
    @properties = Property.find(params[:ids])
		@properties.each do |property|
		    property.destroy
		end
		respond_to do |format|
		  format.html { redirect_to properties_url, notice: 'Параметры удалёны' }
		  format.json { render json: {:status => "ok", :message => "Параметры удалёны"} }
		end
  end


  # DELETE /properties/1
  # DELETE /properties/1.json
  def destroy
    @property.destroy
    respond_to do |format|
      format.html { redirect_to properties_url, notice: 'Property was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_property
      @property = Property.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def property_params
      params.require(:property).permit(:status, :title)
    end
end
