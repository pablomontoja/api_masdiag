module Notifications
  # Wyszukuje autoryzowane pomiary należące do instytucji Toxo, dla których nie
  # wysłano jeszcze powiadomienia result_available (brak odpowiadającego Note).
  # Bezpiecznik na wypadek pominięcia wywołania POST /masdiag/result_available/:measurement_id
  # przez LabSample — wykorzystywany przez EmailsController#send_all obok
  # ContractorResultsNotifierJob/PatientResultsNotifierJob.
  #
  # Przynależność do Toxo ustalamy przez TemplateResolver (kontraktor pacjenta
  # zarejestrowanego, lub kod -> ReservedSampleCode -> InstitutionId dla próbki
  # niezarejestrowanej) — NIE przez bezpośredni join Contractor/Institution, aby
  # nie pominąć ścieżki dla pacjentów wirtualnych (patrz RegistrationRemindersFinder).
  class UnnotifiedToxoResultsFinder
    NOTE_KEY = "result-available-email".freeze

    def self.call
      new.call
    end

    def call
      already_notified = Note.where(key: NOTE_KEY, subject_type: "Measurement").select(:subject_id)

      Measurement
        .where.not(AuthorizedAt: nil)
        .where("AuthorizedAt >= ?", Notifications::ResultAvailableJob::CUTOFF_DATE)
        .where.not(Id: already_notified)
        .select { |measurement| Notifications::TemplateResolver.family_for(measurement.sample) == :toxo }
    end
  end
end
