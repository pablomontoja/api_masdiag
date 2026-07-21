module Toxo
  # Podglądy powiadomień Toxo (rodzina szablonów :toxo) dostępne pod
  # /rails/mailers/toxo/sample_notification_mailer w środowisku development.
  #
  # Metody mailera przyjmują OBIEKT próbki (nie sample_id), więc każdy podgląd
  # losuje realną próbkę z przepływu Toxo (measurement w projektach 39-42) i
  # ładuje ją jako Toxo::Sample. FactoryBot nie jest dostępny w development —
  # dane pochodzą z realnej bazy, zgodnie z konwencją pozostałych previews.
  class SampleNotificationMailerPreview < ActionMailer::Preview
    def sample_registration_confirmation
      Toxo::SampleNotificationMailer.sample_registration_confirmation(toxo_sample)
    end

    def sample_accepted
      Toxo::SampleNotificationMailer.sample_accepted(toxo_sample)
    end

    def registration_reminder
      Toxo::SampleNotificationMailer.registration_reminder(toxo_sample)
    end

    def registration_reminder_final
      Toxo::SampleNotificationMailer.registration_reminder_final(toxo_sample)
    end

    def sample_rejected
      Toxo::SampleNotificationMailer.sample_rejected(toxo_sample)
    end

    def result_available
      Toxo::SampleNotificationMailer.result_available(toxo_sample)
    end

    private

    # Losuje realną próbkę z przepływu Toxo (measurement w Toxo::Constants::TOXO_PROJECT_IDS)
    # i ładuje ją jako Toxo::Sample (enum execution_mode → "CITO"/"Standard" oraz measurements).
    def toxo_sample
      sample_id = Measurement.where(ProjectId: Toxo::Constants::TOXO_PROJECT_IDS)
                             .order(Id: :desc).limit(100).pluck(:SampleId).sample
      Toxo::Sample.find(sample_id)
    end
  end
end
