class ProviderExistValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, id)
    record.errors.add attribute, "#{id} does not exist" unless provider_valid?(id)
  end

  private

  def provider_valid?(id)
    Provider.exists? id
  end

end
