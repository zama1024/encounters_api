# Encounters API

A secure, HIPAA-compliant REST API for managing clinical encounters with patient data protection, audit trails, and role-based access control.

## Table of Contents

- [Setup & Installation](#setup--installation)
- [Running the Project](#running-the-project)
- [Running Tests](#running-tests)
- [API Endpoints](#api-endpoints)
- [Project Structure](#project-structure)

---

## Setup & Installation

### 1. Prerequisites

Ensure you have the following installed:
- Ruby 3.1+ (check with `ruby --version`)

### 2. Install Ruby & Rails Version

If you need to switch Ruby versions, use a version manager like `rbenv` or `asdf`:

```bash
# Using rbenv
brew install rbenv
rbenv install 3.1.0
rbenv local 3.1.0

# Using asdf
asdf install ruby 3.1.0
asdf local ruby 3.1.0
```

### 3. Setup Project

```bash
# Install dependencies
bundle install

# Setup database
# This project uses SQLite, which is built into macOS by default.
RAILS_ENV=development rails db:create db:migrate
```

## Running the Project

### Start Rails Server

```bash
rails server
# or
rails s

# Server runs on http://localhost:3000
```

## Design Decisions
- I decided to use Rails for this project because it is easy to set up and build APIs.
- Rails provide an MVC pattern which provides a separation between the model and controller layer.
- The endpoints are distributed between two controllers. EncountersController and Audit::EncountersController.
- Multiple helper services(EncounterCreator, EncounterFilterService, EncountersQueryService, PaginationService etc) were created to keep the controller logic clean and create boundaries on responsibility. This allows future changes easy to handle.

## Testing Philosophy
- Request specs to test end to end behavior for strong confidence.
- Unit test on helper services to prevent errors on future changes and gain full confidence on the service behavior.

## Running Tests

### Setup Test Database

```bash
RAILS_ENV=test rails db:create db:migrate
```

### Run All Tests

```bash
bundle exec rspec
```

### Run Specific Test Files

```bash
# Encounters request specs
bundle exec rspec spec/requests/encounters_spec.rb

# Audit request specs
bundle exec rspec spec/requests/audit_encounters_spec.rb

# Pagination service specs
bundle exec rspec spec/services/pagination_service_spec.rb

# Audit query service specs
bundle exec rspec spec/services/audit/encounters_query_service_spec.rb
```


## API Endpoints

### Authentication

All endpoints require API key authentication via one of:

```bash
# Header: Authorization
-H "Authorization: ApiKey <YOUR_API_TOKEN>"

# Header: X-API-Key
-H "X-API-Key: <YOUR_API_TOKEN>"
```

### Create User

**POST /users**

Create a new user account.

```bash
curl -i -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Dr. Alice Smith"
    }
  }'
```

Response:
```json
{
  "id": 1,
  "name": "Dr. Alice Smith",
  "created_at": "2026-02-22T12:00:00Z"
}
```

---

### Create API Key

**POST /users/:id/api_keys**

Generate a new API key for a user (plaintext returned once).

```bash
curl -i -X POST http://localhost:3000/users/1/api_keys \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-production-key"
  }'
```

Response (save the `api_key` value immediately):
```json
{
  "api_key": "your-plaintext-token-here",
  "id": 123
}
```

---

### Create Encounter

**POST /encounters**

Create a new clinical encounter record.

```bash
curl -i -X POST http://localhost:3000/encounters \
  -H "Content-Type: application/json" \
  -H "Authorization: ApiKey <API_TOKEN>" \
  -d '{
    "encounterId": "enc-20260222-001",
    "patientId": "patient-5678",
    "providerId": "prov-99",
    "encounterDate": "2026-02-22T14:30:00Z",
    "encounterType": "initial_assessment",
    "clinicalData": {
      "chief_complaint": "Back pain",
      "notes": "Patient presents with acute lower back pain"
    },
    "metadata": {
      "created_at": "2026-02-22T14:30:00Z",
      "updated_at": "2026-02-22T14:30:00Z",
      "created_by": "dr_smith@clinic.com"
    }
  }'
```

Response:
```json
{
  "id": 1
}
```

---

### Get Encounter (with optional filters)

**GET /encounters/:id**

Retrieve an encounter by numeric ID or encounterId, with optional filtering.

```bash
# By numeric ID
curl -i -X GET "http://localhost:3000/encounters/1" \
  -H "Authorization: ApiKey <API_TOKEN>"

# By encounterId with filters
curl -i -X GET "http://localhost:3000/encounters/enc-20260222-001?patientId=patient-5678&encounterType=initial_assessment" \
  -H "Authorization: ApiKey <API_TOKEN>"

# With date range filters
curl -i -X GET "http://localhost:3000/encounters/1?encounterDateAfter=2026-02-01T00:00:00Z&encounterDateBefore=2026-02-28T23:59:59Z" \
  -H "Authorization: ApiKey <API_TOKEN>"
```

Response:
```json
{
  "id": 1,
  "encounterId": "enc-20260222-001",
  "patientId": "patient-5678",
  "providerId": "prov-99",
  "encounterDate": "2026-02-22T14:30:00Z",
  "encounterType": "initial_assessment",
  "clinicalData": {
    "chief_complaint": "Back pain",
    "notes": "Patient presents with acute lower back pain"
  },
  "metadata": {
    "created_at": "2026-02-22T14:30:00Z",
    "updated_at": "2026-02-22T14:30:00Z",
    "created_by": "dr_smith@clinic.com"
  },
  "createdAt": "2026-02-22T14:30:00Z",
  "updatedAt": "2026-02-22T14:30:00Z"
}
```

**Supported Filters:**
- `patientId` — filter by patient ID
- `providerId` — filter by provider ID
- `encounterType` — filter by type (initial_assessment, follow_up, treatment_session)
- `encounterDateBefore` — encounters on/before this date
- `encounterDateAfter` — encounters on/after this date

---

### Get Audit Trail (Paginated)

**GET /audit/encounters**

Retrieve audit log of encounter accesses with pagination and filtering.

```bash
# Basic query (default pagination: page=1, perPage=50)
curl -i -X GET "http://localhost:3000/audit/encounters" \
  -H "Authorization: ApiKey <API_TOKEN>"

# With date range (ISO8601 or YYYY-MM-DD format)
curl -i -X GET "http://localhost:3000/audit/encounters?startDate=2026-02-20&endDate=2026-02-25" \
  -H "Authorization: ApiKey <API_TOKEN>"

# Filter by userId and encounterId with pagination
curl -i -X GET "http://localhost:3000/audit/encounters?userId=1&encounterId=enc-20260222-001&page=1&perPage=20" \
  -H "Authorization: ApiKey <API_TOKEN>"

# Date range with ISO8601 timestamps
curl -i -X GET "http://localhost:3000/audit/encounters?startDate=2026-02-22T00:00:00Z&endDate=2026-02-22T23:59:59Z" \
  -H "Authorization: ApiKey <API_TOKEN>"
```

Response:
```json
{
  "data": [
    {
      "id": 1,
      "encounter_db_id": 1,
      "accessed_by_user_id": 5,
      "accessed_at": "2026-02-22T14:35:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "perPage": 50,
    "total": 15,
    "totalPages": 1
  }
}
```

**Supported Query Params:**
- `startDate` — filter from (YYYY-MM-DD or ISO8601)
- `endDate` — filter to (YYYY-MM-DD or ISO8601)
- `userId` — filter by user ID
- `encounterId` — filter by encounter ID
- `page` — page number (default: 1)
- `perPage` — records per page (1–1000, default: 50)

---

### Generate API Key using console (Alternate to using the API to generate API Keys)

```bash
rails console

# In the console:
user = User.create!(name: "Test User")
result = user.create_api_key!(name: "test-key")
puts result[:token]  # Copy this token for API requests
```

---

## Project Structure

### Models

**`app/models/user.rb`**
- User account model
- `has_many :api_keys`
- Methods: `create_api_key!`, `authenticate_api_key`

**`app/models/api_key.rb`**
- API key record with bcrypt-hashed token digest
- Methods: `revoke!`, `revoked?`
- Never stores plaintext token

**`app/models/encounter.rb`**
- Clinical encounter record
- Validates: encounter_id, patient_id, provider_id, encounter_date, encounter_type, clinical_data, metadata
- Stores JSONB clinical_data and metadata

**`app/models/audit_access.rb`**
- Audit trail for encounter access events
- `belongs_to :encounter`, `belongs_to :accessed_by_user`
- Tracks: who accessed which encounter and when

### Controllers

**`app/controllers/users_controller.rb`**
- `POST /users` — create user
- `POST /users/:id/api_keys` — create API key (returns plaintext once)
- `DELETE /users/:id/api_keys/:key_id` — revoke API key

**`app/controllers/encounters_controller.rb`**
- `POST /encounters` — create encounter
- `GET /encounters/:id` — retrieve encounter with optional filters
- Delegates to service layer for business logic

**`app/controllers/audit/encounters_controller.rb`**
- `GET /audit/encounters` — retrieve audit trail with pagination/filtering
- Delegates to `Audit::EncountersQueryService`

### Services

**`app/services/encounter_creator.rb`**
- Handles encounter creation, validation, and persistence
- Returns `Result` struct with success, encounter, and errors

**`app/services/encounter_serializer.rb`**
- Serializes Encounter to API response JSON
- Formats all timestamps to ISO8601

**`app/services/encounter_filter_service.rb`**
- Validates and applies filters to encounter records
- Supports: patientId, providerId, encounterType, date ranges

**`app/services/audit_recorder.rb`**
- Records encounter access events to audit_accesses table
- Called after successful encounter retrieval

**`app/services/pagination_service.rb`**
- Validates pagination params (page, perPage)
- Returns `Result` struct with page, per_page, errors
- Enforces 1–1000 limit on per_page

**`app/services/audit/encounters_query_service.rb`**
- Queries audit_accesses with filtering, date parsing, and pagination
- Delegates pagination to `PaginationService`
- Returns `Result` struct with success, records, meta, errors

### Concerns

**`app/controllers/concerns/api_authenticatable.rb`**
- Authenticates requests via `Authorization: ApiKey <token>` or `X-API-Key` header
- Sets `@current_api_user` and `@current_api_key`
- Rejects requests with invalid/missing API keys

### Initializers

**`config/initializers/log_redaction.rb`**
- Sanitizes logs to redact sensitive PHI (patient IDs, emails, SSNs, phone numbers)
- Provides `LogRedaction::RedactingFormatter` that wraps Rails loggers
- Applied to Rails, ActiveRecord, and ActionCable loggers

### Migrations

**`db/migrate/*_create_users.rb`**
- Creates users table (id, name, timestamps)

**`db/migrate/*_create_api_keys.rb`**
- Creates api_keys table (user_id, token_digest, key_name, revoked_at, timestamps)

**`db/migrate/*_create_encounters.rb`**
- Creates encounters table (encounter_id, patient_id, provider_id, encounter_date, encounter_type, clinical_data, metadata)

**`db/migrate/*_create_audit_accesses.rb`**
- Creates audit_accesses table (encounter_id, accessed_by_user_id, accessed_at)

### Specs

**`spec/requests/encounters_spec.rb`**
- Integration tests for POST /encounters and GET /encounters/:id
- Tests filtering, validation errors, 404 behavior

**`spec/requests/audit_encounters_spec.rb`**
- Integration tests for GET /audit/encounters
- Tests pagination, date filtering, camelCase params

**`spec/services/pagination_service_spec.rb`**
- Unit tests for PaginationService
- Tests valid/invalid params, defaults, boundary conditions

**`spec/services/audit/encounters_query_service_spec.rb`**
- Unit tests for Audit::EncountersQueryService
- Tests date parsing, filtering, pagination, error handling


## Security Features

- **API Key Authentication**: Bcrypt-hashed tokens, never stored plaintext
- **PHI Redaction**: Logs redact patient IDs, emails, SSNs, phone numbers
- **Audit Trail**: All encounter accesses logged with user and timestamp
- **Input Validation**: Schema validation on all API inputs with clear error messages
- **Date Filtering**: Supports both YYYY-MM-DD and ISO8601 timestamp formats
- **Pagination**: Bounded (1–1000 items per page) to prevent resource exhaustion

## Production env considerations
- **Authentication** - Currently anyone can create a user and get an API key. There's no permission needed to create an API key. In and production environment, only users with certain roles/permissions should be able to create API keys. Also, maybe add JWT based authentication as well.
- **Database** - This project uses SQLite3, we would use a more robust database like Postgres.
- **Cache** - Cache GET /encounters/:encounterId endpoint because encounters do not change.