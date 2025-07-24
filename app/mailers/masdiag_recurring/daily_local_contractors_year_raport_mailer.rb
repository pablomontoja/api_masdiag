module MasdiagRecurring
  class DailyLocalContractorsYearRaportMailer < ApplicationMailer
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail
      inst_ids = [32, 2, 30, 24]
      @foreign_ids = [1, 27, 53, 85, 83, 78, 73, 71, 60]

      package = Axlsx::Package.new
      wb = package.workbook

      all_insts(wb)

      inst_ids.each do |inst_id|
        worksheet(wb, inst_id)
      end

      # path = 'tmp/krajowiklienci.xlsx'
      # package.serialize(path)
    	# attachments["klienci-krajowi-#{Date.today}.xlsx"] = File.read(path)

      stream = package.to_stream
      attachments["klienci-krajowi-#{Date.today}.xlsx"] = stream.read

      mail(to: 'dariusz.kolodynski@masdiag.pl', subject: 'Klienci krajowy - raport z przyjęcia próbek')
    end


    private

      def all_insts(wb)
        wb.add_worksheet(name: "wszyscy") do |sheet|
          sheet.add_row ["dzień", "przyjęte", "odrzucone", "niezarejestrowane na moment przyjęcia"]

          samples_accepted = Sample.includes(patient: :contractor).where(AcceptanceDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).where.not(patient: {Contractors: {institution_id: @foreign_ids}}).group_by_day(:AcceptanceDate).count
          samples_cancelled = Sample.includes(patient: :contractor).where(CancellationDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).where.not(patient: {Contractors: {institution_id: @foreign_ids}}).group_by_day(:AcceptanceDate).count
          samples_nonregistered = Sample.includes(patient: :contractor).where(AcceptanceDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).where("Samples.RegistrationDate > AcceptanceDate").where.not(patient: {Contractors: {institution_id: @foreign_ids}}).group_by_day(:AcceptanceDate).count

          (1.year.ago.to_date..DateTime.now.to_date).each do |day|        
            accepted = samples_accepted[day].nil? ? 0 : samples_accepted[day]
            cancelled = samples_cancelled[day].nil? ? 0 : samples_cancelled[day]
            nonregistered = samples_nonregistered[day].nil? ? 0 : samples_nonregistered[day]

            sheet.add_row [day, accepted, cancelled, nonregistered]
          end
        end
      end

      def worksheet(wb, inst_id)
        inst = Institution.find(inst_id)

        wb.add_worksheet(name: inst.name[0..24]) do |sheet|
          sheet.add_row ["dzień", "przyjęte", "odrzucone", "niezarejestrowane na moment przyjęcia"]

          # PlonPharm trzeba szukać inaczej
          if inst_id == 54
            # codes = ReservedSampleCode.where(InstitutionId: 54).pluck(:Code)
            # samples_accepted = Sample.includes(patient: :contractor).where(Code: codes).where(AcceptanceDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).group_by_day(:AcceptanceDate).count
            # samples_cancelled = Sample.includes(patient: :contractor).where(Code: codes).where(CancellationDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).group_by_day(:AcceptanceDate).count
            # samples_nonregistered = Sample.includes(patient: :contractor).where(Code: codes).where(AcceptanceDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).where("Samples.RegistrationDate > AcceptanceDate").group_by_day(:AcceptanceDate).count
          else
            samples_accepted = Sample.includes(patient: :contractor).where(AcceptanceDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).where(patient: {Contractors: {institution_id: inst_id}}).group_by_day(:AcceptanceDate).count
            samples_cancelled = Sample.includes(patient: :contractor).where(CancellationDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).where(patient: {Contractors: {institution_id: inst_id}}).group_by_day(:AcceptanceDate).count
            samples_nonregistered = Sample.includes(patient: :contractor).where(patient: {Contractors: {institution_id: inst_id}}).where(AcceptanceDate: 1.year.ago.at_beginning_of_day..Date.today.at_end_of_day).where("Samples.RegistrationDate > AcceptanceDate").group_by_day(:AcceptanceDate).count
          end     

          (1.year.ago.to_date..DateTime.now.to_date).each do |day|        
            accepted = samples_accepted[day].nil? ? 0 : samples_accepted[day]
            cancelled = samples_cancelled[day].nil? ? 0 : samples_cancelled[day]
            nonregistered = samples_nonregistered[day].nil? ? 0 : samples_nonregistered[day]

            sheet.add_row [day, accepted, cancelled, nonregistered]
          end
        end
      end


  end
end