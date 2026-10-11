# Python standards for Dyad

## Tooling (uv)

- Python 3.12, managed with uv. Add dependencies with `uv add --group <core|agents|ml|infra|dev> <pkg>`
  (runtime dependencies without `--group`). Never edit `uv.lock` by hand and never call pip directly.
- CI uses `uv sync --locked --all-groups`, so the lockfile must match `pyproject.toml`.
- Format and lint with ruff (line length 100). Type hints on every function signature, checked with mypy.
- Each module's `module.yaml` names its `dependency_group`. Keep Lambda bundles small: a dependency
  belongs in the narrowest group that needs it. OR-Tools and LightGBM never go in `core`.
- `boto3` is a dev dependency only, because the Lambda runtime provides it.
- Do not add a dependency for something the standard library or an existing dependency already does.

## Structure

- `handler.py` is thin: parse the event, call one function from `domain/`, shape the response.
- `domain/` is pure Python. No boto3, no environment reads, no network. Everything arrives through
  arguments or ports.
- `adapters/` implements kernel ports with boto3, the Jev HTTP client, and so on. No business rules.
- Ports are `typing.Protocol` classes in `kernel/ports.py`. Tests use in-memory fakes of them.
- System 1 is always called through `System1Port`. The Jev client and the local stub both implement
  it, and an environment variable selects which.
- Never import from another module. Shared needs become a contract or a port in the kernel, and
  every kernel addition is questioned first. `uv run lint-imports` must pass.

## Data and contracts

- Contracts are pydantic v2 models in `kernel/contracts/v1/`, frozen
  (`model_config = ConfigDict(frozen=True)`). Validate external input at the boundary only.
- Within a major version, changes are additive: new optional fields. A breaking change is `v2`,
  with producer and consumer migrated separately.
- Consumers are tolerant readers: ignore unknown fields, validate only what they use.
- Export JSON Schema into `contracts/` from the models. Exported files are generated, not hand-edited.
- Datetimes are timezone-aware UTC. Never call `datetime.now()` in domain code. Take a `Clock` port.
- Probabilities are floats in [0, 1] and validated. Identifiers are opaque strings or UUIDs.

## Errors and reliability

- Raise specific exception types defined in the module. No bare `except`. `except Exception` only at
  the handler boundary, where you log and re-raise or return a typed failure.
- Retryable handlers are idempotent, using a key derived from the event ID, never a random value.
- Retries and timeouts live in Step Functions or Lambda configuration, not in ad hoc loops.
- Fail closed on safety and privacy decisions: if the policy check, the tokenizer or a confidence
  value is missing or invalid, escalate to a human and do not guess.

## Logging and secrets

- Use Powertools structured logging. Log IDs, tokens, model versions, routes and latencies.
- Never log message text, names, dates of birth or any raw identifier, even at debug level. Never
  log full prompts or model responses.
- No secrets in code, config, tests or logs. Read them from SSM or Secrets at runtime.

## SQL

- Athena SQL lives in `sql/` as files with a header comment stating the table grain and contract
  version. No inline SQL strings in handlers.
- Transforms are idempotent (safe to rerun) and partitioned by decision date.

## Testing

- pytest. Unit tests per module in `tests/modules/<name>/`, using fakes rather than mocks of internals.
- Contract tests in `tests/contract/` check producer output against consumer expectations.
- Router tests cover each threshold edge, the emergent override, per-field abstention, and the
  circuit-breaker widening.
- A point-in-time join test proves that evaluation never sees labels or features from after the
  decision time.
- Golden-set tests use fixed, seeded synthetic cases with known answers and must be deterministic.
- A bug fix starts with a failing test.

## Local emulation (Floci)

- Integration tests run only against Floci (`AWS_ENDPOINT_URL=http://localhost:4566`) and carry the
  `integration` marker. They live in `tests/integration/`.
- Clients read the endpoint and credentials from the environment. Never hard-code them.
- `tests/conftest.py` refuses to run integration tests unless the endpoint is local. Never weaken it.
- Smoke tests in `tests/integration/smoke/` cover the risky services: DynamoDB Streams to Lambda,
  Step Functions task tokens, KMS data keys, S3 Object Lock.
- Floci is not AWS. Athena Iceberg SQL and Bedrock calls are unverified until run against a real
  account, and the summary must say so.
- Do not start or stop Docker containers without asking.

## Style

- Names say what a thing is, not how it works. Small functions with one job. Prefer composition
  over inheritance and typed return values over mutating inputs.
- Docstrings on public functions and classes: one or two lines on behaviour and units. Comments
  explain why, never what.
- No dead code, no commented-out code, no TODOs without an issue reference.

## Infrastructure (CDK)

- Buckets, tables and keys come from the shared constructs in `infra/constructs/`, which enforce
  encryption, blocked public access and sensible removal policies.
- IAM is least privilege and scoped per module. Agent tools get a separate read-only role.
- No hard-coded account IDs or regions. Cross-stack lookups use SSM parameters, not CloudFormation exports.
- Object Lock must be set when the audit bucket is created. It cannot be added later.
- Run `npx cdk synth` and read the diff before suggesting a deploy. Do not deploy.

## Definition of done

```
uv run ruff check . && uv run ruff format --check .
uv run mypy src
uv run lint-imports
uv run pytest
uv run pytest -m integration     # when adapters or flows changed, with Floci running
npx cdk synth                    # when infra changed
```

Report any check that was skipped or failing, and why. Do not commit or push.
