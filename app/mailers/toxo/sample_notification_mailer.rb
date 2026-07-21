module Toxo
  # Rodzina szablonów powiadomień Toxo (toxo.masdiag.pl). Sam mailer wyłącznie
  # komponuje wiadomość — idempotencja, wybór odbiorcy i audyt są realizowane
  # przez warstwę Notifications:: (EventDispatcher / RecipientResolver / Sender).
  class SampleNotificationMailer < ApplicationMailer
    default template_path: "mailers/#{name.underscore}"

    PORTAL_URL = V1::Common::TOXO_PARTNER_PORTAL_URL

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
    def result_available(sample)
      @sample = sample
      @portal_url = PORTAL_URL
      mail(subject: "Wynik badania")
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
