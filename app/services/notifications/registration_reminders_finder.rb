module Notifications
  # Wyszukuje próbki kwalifikujące się do powtórnego przypomnienia o rejestracji
  # (zdarzenie D): dostarczone do laboratorium (AcceptanceDate ustawione), wciąż
  # niezarejestrowane (pacjent wirtualny), należące do instytucji Toxo, dla których
  # minęło co najmniej 7 dni roboczych od AcceptanceDate i którym nie wysłano
  # jeszcze przypomnienia powtórnego.
  #
  # Przynależność do Toxo ustalamy przez kod -> ReservedSampleCode -> InstitutionId
  # (NIE przez ContractorId pacjenta wirtualnego).
  class RegistrationRemindersFinder
    WORKING_DAYS = 7
    NOTE_KEY = "registration-reminder-final-email".freeze

    def self.call
      new.call
    end

    def call
      return Sample.none if V1::Common::TOXO_INSTITUTION_IDS.empty?

      toxo_codes = ReservedSampleCode
                   .where(InstitutionId: V1::Common::TOXO_INSTITUTION_IDS)
                   .select(:Code)

      already_reminded = Note
                         .where(key: NOTE_KEY, subject_type: "Sample")
                         .select(:subject_id)

      Sample
        .joins(:patient)
        .where(Patients: { IsVirtual: true })
        .where.not(AcceptanceDate: nil)
        .where(Code: toxo_codes)
        .where.not(Id: already_reminded)
        .select { |sample| deadline_passed?(sample) }
    end

    private

    def deadline_passed?(sample)
      return false if sample.AcceptanceDate.nil?

      deadline = WORKING_DAYS.business_days.after(sample.AcceptanceDate.to_date)
      Date.current >= deadline
    end
  end
end
