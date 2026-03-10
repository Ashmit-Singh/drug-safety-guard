# API Versioning Strategy

## Current State
- **v1**: Active, production-ready (`/api/v1/*`)
- **v2**: Stub, under development (`/api/v2/*`)

## Versioning Rules

1. **URL-based versioning**: `/api/v1/`, `/api/v2/`
2. **v1 is frozen**: No breaking changes to v1 after v2 launch
3. **Both versions run simultaneously** during migration window
4. **Deprecation timeline**: v1 receives security patches for 12 months after v2 GA

## What Constitutes a Breaking Change?
- Removing or renaming a field in the response envelope
- Changing pagination from offset-based to cursor-based
- Changing HTTP status codes for existing flows
- Removing an endpoint

## Migration from v1 → v2

### v2 Breaking Changes (planned)
1. **Cursor-based pagination** — All list endpoints use `?cursor=<ISO8601>` instead of `?offset=N`
2. **Strict response envelope** — All responses include `_links` (HATEOAS)
3. **Typed error codes** — Error `code` field uses dot-notation (e.g., `auth.token_expired`)

### Non-Breaking Additions to v1
These are safe to add without version bump:
- New optional query parameters
- New fields in response objects
- New endpoints
- New enum values (if clients handle unknown gracefully)

## Headers
- `X-API-Version`: Response header indicating the version served
- `X-Request-Id`: Correlation ID for distributed tracing

## Client Migration Guide
1. Update base URL from `/api/v1` to `/api/v2`
2. Replace `offset` pagination with `cursor` pagination
3. Handle new `_links` fields in responses
4. Update error handling for new error code format
