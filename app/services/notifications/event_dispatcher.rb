module Notifications
  # Punkt wejścia warstwy powiadomień. Dla danego (event, sample):
  #  - ustala rodzinę szablonu (:toxo | :lab) po instytucji próbki,
  #  - dla :toxo buduje wiadomość Toxo::SampleNotificationMailer i przekazuje ją
  #    do Sender (idempotencja przez Note + audyt),
  #  - dla :lab deleguje do istniejących mailerów laboratoryjnych, zachowując
  #    ich dotychczasowe zachowanie.
  #
  # LabSample nie decyduje o wyborze szablonu — decyzja zapada tutaj.
  class EventDispatcher
    KNOWN_EVENTS = %i[
      sample_registration_confirmation
      sample_accepted
      registration_reminder
      registration_reminder_final
      sample_rejected
      result_available
    ].freeze

    def self.call(event:, sample: nil, measurement: nil)
      new(event: event, sample: sample, measurement: measurement).call
    end

    def initialize(event:, sample: nil, measurement: nil)
      @event       = event.to_sym
      @measurement = measurement
      @sample      = measurement&.sample || sample
      @sample_arg  = sample
    end

    def call
      raise ArgumentError, "Unknown notification event: #{@event}" unless KNOWN_EVENTS.include?(@event)
      raise ArgumentError, "result_available requires measurement:" if @event == :result_available && @measurement.nil?
      raise ArgumentError, "#{@event} requires sample:" if @event != :result_available && @sample_arg.nil?

      family = TemplateResolver.family_for(@sample)
      family == :toxo ? dispatch_toxo : dispatch_lab
    end

    private

    def dispatch_toxo
      recipient = RecipientResolver.call(sample: @sample, event: @event)
      return Sender::Result.new(status: :skipped) if recipient.blank?

      mail = @event == :result_available ? Toxo::SampleNotificationMailer.result_available(@sample, @measurement) : Toxo::SampleNotificationMailer.public_send(@event, @sample)
      Sender.call(sample: @sample, measurement: @measurement, event: @event, mail: mail, recipient: recipient, family: :toxo)
    end

    # Rodzina laboratoryjna — delegacja do istniejących mailerów. Zdarzenia
    # przypomnień (C/D) nie mają odpowiednika laboratoryjnego, więc dla instytucji
    # nie-Toxo są pomijane (patrz plan.md, Scope guardrail).
    def dispatch_lab
      case @event
      when :result_available
        return Sender::Result.new(status: :skipped) if lab_result_file_ids.empty?

        MasdiagMailer::ContractorResultNotificationMailer
          .send_mail(@sample.patient.ContractorId, lab_result_file_ids)&.deliver_later
      when :sample_accepted
        MasdiagMailer::SendAcceptanceNotificationsJob.perform_later([@sample.Id])
      when :sample_rejected
        MasdiagMailer::SendCancellationNotificationsJob.perform_later([@sample.Id])
      when :sample_registration_confirmation
        return Sender::Result.new(status: :skipped) unless registration_notifications_allowed?

        MasdiagMailer::IndMailer.after_sample_registration(@sample.Id).deliver_later
      when :registration_reminder, :registration_reminder_final
        # brak odpowiednika laboratoryjnego — pomijamy dla instytucji nie-Toxo
        return Sender::Result.new(status: :skipped)
      end

      Sender::Result.new(status: :sent)
    end

    def registration_notifications_allowed?
      contractor = @sample.patient&.contractor
      contractor.present? && contractor.allow_sample_registration_notifications
    end

    def lab_result_file_ids
      OnlineFile.joins(measurement: :sample)
                .where(Samples: { Id: @sample.Id })
                .where(is_notification_send: false)
                .pluck(:measurement_id)
    end
  end
end
