# Fizzy

This file provides guidance to AI coding agents working with this repository.

## What is Fizzy?

Fizzy is a collaborative project management and issue tracking application built by 37signals/Basecamp. It's a kanban-style tool for teams to create and manage cards (tasks/issues) across boards, organize work into columns representing workflow stages, and collaborate via comments, mentions, and assignments.

## Development Commands

### Setup and Server
```bash
bin/setup              # Initial setup (installs gems, creates DB, loads schema)
bin/dev                # Start development server (runs on port 3006)
```

Development URL: http://fizzy.localhost:3006
Login with: david@37signals.com (development fixtures), password will appear in the browser console

### Testing
```bash
bin/rails test                    # Run unit tests (fast)
bin/rails test test/path/file_test.rb  # Run single test file
bin/rails test:system             # Run system tests (Capybara + Selenium)
bin/ci                            # Run full CI suite (style, security, tests)

# For parallel test execution issues, use:
PARALLEL_WORKERS=1 bin/rails test
```

CI pipeline (`bin/ci`) runs:
1. Rubocop (style)
2. Bundler audit (gem security)
3. Importmap audit
4. Brakeman (security scan)
5. Application tests
6. System tests

### Database
```bash
bin/rails db:fixtures:load   # Load fixture data
bin/rails db:migrate          # Run migrations
bin/rails db:reset            # Drop, create, and load schema
```

### Other Utilities
```bash
bin/rails dev:email          # Toggle letter_opener for email preview
bin/jobs                     # Manage Solid Queue jobs
bin/kamal deploy             # Deploy (requires 1Password CLI for secrets)
```

## Architecture Overview

### Multi-Tenancy (URL-Based)

Fizzy uses **URL path-based multi-tenancy**:
- Each Account (tenant) has a unique `external_account_id` (7+ digits)
- URLs are prefixed: `/{account_id}/boards/...`
- Middleware (`AccountSlug::Extractor`) extracts the account ID from the URL and sets `Current.account`
- The slug is moved from `PATH_INFO` to `SCRIPT_NAME`, making Rails think it's "mounted" at that path
- All models include `account_id` for data isolation
- Background jobs automatically serialize and restore account context

**Key insight**: This architecture allows multi-tenancy without subdomains or separate databases, making local development and testing simpler.

### Authentication & Authorization

**Passwordless magic link authentication**:
- Global `Identity` (email-based) can have `Users` in multiple Accounts
- Users belong to an Account and have roles: admin, member, system
- Sessions managed via signed cookies
- Board-level access control via `Access` records

### Core Domain Models

**Account** → The tenant/organization
- Has users, boards, cards, tags, webhooks
- Has entropy configuration for auto-postponement

**Identity** → Global user (email)
- Can have Users in multiple Accounts
- Session management tied to Identity

**User** → Account membership
- Belongs to Account and Identity
- Has role (admin/member/system)
- Board access via explicit `Access` records

**Board** → Primary organizational unit
- Has columns for workflow stages
- Can be "all access" or selective
- Can be published publicly with shareable key

**Card** → Main work item (task/issue)
- Sequential number within each Account
- Rich text description and attachments
- Lifecycle: triage → columns → closed/not_now
- Automatically postpones after inactivity ("entropy")

**Event** → Records all significant actions
- Polymorphic association to changed object
- Drives activity timeline, notifications, webhooks
- Has JSON `particulars` for action-specific data

### Entropy System

Cards automatically "postpone" (move to "not now") after inactivity:
- Account-level default entropy period
- Board-level entropy override
- Prevents endless todo lists from accumulating
- Configurable via Account/Board settings

### UUID Primary Keys

All tables use UUIDs (UUIDv7 format, base36-encoded as 25-char strings):
- Custom fixture UUID generation maintains deterministic ordering for tests
- Fixtures are always "older" than runtime records
- `.first`/`.last` work correctly in tests

### Background Jobs (Solid Queue)

Database-backed job queue (no Redis):
- Custom `FizzyActiveJobExtensions` prepended to ActiveJob
- Jobs automatically capture/restore `Current.account`
- Mission Control::Jobs for monitoring

Key recurring tasks (via `config/recurring.yml`):
- Deliver bundled notifications (every 30 min)
- Auto-postpone stale cards (hourly)
- Cleanup jobs for expired links, deliveries

### Sharded Full-Text Search

16-shard MySQL full-text search instead of Elasticsearch:
- Shards determined by account ID hash (CRC32)
- Search records denormalized for performance
- Models in `app/models/search/`

## Production Observability

Grafana MCP tools provide access to production metrics and logs for performance analysis.

### Datasources
| Name | UID | Use |
|------|-----|-----|
| Thanos (Prometheus) | `PC96415006F908B67` | Metrics, latencies |
| Loki | `e38bdfea-097e-47fa-a7ab-774fd2487741` | Application logs |

### Key Metrics
- `rails_request_duration_seconds_bucket:rate1m:sum_by_app:quantiles{app="fizzy"}` - Request latency percentiles
- `rails_request_total:rate1m:sum_by_controller_action{app="fizzy"}` - Request rates by endpoint
- `fizzy_replica_wait_seconds` - Database replica consistency wait times

### Loki Log Labels and Query Patterns

**Base label selector:**
```logql
{service_namespace="fizzy", deployment_environment_name="production", service_name="rails"}
```

**Useful JSON fields:** `event_duration_ms`, `performance_time_db_ms`, `performance_time_cpu_ms`, `rails_endpoint`, `rails_controller`, `url_path`, `authentication_identity_id`, `http_response_status_code`

**Query patterns:**
- Filter by fields: `{labels} | field_name = "value"`
- Multiple field filters: `{labels} | field1 = "value1" | field2 = "value2"`
- Reduce returned labels: `{labels} | filters | keep field1,field2,field3` (reduces label payload)
- Minimize log line content: `{labels} | filters | line_format "{{.field_name}}"` (replaces raw log line)
- Combine both for minimal tokens: `{labels} | filters | keep field1,field2 | line_format "{{.field1}}"`
- **Important:** Fields are pre-parsed by the OTel collector. Don't use string search (`|=`) when filtering structured fields
- **Important:** Do NOT use `| json` - it will cause JSONParserErr since fields are already parsed as labels

**Token management (CRITICAL):**
- Always probe with `limit: 3` first to check response size before running larger queries
- Aggregations return time series (many data points), not single values - can explode token usage
- NEVER use `sum by (field)` - returns a time series per unique value, easily exceeds token limits
- For breakdowns by field: fetch raw logs with `| keep field | line_format "{{.field}}"` and count client-side

**Aggregations for statistics (use instead of fetching raw logs):**
- `mcp__grafana__query_loki_logs` returns limited results (default 10, max ~100) and large responses get truncated; use aggregations for statistics on large datasets
- Count: `sum(count_over_time({labels} | filters [12h]))`
- Percentiles: `quantile_over_time(0.95, {labels} | filters | unwrap field_name | __error__="" [12h]) by ()`
- Average: `avg_over_time({labels} | filters | unwrap field_name | __error__="" [12h]) by ()`
- Min/Max: `min_over_time(...)` / `max_over_time(...)`
- The `| unwrap field_name | __error__=""` pattern extracts numeric values from pre-parsed labels
- Use `by ()` or wrap in `sum()` to avoid cardinality limits

**Documentation:** For advanced LogQL syntax (aggregations, pattern matching, etc.), consult https://grafana.com/docs/loki/latest/query/

### Instrumentation
Yabeda-based metrics exported at `:9394/metrics`. Config in `config/initializers/yabeda.rb`.

### Chrome MCP (Local Dev)
URL: `http://fizzy.localhost:3006`
Login: david@37signals.com (passwordless magic link auth - check rails console for link)

Use Chrome MCP tools to interact with the running dev app for UI testing and debugging.

### Sentry Error Tracking
Organization: `basecamp` | Project: `fizzy` | Region: `https://us.sentry.io`

Use Sentry MCP tools to investigate production errors:
- `search_issues` - Find grouped issues by natural language query
- `get_issue_details` - Get full stacktrace and context for a specific issue
- `analyze_issue_with_seer` - AI-powered root cause analysis with code fix suggestions

## Coding style

Please read the separate file `STYLE.md` for some guidance on coding style.
