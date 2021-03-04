class HardJob < ApplicationJob
  queue_as :default

  def perform
    Product.update_price_quantity_all_providers

    ActionCable.server.broadcast 'finish_process', {process_name: "Обновление Цен и Остатков Товаров"}
  end
end
