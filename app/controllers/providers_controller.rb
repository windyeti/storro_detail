class ProvidersController < ApplicationController
  before_action :load_provider, only: [:show, :edit, :update, :destroy, :import, :syncronaize]

  authorize_resource

  def index
    @providers = Provider.all
  end

  def new
    @provider = Provider.new
  end

  def create
    @provider = Provider.new(params_provider)
    if @provider.save
      redirect_to providers_path, notice: "Поставщик создан"
    else
      flash.now[:alert] = "Поставщик не создан"
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @provider.update(params_provider)
      redirect_to @provider, notice: "Поставщик изменен"
    else
      flash.now[:alert] = "Поставщик не изменен"
      render :edit
    end
  end

  def destroy
    @provider.destroy
    redirect_to providers_path
  end


  private

  def load_provider
    @provider = Provider.find(params[:id])
  end

  def params_provider
    params.require(:provider).permit(:name, :prefix, :link, :permalink)
  end
end
