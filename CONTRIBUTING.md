# Contributing to Dyad

Dyad is a research prototype that uses synthetic data only. Read [README.md](README.md) and
[DISCLAIMER.md](DISCLAIMER.md) before you start.

`main` is protected. Nobody pushes to it directly: every change arrives through a pull request
from a branch, and CI must pass before it can merge. Work is tracked as GitHub issues, grouped
into milestones (one per build phase) on the project board.

## Workflow

1. **Pick an issue** from the project board and move it to *In progress*.
2. **Create a branch** from an up-to-date `main`, named `<type>/<issue-number>-<short-description>`:

   ```bash
   git switch main
   git pull
   git switch -c feature/42-router-abstention
   ```

   | Type | Use for | Example |
   |---|---|---|
   | `feature/` | New functionality | `feature/42-router-abstention` |
   | `fix/` | Bug fixes | `fix/57-tokenizer-padding` |
   | `infra/` | CDK, Docker, CI/CD | `infra/31-security-stack` |
   | `chore/` | Tooling, dependencies, housekeeping | `chore/12-pre-commit` |
   | `docs/` | Documentation, ADRs | `docs/88-dpia-draft` |
   | `test/` | Tests only | `test/64-point-in-time-join` |

   Use lowercase with hyphens, and keep it short. One issue per branch.
3. **Make the change** and run the [checks](#checks) locally.
4. **Commit** with a conventional message scoped to the module:

   ```bash
   git add <files>
   git commit -m "feat(router): add per-field abstention"
   ```

   Types: `feat`, `fix`, `chore`, `docs`, `test`, `infra`, `refactor`. Scopes are module names
   (`router`, `ingest`, `agents`, ...), or `kernel`, `infra`, `ci`, `docs`.
5. **Push and open a pull request:**

   ```bash
   git push -u origin feature/42-router-abstention
   gh pr create --fill        # or open it on GitHub
   ```

   Fill in the [PR template](.github/pull_request_template.md) and put `Closes #42` in the
   description, so merging the PR closes the issue and moves its card to *Done*.
6. **Merge** once CI is green and review comments are resolved. Squash merge, then delete the branch.

## Keeping a branch up to date

`main` keeps a linear history, so update your branch by rebasing rather than merging:

```bash
git fetch origin
git rebase origin/main
git push --force-with-lease      # only ever on your own feature branch
```

## Checks

Every pull request must pass these before review:

```bash
uv run ruff check . && uv run ruff format --check .
uv run mypy src
uv run lint-imports
uv run pytest
uv run pytest -m integration     # when adapters or flows changed, with Floci running
npx cdk synth                    # when infra changed
```

In the PR, say which checks you skipped or which failed, and why.

## Code practices

- **Module boundaries.** Modules never import each other. Shared needs become a contract or a
  port in `src/dyad/kernel/`, and every kernel addition is questioned first.
- **Thin handlers, pure domain.** `handler.py` parses the event, calls one function from
  `domain/` and shapes the response. `domain/` has no boto3, no environment reads and no network.
  Only `adapters/` touch AWS.
- **Typed and formatted.** Python 3.12, ruff (line length 100), type hints on every function
  signature, checked with mypy.
- **Dependencies through uv.** Add them with `uv add --group <group> <pkg>`, in the narrowest
  group that needs them. Never edit `uv.lock` by hand. Ask before adding anything to `core`.
- **Contracts.** Pydantic v2 models in `kernel/contracts/v1/`, frozen. Changes are additive within
  a major version, and a breaking change becomes a new version. Exported JSON Schema in
  `contracts/` is generated, not hand-edited.
- **Errors.** Raise specific exception types, with no bare `except`. Retryable handlers are
  idempotent. Fail closed on safety and privacy decisions: escalate to a human, never guess.
- **Logging.** Log IDs, tokens, model versions, routes and latencies. Never log message text,
  prompts, model responses or raw identifiers.
- **SQL.** Athena SQL lives in `sql/`, with a header comment giving the table grain and contract
  version. Transforms are idempotent.
- **Infrastructure.** Use the shared constructs in `infra/constructs/`. IAM is least privilege and
  scoped per module. No hard-coded account IDs, regions or endpoints.
- **Style.** Comments explain why, not what. No dead code, no commented-out code, and no TODOs
  without an issue reference.

## Testing practices

- Unit tests go in `tests/modules/<name>/` and use fakes of the kernel ports, not mocks of internals.
- A bug fix starts with a failing test.
- Router changes are tested at each threshold edge and also cover the emergent override,
  per-field abstention and circuit-breaker widening.
- Golden-set tests use fixed, seeded synthetic cases and must be deterministic.
- Integration tests run only against Floci and carry the `integration` marker. Floci is not AWS:
  Athena Iceberg SQL and Bedrock calls are unverified until run against a real account, so say
  which is which in the PR.

## Rules of thumb

- **One issue per pull request,** and keep it small enough to review in one sitting.
- **Kernel and contract changes get their own PR.** They redeploy every module, so label them
  `touches:kernel-or-contract` and say so in the description.
- **No secrets and no real patient data,** ever. Pre-commit runs gitleaks, but check yourself.
- **Safety rules are not loosened in passing.** Changes to routing thresholds, the emergent
  override or the policy gate need their own PR with tests and an explanation.
- **Careful wording.** Say "aligned with" or "mapped to" for GDPR, EHDS, ISO 27001 and the EU AI
  Act, never "compliant" or "certified". Jev figures are vendor-reported, so quote only this
  repo's own benchmark results.
- **Releases are per module,** tagged like `router-v0.3.0`.

## Using Claude Code

Claude Code works in the working tree only. It is blocked from committing and pushing, so you
run the git commands above yourself. It ends each task by suggesting a branch name and a commit
message. Its standards live in `.claude/skills/dyad-standards/`.
