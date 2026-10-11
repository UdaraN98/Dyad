# Dyad business logic

These rules encode safety and privacy decisions. Do not weaken, bypass or "simplify" them. If a task seems to require it, stop and ask the owner.

## Domain

Incoming patient messages and referral letters (synthetic) are triaged for urgency, specialty and resource need. Scarce slots and beds are allocated across pending cases. A clinician makes every clinical decision of consequence. The system recommends and routes. It never diagnoses.

## Decision schema (System 1)

- The System 1 model returns typed fields, each with a calibrated confidence: `urgency` (routine, urgent, emergent), `specialty`, `resource_need`, `missing_information`.
- Each categorical field has at most 255 options (a limit of the Jev model). The taxonomy is versioned in `contracts/taxonomy.v1.json`. Changing it is a breaking change.
- Jev is early access and its speed and accuracy claims are vendor-reported. Code and docs must not state them as measured facts. Only numbers from our own benchmark are quoted.
- System 1 is always called through `System1Port`. The Jev client and the local stub both implement it, and an environment variable selects which. Domain code never imports either directly.

## Routing

- Costs are asymmetric: under-triage (calling an urgent case routine) costs far more than over-escalation. Thresholds come from an expected-cost calculation, not a single confidence cutoff.
- Any `urgency = emergent` prediction goes to a human regardless of confidence.
- Low confidence on a field abstains for that field only. The case goes to the slow path for that field and does not discard the confident fields.
- Missing, malformed or out-of-range confidence means escalate. Never default to routine.
- Thresholds are read from SSM Parameter Store, not hard-coded.
- The circuit breaker may only widen the grey zone (send more cases to the slow path and to humans). It must never narrow it automatically. Narrowing needs a human change.
- Every routing outcome records which rule fired.

## Slow path and human gate

- System 2 agents read only through the policy gate and a separate read-only role. Their tools cannot write to the transactional store.
- A clinician must approve any urgent or emergent case, any agent-recommended override of System 1, and any case where the critic and the optimizer disagree. The approval carries the Step Functions task token.
- No clinical outcome is decided solely by automated processing. The final recorded decision always names who or what made it and whether a human reviewed it.
- Agent output must cite the guideline chunks it used. A recommendation without retrieved evidence is rejected, not shown.

## Privacy and security

- Tokenize before anything leaves the ingest boundary. Jev, Bedrock and any logging see tokens, never names, dates of birth, contact details or other raw identifiers.
- Tokenized data is pseudonymised, not anonymous. It is still personal data. Never call it anonymised or de-identified in code, docs or comments.
- The audit log bucket stores tokens and references only. This is what lets erasure work: per-patient data keys are wrapped by one KMS key, and deleting a patient's data key makes their records unreadable (crypto-shredding).
- Every table carries a purpose tag. The policy gate checks consent, purpose and restriction or opt-out flags before any agent tool reads a record, and fails closed.
- Real patient data is never used, imported or committed. Synthetic data only.

## Data

- Transactional store is DynamoDB (patients, messages, decisions, outbox, consent flags). Analytical store is S3 with Iceberg tables queried by Athena (bronze raw, silver validated, gold facts and features).
- Writes to the transactional store use the outbox pattern. DynamoDB Streams feeds the CDC publisher. Events carry a stable ID and the lake write deduplicates on it.
- The `decisions` fact table has one row per decision event: message token, per-field outputs and confidences, model name and version, route taken, rule fired, human reviewer flag, timestamps, and later the outcome. Corrections append, they do not overwrite history.
- Outcomes arrive late. Evaluation joins use point-in-time data: only features and labels that existed at decision time, matched to the model version that decided.
- Model versions are pinned and stored with every decision. A model upgrade is treated like a schema migration and never silently reprocesses history.
- Contract validation happens at the silver boundary. Invalid records go to a quarantine location, never silently dropped.

## Monitoring

- Every model call writes a `model_calls` record: input reference (a token, not text), output, confidence, version, latency, cost.
- Headline safety metric: under-triage rate (System 1 said routine, a clinician said urgent). Also track calibration per field, confidence distribution drift (PSI), routing mix, agent-versus-clinician agreement, citation faithfulness, forecast error and interval coverage.
- Three tiers: immediate signals without labels, fast proxy labels such as overrides and disagreements, and delayed ground-truth outcomes.
- A new model or prompt first runs in shadow against the golden set before it can serve traffic.
- Thresholds breached for safety metrics raise an alarm and trigger the circuit breaker. Every breach and action is recorded immutably.

## Language rules for docs and comments

- Say "aligned with" or "mapped to" for GDPR, EHDS, ISO 27001 and the EU AI Act. Never "compliant" or "certified".
- State clearly in the README and any demo that this is a research prototype, not a medical device, and that all data is synthetic.
