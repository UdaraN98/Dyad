# Dyad

A research prototype for clinical decision support on AWS (fast System One model, slow
agents, human gate, OLTP/OLAP split, model monitoring). Synthetic data only. Not a medical device.

Use the `dyad-standards` skill for all work in this repo. Read
`.claude/skills/dyad-standards/references/constraints.md` before starting any task.

## Non-negotiable

- NEVER run `git commit`, `git push`, `git merge`, `git rebase`, `git tag` or `gh pr create`.
  Leave changes uncommitted, summarise them, suggest a branch name and commit message in text.
  The owner commits and pushes.
- Ask before `cdk deploy`, `cdk destroy`, any real AWS call, or starting/stopping Docker.
- Never read or print `.env` files or secrets. Never use real patient data.
- Never loosen `.claude/settings.json`, the hooks, or the constraints. Propose changes to the owner.
- If a task conflicts with a constraint, stop and ask.

## Commands

```
uv sync --all-groups
uv run ruff check . && uv run ruff format --check .
uv run mypy src
uv run lint-imports
uv run pytest
uv run pytest -m integration     # needs Floci running locally
npx cdk synth
```

Report any check you skipped or that failed.
