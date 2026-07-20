# Contract: Order-confirmation trigger (Event A)

Event A (order confirmation) originates when a **registration form is submitted** — this happens in the toxo portal, not in LabSample — so it fires from the portal registrations controller. The same `Notifications::EventDispatcher` then selects the toxo template (the sample's institution is a toxo institution).

**Auth**: Bearer-token via `Session` (`Toxo::BaseController#authenticate_by_token!`) + Pundit (`Toxo::SamplePolicy#create?`).

## Trigger point

`Toxo::Samples::RegistrationsController#create` — after the sample saves successfully and measurements are created, only when `@sample.errors.empty?`:

```ruby
if @sample.errors.empty?
  Notifications::SampleRegistrationConfirmationJob.perform_later(@sample.Id)
  render json: serialize_sample(@sample), status: :created
else
  render json: { errors: ... }, status: :unprocessable_entity
end
```

## Dispatch

`SampleRegistrationConfirmationJob` → `Notifications::EventDispatcher.call(event: :order_confirmation, sample:)`:
- family = toxo (institution ∈ `TOXO_INSTITUTION_IDS`) → `Toxo::SampleNotificationMailer#order_confirmation`; other institutions → existing lab confirmation (`IndMailer`/`ThreeMethylDopaMailer`),
- recipient = ordering party's contractor email (registered path),
- idempotency guard on `order-confirmation-email` Note,
- toxo path attaches `Toxo::OrderConfirmationPdf.new(sample.Id)` as `potwierdzenie_zlecenia.pdf`,
- deliver → audit (`ResultSendingEvent`/`Fileable`) → create Note.

## Guarantees

- Enqueue only on successful create (no email on `422`).
- Portal response unchanged; async, non-blocking (SC-004).
- PDF generation failure is caught in the job, reported (Sentry in production), and never rolls back the completed registration.

## Optional lab-originated confirmations

If a lab-side confirmation trigger is later needed, expose `POST /masdiag/order_confirmation` → same `SampleRegistrationConfirmationJob`; the dispatcher still resolves the family by institution. Not required for the toxo flow (portal hook covers event A).
