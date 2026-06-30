# Contract: External Lalen Portal API — Assign Kit Tests

**Direction**: api_masdiag → Lalen Portal API (outbound)
**Auth**: HTTP Basic (same credentials as `register_kit` endpoint, stored in Rails credentials under `lalenportalapi`)

---

## POST /kit_tests

Assigns one or more tests to a kit on the external Lalen portal.

### Request

```
POST /kit_tests
Content-Type: application/json
Authorization: Basic <base64(username:password)>
```

**Body**:

```json
{
  "barcode": "AU1234567",
  "tests": ["vitamin_d", "aminoacids"]
}
```

| Field     | Type            | Required | Notes                                              |
|-----------|-----------------|----------|----------------------------------------------------|
| `barcode` | String          | Yes      | Kit barcode, uppercase                             |
| `tests`   | Array\<String\> | Yes      | One or more `api_key` slugs; replaces all existing |

### Responses

| Status | Meaning                         | Action in job                              |
|--------|---------------------------------|--------------------------------------------|
| 201    | Tests assigned successfully     | Job completes normally                     |
| 404    | Kit not found on external side  | Job returns (silent no-op, no retry)       |
| 422    | Validation error                | Raises `LalenApi::Error` → triggers retry  |
| 4xx/5xx other | External error           | Raises `LalenApi::Error` → triggers retry  |

### Success response body (201)

```json
{
  "barcode": "AU1234567",
  "kit_status": "ACTIVE",
  "tests": ["vitamin_d", "aminoacids"]
}
```

The response body is logged but not processed by the job.

---

## Connection

Reuses `LalenApi::Client.instance.connection` — a persistent Faraday connection with:
- Base URL: `Rails.application.credentials.lalenportalapi.url`
- Basic auth middleware applied
- JSON request/response middleware
- Debug logging via `Rails.logger`
