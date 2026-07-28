module Notifications
  # Wyznacza adres e-mail odbiorcy powiadomienia. Zwraca nil, gdy powiadomienia
  # nie da się (lub nie należy) wysłać — wywołujący pomija wysyłkę bez błędu.
  #
  # Zdarzenia rejestracyjne (przypomnienia) kierujemy na adres instytucji
  # (email_for_notifications) wyznaczony przez kod -> RSC -> Institution.
  # Pozostałe zdarzenia kierujemy na adres kontraktora zamawiającego.
  class RecipientResolver
    REMINDER_EVENTS = %i[registration_reminder registration_reminder_final].freeze

    # Flagi per-zdarzenie na Contractors pozwalające wyłączyć wybrane
    # powiadomienia adresowane do kontraktora. Zdarzenia bez wpisu w mapie nie są
    # ograniczane dodatkową flagą.
    #
    # Uwaga: nie sprawdzamy tu Contractor#are_notifications_enabled — ta flaga
    # należy do starszego mechanizmu (ContractorResultsNotifierJob /
    # ContractorResultNotificationMailer) i domyślnie jest false (m.in. dla
    # kontraktorów synchronizowanych z regspec), więc użyta tu wyciszałaby
    # powiadomienia Toxo niezamierzenie.
    EVENT_FLAGS = {
      sample_accepted:    :allow_sample_acceptance_notifications,
      sample_rejected:    :allow_sample_rejection_notifications,
      result_available:   :allow_result_notifications,
      sample_registration_confirmation: :allow_sample_registration_notifications
    }.freeze

    def self.call(sample:, event:)
      new(sample: sample, event: event).call
    end

    def initialize(sample:, event:)
      @sample = sample
      @event = event.to_sym
    end

    def call
      REMINDER_EVENTS.include?(@event) ? institution_recipient : contractor_recipient
    end

    private

    def institution_recipient
      institution = TemplateResolver.institution_for(@sample)
      email = institution&.email_for_notifications
      email.presence
    end

    def contractor_recipient
      contractor = @sample.patient&.contractor
      return nil if contractor.nil?
      return nil unless event_allowed?(contractor) # flaga per-zdarzenie

      contractor.email.presence
    end

    def event_allowed?(contractor)
      flag = EVENT_FLAGS[@event]
      flag.nil? || contractor.public_send(flag)
    end
  end
end
