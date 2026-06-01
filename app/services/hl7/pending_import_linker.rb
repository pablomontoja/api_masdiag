module Hl7
  class PendingImportLinker
    def link_pending_imports
      linked  = 0
      waiting = 0
      errors  = []

      Hl7Import.where(status: :awaiting_registration).find_each do |hl7_import|
        project_id = Hl7::Config::TEST_MAPPING[hl7_import.hl7_test_code]

        unless project_id
          hl7_import.mark_registration_error!("Unknown test code: #{hl7_import.hl7_test_code}")
          errors << "#{hl7_import.id}: unknown test code #{hl7_import.hl7_test_code}"
          next
        end

        sample      = Sample.find_by(Code: hl7_import.kit_code_extracted)
        measurement = sample&.measurements&.find_by(ProjectId: project_id)

        if measurement
          hl7_import.update!(measurement_id: measurement.id, status: :pending)
          Hl7::MeasurementImportJob.perform_later(hl7_import.id)
          linked += 1
        else
          waiting += 1
        end
      rescue StandardError => e
        errors << "#{hl7_import.id}: #{e.message}"
      end

      { linked: linked, waiting: waiting, errors: errors }
    end
  end
end
