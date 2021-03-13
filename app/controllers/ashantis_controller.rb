class AshantisController < ApplicationController

  authorize_resource

  def index
    @search = Ashanti.ransack(params[:q])
    @search.sorts = 'id desc' if @search.sorts.empty?
    @ashantis = @search.result.paginate(page: params[:page], per_page: 100)
    # if params['otchet_type'] == 'selected'
    #   Product.csv_param_selected( params['selected_products'], params['otchet_type'])
    #   new_file = "#{Rails.public_path}"+'/ins_detail_selected.csv'
    #   send_file new_file, :disposition => 'attachment'
    # end
  end

  def show
    @ashanti = Ashanti.find(params[:id])
  end

  def import
    Ashanti.delay.import
    redirect_to ashantis_path, notice: "Запущен импорт товаров Ashanti поставщика"
  end

  def linking
    Ashanti.delay.linking
    redirect_to ashantis_path, notice: "Запущена линкование товаров Ashanti поставщика"
  end

  def syncronaize
    Ashanti.delay.syncronaize
    redirect_to ashantis_path, notice: "Запущена синхронизация товаров Ashanti поставщика"
  end

  def import_linking_syncronaize
    Ashanti.delay.import_linking_syncronaize
    redirect_to ashantis_path, notice: "Запущен полный цикл обновления товаров Ashanti поставщика"
  end

  def unlinking_to_xls
    Ashanti.delay.unlinking_to_xls
    redirect_to ashantis_path, notice: "Запущено создание файла из незалинкованных товаров поставщика"
  end

end
