module Notifications
  # Wysyła pojedyncze powiadomienie w sposób idempotentny:
  #  1. pomija, gdy brak odbiorcy,
  #  2. pomija, gdy Note dla (Sample, event-key) już istnieje (już wysłano),
  #  3. dostarcza wiadomość,
  #  4. zapisuje audyt (ResultSendingEvent / Fileable / DbFile),
  #  5. tworzy Note znakujący wysyłkę.
  #
  # Klucz Note odpowiada zdarzeniu (jednakowy dla obu rodzin szablonów), więc
  # próbka otrzymuje najwyżej jeden e-mail danego typu niezależnie od szablonu.
  class Sender
    # event => klucz Note (patrz Note#available_keys)
    EVENT_KEYS = {
      sample_registration_confirmation: "sample-registration-confirmation-email",
      sample_accepted:             "sample-accepted-email",
      registration_reminder:       "registration-reminder-email",
      registration_reminder_final: "registration-reminder-final-email",
      sample_rejected:             "sample-rejected-email",
      result_available:            "result-available-email"
    }.freeze

    Result = Struct.new(:status, keyword_init: true) do
      def sent?    = status == :sent
      def skipped? = status == :skipped
    end

    def self.call(sample:, event:, mail:, recipient:, family:)
      new(sample: sample, event: event, mail: mail, recipient: recipient, family: family).call
    end

    def initialize(sample:, event:, mail:, recipient:, family:)
      @sample    = sample
      @event     = event.to_sym
      @mail      = mail
      @recipient = recipient
      @family    = family
    end

    def call
      return skip if @recipient.blank?
      return skip if already_sent?

      @mail.to = @recipient
      @mail.deliver_now

      record_audit
      mark_note

      Result.new(status: :sent)
    rescue ActiveRecord::RecordNotUnique
      # Wyścig: inny proces wysłał to samo powiadomienie — traktujemy jako pominięte.
      skip
    end

    private

    def note_key
      EVENT_KEYS.fetch(@event)
    end

    def already_sent?
      Note.exists?(subject_type: "Sample", subject_id: @sample.Id, key: note_key)
    end

    def mark_note
      Note.create!(
        key: note_key,
        subject: @sample,
        description: "[#{@family}] powiadomienie #{@event} — #{Date.current.strftime('%F')}"
      )
    end

    def record_audit
      f = Fileable.new
      event = f.build_result_sending_event
      event.measurement = nil
      event.sample = @sample
      event.sent_date = Time.current
      event.sent_through = 1 # EmailNotification
      event.recipient = @recipient
      event.address = @recipient

      html = @mail.html_part&.body&.decoded || @mail.body.decoded
      dbfile = f.db_files.build
      dbfile.file_content = html
      dbfile.file_type = "text/html"
      dbfile.file_length = dbfile.file_content.bytesize
      f.save!
    end

    def skip
      Result.new(status: :skipped)
    end
  end
end
