class MasdiagMailDeliveryJob < ActionMailer::MailDeliveryJob
	limits_concurrency to: 1, key: "mailer", group: "masdiag"
end