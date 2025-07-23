module MasdiagRecurring
  module Daily

    class DelayedSamplesJob < ApplicationJob

      def perform
        result = MasdiagRecurring::DelayedSamplesFinder.call()
        if result.success?
          items = result.payload
          Project.where.not(responsible_person_email: nil).each do |project|
            current_project_items = items.select {|s| s.fetch(:project_id) == project.Id}
            next if current_project_items.length == 0
            MasdiagRecurring::DailyDelayedSamplesMailer.send_mail(current_project_items, project).deliver_later
          end
        end 
      end

    end

  end
end