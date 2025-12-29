module MasdiagRecurring
  module Daily

    class HospitalsSamplesZipperJob < ApplicationJob

      def perform
        settled_before = []
        settled_before = Note.where(key: "included-in-daily-hospital-zip-archive", subject_type: "Measurement").pluck(:subject_id)
        date_start = (Time.now - 1.month).at_beginning_of_day
        date_end = (Time.now - 1.day).at_end_of_day
        last_day_authorized = []

        # CENTRUM ZDROWIA BIOMED - institution_id: 115
        # HolisticaMed Aleksandra Ściebur - institution_id: 87
        # metanefryny.bielanski@gmail.com - ContractorId: 623
        contractor_ids = Contractor.includes(:institution).where(institutions: { kind: "Hospital" }).where.not(institution_id: [87, 115]).where.not(Id: 623).pluck(:Id)

        last_day_authorized << Measurement.includes(sample: {patient: :contractor})
                                          .where(Status: 5, AuthorizedAt: date_start..date_end)
                                          .where.not(Id: settled_before)
                                          .where(sample: { patient: { Contractors: {Id: contractor_ids } } })
                                          .group_by{|m| m.sample.patient.contractor.institution_id}

        last_day_authorized.first.each do |inst_id, measurements|
          MasdiagRecurring::DailyHospitalSamplesZipperMailer.send_mail(measurements.pluck(:Id), inst_id).deliver_later
        end
      end
    	
    end

  end
end