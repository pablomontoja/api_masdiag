Rails.application.configure do
  config.active_record.yaml_column_permitted_classes ||= [Symbol]
  config.active_record.yaml_column_permitted_classes += [OpenStruct, BigDecimal]
end