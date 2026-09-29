# Phase 0 Research: Measurement-Scoped Result-Available Notifications

All decisions below were resolved during an earlier plan-mode design session
(Explore + Plan agent pass, with explicit user sign-off on the two open
questions) before this spec-kit workflow was seeded. No NEEDS CLARIFICATION
markers remain in the Technical Context — this document records the
already-made decisions in the standard research format for auditability.

## 1. How should `EventDispatcher` accept a per-measurement event alongside five Sample-scoped events?

**Decision**: Add an optional `measurement:` keyword to `EventDispatcher.call`
alongside the existing `sample:` keyword. `@sample` is derived internally as
`measurement&.sample || sample`. Only `:result_available` requires
`measurement:`; the other five events continue to require `sample:` exactly as
today.

**Rationale**: `TemplateResolver` and `RecipientResolver` already operate
purely on `Sample` — deriving `@sample` from `measurement.sample` means zero
changes to either collaborator. The other five events documented in the spec
(`sample_accepted`, `sample_rejected`, `sample_registration_confirmation`,
`registration_reminder`, `registration_reminder_final`) are genuine
Sample-level lifecycle events with no per-measurement concern — the constitution
(Principle VI, "MUST NOT abstract when... used only once") argues directly
against building a generic polymorphic `subject:` parameter for a concern that
has exactly one consumer today.

**Alternatives considered**:
- **Generic polymorphic `subject:` parameter** across all six events — rejected
  as speculative abstraction with no second consumer; makes every call site
  guess which subject type is legal for which event.
- **Separate dispatcher class for measurement-level events** — rejected as
  unnecessary duplication of `TemplateResolver`/`RecipientResolver` wiring for
  a single event.

## 2. How should `Note`/`Sender` idempotency track per-measurement state?

**Decision**: Add `"result-available-email"` to `Note::KEYS_BY_SUBJECT["Measurement"]`
(already a supported subject type for six other keys — no schema change).
Generalize `Notifications::Sender` to accept `measurement:` alongside `sample:`,
using whichever is present as the idempotency `@subject` for `Note.exists?`/`Note.create!`.

**Rationale**: `Note`'s polymorphic `belongs_to :subject` and its
`uniqueness: { scope: [:subject_type, :key] }` validation already work
unmodified for `subject_type: "Measurement"` — this is a pure data change to an
existing mechanism, not new infrastructure. `record_audit`'s
`event.measurement = nil` line was already present but unused for the Toxo
path — this finally activates that existing-but-dormant slot on
`ResultSendingEvent`, matching what the `:lab` family's own
`ContractorResultNotificationMailer#set_sendmail` already does per-file.

**Alternatives considered**:
- **New dedicated table for measurement-level notification tracking** —
  rejected; `Note` already generically supports this via its polymorphic
  design, so a new table would duplicate existing infrastructure.
- **Compute idempotency by inspecting `OnlineFile.is_notification_send`
  instead of `Note`** — rejected; that flag belongs to the separate, older
  `:lab`-family mechanism (see decision 5) and conflating the two idempotency
  mechanisms would blur a boundary the codebase already keeps clean.

## 3. Should the Toxo email narrow to only newly-authorized measurements, or keep showing the full table every time?

**Decision**: Keep rendering the full `sample.measurements` table on every
send (no mailer/view restructuring), and add one short sentence identifying
which specific measurement triggered this particular email.

**Rationale (user-confirmed)**: A "diff since last send" view would require
querying sibling `Note`s to compute "newly authorized since last email,"
introducing a new query, new edge cases (a sibling authorized-but-not-yet-
dispatched race), and a second source of truth that can drift from `Note`
itself. The full-table approach requires none of this — it is the existing,
already-tested mailer behavior, unchanged. The accepted tradeoff: a
multi-measurement sample may generate several emails over time, each showing
an overlapping/growing table — judged acceptable because it's a strict
improvement over the current bug (one email, permanently stale) and batching/
debounce strategies are explicitly out of scope as a separate, deliberately-
scoped concern if inbox noise becomes a real complaint.

**Alternatives considered**:
- **Diff-since-last-send table** — rejected per above; materially more complex
  for marginal UX benefit, and the constitution's simplicity bias
  ("Premature Abstraction... Keep inline until threshold crossed") favors the
  simpler mechanism.
- **Debounced/batched single email per sample** — rejected as out of scope;
  would require a new "expected measurement count" or scheduling/coalescing
  concept that doesn't exist anywhere in this domain today. Flagged as a
  possible future follow-up, not built speculatively now.

## 4. Should the CUTOFF_DATE eligibility gate change semantics?

**Decision**: No semantic change. `Notifications::ResultAvailableJob::CUTOFF_DATE`
stays a plain Ruby constant; `#eligible?` now checks the single measurement's
own `AuthorizedAt` against it, replacing the prior
`sample.measurements.where("AuthorizedAt >= ?", CUTOFF_DATE).exists?` check.

**Rationale**: This is a strictly more precise translation of the existing
sample-level check down to the single-record case being dispatched — a
measurement authorized before `CUTOFF_DATE` still never dispatches; one
authorized on/after it always does (subject to `Sender`/`Note` idempotency).
No bypass of the cutoff is introduced.

**Alternatives considered**: None — this follows directly from the
Measurement-scoping decision and required no independent evaluation.

## 5. Does the legacy `:lab`-family dispatch path need to change?

**Decision**: Yes — `EventDispatcher#lab_result_file_ids` is scoped to
`OnlineFile.where(is_notification_send: false)` (previously: all files for the
sample), and `dispatch_lab`'s `:result_available` branch skips entirely
(returns `Sender::Result.new(status: :skipped)`) when that scoped list is
empty, instead of unconditionally calling
`ContractorResultNotificationMailer.send_mail`.

**Rationale**: The `:lab` family's own idempotency is per-`OnlineFile` via the
`is_notification_send` flag, set inside `ContractorResultNotificationMailer#set_sendmail`'s
`@files.each` loop — but `set_sendmail` unconditionally resends/re-audits every
file it's given, with no internal "already sent" check of its own. This was
safe only because `dispatch_lab` was invoked once per sample historically.
Once the Toxo-motivated redesign makes the trigger fire once per measurement,
`dispatch_lab` would also fire more than once per sample, and would resend
every previously-delivered file each additional time — a genuine regression
for lab-family contractors introduced as a side effect of this change, not a
pre-existing bug being incidentally fixed. This must be fixed in the same
change per the spec's User Story 3 (confirmed by the user as in-scope, not
deferred).

**Alternatives considered**:
- **Leave `dispatch_lab` unguarded, track as a separate ticket** — explicitly
  considered and rejected by the user; the regression is a direct, immediate
  consequence of this change and shipping it unguarded would be a known,
  avoidable defect.
- **Add idempotency to `ContractorResultNotificationMailer#set_sendmail` itself**
  — rejected as broader in scope than necessary; scoping the file list at the
  dispatch call site (before the mailer is even invoked) is the smaller,
  more targeted fix and keeps the mailer's existing behavior/tests intact.
