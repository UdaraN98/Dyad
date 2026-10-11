## Summary

<!-- What does this change, and why? Two or three sentences. -->

Closes #

## Type of change

- [ ] Feature
- [ ] Bug fix
- [ ] Infrastructure (CDK, Docker, CI/CD)
- [ ] Refactor, no behaviour change
- [ ] Tests only
- [ ] Documentation or ADR
- [ ] Chore (tooling, dependencies)

## Modules affected

<!-- e.g. router, ingest. Write "none" for docs-only changes. -->

## Release impact

- [ ] Only the modules listed above need redeploying
- [ ] Touches `src/dyad/kernel/` or a contract, so **every module redeploys** (labelled `touches:kernel-or-contract`)
- [ ] Contract change is additive within its major version, or a new version is added
- [ ] Platform stack change (needs manual approval to deploy)

## How it was tested

- [ ] `uv run ruff check . && uv run ruff format --check .`
- [ ] `uv run mypy src`
- [ ] `uv run lint-imports`
- [ ] `uv run pytest`
- [ ] `uv run pytest -m integration` against Floci (if adapters or flows changed)
- [ ] `npx cdk synth` (if infrastructure changed)

**Verified where:**

- [ ] Unit tests with fakes
- [ ] Floci (local emulator)
- [ ] Real AWS (required if the issue is labelled `needs:real-aws`)

<!-- Anything skipped or failing, and why: -->

## Safety and privacy checklist

- [ ] No secrets, keys or `.env` files committed
- [ ] No real patient data, synthetic only
- [ ] No raw identifiers or message text sent to models or written to logs
- [ ] Routing and safety rules unchanged (emergent override, fail closed, circuit breaker only widens), **or** the change is explained below
- [ ] Docs wording says "aligned with", never "compliant"

## Notes for the reviewer

<!-- Design decisions, trade-offs, follow-up issues, anything unverified. Screenshots or query output if useful. -->