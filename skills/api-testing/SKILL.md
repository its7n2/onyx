---
name: api-testing
description: API security testing for authorized pentest targets — REST and GraphQL. Covers BOLA/IDOR on object IDs, broken authentication and authorization per endpoint and role, mass assignment, excessive data exposure, injection, and rate-limit checks. Use when the user mentions testing an API, Swagger/OpenAPI spec, GraphQL, BOLA, mass assignment, API keys/tokens, endpoints, or is running an api engagement.
---

# API Security Testing

APIs leak by design pattern: the same object ID gets checked for ownership in the UI but not the backend. Test the backend, not the UI. Target API must be in `scope.md`.

## Phase 1 — Get the full surface

- **Spec first:** `swagger.json` / `openapi.json` / GraphQL introspection (if enabled). Common locations: `/swagger`, `/api-docs`, `/openapi.json`, `/graphiql`, `/v1/../v3/` — try version increments; old API versions often lack fixes applied to current ones.
- **No spec? Reconstruct it:** mine JS bundles for endpoints, watch proxy traffic for base URLs, and probe REST conventions (`/api/v1/users`, `/api/v1/users/1`, plural/singular variants).
- **Document:** every endpoint × method × parameters × expected role in `<activity>/api/surface.md`. The matrix is the test plan.

## Phase 2 — Test the matrix

- **BOLA (object-level authz):** for every endpoint taking an object ID, call it with another user's object ID. UUIDs aren't authorization. Test sequential IDs, UUIDs leaked in other responses, and IDs from user A's data used by user B.
- **Function-level authz:** call admin endpoints (`/admin/*`, role-specific operations) as a regular user. Enumerate roles if registration allows role hints.
- **Mass assignment:** add privileged fields to requests — `"role":"admin"`, `"isAdmin":true`, `"price":0`, `"verified":true`. Compare against the spec: fields that exist in responses but not requests are the candidates.
- **Excessive data exposure:** diff what the API returns vs what the UI renders. Password hashes, tokens, internal flags, and other users' data in responses are findings.
- **Auth itself:** token lifetime, missing expiration, token reuse after logout/password change, JWT claims tampering (alg confusion, weak secret), API key scope confusion (one key, many scopes).
- **Injection:** query params, headers, GraphQL arguments; GraphQL-specific — batch queries to bypass rate limits, depth/complexity abuse detection, field suggestions for hidden data, mutation abuse.
- **Rate limiting:** measure, don't hammer — time 20 requests, check for 429s. Missing rate limit on auth/otp/reset endpoints is the finding; brute-force demos need explicit RoE coverage.

## Phase 3 — Evidence

One file per finding in `<activity>/findings/` using `templates/finding.md`, raw request/response pairs inline. For BOLA chains, capture both accounts' requests side by side in the same file.

## Rules

- Register your own test accounts; never enumerate real users' objects beyond the single proof record.
- Version-diff findings matter: a bug in `/v1/` that's fixed in `/v2/` is still a finding if `/v1/` is live.
