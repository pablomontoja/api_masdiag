class HospitalContractorAdjustmentsForRegspec < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.transaction do
      contractors = Contractor.includes(:institution).where(institutions: { kind: "Hospital" }).map{ |c| OpenStruct.new(institution_id: c.institution_id, institution_nip: c.institution.nip, id: c.id, first_name: c.first_name, last_name: c.last_name) }

      contractors.each do |c|      
        next if c.id == 623
        contractor = Contractor.find(c.id)
        contractor.last_name = "" if c.institution_id == 88
        contractor.last_name = "" if c.institution_id == 90
        contractor.last_name = "" if c.institution_id == 104
        contractor.last_name = "" if c.institution_id == 116

        contractor.first_name = [contractor.first_name, contractor.last_name].join(" ")
        contractor.last_name = ""

        contractor.first_name = "Oddział Neurologii Dziecięcej" if c.id == 678
        contractor.first_name = "Klinika Obserwacyjno-Zakaźna Dzieci" if c.id == 756

        contractor.save!
      end
    end
  end
end
