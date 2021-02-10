class MbsController < ApplicationController
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

  def import
    Mb.import
    redirect_to mbs_path
  end

  def syncronaize
    Mb.syncronaize
    redirect_to mbs_path
  end
end
