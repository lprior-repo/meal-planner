# Web Routing Specification

## MODIFIED Requirements

### Requirement: HTTP Request Routing
The system SHALL route HTTP requests to appropriate handlers based on path segments.

The system routes requests as follows:
- `GET /` or `GET /health` → Health check
- `POST /api/ai/score-recipe` → Recipe scoring
- `GET /api/diet/vertical/compliance/{recipe_id}` → Diet compliance check
- `POST /api/macros/calculate` → Macro calculation
- **`GET /metrics` → Prometheus metrics export** (ADDED)

#### Scenario: Route metrics request
- **WHEN** GET /metrics is requested
- **THEN** the metrics handler is invoked
- **AND** Prometheus format metrics are returned
- **AND** status 200 OK is returned

#### Scenario: Existing routes unchanged
- **WHEN** existing routes are requested (/, /health, /api/*)
- **THEN** existing handlers process the request
- **AND** no behavior changes occur
