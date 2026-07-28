# Phase 1 — Data Model: Toxo Sample Email Notification System (unified dispatch)

**No new tables or migrations.** Reuses existing MySQL tables and the polymorphic `notes` table. Template family (lab vs. toxo) is chosen at runtime from the sample's institution; the data model is identical for both families.

---

## Entities (existing — read)

### Sample (`Samples`)
| Field | Use |
|-------|-----|
| `Id` | Note subject id; job argument |
| `Code` | sample code (event E; RSC → institution lookup for reminders C/D and for template-family resolution) |
| `AcceptanceDate` | delivery timestamp; start of the 7-business-day count (D); "delivered" = present |
| `RegistrationDate` | order confirmation reference (A) |
| `IsWrongRegistration` | part of the "not yet registered" set |
| `MaterialType` (enum) | rejection detail (E) |
| `execution_mode` (enum standard/expedited) | mode CITO/Standard (E) |
| `Comment`/`Lot`/`Level` | order-confirmation PDF content (A) |
| `PatientId` | link to virtual/real patient |

### Patient (`Patients`)
| Field | Use |
|-------|-----|
| `IsVirtual` | discriminator: `true` = not yet registered |
| `ContractorId` | ordering party for registered samples; **NOT used** for reminder recipient/institution |
| `email` | registered path |
| `FirstName`/`LastName` | virtual placeholder = `"PACJENT"`/`"TOXO"` |

### ReservedSampleCode (`ReservedSampleCodes`)
| Field | Use |
|-------|-----|
| `Code` | matched to `Sample.Code` |
| `InstitutionId` | **the institution used for template-family resolution and reminder recipient** |

### Institution (`Institutions`)
| Field | Use |
|-------|-----|
| `id` | membership test against `V1::Common::TOXO_INSTITUTION_IDS` → toxo family vs. lab family |
| `email_for_notifications` | reminder recipient (C/D) |

### Contractor (`Contractors`)
| Field | Use |
|-------|-----|
| `email` | ordering-party recipient for registered events (A/B/E/F) |
| `are_notifications_enabled` | gate: skip when false |
| `institution_id` | tenancy / family resolution for registered samples |

### Measurement (`Measurements`)
`ProjectId ∈ Toxo::Constants::TOXO_PROJECT_IDS` (39–42) confirms a toxo sample; ordered tests for E/F.

---

## Code constant (new)

`V1::Common::TOXO_INSTITUTION_IDS = [...]` — the hard-coded set of institutions whose samples use the toxo template family. Placed beside `LALEN_INSTITUTION_IDS = [83, 85, 89, 93, 95]`. The `Notifications::TemplateResolver` reads it.

---

## Template-family mapping

For each event, the dispatcher picks a family by institution and routes to a mailer:

| Event | Toxo family (institution ∈ TOXO_INSTITUTION_IDS) | Lab family (all other institutions) | Lab template status |
|-------|--------------------------------------------------|-------------------------------------|---------------------|
| A order confirmation | `Toxo::SampleNotificationMailer#order_confirmation` (+PDF) | existing `IndMailer#after_sample_registration` / `ThreeMethylDopaMailer` | exists |
| B sample accepted | `…#sample_accepted` | existing `SendAcceptanceNotificationsMailer` | exists |
| C registration reminder | `…#registration_reminder` | **none — new template built to toxo spec** | **created** |
| D final registration reminder | `…#registration_reminder_final` | **none — new template built to toxo spec** | **created** |
| E sample rejected | `…#sample_rejected` | existing `SendCancellationNotificationsMailer` | exists |
| F result available | `…#result_available` | existing `ContractorResultNotificationMailer` | exists |

For non-toxo samples the dispatcher delegates to the existing lab mailers (unchanged behavior). C and D have no lab counterpart, so their templates are authored fresh from spec §C/§D and are used for toxo samples now; a lab variant can reuse the same view later if lab reminders are ever needed.

---

## Records written

### Note (`notes`) — idempotency (family-neutral)
| Field | Value |
|-------|-------|
| `subject_type` | `"Sample"` |
| `subject_id` | `sample.Id` |
| `key` | one of the six keys below |
| `description` | e.g. `"[toxo] przyjęcie próbki, #{Date.today}"` — records which family was used |

Uniqueness `(subject_type, subject_id, key)` → at most one email per sample + event (FR-016), regardless of family.

**New allowed keys** (add to `Note#available_keys`):

| Event | Key |
|-------|-----|
| A | `order-confirmation-email` |
| B | `sample-accepted-email` |
| C | `registration-reminder-email` |
| D | `registration-reminder-final-email` |
| E | `sample-rejected-email` |
| F | `result-available-email` |

### ResultSendingEvent + Fileable + DbFile — audit history
One `Fileable` + built `ResultSendingEvent` (`sent_through = 1`, `sample`, `recipient`, `address`, `sent_date`) + a `DbFile` with the rendered email HTML — mirrors `SendAcceptanceNotificationsMailer#set_sendmail`. Written for both families (FR-017).
