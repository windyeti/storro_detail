class VlsController < ApplicationController

  authorize_resource

  def index
    @search = Vl.ransack(params[:q])
    @search.sorts = 'id desc' if @search.sorts.empty?
    @vls = @search.result.paginate(page: params[:page], per_page: 100)
  end

  def show
    @vl = Vl.find(params[:id])
  end

  def import
    Vl.delay.import
    redirect_to vls_path, notice: "Запущен импорт товаров ВЛ поставщика"
  end

  def linking
    Vl.delay.linking
    redirect_to vls_path, notice: "Запущена линкование товаров ВЛ поставщика"
  end

  def syncronaize
    Vl.delay.syncronaize
    redirect_to vls_path, notice: "Запущена синхронизация товаров ВЛ поставщика"
  end

  def import_linking_syncronaize
    Vl.delay.import_linking_syncronaize
    redirect_to vls_path, notice: "Запущен полный цикл обновления товаров ВЛ поставщика"
  end

  def unlinking_to_xls
    Vl.delay.unlinking_to_xls
    redirect_to vls_path, notice: "Запущено создание файла из незалинкованных товаров поставщика"
  end
end
