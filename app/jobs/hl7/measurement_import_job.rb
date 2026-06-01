module Hl7
  class MeasurementImportJob < ApplicationJob
    queue_as :default

    def perform(hl7_import_id)
      hl7_import = Hl7Import.find(hl7_import_id)
      Hl7::MeasurementImporter.new(hl7_import).import
    end
  end
end
