class ProductProviderExistValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, id)
    record.errors.add attribute, "#{id} does not exist" unless product_provider_exist?(record, id)
  end

  private

  def product_provider_exist?(record, id)
    id_provider = record.provider
    provider = Provider.find(id_provider)
    provider.permalink.constantize.find(id) rescue false
  end
end
