class MbsController < ApplicationController

  # authorize_resource

  def index
    @search = Mb.ransack(params[:q])
    @search.sorts = 'id desc' if @search.sorts.empty?
    @mbs = @search.result.paginate(page: params[:page], per_page: 100)
    # if params['otchet_type'] == 'selected'
    #   Product.csv_param_selected( params['selected_products'], params['otchet_type'])
    #   new_file = "#{Rails.public_path}"+'/ins_detail_selected.csv'
    #   send_file new_file, :disposition => 'attachment'
    # end
  end

  def show
    @mb = Mb.find(params[:id])
  end

  def import
    Mb.delay.import
    redirect_to mbs_path, notice: "Запущен импорт товаров МБ поставщика"
  end

  def linking
    Mb.delay.linking
    redirect_to mbs_path, notice: "Запущена линкование товаров МБ поставщика"
  end

  def syncronaize
    Mb.delay.syncronaize
    redirect_to mbs_path, notice: "Запущена синхронизация товаров МБ поставщика"
  end

  def import_linking_syncronaize
    Mb.delay.import_linking_syncronaize
    redirect_to mbs_path, notice: "Запущен полный цикл обновления товаров МБ поставщика"
  end

  def unlinking_to_csv
    Mb.delay.unlinking_to_csv
    redirect_to mbs_path, notice: "Запущено создание файла из незалинкованных товаров поставщика"
  end
end
