module Toxo
  # Rodzina szablonów powiadomień Toxo (toxo.masdiag.pl). Sam mailer wyłącznie
  # komponuje wiadomość — idempotencja, wybór odbiorcy i audyt są realizowane
  # przez warstwę Notifications:: (EventDispatcher / RecipientResolver / Sender).
  class SampleNotificationMailer < ApplicationMailer
    default template_path: "mailers/#{name.underscore}"

    PORTAL_URL = V1::Common::TOXO_PARTNER_PORTAL_URL

    # Etykiety statusu pomiaru — zsynchronizowane ze słownikiem toxo (Measurement::STATUS
    # w ../toxo/app/models/measurement.rb i enums.measurement_status w jego config/locales/pl.yml).
    MEASUREMENT_STATUS_LABELS = {
      1 => "w laboratorium",
      2 => "w laboratorium",
      3 => "potrzebna powtórka",
      4 => "kompletowanie wyniku",
      5 => "autoryzowany wynik",
      6 => "nieudany pomiar",
      7 => "dodana online"
    }.freeze

    # A — Potwierdzenie zlecenia badania (+ załącznik PDF).
    def sample_registration_confirmation(sample)
      @sample = sample
      attachments["potwierdzenie_zlecenia.pdf"] = Toxo::OrderConfirmationPdf.new(sample.Id).render
      mail(subject: "Potwierdzenie zlecenia badania")
    end

    # B — Potwierdzenie przyjęcia próbki do badań.
    def sample_accepted(sample)
      @sample = sample
      mail(subject: "Potwierdzenie przyjęcia próbki do badań")
    end

    # C — Przypomnienie o konieczności rejestracji próbki.
    def registration_reminder(sample)
      @sample = sample
      @portal_url = PORTAL_URL
      mail(subject: "Przypomnienie o konieczności rejestracji próbki")
    end

    # D — Przypomnienie powtórne o konieczności rejestracji próbki.
    def registration_reminder_final(sample)
      @sample = sample
      @portal_url = PORTAL_URL
      mail(subject: "Przypomnienie powtórne o konieczności rejestracji próbki")
    end

    # E — Odrzucenie próbki zleconej do badań.
    def sample_rejected(sample)
      @sample = sample
      @sample_code            = sample.Code
      @sample_number          = sample.Lot
      @client_internal_number = sample.try(:Level)
      @material_type          = MaterialTypes::HASH[sample.MaterialType.to_sym]
      @ordered_tests          = ordered_tests_for(sample)
      @mode                   = execution_mode_label(sample)
      mail(subject: "Odrzucenie próbki zleconej do badań")
    end

    # F — Wynik badania.
    #
    # TODO: brak jeszcze i18n dla tego mailera — wymuszamy polski (Contractor#locale
    # nie jest jeszcze uwzględniany), zamiast pozostawić domyślny :en, który psuł
    # nazwy badań (Project#Name, tłumaczone przez Mobility w zależności od I18n.locale).
    def result_available(sample, measurement)
      I18n.with_locale(:pl) do
        @sample = sample
        @portal_url = PORTAL_URL
        @measurements = sample.measurements
        @triggering_measurement = measurement
        mail(subject: "Wynik badania")
      end
    end

    # G — Prośba o chromatogram.
    def chromatogram_request(measurement, contractor)
      @measurement      = measurement
      @contractor_email = contractor.email
      @sample_code      = measurement.sample.Code
      @test_name        = Toxo::Constants::PROJECT_NAMES[measurement.ProjectId] || measurement.ProjectId
      mail(to: "toxo@masdiag.pl", subject: "Prośba o chromatogram")
    end

    # H — Zgłoszenie badania na zlecenie.
    def on_request_measurement(measurement, contractor)
      @institution_name = contractor.institution.name
      @measurement      = measurement
      @contractor_email = contractor.email
      @sample_code      = measurement.sample.Code
      @note             = measurement.sample.Comment
      mail(to: "toxo@masdiag.pl", subject: "Zgłoszono badanie na zlecenie")
    end

    private

    def ordered_tests_for(sample)
      return [] unless sample.respond_to?(:measurements)

      sample.measurements.map do |m|
        Toxo::Constants::PROJECT_NAMES[m.ProjectId] || m.ProjectId
      end
    end

    def execution_mode_label(sample)
      return nil unless sample.respond_to?(:execution_mode)

      sample.execution_mode == "expedited" ? "CITO" : "Standard"
    end
  end
end
